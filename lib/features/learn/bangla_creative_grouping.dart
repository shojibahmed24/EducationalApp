// Pure creative grouping for the Bangla 1st Paper lesson screen.
// Rows sharing a non-empty stimulusId form one group, in
// first-seen order; part order inside a group is fixed at
// display time by orderedCreativeParts (ক→খ→গ→ঘ), not here.
// A row with an empty stimulusId stands alone: a missing id
// means "no shared stimulus known", never "same stimulus" —
// so such rows are never merged and never dropped.
import '../../core/models/guide_bank_model.dart';

class BanglaCreativeGroup {
  BanglaCreativeGroup({required this.stimulusText, required this.parts});
  final String stimulusText;
  final List<GuideBankQuestion> parts;
}

List<BanglaCreativeGroup> groupBanglaCreative(
    List<GuideBankQuestion> rows) {
  final groups = <BanglaCreativeGroup>[];
  final indexById = <String, int>{};
  for (final q in rows) {
    final sid = q.stimulusId;
    if (sid == null || sid.isEmpty) {
      groups.add(BanglaCreativeGroup(
          stimulusText: q.stimulusText ?? '', parts: [q]));
      continue;
    }
    final i = indexById[sid];
    if (i == null) {
      indexById[sid] = groups.length;
      groups.add(BanglaCreativeGroup(
          stimulusText: q.stimulusText ?? '', parts: [q]));
    } else {
      groups[i].parts.add(q);
    }
  }
  // Group stimulus = first non-empty part stimulus, else ''.
  // The detail screen falls back to the parts themselves.
  for (var gi = 0; gi < groups.length; gi++) {
    final g = groups[gi];
    if (g.stimulusText.isNotEmpty) continue;
    for (final p in g.parts) {
      if (p.stimulusText?.isNotEmpty == true) {
        groups[gi] =
            BanglaCreativeGroup(stimulusText: p.stimulusText!, parts: g.parts);
        break;
      }
    }
  }
  return groups;
}
