// Chat marks routing (items 5): marks-bearing messages take the
// structured path with the marks budget; marks-less messages
// keep the plain path. Pure helper level only — no live Edge,
// no widget harness; the structured service call itself is
// injected as a stub.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/models/solution_model.dart';
import 'package:yes_sir_ai/core/services/chat_marks.dart';
import 'package:yes_sir_ai/core/services/explanation_service.dart';
import 'package:yes_sir_ai/core/services/marks_budget.dart';
import 'package:yes_sir_ai/core/services/structured_explanation_service.dart';
import 'package:yes_sir_ai/features/learn/chat_structured_reply.dart';

StructuredSolution fixtureSolution() => const StructuredSolution(
  summary: 'Plan: add first.',
  steps: [
    SolutionStep(n: 1, title: 'Add', text: 'Add 2 and 3 to get 5.'),
    // sectionMarks 4 is budget input only: it must never
    // appear in the rendered chat text.
    SolutionStep(n: 2, title: '', text: 'Write 5.', sectionMarks: 4),
  ],
  finalAnswer: '5.',
);

const _plainStrings = {
  'demoReply': 'DEMO',
  'aiServerKeyMissing': 'KEY',
  'aiFailed': 'FAILED',
};

void main() {
  test('marks-bearing message takes the structured path', () {
    expect(useStructuredChatReply('এই প্রশ্নের মার্ক ৪, সমাধান দাও'), isTrue);
    expect(useStructuredChatReply('Solve this, marks 5 please'), isTrue);
    expect(parseUserMarks('এই প্রশ্নের মার্ক ৪, সমাধান দাও'), 4);
  });

  test('marks-less message keeps the plain path', () {
    expect(useStructuredChatReply('২ আর ৩ যোগ করলে কত?'), isFalse);
    expect(useStructuredChatReply('What is 4 + 5?'), isFalse);
    expect(useStructuredChatReply('Explain this question'), isFalse);
  });

  test('structured reply passes the parsed marks to the budget', () async {
    int? captured;
    final text = await structuredChatReply(
      grounding: const Grounding(reason: 'not-indexed'),
      bangla: true,
      userQuestion: 'এই প্রশ্নের মার্ক ৪, সমাধান দাও',
      structuredAttempt: (marks) async {
        captured = marks;
        return StructuredAttempt(
          status: StructuredStatus.ok,
          solution: fixtureSolution(),
        );
      },
    );
    expect(captured, 4);
    expect(text, structuredSolutionToChatText(fixtureSolution()));
    // The parsed marks feed the real budget bands in the service:
    // 4 marks allows far more steps than 1 mark.
    expect(marksBudgetFor(marks: 4, questionType: 'textbook').maxSteps, 10);
    expect(marksBudgetFor(marks: 1, questionType: 'textbook').maxSteps, 2);
    expect(marksBudgetFor(marks: 4, questionType: 'textbook').marks, 4);
  });

  test('marks-less message never calls the structured path', () async {
    final text = await structuredChatReply(
      grounding: const Grounding(reason: 'not-indexed'),
      bangla: true,
      userQuestion: '২ আর ৩ যোগ করলে কত?',
      structuredAttempt: (_) async {
        throw StateError('structured path must not run without marks');
      },
    );
    expect(text, isNull);
  });

  test('structured failure falls back to the plain path (null)', () async {
    final text = await structuredChatReply(
      grounding: const Grounding(reason: 'not-indexed'),
      bangla: true,
      userQuestion: 'মার্ক ৩ এর প্রশ্ন',
      structuredAttempt: (_) async =>
          const StructuredAttempt(status: StructuredStatus.failed),
    );
    expect(text, isNull);
  });

  test('solution renders as chat text without any printed marks', () {
    final text = structuredSolutionToChatText(fixtureSolution());
    expect(
      text,
      'Plan: add first.\n\n'
      '1. Add\nAdd 2 and 3 to get 5.\n\n'
      '2.\nWrite 5.\n\n'
      '5.',
    );
    expect(text, isNot(contains('মার্ক')));
    expect(text, isNot(contains('marks')));
  });

  test('duplicate summary is shown once, not as summary + final', () {
    final text = structuredSolutionToChatText(
      const StructuredSolution(
        summary: 'Same.',
        steps: [],
        finalAnswer: 'Same.',
      ),
    );
    expect(text, 'Same.');
  });

  test('attempt mapping: ok, keyMismatch, rawText, failed', () {
    expect(
      chatReplyFromStructuredAttempt(
        StructuredAttempt(
          status: StructuredStatus.ok,
          solution: fixtureSolution(),
        ),
      ),
      structuredSolutionToChatText(fixtureSolution()),
    );
    expect(
      chatReplyFromStructuredAttempt(
        const StructuredAttempt(
          status: StructuredStatus.keyMismatch,
          storedKey: 'খ',
        ),
      ),
      'খ',
    );
    expect(
      chatReplyFromStructuredAttempt(
        const StructuredAttempt(
          status: StructuredStatus.failed,
          rawText: 'prose fallback',
        ),
      ),
      'prose fallback',
    );
    expect(
      chatReplyFromStructuredAttempt(
        const StructuredAttempt(status: StructuredStatus.failed),
      ),
      isNull,
    );
  });

  test('plain-path outcome mapping is unchanged', () {
    expect(
      chatReplyFromPlainResult(
        const ExplanationResult(
          outcome: ExplanationOutcome.live,
          text: 'hello',
        ),
        _plainStrings,
      ),
      'hello',
    );
    expect(
      chatReplyFromPlainResult(
        const ExplanationResult(outcome: ExplanationOutcome.demo, text: 'd'),
        _plainStrings,
      ),
      'DEMO\nd',
    );
    expect(
      chatReplyFromPlainResult(
        const ExplanationResult(
          outcome: ExplanationOutcome.failed,
          serverKeyMissing: true,
        ),
        _plainStrings,
      ),
      'KEY',
    );
    expect(
      chatReplyFromPlainResult(
        const ExplanationResult(outcome: ExplanationOutcome.failed),
        _plainStrings,
      ),
      'FAILED',
    );
    expect(
      chatReplyFromPlainResult(
        const ExplanationResult(
          outcome: ExplanationOutcome.failed,
          context: GroundedContext(
            bookTitle: '',
            chapterTitle: '',
            subject: 'math',
            schoolClass: 6,
            chapterNumber: 3,
            page: 45,
            problem: 5,
            questionText: 'q',
            localAnswer: 'book text',
            source: 'local-index',
          ),
        ),
        _plainStrings,
      ),
      'book text',
    );
  });
}
