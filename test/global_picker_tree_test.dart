// Global picker tree tests: one picker, every subject. The tree
// is built from controller/extras snapshots only, so these tests
// set fields directly and assert nodes + picks, no I/O.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/bangla_first_lessons.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/bangla_second_types.dart';
import 'package:yes_sir_ai/features/learn/global_picker_model.dart';
import 'package:yes_sir_ai/features/learn/global_picker_tree.dart';
import 'package:yes_sir_ai/features/learn/search_flow_browse_extras.dart';
import 'package:yes_sir_ai/features/learn/search_flow_controller.dart';
import 'package:yes_sir_ai/l10n/pages/search_flow_strings.dart';

SearchFlowController _controller() => SearchFlowController(
      initialSubjectId: 'math',
      initialSchoolClass: 9,
      onChanged: () {},
    );

SearchFlowBrowseExtras _extras() =>
    SearchFlowBrowseExtras(onChanged: () {});

GlobalPickerTree _tree(
  SearchFlowController c,
  SearchFlowBrowseExtras e,
) =>
    buildGlobalPickerTree(
        c: c, extras: e, s: searchFlowStringsBn, bn: true);

void main() {
  test('math guide: chapters root, lessons drill under a chapter', () {
    final c = _controller()
      ..subjectId = 'math'
      ..source = 'guide'
      ..schoolClass = 9
      ..chapters = [(2, 'বীজগাণিতিক রাশি'), (3, 'জ্যামিতি')]
      ..chaptersLoading = false;
    final tree = _tree(c, _extras());
    expect(tree.loading, isFalse);
    final chapter2 =
        tree.rootNodes.firstWhere((n) => n.id == 'chapter:2');
    expect(chapter2.hasChildren, isTrue);
    expect(chapter2.pick?.kind, GlobalPickerPickKind.chapter);
    final kids = tree.childrenOf(chapter2)!;
    expect(kids.first.id, 'lesson:2:all');
    expect(kids.first.pick?.kind, GlobalPickerPickKind.chapterLesson);
    expect(kids.first.pick?.chapter, 2);
    expect(kids.first.pick?.lesson, isNull);
    // Every static lesson of chapter 2 appears exactly once.
    expect(kids.length - 1, 2);
    expect(kids.any((n) => n.id == 'lesson:2:2.1'), isTrue);
  });

  test('math textbook: chapters are leaves, no sets group', () {
    final c = _controller()
      ..subjectId = 'math'
      ..source = 'textbook'
      ..schoolClass = 9
      ..chapters = [(2, 'বীজগাণিতিক রাশি')]
      ..chaptersLoading = false;
    final tree = _tree(c, _extras());
    expect(tree.rootNodes.single.hasChildren, isFalse);
    expect(tree.rootNodes.single.pick?.kind, GlobalPickerPickKind.chapter);
  });

  test('generic guide: chapters plus a sets group when sets exist', () {
    final c = _controller()
      ..subjectId = 'physics'
      ..source = 'guide'
      ..schoolClass = 9
      ..chapters = [(1, 'ভৌত রাশি')]
      ..chaptersLoading = false;
    final e = _extras()
      ..sets = [
        const GuideModelSetInfo(
            setId: 'model-1', totalCount: 30, keyedCount: 30),
      ];
    final tree = _tree(c, e);
    expect(tree.rootNodes.map((n) => n.id), ['chapter:1', 'sets-group']);
    final group =
        tree.rootNodes.firstWhere((n) => n.id == 'sets-group');
    expect(group.hasChildren, isTrue);
    expect(group.pick, isNull);
    final setKids = tree.childrenOf(group)!;
    expect(setKids.single.id, 'set:model-1');
    expect(setKids.single.pick?.kind, GlobalPickerPickKind.set);
  });

  test('bangla 1st guide: sections root, lessons filter by section',
      () {
    final c = _controller()
      ..subjectId = 'bangla-1st'
      ..source = 'guide'
      ..schoolClass = 9
      ..chaptersLoading = false;
    final firstLesson = banglaFirstLessons.first;
    final e = _extras()
      ..serverLessons = {firstLesson.title: 4, 'অজানা-লেসন': 2}
      ..serverLessonsLoading = false;
    final tree = _tree(c, e);
    final sectionNode = tree.rootNodes
        .firstWhere((n) => n.id == 'section:${firstLesson.section}');
    expect(sectionNode.hasChildren, isTrue);
    final kids = tree.childrenOf(sectionNode)!;
    expect(kids.first.id, 'lesson:${firstLesson.section}:all');
    expect(
        kids.any((n) => n.title == firstLesson.title), isTrue);
    // The unmapped title belongs to no section: hidden here.
    expect(kids.any((n) => n.title == 'অজানা-লেসন'), isFalse);
    // ...but reachable through the all-lessons branch.
    final allNode =
        tree.rootNodes.firstWhere((n) => n.id == 'section:__all');
    final allKids = tree.childrenOf(allNode)!;
    expect(allKids.any((n) => n.title == 'অজানা-লেসন'), isTrue);
    final unmappedPick = allKids
        .firstWhere((n) => n.title == 'অজানা-লেসন')
        .pick!;
    expect(unmappedPick.kind, GlobalPickerPickKind.sectionLesson);
    expect(unmappedPick.banglaSection, isNull);
    expect(unmappedPick.lesson, 'অজানা-লেসন');
  });

  test('bangla 1st guide: section children load while server lags',
      () {
    final c = _controller()
      ..subjectId = 'bangla-1st'
      ..source = 'guide'
      ..schoolClass = 9
      ..chaptersLoading = false;
    final e = _extras()..serverLessonsLoading = true;
    final tree = _tree(c, e);
    final sectionNode =
        tree.rootNodes.firstWhere((n) => n.id == 'section:goddo');
    expect(tree.childrenOf(sectionNode), isNull);
  });

  test('paper2 guide: sections root in fixed order', () {
    final c = _controller()
      ..subjectId = 'english-2nd'
      ..source = 'guide'
      ..schoolClass = 9
      ..chaptersLoading = false;
    final tree = _tree(c, _extras());
    expect(tree.rootNodes.length, 15);
    expect(tree.rootNodes.first.pick?.kind, GlobalPickerPickKind.paper2);
    expect(tree.rootNodes.first.pick?.paper2Section, 'gapbox');
    expect(tree.rootNodes.last.pick?.paper2Section,
        'writing-composition');
  });

  test('bangla 2nd guide: 11 type nodes, each a route pick', () {
    final c = _controller()
      ..subjectId = 'bangla-2nd'
      ..source = 'guide'
      ..schoolClass = 10
      ..chaptersLoading = false;
    final tree = _tree(c, _extras());
    expect(tree.rootNodes.length, banglaSecondTypesInOrder.length);
    expect(tree.rootNodes.length, 11);
    for (final n in tree.rootNodes) {
      expect(n.kind, GlobalPickerNodeKind.banglaSecondType);
      expect(n.hasChildren, isFalse);
      expect(n.pick?.kind, GlobalPickerPickKind.route);
      expect(n.pick?.route, startsWith('/bangla-second'));
    }
    expect(tree.rootNodes.last.id, 'b2:modelTest');
  });

  test('loading root while chapters still load', () {
    final c = _controller()
      ..subjectId = 'math'
      ..source = 'guide'
      ..chaptersLoading = true;
    expect(_tree(c, _extras()).loading, isTrue);
  });
}
