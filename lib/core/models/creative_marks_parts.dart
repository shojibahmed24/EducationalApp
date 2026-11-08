// Pure helpers for creative-question part marks (no Flutter).
// The database stores `marks_parts` in four shapes: {ক,খ,গ,(ঘ),মোট},
// {ka,kha,ga,gha}, {part-1..part-4} and a plain list [1,2,3,4].
// normalizeMarksParts folds them into one list, index 0 = ক.
// Nothing is invented: anything unreadable gives null, and a total
// key (মোট) is ignored, never treated as a part.

const _letterIndex = {
  'ক': 0, 'খ': 1, 'গ': 2, 'ঘ': 3,
  'ka': 0, 'kha': 1, 'ga': 2, 'gha': 3,
};

int? _partKeyIndex(String key) {
  final m = RegExp(r'^part-(\d)$').firstMatch(key);
  if (m == null) return null;
  final i = int.parse(m.group(1)!) - 1;
  return i >= 0 && i < 4 ? i : null;
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is num && v % 1 == 0) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

List<int>? _validated(List<int?> parts) {
  if (parts.isEmpty || parts.length > 4) return null;
  if (parts.any((v) => v == null || v <= 0)) return null;
  return [for (final v in parts) v!];
}

/// Part marks in ক, খ, গ, ঘ order, or null when [raw] is missing,
/// has a gap (e.g. ক and গ but no খ) or holds a non-positive mark.
List<int>? normalizeMarksParts(Object? raw) {
  if (raw is List) return _validated(raw.map(_asInt).toList());
  if (raw is! Map) return null;
  final slots = List<int?>.filled(4, null);
  for (final e in raw.entries) {
    final key = e.key.toString().trim().toLowerCase();
    final i = _letterIndex[key] ?? _partKeyIndex(key);
    if (i != null) slots[i] = _asInt(e.value);
  }
  var n = slots.length;
  while (n > 0 && slots[n - 1] == null) {
    n--;
  }
  return _validated(slots.sublist(0, n));
}

/// Natural order for ids like 'pilot3-creative-094': digit runs
/// compare as numbers, so "-9" sorts before "-10".
int compareIdsNatural(String a, String b) {
  final ra = RegExp(r'\d+|\D+').allMatches(a).map((m) => m[0]!).toList();
  final rb = RegExp(r'\d+|\D+').allMatches(b).map((m) => m[0]!).toList();
  for (var i = 0; i < ra.length && i < rb.length; i++) {
    final x = ra[i], y = rb[i];
    final nx = int.tryParse(x), ny = int.tryParse(y);
    final c = (nx != null && ny != null) ? nx.compareTo(ny) : x.compareTo(y);
    if (c != 0) return c;
  }
  return ra.length.compareTo(rb.length);
}
