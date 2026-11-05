// One cache layer for picker metadata (chapters, sets, server
// lessons). Previously each picker path had its own rule —
// guide chapters, sets and lessons had NO cache at all, so
// every subject change refetched them. Now every picker path
// goes through here with the same rules:
// - Disk (SharedPreferences): survives app restarts, unlike the
//   5-minute memory TTL caches. Picker payloads are small text.
// - Stale-while-revalidate: read() returns data of ANY age, so
//   the picker renders instantly from disk; callers always
//   fetch fresh afterwards and overwrite. A stale entry is
//   never hidden behind: the background refresh heals it on
//   the next visit, and isFresh() tells prefetch when to skip.
// - All-or-nothing reads: a corrupt entry yields null, never
//   a partial list. Writes are best-effort and never throw.
// - Version in the key prefix: bumping pickerCacheVersion
//   invalidates every entry at once (server-side reshapes).
// - In-flight dedupe: a live load and a prefetch for the same
//   key share one network run instead of hitting Edge twice.
// Language-independent kinds (sets) use lang 'all'; titles
// differ by language, so chapter kinds carry bn/en. Question
// rows are NOT here: they already have their own disk cache
// (guide_bank_disk_cache) with the same SWR shape.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/guide_bank_model.dart';

const pickerCacheVersion = 1;
const pickerCacheTtl = Duration(hours: 24);
const pickerCacheKindGuideChapters = 'guideChapters';
const pickerCacheKindTextbookChapters = 'textbookChapters';
const pickerCacheKindSets = 'sets';
const pickerCacheKindServerLessons = 'serverLessons';
const pickerCacheKindEnglishSets = 'englishSets';
const _pickerCacheKinds = [
  pickerCacheKindGuideChapters,
  pickerCacheKindTextbookChapters,
  pickerCacheKindSets,
  pickerCacheKindServerLessons,
  pickerCacheKindEnglishSets,
];

String pickerCacheKey(
        int schoolClass, String subject, String lang, String kind) =>
    'picker_cache:v$pickerCacheVersion:$schoolClass:$subject:$lang:$kind';

class PickerCacheService {
  final _inflight = <String, Future<dynamic>>{};

  /// Shares one run between concurrent callers for [key];
  /// the entry is dropped on completion or error, so a later
  /// call runs again (never a stuck failed future).
  Future<T> dedupe<T>(String key, Future<T> Function() run) {
    final existing = _inflight[key];
    if (existing != null) return existing as Future<T>;
    final fut = run();
    _inflight[key] = fut;
    fut.then<void>((_) {
      _inflight.remove(key);
    }, onError: (_) {
      _inflight.remove(key);
    });
    return fut;
  }

  /// Cached payload of any age, or null when absent, corrupt,
  /// or written by another version. Stale is a valid display:
  /// callers refresh in the background after showing it.
  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      if (decoded['v'] != pickerCacheVersion) return null;
      final data = decoded['data'];
      if (data is! Map) return null;
      return data.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {
      return null;
    }
  }

  /// True only when a fresh (within [ttl]) entry exists.
  /// A stale entry still reads fine; this only gates prefetch.
  Future<bool> isFresh(String key,
      {Duration ttl = pickerCacheTtl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['v'] != pickerCacheVersion) {
        return false;
      }
      final savedAt = decoded['savedAt'];
      if (savedAt is! num) return false;
      return DateTime.now().millisecondsSinceEpoch - savedAt.toInt() <=
          ttl.inMilliseconds;
    } catch (_) {
      return false;
    }
  }

  Future<void> write(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode({
          'v': pickerCacheVersion,
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        }),
      );
    } catch (_) {}
  }

  Future<void> invalidateSubject(
      int schoolClass, String subject, String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final kind in _pickerCacheKinds) {
        await prefs.remove(
            pickerCacheKey(schoolClass, subject, lang, kind));
      }
    } catch (_) {}
  }

  Future<void> invalidateAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith('picker_cache:'))
          .toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}

final pickerCacheService = PickerCacheService();

/// Chapter tuples (number, title) as shown by the picker.
Map<String, dynamic> encodeChapterTuples(
        List<(int, String)> chapters) =>
    {
      'chapters': [
        for (final c in chapters) {'n': c.$1, 't': c.$2},
      ],
    };

List<(int, String)>? decodeChapterTuples(Map<String, dynamic> data) {
  try {
    final list = data['chapters'];
    if (list is! List) return null;
    final out = <(int, String)>[];
    for (final e in list) {
      if (e is! Map) return null;
      final n = e['n'];
      final t = e['t'];
      if (n is! num || t is! String) return null;
      out.add((n.toInt(), t));
    }
    return out;
  } catch (_) {
    return null;
  }
}

/// Model-test set metadata (counts only, no rows).
Map<String, dynamic> encodeModelSets(List<GuideModelSetInfo> sets) =>
    {
      'sets': [for (final s in sets) s.toJson()],
    };

List<GuideModelSetInfo>? decodeModelSets(Map<String, dynamic> data) {
  try {
    final list = data['sets'];
    if (list is! List) return null;
    final out = <GuideModelSetInfo>[];
    for (final e in list) {
      if (e is! Map) return null;
      out.add(GuideModelSetInfo.fromJson(
          e.map((k, v) => MapEntry(k.toString(), v))));
    }
    return out;
  } catch (_) {
    return null;
  }
}

/// Server lesson values (lesson -> totalCount), verbatim.
Map<String, dynamic> encodeServerLessons(Map<String, int> lessons) =>
    {'lessons': lessons};

Map<String, int>? decodeServerLessons(Map<String, dynamic> data) {
  try {
    final map = data['lessons'];
    if (map is! Map) return null;
    final out = <String, int>{};
    for (final e in map.entries) {
      final v = e.value;
      if (v is! num) return null;
      out[e.key.toString()] = v.toInt();
    }
    return out;
  } catch (_) {
    return null;
  }
}
