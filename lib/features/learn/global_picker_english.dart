// English guide tree for the global picker: the redesign's 13
// sections as level 1 (constants, so the picker opens instantly),
// collections drilling to their lessons, writing sections going
// straight to the existing list route. Destinations are exactly
// the ones the dedicated English screen uses (list + reader) —
// only the entry picker is unified, nothing downstream changes.
// Lesson loading stays lazy: sets/bank load once when the English
// controller is created, bucket rows only on first bucket drill.
import '../../core/data/english_redesign.dart';
import '../../core/data/english_redesign_lessons.dart';
import 'english_search_flow_controller.dart';
import 'global_picker_model.dart';

/// Collection sections drill to lessons; the rest open the list
/// directly, mirroring the dedicated English screen's buttons.
bool _isEnglishCollection(String section) =>
    section == 'practice' ||
    section == 'model' ||
    section == 'special' ||
    section == 'poem' ||
    section == 'story' ||
    section == 'bucket';

GlobalPickerTree buildEnglishPickerTree({
  required EnglishSearchFlowController c,
  required int schoolClass,
  required Map<String, String> s,
  required bool bn,
}) {
  String readerRoute(EnglishRedesignLesson item) {
    final q = StringBuffer(
        '/english-reader?class=$schoolClass&kind=${item.kind}');
    q.write('&title=${Uri.encodeComponent(
        redesignLessonDisplayLabel(item, bn))}');
    if (item.setId != null) q.write('&setId=${item.setId}');
    if (item.lesson != null) {
      q.write('&lesson=${Uri.encodeComponent(item.lesson!)}');
    }
    if (item.stimulusRef != null) {
      q.write('&ref=${Uri.encodeComponent(item.stimulusRef!)}');
    }
    if (item.workName != null) {
      q.write('&work=${Uri.encodeComponent(item.workName!)}');
    }
    return q.toString();
  }

  List<GlobalPickerNode>? childrenOf(GlobalPickerNode node) {
    if (node.kind != GlobalPickerNodeKind.englishSection) {
      return const [];
    }
    // Null while the section's data is still loading: the widget
    // shows a spinner and the controller's notify rebuilds it.
    final items = c.lessonItems;
    if (items == null) return null;
    return [
      for (final item in items)
        GlobalPickerNode(
          id: 'enlesson:${item.kind}:${item.setId ?? ''}:'
              '${item.lesson ?? ''}:${item.workName ?? ''}:${item.index}',
          title: redesignLessonDisplayLabel(item, bn),
          kind: GlobalPickerNodeKind.englishLesson,
          pick: GlobalPickerPick.route(readerRoute(item)),
        ),
    ];
  }

  return GlobalPickerTree(
    loading: false,
    rootNodes: [
      for (final sec in englishRedesignSections)
        GlobalPickerNode(
          id: 'en:$sec',
          title: s[englishRedesignSectionStringKey(sec)]!,
          kind: GlobalPickerNodeKind.englishSection,
          hasChildren: _isEnglishCollection(sec),
          pick: _isEnglishCollection(sec)
              ? null
              : GlobalPickerPick.route(
                  '/english-search-flow-list?class=$schoolClass'
                  '&section=$sec'),
        ),
    ],
    childrenOf: childrenOf,
  );
}
