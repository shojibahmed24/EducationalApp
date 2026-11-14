// Picker type step: chapter/lesson rows drill into the question
// types with exact counts; a type pick fixes chapter + lesson +
// type in one tap. Tree tests use snapshots only (no I/O).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/guide_flow_count_service.dart';
import 'package:yes_sir_ai/features/learn/global_picker_model.dart';
import 'package:yes_sir_ai/features/learn/global_picker_tree.dart';
import 'package:yes_sir_ai/features/learn/global_picker_type_nodes.dart';
import 'package:yes_sir_ai/features/learn/search_flow_browse_extras.dart';
import 'package:yes_sir_ai/features/learn/search_flow_controller.dart';
import 'package:yes_sir_ai/features/learn/search_flow_lesson_counts.dart';
import 'package:yes_sir_ai/features/learn/search_flow_picker_host.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';
import 'package:yes_sir_ai/l10n/pages/search_flow_strings.dart';

SearchFlowController _c(String subject, String source) =>
    SearchFlowController(
        initialSubjectId: subject, initialSchoolClass: 9, onChanged: () {})
      ..subjectId = subject
      ..source = source
      ..schoolClass = 9
      ..chapters = [(2, 'অধ্যায়'), (5, 'অধ্যায় পাঁচ')]
      ..chaptersLoading = false;

GlobalPickerTree _tree(SearchFlowController c, SearchFlowBrowseExtras e) =>
    buildGlobalPickerTree(c: c, extras: e, s: searchFlowStringsBn, bn: true);

void main() {
  test('scope parsing of chapter and lesson node ids', () {
    expect(globalPickerParseScope('lesson:2:2.1'), (2, '2.1'));
    expect(globalPickerParseScope('lesson:2:all'), (2, null));
    expect(globalPickerParseScope('chapter:7'), (7, null));
    expect(globalPickerParseScope('lesson:__all:x'), isNull);
  });

  test('math lesson row drills into all five types, pick carries them', () {
    final c = _c('math', 'guide');
    final e = SearchFlowBrowseExtras(onChanged: () {});
    final tree = _tree(c, e);
    final ch2 = tree.rootNodes.firstWhere((n) => n.id == 'chapter:2');
    final lesson =
        tree.childrenOf(ch2)!.firstWhere((n) => n.id == 'lesson:2:2.1');
    expect(lesson.hasChildren, isTrue);
    final types = tree.childrenOf(lesson)!;
    expect(types.length, searchFlowBaseTypes.length);
    expect(types.first.id, 'type:2:2.1:${SearchFlowType.values.first.name}');
    expect(types.first.pick?.kind, GlobalPickerPickKind.chapterType);
    expect(types.first.pick?.chapter, 2);
    expect(types.first.pick?.lesson, '2.1');
    expect(types.first.pick?.type, SearchFlowType.values.first);
    // No count known yet: nothing is guessed.
    expect(types.every((n) => n.subtitle == null), isTrue);
  });

  test('"all lessons" row gives types with a null lesson', () {
    final c = _c('math', 'guide');
    final tree = _tree(c, SearchFlowBrowseExtras(onChanged: () {}));
    final ch2 = tree.rootNodes.firstWhere((n) => n.id == 'chapter:2');
    final all = tree.childrenOf(ch2)!.first;
    final types = tree.childrenOf(all)!;
    expect(types.first.id, startsWith('type:2:all:'));
    expect(types.first.pick?.lesson, isNull);
  });

  test('a chapter without lessons goes straight to the types', () {
    final c = _c('physics', 'guide');
    final tree = _tree(c, SearchFlowBrowseExtras(onChanged: () {}));
    final ch = tree.rootNodes.firstWhere((n) => n.id == 'chapter:5');
    expect(ch.hasChildren, isTrue);
    final kids = tree.childrenOf(ch)!;
    expect(kids.map((n) => n.kind).toSet(), {GlobalPickerNodeKind.type});
    expect(kids.first.pick?.lesson, isNull);
  });

  test('textbook chapters stay leaves (no type step there)', () {
    final c = _c('math', 'textbook');
    final tree = _tree(c, SearchFlowBrowseExtras(onChanged: () {}));
    expect(tree.rootNodes.first.hasChildren, isFalse);
  });

  testWidgets('a type pick sets chapter, lesson and type; selected id '
      'round-trips', (tester) async {
    final c = _c('math', 'guide');
    final extras = SearchFlowBrowseExtras(onChanged: () {})..setId = 'model-1';
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }),
    ));
    applyGlobalPickerPick(
      context: ctx,
      c: c,
      extras: extras,
      pick: GlobalPickerPick.chapterType(2, '2.2', SearchFlowType.creative),
      onChanged: () {},
    );
    expect(c.chapter, 2);
    expect(c.lesson, '2.2');
    expect(c.type, SearchFlowType.creative);
    expect(extras.setId, isNull);
    expect(globalPickerSelectedId(c, extras),
        globalPickerTypeId(2, '2.2', SearchFlowType.creative));
  });

  Future<SearchFlowLessonCounts> loaded(int Function(String section) n) async {
    final lc = SearchFlowLessonCounts(
      onChanged: () {},
      service: GuideFlowCountService(post: (b, {endpoint}) async => {
            'found': true,
            'total': n(b['section'] as String),
            'lesson': b['lesson'],
            'section': b['section'],
          }),
    );
    await lc.load(
        subject: 'chemistry', schoolClass: 9, chapter: 3, lessons: const []);
    return lc;
  }

  List<GlobalPickerNode> typeNodes(SearchFlowLessonCounts lc) =>
      globalPickerTypeNodes(
        chapter: 3,
        lesson: null,
        counts: lc,
        s: searchFlowStringsBn,
        bn: true,
      );

  test('types with a known zero count are hidden', () async {
    final lc = await loaded((sec) =>
        const {'mcq_bank': 350, 'short': 72, 'creative': 48}[sec] ?? 0);
    final names = typeNodes(lc).map((n) => n.pick!.type).toSet();
    expect(names, {
      SearchFlowType.mcq,
      SearchFlowType.short,
      SearchFlowType.creative,
    });
  });

  test('when every count is zero all types stay visible', () async {
    final lc = await loaded((sec) => 0);
    // all-zero counts are stored as unknown-free zeros: nothing hidden
    expect(typeNodes(lc).length, searchFlowBaseTypes.length);
  });
}
