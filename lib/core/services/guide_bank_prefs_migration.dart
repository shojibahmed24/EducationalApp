// One-time prefs -> disk migration (quick-load Phase 4).
// Runs in the background (never blocks a list): prefs chapter
// blobs move to disk files, then their prefs keys are deleted.
// Sets keys (metadata, not rows) are dropped — metadata
// refetches from the server. Idempotent: re-running after an
// interrupted run only processes keys still present. Prefs
// INDEX keys are kept (tiny, and the fallback for scopes not
// yet re-cached on disk).
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/guide_bank_model.dart';
import 'guide_bank_cache.dart';
import 'guide_bank_disk_cache.dart';

Future<void> migratePrefsChaptersToDisk() async {
  try {
    if (await guideBankDiskCache.isPrefsMigrated()) return;
    await ensureGuideCacheMigrated();
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs
        .getKeys()
        .where((k) => k.startsWith(guideBankChapterPrefix))
        .toList()) {
      final rest = key.substring(guideBankChapterPrefix.length);
      final parts = rest.split('_');
      if (parts.length < 3) continue;
      final cls = int.tryParse(parts.first);
      final chapter = int.tryParse(parts.last);
      if (cls == null || chapter == null) continue;
      final subject = parts.sublist(1, parts.length - 1).join('_');
      final raw = prefs.getString(key);
      var moved = false;
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = jsonDecode(raw) as List;
          final rows = list
              .whereType<Map>()
              .map((e) => GuideBankQuestion.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v))))
              .toList();
          moved = await guideBankDiskCache.writeRows(
              guideBankDiskCache.chapterFile(cls, subject, chapter),
              rows.map((q) => q.toJson()).toList());
        } catch (_) {}
      }
      // Delete only after a successful disk write: when disk
      // is unavailable the prefs rows must stay (they are the
      // only copy, and the next start retries the move).
      // Empty keys hold nothing, so they can go either way.
      if (moved || raw == null || raw.isEmpty) await prefs.remove(key);
    }
    for (final key in prefs
        .getKeys()
        .where((k) => k.startsWith(guideBankSetsPrefix))
        .toList()) {
      await prefs.remove(key);
    }
    await guideBankDiskCache.markPrefsMigrated();
  } catch (_) {
    // Next start retries; migration is idempotent.
  }
}
