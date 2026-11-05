// Pure user-stated marks parsing for chat (no UI, no network).
// Chat ignores printed marks: the user types the marks
// themselves ("এর মার্ক ৪"), so the chat worker parses that
// message and passes the result as marksOverride. A bare number
// in a maths question is NEVER marks — every pattern below
// requires a marks word (মার্ক / marks / নম্বর) adjacent to
// the number. Returns null when no marks pattern is found.
// Bangla digits ০-৯ and ASCII digits both work; the result is
// clamped to 1..10 (the marksBudgetFor range).

int? _toInt(String digits) {
  var value = 0;
  for (var i = 0; i < digits.length; i++) {
    final c = digits.codeUnitAt(i);
    if (c >= 0x09E6 && c <= 0x09EF) {
      value = value * 10 + (c - 0x09E6);
    } else if (c >= 0x30 && c <= 0x39) {
      value = value * 10 + (c - 0x30);
    } else {
      return null;
    }
  }
  return value;
}

int? parseUserMarks(String input) {
  final patterns = [
    // "মার্ক ৪" / "মার্কস ৪" (marks word first).
    RegExp(r'মার্কস?\s*([০-৯0-9]+)'),
    // "৪ মার্ক" / "৪ মার্কস" (number first).
    RegExp(r'([০-৯0-9]+)\s*মার্কস?'),
    // "marks 4" / "mark 4" (Banglish, either order).
    RegExp(r'marks?\s*([০-৯0-9]+)', caseSensitive: false),
    RegExp(r'([০-৯0-9]+)\s*marks?', caseSensitive: false),
    // "৪ নম্বর" / "নম্বর ৪".
    RegExp(r'([০-৯0-9]+)\s*নম্বর'),
    RegExp(r'নম্বর\s*([০-৯0-9]+)'),
  ];
  // Earliest match in the message wins, so a leading number
  // ("৪ মার্কের প্রশ্ন, মার্ক ৫") is not overruled by a later
  // pattern; ties keep the first pattern's match.
  RegExpMatch? best;
  for (final pattern in patterns) {
    final match = pattern.firstMatch(input);
    if (match != null && (best == null || match.start < best.start)) {
      best = match;
    }
  }
  if (best == null) return null;
  final value = _toInt(best.group(1)!);
  if (value == null) return null;
  return value.clamp(1, 10);
}
