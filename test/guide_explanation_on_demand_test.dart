// 2026-11-03 explanation fix: Bangla + easy language, verbatim
// options, correct option by exact text + label, the option-less
// MCQ backstop, and the on-demand explanation section (button
// first, no auto-generation). Fixture data is fake — never real
// guide content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/models/solution_model.dart';
import 'package:yes_sir_ai/core/services/marks_budget.dart';
import 'package:yes_sir_ai/core/services/structured_prompts.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_explanation_section.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';

GroundedContext _mcqCtx({
  String questionText = 'shriek',
  List<String> options = const [
    'laughs loudly',
    'cries out sharply',
    'sings softly',
    'talks quietly',
  ],
  String answerKey = 'ii',
  String stimulusText = '',
  String stimulusRef = '',
}) =>
    GroundedContext(
      bookTitle: 'English',
      chapterTitle: 'Unit 1',
      subject: 'english',
      schoolClass: 9,
      chapterNumber: 0,
      page: 0,
      problem: 0,
      questionText: questionText,
      source: 'guide',
      guideQuestionId: 'fake-mcq-1',
      questionType: 'mcq',
      answerKey: answerKey,
      options: options,
      stimulusText: stimulusText,
      stimulusRef: stimulusRef,
    );

void main() {
  group('Bangla + easy-language prompt enforcement', () {
    test('Bangla system prompt demands all-Bangla easy words', () {
      final prompt = structuredSystemPrompt(
        true,
        marksBudgetFor(marks: 1, questionType: 'mcq'),
        false,
      );
      expect(prompt, contains('Bangla'));
      expect(prompt, contains('easy simple words'));
      expect(prompt, contains('Never write any part of the explanation in English'));
    });

    test('English system prompt carries no Bangla-only clause', () {
      final prompt = structuredSystemPrompt(
        false,
        marksBudgetFor(marks: 1, questionType: 'mcq'),
        false,
      );
      expect(prompt, contains('English'));
      expect(prompt.contains('Never write any part of the explanation in English'),
          isFalse);
    });

    test('Bangla system prompt carries the script rule', () {
      final prompt = structuredSystemPrompt(
        true,
        marksBudgetFor(marks: 1, questionType: 'mcq'),
        false,
      );
      expect(prompt, contains('Bengali script'));
      expect(prompt, contains('never mix scripts'));
      expect(prompt, contains('Arabic script'));
    });
  });

  group('verbatim-option quoting constraint', () {
    test('user prompt quotes every option verbatim with both labels', () {
      final prompt = structuredUserPrompt(_mcqCtx(), 'steps', null);
      expect(prompt, contains('Question (verbatim): shriek'));
      expect(prompt, contains('ক (i). laughs loudly'));
      expect(prompt, contains('খ (ii). cries out sharply'));
      expect(prompt, contains('গ (iii). sings softly'));
      expect(prompt, contains('ঘ (iv). talks quietly'));
      // Correct option named by exact text + label, never invented.
      expect(prompt, contains("exact text: 'cries out sharply'"));
      expect(prompt, contains('খ (ii)'));
      expect(prompt.contains('scream'), isFalse);
    });

    test('roman + Bengali keys both map to the same option', () {
      expect(_mcqCtx(answerKey: 'ii').correctOptionText, 'cries out sharply');
      expect(_mcqCtx(answerKey: 'খ').correctOptionText, 'cries out sharply');
      expect(_mcqCtx(answerKey: 'i').correctOptionText, 'laughs loudly');
      expect(_mcqCtx(answerKey: 'zz').correctOptionText, isNull);
      expect(_mcqCtx(answerKey: 'v').correctOptionText, isNull);
    });

    test('stimulus rides as its own block, never fused into the question', () {
      final prompt = structuredUserPrompt(
        _mcqCtx(
          stimulusText: 'A story about a duck.',
          stimulusRef: 'Unit-01 Lesson-01 seen passage',
        ),
        'steps',
        null,
      );
      expect(prompt, contains('উদ্দীপক (stimulus — context only'));
      expect(prompt, contains('Question (verbatim): shriek'));
      expect(prompt.contains('উদ্দীপক: A story about a duck.\nshriek'), isFalse);
    });

    test('option-less MCQ prompt forbids invented options', () {
      final prompt = structuredUserPrompt(
        _mcqCtx(options: const []),
        'steps',
        null,
      );
      expect(prompt, contains('Options: NONE were provided'));
      expect(prompt, contains('Do NOT invent options'));
      expect(prompt.contains('ক (i).'), isFalse);
    });

    test('shared blocks are identical for both prompt paths', () {
      final ctx = _mcqCtx();
      expect(optionsPromptBlock(ctx), contains('খ (ii). cries out sharply'));
      expect(stimulusPromptBlock(ctx), isEmpty);
      expect(
        stimulusPromptBlock(_mcqCtx(stimulusText: 'Some prose.')),
        contains('উদ্দীপক (stimulus — context only'),
      );
      expect(correctOptionLabel(1), 'খ (ii)');
      expect(correctOptionLabel(0), 'ক (i)');
    });
  });

  group('on-demand explanation section', () {
    Widget wrap(GuideExplanationSection section) => MaterialApp(
          home: Scaffold(body: section),
        );

    GuideExplanationSection section({
      required bool requested,
      required bool pending,
      required bool unavailable,
      required void Function() onRequest,
    }) =>
        GuideExplanationSection(
          attempt: null,
          question: const GuideBankQuestion(
            id: 'fake-mcq-1',
            questionText: 'shriek',
            questionType: 'mcq',
          ),
          chips: const ['guide'],
          fontSize: 16,
          s: guideBankStringsBn,
          ls: const {},
          stepsOnly: false,
          explanation: ExplanationSectionInput(
            requested: requested,
            pending: pending,
            unavailable: unavailable,
            onRequest: onRequest,
            onRetry: () {},
          ),
        );

    testWidgets('shows the button first; tap fires onRequest once',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(section(
        requested: false,
        pending: false,
        unavailable: false,
        onRequest: () => taps++,
      )));
      expect(find.text(guideBankStringsBn['viewExplanation']!), findsOneWidget);
      expect(find.text(guideBankStringsBn['explanationLoading']!), findsNothing);
      await tester.tap(find.text(guideBankStringsBn['viewExplanation']!));
      expect(taps, 1);
    });

    testWidgets('pending shows loading, never the button', (tester) async {
      await tester.pumpWidget(wrap(section(
        requested: true,
        pending: true,
        unavailable: false,
        onRequest: () {},
      )));
      expect(find.text(guideBankStringsBn['explanationLoading']!), findsOneWidget);
      expect(find.text(guideBankStringsBn['viewExplanation']!), findsNothing);
    });

    testWidgets('option-less MCQ shows the honest note, no button',
        (tester) async {
      await tester.pumpWidget(wrap(section(
        requested: false,
        pending: false,
        unavailable: true,
        onRequest: () {},
      )));
      expect(
        find.text(guideBankStringsBn['explanationUnavailableOptions']!),
        findsOneWidget,
      );
      expect(find.text(guideBankStringsBn['viewExplanation']!), findsNothing);
    });

    testWidgets('key-mismatch attempt shows the honest note, never blank',
        (tester) async {
      var retries = 0;
      await tester.pumpWidget(wrap(GuideExplanationSection(
        attempt: const StructuredAttempt(
            status: StructuredStatus.keyMismatch, storedKey: 'ii'),
        question: const GuideBankQuestion(
          id: 'fake-mcq-1',
          questionText: 'shriek',
          questionType: 'mcq',
        ),
        chips: const ['guide'],
        fontSize: 16,
        s: guideBankStringsBn,
        ls: const {},
        stepsOnly: false,
        explanation: ExplanationSectionInput(
          requested: true,
          pending: false,
          unavailable: false,
          onRequest: () {},
          onRetry: () => retries++,
        ),
      )));
      expect(
        find.text(guideBankStringsBn['explanationKeyMismatch']!),
        findsOneWidget,
      );
      await tester.tap(find.text(guideBankStringsBn['retry']!));
      expect(retries, 1);
    });
  });
}
