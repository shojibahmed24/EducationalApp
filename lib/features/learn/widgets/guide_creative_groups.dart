import '../../../core/models/guide_bank_model.dart';

/// Pilot creative grouping (lesson 2.1, 2026-10-31): pure
/// function. Creative rows sharing a non-empty stimulusId form
/// one group, in first-appearance order of the stimulus; every
/// other entry stays a singleton. A group with a single visible
/// part (the rest filtered out) renders as a plain row — the
/// caller collapses it, so a lone part never gets a lonely
/// header. No stimulus text is invented: the model carries no
/// separate stimulus field yet, so the header shows the part
/// count only; full stimulus-once rendering waits on the
/// backend's stimulus text field.
class GroupedRows {
  const GroupedRows({required this.stimulusId, required this.parts});
  final String? stimulusId;
  final List<(int, GuideBankQuestion)> parts;
}

List<GroupedRows> groupQuestionRows(
  List<(int, GuideBankQuestion)> entries,
) {
  final groups = <GroupedRows>[];
  final byStimulus = <String, GroupedRows>{};
  for (final e in entries) {
    final q = e.$2;
    final stim = q.stimulusId;
    if (q.questionType == 'creative' && stim != null && stim.isNotEmpty) {
      final existing = byStimulus[stim];
      if (existing != null) {
        existing.parts.add(e);
      } else {
        final g = GroupedRows(stimulusId: stim, parts: [e]);
        byStimulus[stim] = g;
        groups.add(g);
      }
    } else {
      groups.add(GroupedRows(stimulusId: null, parts: [e]));
    }
  }
  return groups;
}
