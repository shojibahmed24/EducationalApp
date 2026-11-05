// Pure grade-band helpers (Phase 3): parse the sets-action
// gradeBands payload ({A: [lo, hi], ...}) and look up a total
// score. Null bands, a malformed band, or a score outside every
// band returns null: a grade is never invented.
Map<String, List<int>>? parseGradeBands(Object? raw) {
  if (raw is! Map) return null;
  final out = <String, List<int>>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! List || value.length != 2) return null;
    final lo = (value[0] as num?)?.toInt();
    final hi = (value[1] as num?)?.toInt();
    if (lo == null || hi == null || lo > hi) return null;
    out[entry.key.toString()] = [lo, hi];
  }
  return out.isEmpty ? null : out;
}

/// Grade for [score] inside [bands], checked A first so an
/// overlapping band resolves deterministically. Null = no band
/// fits (never a guessed grade).
String? gradeForScore(Map<String, List<int>> bands, int score) {
  for (final grade in const ['A', 'B', 'C', 'D']) {
    final range = bands[grade];
    if (range != null && score >= range[0] && score <= range[1]) {
      return grade;
    }
  }
  return null;
}
