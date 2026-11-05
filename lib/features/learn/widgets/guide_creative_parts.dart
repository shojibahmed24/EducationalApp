// Pure creative-part ordering helpers (step 6, no Flutter).
// One creative question's parts share a stimulus; each part row
// carries its own marks. Parts arrive in an arbitrary order, so
// the answer view orders them by marks ascending (ক=1, খ=2,
// গ=3, ঘ=4); unmarked rows keep input order after the marked
// ones. Labels are positional, never parsed from the question
// text: a question that merely starts with a part letter (e.g.
// "খলিফা...") is NOT a part label, and parsing it produced
// duplicate খ / missing ক chips (147 Bangla groups, 2026-11-04).
// Ties on marks keep input order, with lettered rows first
// (the old lettered-first rule, now only a tiebreaker).
import '../../../core/models/guide_bank_model.dart';

/// Canonical part letters, in display order.
const creativePartLetters = ['ক', 'খ', 'গ', 'ঘ'];

/// 0-based part index parsed from the row's leading letter, or
/// null when the text starts with anything else (or is empty).
/// Tiebreaker ONLY for orderedCreativeParts: never a label, and
/// never the primary order (marks are).
int? creativePartIndex(GuideBankQuestion q) {
  final text = q.questionText.trimLeft();
  if (text.isEmpty) return null;
  final i = creativePartLetters.indexOf(text[0]);
  return i >= 0 ? i : null;
}

/// Tab label for a part: the letter at its position in the
/// marks-ordered list (so the first part always reads ক, the
/// second খ, and so on). Beyond ঘ, the 1-based position number.
String creativePartLabel(int index) {
  if (index >= 0 && index < creativePartLetters.length) {
    return creativePartLetters[index];
  }
  return '${index + 1}';
}

/// Parts in marks order (ক=1, খ=2, গ=3, ঘ=4; stable for equal
/// marks, lettered rows first on ties). Unmarked rows keep
/// input order after the marked ones. Missing parts are simply
/// absent — never synthesised.
List<GuideBankQuestion> orderedCreativeParts(
  List<GuideBankQuestion> group,
) {
  final indexed = <(int, int, int, GuideBankQuestion)>[];
  for (var i = 0; i < group.length; i++) {
    final p = group[i];
    indexed.add((p.marks ?? 999, creativePartIndex(p) ?? 999, i, p));
  }
  indexed.sort((a, b) =>
      a.$1 != b.$1
          ? a.$1.compareTo(b.$1)
          : a.$2 != b.$2
              ? a.$2.compareTo(b.$2)
              : a.$3.compareTo(b.$3));
  return indexed.map((e) => e.$4).toList();
}
