// Guide bank data layer: client cache + honest unavailable states.
// Null = unreachable (never demo data). Cache-first, class-keyed.
// After a new import, call invalidateGuideBankCache().
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/guide_bank_model.dart';
import 'app_config.dart';
import 'edge_post.dart';
import 'guide_bank_cache.dart';
import 'guide_bank_disk_cache.dart';
import 'guide_bank_fetch.dart';
import 'guide_bank_prefs_migration.dart';

/// Maps a guideChapters Edge response to chapter counts.
/// Null = unreachable or unknown. found:false with reason
/// no-book is NOT unknown: the server gates every guide-bank
/// action on books, so no book means definitively no chapters —
/// {} lets flag resolution complete instead of refetching
/// forever for book-less subjects.
Map<int, int>? parseGuideChaptersResponse(Map<String, dynamic>? res) {
  if (res == null) return null;
  if (res['found'] != true) {
    return res['reason'] == 'no-book' ? <int, int>{} : null;
  }
  final list = res['guideChapters'];
  if (list is! List) return null;
  final out = <int, int>{};
  for (final e in list.whereType<Map>()) {
    final n = e['chapter'];
    final t = e['totalCount'];
    if (n is num && t is num) out[n.toInt()] = t.toInt();
  }
  return out;
}

class GuideBankService {
  static const _reportsKey = 'guide_reports_outbox';
  static bool _migrationStarted = false;

  /// Starts the one-time prefs -> disk migration in the
  /// background (never blocks the caller; idempotent).
  void _startPrefsMigration() {
    if (_migrationStarted) return;
    _migrationStarted = true;
    migratePrefsChaptersToDisk();
  }

  /// Cached chapter rows, or null when nothing was ever cached.
  /// Disk first; a prefs-only hit is still served (migration
  /// moves it to disk in the background). Null means "unknown",
  /// NOT "empty": callers must show the unavailable state,
  /// never an empty-bank message, for null.
  Future<List<GuideBankQuestion>?> cachedChapter(
      String subject, int chapter,
      {int schoolClass = 6}) async {
    _startPrefsMigration();
    final diskRows = await guideBankDiskCache.readRows(
        guideBankDiskCache.chapterFile(schoolClass, subject, chapter));
    if (diskRows != null) {
      return diskRows.map(GuideBankQuestion.fromJson).toList();
    }
    return readPrefsChapter(schoolClass, subject, chapter);
  }

  /// Stores a chapter list on disk and refreshes the indexes.
  /// When disk is unavailable the prefs store takes over
  /// (Phase 4 fallback) so rows are never lost. The prefs
  /// index is ALWAYS refreshed (it is the card's fast lookup),
  /// so the disk index never shadows a newer chapter.
  Future<void> cacheChapter(String subject, int chapter,
      List<GuideBankQuestion> questions,
      {int schoolClass = 6}) async {
    _startPrefsMigration();
    final rowsJson = questions.map((q) => q.toJson()).toList();
    final diskOk = await guideBankDiskCache.writeRows(
        guideBankDiskCache.chapterFile(schoolClass, subject, chapter),
        rowsJson);
    final index =
        await subjectChapterCounts(subject, schoolClass: schoolClass) ?? {};
    index[chapter] = questions.length;
    if (diskOk) {
      await guideBankDiskCache.writeIndex(
          guideBankDiskCache.indexFile(schoolClass, subject), index);
    } else {
      await writePrefsChapter(
          schoolClass, subject, chapter, rowsJson, index);
    }
    await writePrefsIndex(schoolClass, subject, index);
  }

  /// Server chapter list via the guide-bank Edge Function.
  /// Whole-chapter fetch via guide_bank_fetch: bulk first (one
  /// Edge call), else parallel pages of 50 (cap 2000 rows;
  /// observed chapters are <= 967). Null = unreachable
  /// (unavailable, never cached). Empty = honest empty
  /// (returned, NOT cached, so later-arriving data is never
  /// hidden behind a stale cache). onProgress fires once with
  /// the final counts (bulk has no intermediate pages).
  Future<List<GuideBankQuestion>?> fetchChapterFromServer(
    String subject,
    int chapter, {
    int schoolClass = 6,
    void Function(int fetched, int total)? onProgress,
  }) async {
    if (AppConfig.guideBankEndpoint.isEmpty) return null;
    final base = <String, dynamic>{
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
    };
    Future<Map<String, dynamic>?> post(Map<String, dynamic> b,
            {String? endpoint}) =>
        edgePost(b, endpoint: AppConfig.guideBankEndpoint);
    final fetched = await fetchBulkRows(
            post: post, baseBody: base, label: 'chapter $subject/$chapter') ??
        await fetchAllListRows(
            post: post, baseBody: base, label: 'chapter $subject/$chapter');
    if (fetched == null) return null;
    final all =
        fetched.rows.map(GuideBankQuestion.fromServerJson).toList();
    onProgress?.call(all.length, fetched.total);
    if (all.isEmpty) return const [];
    await cacheChapter(subject, chapter, all, schoolClass: schoolClass);
    return all;
  }

  // Model-test sets moved to model_test_set_service.dart
  // (Phase 2): server metadata + cached rows + set fetching.
  // This file keeps the chapter bank layer only.

  /// Server guide-native chapters for a subject: chapter number
  /// -> bank question count. Null = unreachable. This is the
  /// fallback when no textbook chapters exist for the class
  /// (guide-native system, migration 011): the tab and the quiz
  /// pool use these numbers when the textbook list is empty.
  Future<Map<int, int>?> fetchGuideChapters(String subject,
      {int schoolClass = 6}) async {
    if (AppConfig.guideBankEndpoint.isEmpty) return null;
    final res = await edgePost(
      {
        'action': 'guideChapters',
        'classId': schoolClass,
        'subject': subject,
      },
      endpoint: AppConfig.guideBankEndpoint,
    );
    return parseGuideChaptersResponse(res);
  }

  /// Flagged-board counts for a subject (migration 018
  /// flag, Board revision 2026-11-02): null = none or
  /// pre-migration server. Never a guessed chapter number —
  /// Board is a flag scope, not a chapter, so it travels
  /// separately from fetchGuideChapters. The sub-section
  /// counts sum to the total by server construction.
  Future<({int total, int mcq, int creative})?> fetchGuideBoard(
      String subject,
      {int schoolClass = 6}) async {
    if (AppConfig.guideBankEndpoint.isEmpty) return null;
    final res = await edgePost(
      {
        'action': 'guideChapters',
        'classId': schoolClass,
        'subject': subject,
      },
      endpoint: AppConfig.guideBankEndpoint,
    ).catchError((_) => null);
    if (res == null || res['found'] != true) return null;
    final b = res['board'];
    if (b is! Map) return null;
    final t = b['totalCount'];
    if (t is! num || t <= 0) return null;
    return (
      total: t.toInt(),
      mcq: (b['mcqCount'] as num?)?.toInt() ?? 0,
      creative: (b['creativeCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Chapter number -> cached question count, or null when the
  /// subject has no cached index at all (unknown, not zero).
  /// Prefs ONLY, by design: the index is small and always
  /// refreshed by cacheChapter, so this path never waits on
  /// the disk platform hop (which widget tests cannot resolve
  /// without pumps, and which the card needs on every build).
  /// Disk holds the rows; prefs holds the lookup.
  Future<Map<int, int>?> subjectChapterCounts(String subject,
      {int schoolClass = 6}) async {
    _startPrefsMigration();
    return readPrefsIndex(schoolClass, subject);
  }

  /// LOCAL capture only: no server endpoint exists; the UI
  /// must say so plainly, never claim "sent".
  Future<void> submitReportLocal(GuideReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await pendingReports();
    pending.add(report);
    await prefs.setString(
      _reportsKey,
      jsonEncode(pending.map((r) => r.toJson()).toList()),
    );
  }

  Future<List<GuideReport>> pendingReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reportsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => GuideReport.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Paywall gate. Unknown/unverified premium is NEVER premium.
  /// [index] is the position in the FULL chapter list, not the
  /// filtered view. Negative freeLimit (free-open) unlocks all.
  bool isUnlocked({
    required bool isPremium,
    required int index,
    required int freeLimit,
  }) {
    if (isPremium) return true;
    if (freeLimit < 0) return true;
    return index < freeLimit;
  }
}

final guideBankService = GuideBankService();
