// Guide-based subject sourcing (all classes): Home shows locked
// subjects that have guide content, and their tiles lead to the
// new search flow (which defaults their source to guide) — never
// to a textbook chapter list that does not exist. Search's guide
// section renders the note + link in every state and never
// crashes when the guide is unreachable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/features/home/widgets/home_subject_grid.dart';
import 'package:yes_sir_ai/features/home/widgets/home_subject_tile.dart';
import 'package:yes_sir_ai/features/learn/widgets/search_guide_section.dart';

SubjectInfo _subject(
  String id, {
  required bool locked,
  bool hasGuide = false,
  int guideChapters = 0,
}) =>
    SubjectInfo(
      id: id,
      nameBn: id,
      nameEn: id,
      locked: locked,
      chapterCount: 5,
      hasGuide: hasGuide,
      guideChapterCount: guideChapters,
    );

void main() {
  test('SubjectInfo guide flags default to false/0', () {
    const s = SubjectInfo(
      id: 'math',
      nameBn: 'গণিত',
      nameEn: 'Maths',
      locked: true,
      chapterCount: 0,
    );
    expect(s.hasGuide, isFalse);
    expect(s.guideChapterCount, 0);
  });

  test('visibleHomeSubjects keeps unlocked + guide-locked, drops others',
      () {
    final out = visibleHomeSubjects([
      _subject('math', locked: false),
      _subject('science', locked: true, hasGuide: true, guideChapters: 8),
      _subject('bgs', locked: true),
    ]);
    expect(out.map((s) => s.id), ['math', 'science']);
  });

  test('homeSubjectRoute: every tile goes to the new search flow', () {
    expect(
      homeSubjectRoute('math'),
      '/search-flow?subject=math',
    );
    expect(
      homeSubjectRoute('science'),
      '/search-flow?subject=science',
    );
  });

  testWidgets('SearchGuideSection unlocked renders note + link only',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SearchGuideSection(
            subject: 'math',
            schoolClass: 9,
            locked: false,
            note: 'note-text',
            linkLabel: 'link-text',
            buttonLabel: 'button-text',
          ),
        ),
      ),
    );
    expect(find.text('note-text'), findsOneWidget);
    expect(find.text('link-text'), findsOneWidget);
    expect(find.text('button-text'), findsNothing);
  });

  testWidgets('SearchGuideSection locked without guide never crashes',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SearchGuideSection(
            subject: 'math',
            schoolClass: 9,
            locked: true,
            note: 'note-text',
            linkLabel: 'link-text',
            buttonLabel: 'button-text',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('note-text'), findsOneWidget);
    expect(find.text('link-text'), findsOneWidget);
    // No guide endpoint in tests, so no guide button — but also
    // no crash and no dead-end placeholder.
    expect(find.text('button-text'), findsNothing);
  });
}
