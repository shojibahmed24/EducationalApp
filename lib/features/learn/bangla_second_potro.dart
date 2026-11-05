// চিঠিপত্র lesson divisions (split out of
// bangla_second_types.dart to keep it under the 250-line cap).
// Ranges are the collection q_no ranges, verified against id
// numbers 1:1 for all 48 potro rows. An out-of-range number
// maps to null, never to a guessed division.
final _potroPattern = RegExp(r'^ban2-nirmiti-potro-(\d+)$');

/// Potro id number (001–048), or null for non-potro ids.
int? parseBanglaSecondPotroNumber(String id) {
  final m = _potroPattern.firstMatch(id);
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// চিঠিপত্র lesson divisions, in book order.
const banglaSecondPotroDivisions = <(String, int, int)>[
  ('personal', 1, 19),
  ('invitation', 20, 23),
  ('newspaper', 24, 28),
  ('manpotro', 29, 32),
  ('application', 33, 46),
  ('business', 47, 48),
];

/// Division key for a potro id number, or null when out of
/// range (never a guessed division).
String? potroDivisionForNumber(int n) {
  for (final d in banglaSecondPotroDivisions) {
    if (n >= d.$2 && n <= d.$3) return d.$1;
  }
  return null;
}

/// Lesson-division label for a potro division key.
String banglaSecondDivisionLabel(String key, Map<String, String> s) {
  switch (key) {
    case 'personal':
      return s['divisionPersonal']!;
    case 'invitation':
      return s['divisionInvitation']!;
    case 'newspaper':
      return s['divisionNewspaper']!;
    case 'manpotro':
      return s['divisionManpotro']!;
    case 'application':
      return s['divisionApplication']!;
    case 'business':
      return s['divisionBusiness']!;
    default:
      return key;
  }
}
