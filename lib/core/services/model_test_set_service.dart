// Guide model-test sets: server metadata + cached rows + set
// row fetching. Split out of guide_bank_service.dart to keep it
// under the 250-line cap (Phase 2, plan §2 step 4).
// - The LIST screen fetches set metadata from the server
//   (sets action: counts only); the cache is FALLBACK ONLY,
//   never the primary source — the old cache-only screen could
//   never show a set that arrived after the last cache write
//   (and nothing ever wrote the cache, so it showed nothing).
// - Rows for one set come from the list action with a setId
//   filter (paged 50/page; sets ignore chapters server-side).
//   Fetched rows are cached as GuideModelSet so a later offline
//   start can reuse them; keys are NEVER in list rows, so the
//   exam start resolves keys via Mode G (see the list screen).
// - Chapter-less bank rows come from the list action with
//   chapterless: true (same paging; bank rows only, set_id
//   NULL, chapter_number NULL). English practice rows reach
//   the app through this path — the chapter path can never
//   match them (both chapter fields NULL).
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/guide_bank_model.dart';
import 'app_config.dart';
import 'edge_post.dart';
import 'guide_bank_cache.dart';
import 'guide_bank_disk_cache.dart';
import 'guide_bank_fetch.dart';

typedef ModelTestSetPost = Future<Map<String, dynamic>?> Function(
    Map<String, dynamic> body, {String? endpoint});

class ModelTestSetService {
  ModelTestSetService({ModelTestSetPost? post})
      : _post = post ?? edgePost,
        _customPost = post != null;
  final ModelTestSetPost _post;
  final bool _customPost;

  Future<Map<String, dynamic>?> _call(Map<String, dynamic> body) async {
    if (!_customPost && AppConfig.guideBankEndpoint.isEmpty) return null;
    return _post(body, endpoint: AppConfig.guideBankEndpoint);
  }

  /// Server model-test set metadata (counts only, no rows).
  /// Null = unreachable (unknown, not empty). found:false with
  /// reason no-book is definitively empty (the server gates
  /// every guide-bank action on books), so [] — not null.
  Future<List<GuideModelSetInfo>?> fetchSetsFromServer(
    String subject, {
    int schoolClass = 6,
  }) async {
    final res = await _call(
      {
        'action': 'sets',
        'classId': schoolClass,
        'subject': subject,
      },
    );
    if (res == null) return null;
    if (res['found'] != true) {
      return res['reason'] == 'no-book' ? <GuideModelSetInfo>[] : null;
    }
    final sets = res['sets'];
    if (sets is! List) return null;
    return sets
        .whereType<Map>()
        .map((e) => GuideModelSetInfo.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  /// All rows of one set, stale-while-revalidate (Phase 4):
  /// disk rows return instantly with a background refresh for
  /// the next open; a disk miss fetches (bulk first, else
  /// parallel pages of 50) and writes disk. Null = unreachable
  /// with nothing cached. Rows carry hasKey booleans only —
  /// never key indexes (Mode G owns keys). Empty = the set
  /// genuinely has no rows.
  Future<List<GuideBankQuestion>?> fetchSetRows(
    String subject,
    String setId, {
    int schoolClass = 6,
  }) async {
    final file = guideBankDiskCache.setFile(schoolClass, subject, setId);
    final diskRows = await guideBankDiskCache.readRows(file);
    if (diskRows != null) {
      _refreshDiskRows(
          file: file,
          fetch: () => _fetchSetRowsFromServer(subject, setId,
              schoolClass: schoolClass));
      return diskRows.map(GuideBankQuestion.fromJson).toList();
    }
    final fresh = await _fetchSetRowsFromServer(subject, setId,
        schoolClass: schoolClass);
    if (fresh == null) return null;
    await guideBankDiskCache.writeRows(
        file, fresh.map((q) => q.toJson()).toList());
    return fresh;
  }

  /// Background disk refresh for one scope. Failures are
  /// swallowed: the cached rows stay, and the next open retries.
  void _refreshDiskRows({
    required String file,
    required Future<List<GuideBankQuestion>?> Function() fetch,
  }) {
    () async {
      try {
        final fresh = await fetch();
        if (fresh != null) {
          await guideBankDiskCache.writeRows(
              file, fresh.map((q) => q.toJson()).toList());
        }
      } catch (_) {}
    }();
  }

  Future<List<GuideBankQuestion>?> _fetchSetRowsFromServer(
    String subject,
    String setId, {
    int schoolClass = 6,
  }) async {
    final base = <String, dynamic>{
      'classId': schoolClass,
      'subject': subject,
      'setId': setId,
    };
    Future<Map<String, dynamic>?> post(Map<String, dynamic> b,
            {String? endpoint}) =>
        _call(b);
    final fetched = await fetchBulkRows(
            post: post, baseBody: base, label: 'set $subject/$setId') ??
        await fetchAllListRows(
            post: post, baseBody: base, label: 'set $subject/$setId');
    if (fetched == null) return null;
    return fetched.rows.map(GuideBankQuestion.fromServerJson).toList();
  }

  /// All chapter-less bank rows of one subject,
  /// stale-while-revalidate like fetchSetRows (Phase 4).
  /// Null = unreachable with nothing cached. Empty = the book
  /// genuinely has no chapter-less bank rows (e.g. class-9
  /// Math: every row carries a chapter number). Mirrors
  /// fetchSetRows so the English scan can treat bank rows as
  /// a second phase.
  Future<List<GuideBankQuestion>?> fetchChapterlessBankRows(
    String subject, {
    int schoolClass = 6,
  }) async {
    final file = guideBankDiskCache.chapterlessFile(schoolClass, subject);
    final diskRows = await guideBankDiskCache.readRows(file);
    if (diskRows != null) {
      _refreshDiskRows(
          file: file,
          fetch: () => _fetchChapterlessFromServer(subject,
              schoolClass: schoolClass));
      return diskRows.map(GuideBankQuestion.fromJson).toList();
    }
    final fresh = await _fetchChapterlessFromServer(subject,
        schoolClass: schoolClass);
    if (fresh == null) return null;
    await guideBankDiskCache.writeRows(
        file, fresh.map((q) => q.toJson()).toList());
    return fresh;
  }

  Future<List<GuideBankQuestion>?> _fetchChapterlessFromServer(
    String subject, {
    int schoolClass = 6,
  }) async {
    final base = <String, dynamic>{
      'classId': schoolClass,
      'subject': subject,
      'chapterless': true,
    };
    Future<Map<String, dynamic>?> post(Map<String, dynamic> b,
            {String? endpoint}) =>
        _call(b);
    final fetched = await fetchBulkRows(
            post: post, baseBody: base, label: 'chapterless $subject') ??
        await fetchAllListRows(
            post: post, baseBody: base, label: 'chapterless $subject');
    if (fetched == null) return null;
    return fetched.rows.map(GuideBankQuestion.fromServerJson).toList();
  }

  /// Cached model-test sets (empty = none cached).
  Future<List<GuideModelSet>> cachedSets(String subject,
      {int schoolClass = 6}) async {
    await ensureGuideCacheMigrated();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(guideSetsKey(schoolClass, subject));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => GuideModelSet.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> cacheSets(String subject, List<GuideModelSet> sets,
      {int schoolClass = 6}) async {
    await ensureGuideCacheMigrated();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      guideSetsKey(schoolClass, subject),
      jsonEncode(sets.map((s) => s.toJson()).toList()),
    );
  }
}

final modelTestSetService = ModelTestSetService();
