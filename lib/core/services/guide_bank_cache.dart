// Guide-bank cache keys + one-time migration, split out of
// guide_bank_service.dart to keep it under the 250-line limit.
// Keys are class-keyed: guide_bank_chapter_<class>_<subject>_
// <chapter> (same shape for index + sets). A class-7 chapter
// cached earlier must never be served to a class-6 student.
// Pre-v2 keys had no class segment; on first run after this
// change they are deleted (migration marker below), so no stale
// class-less row can ever be read again.
// INVALIDATION: after a new guide import (e.g. the Talimit Math
// import), call invalidateGuideBankCache() once so the next
// visit refetches fresh server rows instead of stale cache.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/guide_bank_model.dart';
import 'guide_bank_disk_cache.dart';

const guideBankCacheVersion = 2;
const _versionKey = 'guide_bank_cache_version';
const _chapterPrefix = 'guide_bank_chapter_';
const _indexPrefix = 'guide_bank_index_';
const _setsPrefix = 'guide_bank_sets_';

// Public prefixes for the prefs -> disk migration (Phase 4):
// it enumerates prefs keys instead of building them.
const guideBankChapterPrefix = _chapterPrefix;
const guideBankSetsPrefix = _setsPrefix;

String guideChapterKey(int schoolClass, String subject, int chapter) =>
    '$_chapterPrefix${schoolClass}_${subject}_$chapter';
String guideIndexKey(int schoolClass, String subject) =>
    '$_indexPrefix${schoolClass}_$subject';
String guideSetsKey(int schoolClass, String subject) =>
    '$_setsPrefix${schoolClass}_$subject';

bool _migrated = false;

/// One-time migration: deletes pre-v2 (class-less) keys, keeps
/// class-keyed ones. Runs at most once per process; the version
/// marker makes it once ever per install.
Future<void> ensureGuideCacheMigrated() async {
  if (_migrated) return;
  _migrated = true;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getInt(_versionKey) == guideBankCacheVersion) return;
  final newPattern = RegExp(r'^guide_bank_(chapter|index|sets)_\d+_');
  final legacy = prefs
      .getKeys()
      .where((k) =>
          k.startsWith(_chapterPrefix) ||
          k.startsWith(_indexPrefix) ||
          k.startsWith(_setsPrefix))
      .where((k) => !newPattern.hasMatch(k))
      .toList();
  for (final k in legacy) {
    await prefs.remove(k);
  }
  await prefs.setInt(_versionKey, guideBankCacheVersion);
}

/// Prefs chapter read (fallback when disk is unavailable, and
/// the pre-disk store). Null = nothing cached or unparsable.
Future<List<GuideBankQuestion>?> readPrefsChapter(
    int schoolClass, String subject, int chapter) async {
  await ensureGuideCacheMigrated();
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(guideChapterKey(schoolClass, subject, chapter));
  if (raw == null || raw.isEmpty) return null;
  try {
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map>()
        .map((e) => GuideBankQuestion.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  } catch (_) {
    return null;
  }
}

/// Prefs chapter + index write (fallback when disk is
/// unavailable). Keeps the service under the line cap.
Future<void> writePrefsChapter(int schoolClass, String subject, int chapter,
    List<Map<String, dynamic>> rowsJson, Map<int, int> index) async {
  await ensureGuideCacheMigrated();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      guideChapterKey(schoolClass, subject, chapter), jsonEncode(rowsJson));
  await prefs.setString(guideIndexKey(schoolClass, subject),
      jsonEncode(index.map((k, v) => MapEntry(k.toString(), v))));
}

/// Prefs index write only (no rows). The index is small, so
/// it always lives in prefs even when the rows live on disk:
/// the subject card reads the index on every build, and it
/// must never wait on the disk platform hop.
Future<void> writePrefsIndex(
    int schoolClass, String subject, Map<int, int> index) async {
  await ensureGuideCacheMigrated();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(guideIndexKey(schoolClass, subject),
      jsonEncode(index.map((k, v) => MapEntry(k.toString(), v))));
}

/// Prefs index read (fallback + merge base). Null = none.
Future<Map<int, int>?> readPrefsIndex(
    int schoolClass, String subject) async {
  await ensureGuideCacheMigrated();
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(guideIndexKey(schoolClass, subject));
  if (raw == null || raw.isEmpty) return null;
  try {
    final map = jsonDecode(raw) as Map;
    final out = <int, int>{};
    map.forEach((k, v) {
      final n = int.tryParse(k.toString());
      if (n != null && v is num) out[n] = v.toInt();
    });
    return out;
  } catch (_) {
    return null;
  }
}

/// Drops ALL cached guide-bank rows (chapters, indexes, sets).
/// Call after a guide import; the version marker is kept, so the
/// migration above does not re-run and delete fresh keys.
/// Disk files go too (Phase 4): otherwise stale disk chapters
/// would keep serving after the prefs clear.
Future<void> invalidateGuideBankCache() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs
      .getKeys()
      .where((k) =>
          k.startsWith(_chapterPrefix) ||
          k.startsWith(_indexPrefix) ||
          k.startsWith(_setsPrefix))
      .toList();
  for (final k in keys) {
    await prefs.remove(k);
  }
  await guideBankDiskCache.clearAll();
}
