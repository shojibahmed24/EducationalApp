// Stage-1 independence (2026-10-31 fix): the guide answer body's
// question, key and verbatim cards must render even when the AI
// explanation attempt is null or failed. Previously the whole body
// was replaced by the "ব্যাখ্যা তৈরি করা যায়নি" failure screen,
// hiding the guide's own answer — the bug users reported in every
// class ("guide theke answer konota tei ashe na").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/structured_explanation_service.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_answer_body.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_explanation_section.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';
import 'package:yes_sir_ai/l10n/pages/lesson_strings.dart';

GuideAnswerBody buildBody({
  StructuredAttempt? attempt,
  String kind = 'none',
  String text = '',
  bool showExplanation = true,
}) {
  return GuideAnswerBody(
    q: const GuideBankQuestion(
      id: 't1',
      questionText: 'পরীক্ষার প্রশ্ন?',
      questionType: 'problem',
    ),
    attempt: attempt,
    keyText: null,
    chips: const ['guide'],
    fontSize: 16,
    onFontSmaller: () {},
    onFontLarger: () {},
    verbatimKind: kind,
    verbatimText: text,
    correctionNote: '',
    guideError: false,
    showExplanation: showExplanation,
    stepsOnly: false,
    onExplainDetailed: () {},
    onExplainSteps: () {},
    explanation: ExplanationSectionInput(
      requested: true,
      pending: false,
      unavailable: false,
      onRequest: () {},
      onRetry: () {},
    ),
    subjectId: 'math',
    chapterNumber: 1,
    bn: true,
    s: guideBankStringsBn,
    ls: lessonStringsBn,
  );
}

Widget wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('null attempt + verbatim still shows guide answer',
      (tester) async {
    // Initial verbatim-first state: explanation hidden behind buttons.
    await tester.pumpWidget(wrap(buildBody(
      kind: 'guide',
      text: 'গাইডের আসল উত্তর',
      showExplanation: false,
    )));
    expect(find.text('গাইডের আসল উত্তর', findRichText: true), findsOneWidget);
    expect(find.text('পরীক্ষার প্রশ্ন?', findRichText: true), findsOneWidget);
    expect(find.text(guideBankStringsBn['answerFailed']!), findsNothing);
  });

  testWidgets('null attempt + no verbatim shows AI card + failed row',
      (tester) async {
    await tester.pumpWidget(wrap(buildBody()));
    expect(find.text(guideBankStringsBn['aiAnswerTitle']!), findsOneWidget);
    expect(find.text(guideBankStringsBn['answerFailed']!), findsOneWidget);
    expect(find.text(guideBankStringsBn['retry']!), findsOneWidget);
  });

  testWidgets('failed attempt with prose renders prose, not failure',
      (tester) async {
    await tester.pumpWidget(wrap(buildBody(
      attempt: const StructuredAttempt(
        status: StructuredStatus.failed,
        rawText: 'মডেলের গদ্য ব্যাখ্যা',
      ),
    )));
    // The prose section sits below the fold in the test viewport,
    // and the block renderer emits a RichText (not a plain Text),
    // so scroll it into view and match RichText explicitly.
    await tester.scrollUntilVisible(
      find.textContaining('মডেলের গদ্য ব্যাখ্যা', findRichText: true),
      200,
    );
    expect(
      find.textContaining('মডেলের গদ্য ব্যাখ্যা', findRichText: true),
      findsWidgets,
    );
    expect(find.text(guideBankStringsBn['answerFailed']!), findsNothing);
  });

  testWidgets('keyMismatch attempt still renders body, not failure',
      (tester) async {
    await tester.pumpWidget(wrap(buildBody(
      attempt: const StructuredAttempt(
        status: StructuredStatus.keyMismatch,
        storedKey: 'ক',
      ),
    )));
    expect(find.text('পরীক্ষার প্রশ্ন?', findRichText: true), findsOneWidget);
    expect(find.text(guideBankStringsBn['answerFailed']!), findsNothing);
  });
}
