// Type step of the global picker (guide mode): under every chapter
// / lesson row the question types are listed with their exact
// counts, so the picker alone fixes chapter + lesson + type. A
// count that is not known yet (still loading, old server) is
// left off, never guessed. A type whose count is a known zero is
// hidden (chemistry has no textbook-exercise rows, so that row
// would only lead to an empty list); if every type is zero all
// stay visible, so a chapter never shows an empty step.
import 'global_picker_model.dart';
import 'search_flow_lesson_counts.dart';
import 'search_flow_types.dart';
import 'widgets/digits.dart';

/// Node id of one type row: `type:<chapter>:<lesson|all>:<type>`.
String globalPickerTypeId(int chapter, String? lesson, SearchFlowType t) =>
    'type:$chapter:${lesson ?? 'all'}:${t.name}';

/// Chapter + lesson ("all" = null) parsed from a lesson/chapter
/// node id (`lesson:<chapter>:<lesson|all>` or `chapter:<n>`).
(int, String?)? globalPickerParseScope(String nodeId) {
  final parts = nodeId.split(':');
  final chapter = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (chapter == null) return null;
  if (parts.first != 'lesson' || parts.length < 3) return (chapter, null);
  final lesson = parts.sublist(2).join(':');
  return (chapter, lesson == 'all' ? null : lesson);
}

List<GlobalPickerNode> globalPickerTypeNodes({
  required int chapter,
  required String? lesson,
  required SearchFlowLessonCounts counts,
  required Map<String, String> s,
  required bool bn,
  List<SearchFlowType> offered = searchFlowBaseTypes,
}) {
  final known = counts.of(chapter, lesson);
  final types = [
    for (final t in offered)
      if (known?[t] != 0) t,
  ];
  return [
    for (final t in types.isEmpty ? offered : types)
      GlobalPickerNode(
        id: globalPickerTypeId(chapter, lesson, t),
        title: searchFlowTypeLabel(t, s),
        subtitle: known?[t] == null ? null : numStr(known![t]!, bn),
        kind: GlobalPickerNodeKind.type,
        pick: GlobalPickerPick.chapterType(chapter, lesson, t),
      ),
  ];
}
