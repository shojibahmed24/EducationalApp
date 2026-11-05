// Set display labels for the global picker: one rule for every
// subject, Bengali in Bn mode, romanized in En. A raw set id is
// NEVER the title; ids with no number fall back to the displayed
// position; unknown tokens show as-is, never invented.
import '../../core/models/guide_bank_model.dart';
import 'widgets/guide_creative_groups.dart';

/// Set lists page by WHOLE stimulus groups, never by raw rows:
/// grouping runs over ALL rows of the set first, then whole
/// groups are taken until the row budget is reached, so a
/// stimulus group never splits across the "আরো দেখুন" boundary.
/// Singletons count as one row.
List<GuideBankQuestion> visibleSetRows(
  List<GuideBankQuestion> all,
  int rowBudget,
) {
  final groups = groupQuestionRows([
    for (var i = 0; i < all.length; i++) (i, all[i]),
  ]);
  final out = <GuideBankQuestion>[];
  for (final g in groups) {
    if (out.isNotEmpty && out.length >= rowBudget) break;
    for (final p in g.parts) {
      out.add(p.$2);
    }
  }
  return out;
}
