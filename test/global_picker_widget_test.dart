// Global picker widget tests + pick-application tests: the one
// widget drills, filters, goes back, and picks; the host apply
// keeps the old mutual-exclusion rules.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/global_picker_model.dart';
import 'package:yes_sir_ai/features/learn/search_flow_browse_extras.dart';
import 'package:yes_sir_ai/features/learn/search_flow_controller.dart';
import 'package:yes_sir_ai/features/learn/search_flow_picker_host.dart';
import 'package:yes_sir_ai/features/learn/widgets/global_picker.dart';
import 'package:yes_sir_ai/l10n/pages/search_flow_strings.dart';

GlobalPickerTree _fakeTree() {
  const chapter = GlobalPickerNode(
    id: 'chapter:2',
    title: 'অধ্যায় ২',
    kind: GlobalPickerNodeKind.chapter,
    hasChildren: true,
  );
  const leaf = GlobalPickerNode(
    id: 'chapter:3',
    title: 'অধ্যায় ৩',
    kind: GlobalPickerNodeKind.chapter,
    pick: GlobalPickerPick.chapter(3),
  );
  return GlobalPickerTree(
    loading: false,
    rootNodes: const [chapter, leaf],
    childrenOf: (node) => node.id == 'chapter:2'
        ? const [
            GlobalPickerNode(
              id: 'lesson:2:all',
              title: 'সব লেসন',
              kind: GlobalPickerNodeKind.lesson,
              pick: GlobalPickerPick.chapterLesson(2, null),
            ),
            GlobalPickerNode(
              id: 'lesson:2:2.1',
              title: '2.1 · সেট',
              kind: GlobalPickerNodeKind.lesson,
              pick: GlobalPickerPick.chapterLesson(2, '2.1'),
            ),
          ]
        : const [],
  );
}

Widget _wrap(GlobalPicker picker) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: picker)),
    );

void main() {
  testWidgets('drills into a branch, picks a leaf, goes back',
      (tester) async {
    GlobalPickerPick? picked;
    await tester.pumpWidget(_wrap(GlobalPicker(
      treeKey: 'math|guide|9',
      tree: _fakeTree(),
      s: searchFlowStringsBn,
      selectedId: null,
      onPick: (p) => picked = p,
    )));
    expect(find.text('অধ্যায় ২'), findsOneWidget);
    expect(find.text('অধ্যায় ৩'), findsOneWidget);
    await tester.tap(find.text('অধ্যায় ২'));
    await tester.pumpAndSettle();
    expect(find.text('সব লেসন'), findsOneWidget);
    expect(find.text('2.1 · সেট'), findsOneWidget);
    await tester.tap(find.text('2.1 · সেট'));
    await tester.pumpAndSettle();
    expect(picked?.kind, GlobalPickerPickKind.chapterLesson);
    expect(picked?.chapter, 2);
    expect(picked?.lesson, '2.1');
    // Back returns to the root level.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('অধ্যায় ৩'), findsOneWidget);
  });

  testWidgets('filter narrows the current level, treeKey resets',
      (tester) async {
    late StateSetter setOuter;
    var key = 'math|guide|9';
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          setOuter = setState;
          return Scaffold(
            body: SingleChildScrollView(
              child: GlobalPicker(
                treeKey: key,
                tree: _fakeTree(),
                s: searchFlowStringsBn,
                selectedId: null,
                onPick: (_) {},
              ),
            ),
          );
        },
      ),
    ));
    await tester.enterText(find.byType(TextField), '৩');
    await tester.pumpAndSettle();
    expect(find.text('অধ্যায় ৩'), findsOneWidget);
    expect(find.text('অধ্যায় ২'), findsNothing);
    // Drill, then a treeKey change resets to the root level.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('অধ্যায় ২'));
    await tester.pumpAndSettle();
    expect(find.text('সব লেসন'), findsOneWidget);
    setOuter(() => key = 'physics|guide|9');
    await tester.pumpAndSettle();
    expect(find.text('অধ্যায় ৩'), findsOneWidget);
    expect(find.text('সব লেসন'), findsNothing);
  });

  testWidgets('selected row shows a check', (tester) async {
    await tester.pumpWidget(_wrap(GlobalPicker(
      treeKey: 'math|guide|9',
      tree: _fakeTree(),
      s: searchFlowStringsBn,
      selectedId: 'chapter:3',
      onPick: (_) {},
    )));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('apply keeps the old mutual-exclusion rules',
      (tester) async {
    final c = SearchFlowController(
        initialSubjectId: 'math', initialSchoolClass: 9, onChanged: () {})
      ..subjectId = 'math'
      ..source = 'guide'
      ..chapter = 2
      ..lesson = '2.1';
    final extras = SearchFlowBrowseExtras(onChanged: () {})
      ..setId = 'model-1';
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }),
    ));
    // A set pick clears lesson + Paper-II section.
    applyGlobalPickerPick(
        context: ctx,
        c: c,
        extras: extras,
        pick: const GlobalPickerPick.set('model-2'),
        onChanged: () {});
    expect(extras.setId, 'model-2');
    expect(c.lesson, isNull);
    // A lesson pick clears the set but keeps the chapter.
    applyGlobalPickerPick(
        context: ctx,
        c: c,
        extras: extras,
        pick: const GlobalPickerPick.chapterLesson(2, '2.2'),
        onChanged: () {});
    expect(extras.setId, isNull);
    expect(c.chapter, 2);
    expect(c.lesson, '2.2');
    // A chapter pick clears the lesson.
    applyGlobalPickerPick(
        context: ctx,
        c: c,
        extras: extras,
        pick: const GlobalPickerPick.chapter(3),
        onChanged: () {});
    expect(c.chapter, 3);
    expect(c.lesson, isNull);
    // Selected-id round-trips the same state.
    expect(globalPickerSelectedId(c, extras), 'chapter:3');
  });
}
