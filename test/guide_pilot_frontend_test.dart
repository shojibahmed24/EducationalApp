// Pilot frontend tests (lesson 2.1, 2026-10-31), Step 7 trim:
// the level-filter, section-tab and level-selector tests are
// GONE with the deleted old filter widgets (guide_bank_filter,
// guide_level_filter, guide_section_tabs). What survives tests
// intact code: creative grouping, model parsing tolerance,
// practice label + solution chip on GuideQuestionRow, and the
// stage-1 verbatim answer body.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/structured_explanation_service.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_answer_body.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_explanation_section.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_groups.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_question_row.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';
import 'package:yes_sir_ai/l10n/pages/lesson_strings.dart';

GuideBankQuestion q(
  String id,
  String type,
  int? marks, {
  String? section,
  String? stimulusId,
}) =>
    GuideBankQuestion(
      id: id,
      questionText: 'প্রশ্ন $id',
      questionType: type,
      marks: marks,
      section: section,
      stimulusId: stimulusId,
    );

void main() {
  test('grouping shares a stimulus, keeps order, singletons stay single',
      () {
    final entries = [
      (0, q('k', 'creative', 2, stimulusId: 's1')),
      (1, q('m', 'mcq', 1)),
      (2, q('kh', 'creative', 4, stimulusId: 's1')),
      (3, q('g', 'creative', 4, stimulusId: 's2')),
      (4, q('plain', 'creative', 2)),
    ];
    final groups = groupQuestionRows(entries);
    expect(groups.length, 4);
    expect(groups[0].stimulusId, 's1');
    expect(
      groups[0].parts.map((e) => e.$2.id),
      ['k', 'kh'],
    );
    expect(groups[1].parts.map((e) => e.$2.id), ['m']);
    expect(groups[2].stimulusId, 's2');
    expect(groups[3].stimulusId, isNull);
  });

  test('model parsing tolerates missing pilot fields', () {
    final from = GuideBankQuestion.fromJson({
      'id': 'x',
      'questionText': 'প্রশ্ন',
      'questionType': 'short',
    });
    expect(from.lesson, isNull);
    expect(from.section, isNull);
    expect(from.stimulusId, isNull);
    final server = GuideBankQuestion.fromServerJson({
      'id': 'y',
      'questionText': 'প্রশ্ন',
      'questionType': 'creative',
    });
    expect(server.lesson, isNull);
    expect(server.stimulusId, isNull);
  });

  test('model round-trips pilot fields', () {
    const original = GuideBankQuestion(
      id: 'z',
      questionText: 'প্রশ্ন',
      questionType: 'creative',
      lesson: '2.1',
      section: 'creative',
      stimulusId: 's9',
    );
    final back = GuideBankQuestion.fromJson(original.toJson());
    expect(back.lesson, '2.1');
    expect(back.section, 'creative');
    expect(back.stimulusId, 's9');
  });

  testWidgets('practice-work row shows the warning label',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuideQuestionRow(
            question: q('p', 'task', null, section: 'practice_work'),
            locked: false,
            s: guideBankStringsBn,
            subjectId: 'math',
            chapterNumber: 2,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(
      find.text('এটা অনুশীলনের জন্য, পাঠ্যবইয়ের সমাধান নয়'),
      findsOneWidget,
    );
  });

  testWidgets('non-practice row shows no warning label',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuideQuestionRow(
            question: q('t', 'short', 2, section: 'short'),
            locked: false,
            s: guideBankStringsBn,
            subjectId: 'math',
            chapterNumber: 2,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(
      find.text('এটা অনুশীলনের জন্য, পাঠ্যবইয়ের সমাধান নয়'),
      findsNothing,
    );
  });

  test('hasSolution parses true/false/absent/non-bool, both parsers',
      () {
    GuideBankQuestion viaJson(Map<String, dynamic> j) =>
        GuideBankQuestion.fromJson({
          'id': 'h',
          'questionText': 'প্রশ্ন',
          'questionType': 'short',
          ...j,
        });
    GuideBankQuestion viaServer(Map<String, dynamic> j) =>
        GuideBankQuestion.fromServerJson({
          'id': 'h',
          'questionText': 'প্রশ্ন',
          'questionType': 'short',
          ...j,
        });
    expect(viaJson({'hasSolution': true}).hasSolution, isTrue);
    expect(viaJson({'hasSolution': false}).hasSolution, isFalse);
    expect(viaJson({}).hasSolution, isNull);
    expect(viaJson({'hasSolution': 'yes'}).hasSolution, isNull);
    expect(viaServer({'hasSolution': true}).hasSolution, isTrue);
    expect(viaServer({}).hasSolution, isNull);
  });

  test('hasSolution round-trips through toJson', () {
    const original = GuideBankQuestion(
      id: 'h',
      questionText: 'প্রশ্ন',
      questionType: 'short',
      hasSolution: true,
    );
    expect(GuideBankQuestion.fromJson(original.toJson()).hasSolution, isTrue);
  });

  testWidgets('solution chip shows only when hasSolution is true',
      (tester) async {
    Widget rowFor(bool? hasSolution) => MaterialApp(
          home: Scaffold(
            body: GuideQuestionRow(
              question: GuideBankQuestion(
                id: 'h',
                questionText: 'প্রশ্ন',
                questionType: 'short',
                marks: 2,
                hasSolution: hasSolution,
              ),
              locked: false,
              s: guideBankStringsBn,
              subjectId: 'math',
              chapterNumber: 2,
              onTap: () {},
            ),
          ),
        );
    await tester.pumpWidget(rowFor(true));
    expect(find.text('সমাধান আছে'), findsOneWidget);
    await tester.pumpWidget(rowFor(null));
    expect(find.text('সমাধান আছে'), findsNothing);
    await tester.pumpWidget(rowFor(false));
    expect(find.text('সমাধান আছে'), findsNothing);
  });

  GuideAnswerBody pilotBody({
    StructuredAttempt? attempt,
    bool pending = false,
  }) {
    return GuideAnswerBody(
      q: const GuideBankQuestion(
        id: 'pilot-2-1',
        questionText: 'পাইলট প্রশ্ন?',
        questionType: 'short',
        marks: 2,
        lesson: '2.1',
        section: 'textbook_exercise',
        hasSolution: true,
      ),
      attempt: attempt,
      keyText: null,
      chips: const ['guide'],
      fontSize: 16,
      onFontSmaller: () {},
      onFontLarger: () {},
      verbatimKind: 'guide',
      verbatimText: 'পাইলট গাইড উত্তর',
      correctionNote: '',
      guideError: false,
      showExplanation: true,
      stepsOnly: false,
      onExplainDetailed: () {},
      onExplainSteps: () {},
      explanation: ExplanationSectionInput(
        requested: true,
        pending: pending,
        unavailable: false,
        onRequest: () {},
        onRetry: () {},
      ),
      subjectId: 'math',
      chapterNumber: 2,
      bn: true,
      s: guideBankStringsBn,
      ls: lessonStringsBn,
    );
  }

  testWidgets('pilot stage-1: verbatim shows while explanation pending',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: pilotBody(pending: true))),
    );
    expect(find.text('পাইলট প্রশ্ন?', findRichText: true), findsOneWidget);
    expect(find.text('পাইলট গাইড উত্তর', findRichText: true), findsOneWidget);
    expect(find.text('ব্যাখ্যা তৈরি হচ্ছে…'), findsOneWidget);
    expect(find.text(guideBankStringsBn['answerFailed']!), findsNothing);
  });

  testWidgets('pilot stage-1: verbatim survives a failed explanation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: pilotBody(
            attempt: const StructuredAttempt(
              status: StructuredStatus.failed,
            ),
          ),
        ),
      ),
    );
    expect(find.text('পাইলট গাইড উত্তর', findRichText: true), findsOneWidget);
    // The failed row lives ONLY in the explanation section below
    // the intact stage-1 cards — it never replaces them.
    expect(find.text(guideBankStringsBn['answerFailed']!), findsOneWidget);
  });
}
