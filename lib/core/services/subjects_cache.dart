// Persisted last-good subjects list (cache-once home grid).
// Only COMPLETE server enrichments are ever written here: a
// partial snapshot must never shadow the real server list, and
// DEMO fallbacks are never persisted (they are not server
// truth). Reads are all-or-nothing: any corrupt entry yields
// null, so a damaged cache degrades to a fresh fetch, never a
// partial list.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/backend_models.dart';

String subjectsLastGoodKey(int schoolClass, bool bangla) =>
    'subjects_last_good:$schoolClass:$bangla';

/// Best-effort write: never throws, so a storage failure can
/// never break a subjects fetch.
Future<void> persistSubjectsList(String key, List<SubjectInfo> list) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(list.map((s) => s.toJson()).toList()),
    );
  } catch (_) {}
}

/// Null = no usable cache (absent, empty, or corrupt).
Future<List<SubjectInfo>?> loadPersistedSubjectsList(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.isEmpty) return null;
    final out = <SubjectInfo>[];
    for (final e in decoded) {
      if (e is! Map) return null;
      final s = SubjectInfo.fromJson(
        e.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (s.id.isEmpty) return null;
      out.add(s);
    }
    return out;
  } catch (_) {
    return null;
  }
}

/// Tiny in-memory TTL cache: one entry per key, dropped after
/// [ttl]. Only successful reads are cached — failures and DEMO
/// fallbacks are never cached, so recovery is never hidden
/// behind a stale entry.
class TtlCache<T> {
  static const ttl = Duration(minutes: 5);
  final _entries = <String, ({T value, DateTime at})>{};
  T? get(String key) {
    final e = _entries[key];
    if (e == null) return null;
    if (DateTime.now().difference(e.at) > ttl) {
      _entries.remove(key);
      return null;
    }
    return e.value;
  }

  void set(String key, T value) =>
      _entries[key] = (value: value, at: DateTime.now());

  void remove(String key) => _entries.remove(key);
}
