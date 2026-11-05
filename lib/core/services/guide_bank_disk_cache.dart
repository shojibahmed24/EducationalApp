// File-based disk cache for whole guide scopes (quick-load
// plan, Phase 4). SharedPreferences is the wrong store for
// multi-hundred-row JSON: it rewrites the whole prefs file per
// write. One JSON file per scope in the app documents
// directory; call sites do stale-while-revalidate (cached rows
// return instantly, a background refresh rewrites the file for
// the next open). Empty/error results are never cached.
// 50 MB cap across all cache files (oldest first, never the
// file just written). Versioned: a future row-shape change
// bumps [version] and old files stop matching.
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class GuideBankDiskCache {
  GuideBankDiskCache({Directory? rootOverride})
      : _rootOverride = rootOverride;
  final Directory? _rootOverride;

  static const version = 1;
  static const maxBytes = 50 * 1024 * 1024;
  static const _migratedMarker = 'prefs_migrated';

  Future<Directory> _dir() async {
    final override = _rootOverride;
    if (override != null) {
      if (!await override.exists()) {
        await override.create(recursive: true);
      }
      return override;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/guide_bank_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _safe(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  String chapterFile(int schoolClass, String subject, int chapter) =>
      'chapter_${schoolClass}_${_safe(subject)}_$chapter.json';

  String setFile(int schoolClass, String subject, String setId) =>
      'set_${schoolClass}_${_safe(subject)}_${_safe(setId)}.json';

  String chapterlessFile(int schoolClass, String subject) =>
      'chapterless_${schoolClass}_${_safe(subject)}.json';

  String indexFile(int schoolClass, String subject) =>
      'index_${schoolClass}_${_safe(subject)}.json';

  Future<List<Map<String, dynamic>>?> readRows(String file) async {
    try {
      final f = File('${(await _dir()).path}/$file');
      if (!await f.exists()) return null;
      final data = jsonDecode(await f.readAsString());
      if (data is! Map || data['version'] != version) return null;
      final rows = data['rows'];
      if (rows is! List) return null;
      return rows
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// True when the file was written; false when the store is
  /// unavailable (tests without path_provider, disk errors).
  /// Callers fall back to prefs on false so rows are not lost.
  Future<bool> writeRows(
      String file, List<Map<String, dynamic>> rows) async {
    try {
      final dir = await _dir();
      final f = File('${dir.path}/$file');
      await f.writeAsString(jsonEncode({'version': version, 'rows': rows}));
      await _enforceCap(dir, f);
      return true;
    } catch (_) {
      // Best-effort: a failed write never fails the list.
      return false;
    }
  }

  Future<Map<int, int>?> readIndex(String file) async {
    try {
      final f = File('${(await _dir()).path}/$file');
      if (!await f.exists()) return null;
      final data = jsonDecode(await f.readAsString());
      if (data is! Map || data['version'] != version) return null;
      final counts = data['counts'];
      if (counts is! Map) return null;
      final out = <int, int>{};
      counts.forEach((k, v) {
        final n = int.tryParse(k.toString());
        if (n != null && v is num) out[n] = v.toInt();
      });
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<bool> writeIndex(String file, Map<int, int> counts) async {
    try {
      final dir = await _dir();
      final f = File('${dir.path}/$file');
      await f.writeAsString(jsonEncode({
        'version': version,
        'counts': counts.map((k, v) => MapEntry(k.toString(), v)),
      }));
      return true;
    } catch (_) {
      // Best-effort, same as writeRows.
      return false;
    }
  }

  Future<bool> isPrefsMigrated() async {
    try {
      return await File('${(await _dir()).path}/$_migratedMarker').exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> markPrefsMigrated() async {
    try {
      await File('${(await _dir()).path}/$_migratedMarker').writeAsString('1');
    } catch (_) {
      // Next start retries the migration; it is idempotent.
    }
  }

  /// Drops every cached file (called after a guide import, so
  /// the next visit refetches fresh server rows).
  Future<void> clearAll() async {
    try {
      final dir = await _dir();
      if (!await dir.exists()) return;
      for (final e in await dir.list().toList()) {
        try {
          await e.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _enforceCap(Directory dir, File justWritten) async {
    try {
      final files =
          await dir.list().where((e) => e is File).cast<File>().toList();
      var total = 0;
      final sized = <({File file, int size, DateTime modified})>[];
      for (final f in files) {
        final stat = await f.stat();
        total += stat.size;
        sized.add((file: f, size: stat.size, modified: stat.modified));
      }
      if (total <= maxBytes) return;
      sized.sort((a, b) => a.modified.compareTo(b.modified));
      for (final s in sized) {
        if (total <= maxBytes) break;
        if (s.file.path == justWritten.path) continue;
        try {
          await s.file.delete();
          total -= s.size;
        } catch (_) {}
      }
    } catch (_) {}
  }
}

final guideBankDiskCache = GuideBankDiskCache();
