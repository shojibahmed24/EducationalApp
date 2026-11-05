// Random-offset guide-quiz sampling (Phase 2, plan §2 step 1).
// Replaces the old full-chapter download (fetchPool): per-chapter
// MCQ totals via the EXISTING list action (section=mcq_bank,
// limit=1), proportional allocation across chapters, one 50-row
// page per chapter at a random offset, refills when a page yields
// too few scorable rows. Sampled rows NEVER touch the chapter
// cache — cacheChapter is never called here, so a partial page
// can never poison the full-chapter cache. No Edge deploy, no
// new endpoint, no new action. Daily sampling is seeded (same
// day = same set); practice sampling is random + seen-excluded
// with a seen-refill round when the unseen pool runs short.
import 'dart:math';

import '../models/guide_bank_model.dart';
import 'app_config.dart';
import 'books_service.dart';
import 'edge_post.dart';
import 'guide_quiz_pool.dart';

typedef GuideQuizPost = Future<Map<String, dynamic>?> Function(
    Map<String, dynamic> body, {String? endpoint});

/// One chapter's sampling frame: the MCQ total and whether the
/// server honoured the section filter for it.
class ChapterFrame {
  final int chapter;
  final int total;
  final bool sectionFiltered;
  const ChapterFrame(this.chapter, this.total, this.sectionFiltered);
}

class GuideQuizSampling {
  GuideQuizSampling({GuideQuizPost? post})
      : _post = post ?? edgePost,
        _customPost = post != null;
  final GuideQuizPost _post;
  final bool _customPost;

  static const pageSize = 50;

  Future<Map<String, dynamic>?> _list(Map<String, dynamic> body) async {
    if (!_customPost && AppConfig.guideBankEndpoint.isEmpty) return null;
    return _post(body, endpoint: AppConfig.guideBankEndpoint);
  }

  /// Chapters with guide rows: guide-native chapters first (the
  /// server's own list, so chapters without rows cost nothing),
  /// textbook chapters when the server reports none. The
  /// guide-chapters call goes through the injected [_post] (same
  /// endpoint + shape as guideBankService.fetchGuideChapters) so
  /// tests can fake the whole sampling frame offline.
  Future<List<int>> chapters({
    required String subject,
    required int schoolClass,
  }) async {
    final res = await _list({
      'action': 'guideChapters',
      'classId': schoolClass,
      'subject': subject,
    });
    if (res != null && res['found'] == true) {
      final list = res['guideChapters'];
      if (list is List) {
        final numbers = list
            .whereType<Map>()
            .map((e) => (e['chapter'] as num?)?.toInt())
            .whereType<int>()
            .toList()
          ..sort();
        if (numbers.isNotEmpty) return numbers;
      }
    }
    final textbook = await booksService.chaptersForSubjectAsync(
        schoolClass, subject, true);
    if (textbook == null || textbook.isEmpty) return const [];
    return textbook.map((c) => c.number).toList();
  }

  /// One chapter's sampling frame. Section-filtered total when
  /// the server echoes the filter; otherwise the unfiltered
  /// chapter total (a valid frame — page rows are always
  /// client-filtered by isScorableGuideMcq, so an ignored filter
  /// costs efficiency, never correctness).
  Future<ChapterFrame> frame({
    required String subject,
    required int schoolClass,
    required int chapter,
  }) async {
    final res = await _list({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      'section': 'mcq_bank',
      'offset': 0,
      'limit': 1,
    });
    if (res != null &&
        res['found'] == true &&
        res['section'] == 'mcq_bank') {
      return ChapterFrame(
          chapter, (res['total'] as num?)?.toInt() ?? 0, true);
    }
    final all = await _list({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      'offset': 0,
      'limit': 1,
    });
    if (all == null || all['found'] != true) {
      return ChapterFrame(chapter, 0, false);
    }
    return ChapterFrame(
        chapter, (all['total'] as num?)?.toInt() ?? 0, false);
  }

  /// One 50-row page at [offset] from a chapter frame, parsed
  /// to list rows (never cached).
  Future<List<GuideBankQuestion>> _page({
    required String subject,
    required int schoolClass,
    required ChapterFrame frame,
    required int offset,
  }) async {
    final body = {
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': frame.chapter,
      'offset': offset,
      'limit': pageSize,
    };
    if (frame.sectionFiltered) body['section'] = 'mcq_bank';
    final res = await _list(body);
    if (res == null || res['found'] != true) return const [];
    final rows = res['questions'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((r) => GuideBankQuestion.fromServerJson(
            r.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  /// Stable djb2 seed (mirrors question_generation._seed, which
  /// is private): same seedKey string = same offsets every run.
  int _seed(String key) {
    var h = 5381;
    for (final c in key.codeUnits) {
      h = ((h << 5) + h + c) & 0x7fffffff;
    }
    return h;
  }

  /// Sample up to [want] scorable candidates across chapters.
  /// [seedKey] (daily) fixes every offset/pick; null (practice)
  /// uses a fresh Random. [seenIds] excludes seen rows on the
  /// first pass; a shortfall refills from seen rows rather than
  /// returning short. Returns at most [want] candidates.
  Future<List<GuideQuizCandidate>> sample({
    required String subject,
    required int schoolClass,
    required int want,
    String? seedKey,
    Set<String> seenIds = const {},
  }) async {
    final numbers = await chapters(subject: subject, schoolClass: schoolClass);
    if (numbers.isEmpty || want <= 0) return const [];
    final frames = await Future.wait(numbers.map((n) => frame(
        subject: subject, schoolClass: schoolClass, chapter: n)));
    final usable = frames.where((f) => f.total > 0).toList();
    if (usable.isEmpty) return const [];
    final alloc = allocateProportional(
        usable.map((f) => f.total).toList(), want);
    final rng = seedKey == null ? Random() : Random(_seed(seedKey));
    final out = <GuideQuizCandidate>[];
    final picked = <String>{};
    // Two passes: unseen first, then seen-refill for shortfall.
    for (var pass = 0; pass < 2; pass++) {
      final allowSeen = pass == 1;
      for (var i = 0; i < usable.length; i++) {
        final need = alloc[i] -
            out.where((c) => c.chapter == usable[i].chapter).length;
        if (need <= 0) continue;
        final f = usable[i];
        // One random page, plus one refill page at a different
        // offset when the first yields too few fresh rows.
        var rows = <GuideBankQuestion>[];
        final firstOffset = f.total <= pageSize
            ? 0
            : rng.nextInt(f.total - pageSize + 1);
        rows = await _page(
            subject: subject, schoolClass: schoolClass,
            frame: f, offset: firstOffset);
        var fresh = _fresh(rows, picked, seenIds, allowSeen);
        if (fresh.length < need && f.total > pageSize) {
          var secondOffset = rng.nextInt(f.total);
          if (secondOffset == firstOffset) {
            secondOffset = (secondOffset + pageSize) % f.total;
          }
          final more = await _page(
              subject: subject, schoolClass: schoolClass,
              frame: f, offset: secondOffset);
          fresh = [
            ...fresh,
            ..._fresh(more, picked, seenIds, allowSeen),
          ];
        }
        fresh.shuffle(rng);
        for (final q in fresh.take(need)) {
          picked.add(q.id);
          out.add(GuideQuizCandidate(q, f.chapter));
        }
      }
      if (out.length >= want) break;
    }
    return out.length > want ? out.sublist(0, want) : out;
  }

  List<GuideBankQuestion> _fresh(
    List<GuideBankQuestion> rows,
    Set<String> picked,
    Set<String> seenIds,
    bool allowSeen,
  ) =>
      rows
          .where((q) =>
              isScorableGuideMcq(q) &&
              !picked.contains(q.id) &&
              (allowSeen || !seenIds.contains(q.id)))
          .toList();
}

final guideQuizSampling = GuideQuizSampling();
