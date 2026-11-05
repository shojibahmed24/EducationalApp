// Single-question answer body (2026-11-01): a row carrying
// stimulus text must show the pinned passage block above the
// question; a row without stimulus text or ref must render
// exactly as before (no fake passage block).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_answer_body.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_explanation_section.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';
import 'package:yes_sir_ai/l10n/pages/lesson_strings.dart';

GuideAnswerBody buildBody(GuideBankQuestion q) {
  return GuideAnswerBody(
    q: q,
    attempt: null,
    keyText: null,
    chips: const ['guide'],
    fontSize: 16,
    onFontSmaller: () {},
    onFontLarger: () {},
    verbatimKind: 'none',
    verbatimText: '',
    correctionNote: '',
    guideError: false,
    showExplanation: false,
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
    subjectId: 'english',
    chapterNumber: 0,
    bn: true,
    s: guideBankStringsBn,
    ls: lessonStringsBn,
  );
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('row with stimulus text shows the pinned block', (tester) async {
    await tester.pumpWidget(
      wrap(
        buildBody(
          const GuideBankQuestion(
            id: 'eng1-p281-writing-story-w1',
            questionText: 'Read the following story. Complete it.',
            questionType: 'writing-story',
            stimulusText: 'There lived a woodcutter in a village.',
          ),
        ),
      ),
    );
    expect(find.text(guideBankStringsBn['stimulusTitle']!), findsOneWidget);
    expect(
      find.text('There lived a woodcutter in a village.', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Read the following story. Complete it.', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('row with only a passage ref shows the source line', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        buildBody(
          const GuideBankQuestion(
            id: 'eng1-p019-mcq-q1-set1-a',
            questionText: 'shriek',
            questionType: 'mcq',
            stimulusRef: 'Unit-01 Lesson-01 seen passage (Mr. Moti)',
          ),
        ),
      ),
    );
    expect(
      find.text(
        '${guideBankStringsBn['passageSource']!}: Unit-01 Lesson-01 seen passage (Mr. Moti)',
      ),
      findsOneWidget,
    );
    expect(find.text(guideBankStringsBn['stimulusTitle']!), findsNothing);
  });

  testWidgets('row with neither renders no passage block', (tester) async {
    await tester.pumpWidget(
      wrap(
        buildBody(
          const GuideBankQuestion(
            id: 'eng1-p017-short-a1',
            questionText: 'Why is the rooster called Mr. Moti?',
            questionType: 'short',
          ),
        ),
      ),
    );
    expect(find.text(guideBankStringsBn['stimulusTitle']!), findsNothing);
    expect(find.text(guideBankStringsBn['passageSource']!), findsNothing);
    expect(
      find.text('Why is the rooster called Mr. Moti?', findRichText: true),
      findsOneWidget,
    );
  });
}
