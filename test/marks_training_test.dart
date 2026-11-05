// Marks training spec (MARKS_ANSWER_TRAINING_PLAN §4, implemented
// 2026-10-31): caps stay locked, guidance carries the full shape
// spec, and the MCQ rule appends only for MCQs. The Edge
// marksBudget mirror is verified by phrase diff at change time;
// these tests pin the Dart side so a drift is caught here.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/marks_budget.dart';
import 'package:yes_sir_ai/core/services/structured_prompts.dart';

void main() {
  test('caps are unchanged for every band', () {
    expect(marksBudgetFor(marks: 1, questionType: 'short').maxSteps, 2);
    expect(marksBudgetFor(marks: 1, questionType: 'short').maxLines, 4);
    expect(marksBudgetFor(marks: 2, questionType: 'short').maxSteps, 4);
    expect(marksBudgetFor(marks: 2, questionType: 'short').maxLines, 10);
    expect(marksBudgetFor(marks: 3, questionType: 'short').maxSteps, 7);
    expect(marksBudgetFor(marks: 3, questionType: 'short').maxLines, 18);
    expect(marksBudgetFor(marks: 4, questionType: 'short').maxSteps, 10);
    expect(marksBudgetFor(marks: 4, questionType: 'short').maxLines, 28);
    expect(marksBudgetFor(marks: 5, questionType: 'short').maxSteps, 14);
    expect(marksBudgetFor(marks: 5, questionType: 'short').maxLines, 45);
    expect(marksBudgetFor(marks: 10, questionType: 'short').maxSteps, 14);
  });

  test('1-mark guidance: direct answer, no preamble, no method', () {
    final g = marksBudgetFor(marks: 1, questionType: 'short').guidance;
    expect(g, contains('direct answer first'));
    expect(g, contains('No preamble'));
    expect(g, contains('no alternative method'));
    expect(g, contains('20-40'));
  });

  test('2-mark guidance: steps with reasons, no padding split', () {
    final g = marksBudgetFor(marks: 2, questionType: 'short').guidance;
    expect(g, contains('2-4 steps or points'));
    expect(g, contains('one short reason'));
    expect(g, contains('never split'));
    expect(g, contains('40-80'));
  });

  test('3-mark guidance: formula, substitute, reasoned steps', () {
    final g = marksBudgetFor(marks: 3, questionType: 'short').guidance;
    expect(g, contains('substitute'));
    expect(g, contains('brief reason for each step'));
    expect(g, contains('80-150'));
  });

  test('4-mark guidance: verification line is mandatory', () {
    final g = marksBudgetFor(marks: 4, questionType: 'creative').guidance;
    expect(g, contains('VERIFICATION'));
    expect(g, contains('never end abruptly'));
    expect(g, contains('separately'));
    expect(g, contains('150-250'));
  });

  test('5+ guidance: 3-4 line intro and conclusion, no padding', () {
    final g = marksBudgetFor(marks: 5, questionType: 'creative').guidance;
    expect(g, contains('3-4 line intro'));
    expect(g, contains('3-4 line conclusion'));
    expect(g, isNot(contains('one-line intro')));
    expect(g, isNot(contains('one-line conclusion')));
    expect(g, contains('never padding'));
    expect(g, contains('250-400'));
  });

  test('MCQ appends only for MCQs', () {
    final mcq = marksBudgetFor(marks: 1, questionType: 'mcq').guidance;
    expect(mcq, contains('correct option'));
    expect(mcq, contains('memorize'));
    final short = marksBudgetFor(marks: 1, questionType: 'short').guidance;
    expect(short, isNot(contains('correct option')));
    expect(short, isNot(contains('memorize')));
  });

  test('type defaults are unchanged', () {
    expect(marksBudgetFor(questionType: 'mcq').marks, 1);
    expect(marksBudgetFor(questionType: 'short').marks, 2);
    expect(
      marksBudgetFor(questionType: 'creative', sectionLabel: 'ঘ').marks,
      4,
    );
    expect(marksBudgetFor(questionType: 'other').marks, 3);
  });

  test('structured prompt carries steps AND lines budget', () {
    final budget = marksBudgetFor(marks: 4, questionType: 'creative');
    final prompt = structuredSystemPrompt(true, budget, false);
    expect(prompt, contains('At most 10 steps and 28 lines'));
    expect(prompt, contains('VERIFICATION'));
    expect(prompt, contains('step count and shape are the real control'));
  });

  test('retry rule is unchanged', () {
    final b4 = marksBudgetFor(marks: 4, questionType: 'short');
    expect(stepsFarOffBudget(13, b4), isTrue);
    expect(stepsFarOffBudget(4, b4), isTrue);
    expect(stepsFarOffBudget(9, b4), isFalse);
  });
}
