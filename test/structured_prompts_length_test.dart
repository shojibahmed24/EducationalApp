// 2026-11-03 AI length rule: when the prompt carries a guide
// answer (worked solution), the explanation must run at least as
// long as that guide answer — same length or a little longer,
// never shorter — unless the student explicitly asks for a brief
// explanation. Fixture data is fake — never real guide content.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/marks_budget.dart';
import 'package:yes_sir_ai/core/services/structured_prompts.dart';

const _budget = MarksBudget(
  marks: 5,
  maxSteps: 5,
  maxLines: 20,
  guidance: 'Test budget.',
);

GroundedContext _ctx({String guideUnitText = ''}) => GroundedContext(
      bookTitle: 'English',
      chapterTitle: 'Unit 1',
      subject: 'english',
      schoolClass: 9,
      chapterNumber: 0,
      page: 0,
      problem: 0,
      questionText: 'Why is the sky blue?',
      source: 'guide',
      guideQuestionId: 'fake-q-1',
      questionType: 'short',
      guideUnitText: guideUnitText,
    );

void main() {
  test('system prompt carries the length rule and brief exception',
      () {
    final prompt = structuredSystemPrompt(true, _budget, false);
    expect(prompt, contains('LENGTH RULE'));
    expect(prompt, contains('never shorter'));
    expect(prompt, contains('short or brief explanation'));
    expect(prompt, contains('overrides the length rule'));
  });

  test('user prompt anchors the guide answer word count', () {
    // Ten words, counted on whitespace.
    const guide = 'one two three four five six seven eight nine ten';
    final prompt = structuredUserPrompt(_ctx(guideUnitText: guide), 'simple', null);
    expect(prompt, contains('Guide answer length: 10 words'));
    expect(prompt, contains('at least 10 words long'));
    expect(prompt, contains('never shorter'));
  });

  test('user prompt has no length anchor without a guide answer',
      () {
    final prompt = structuredUserPrompt(_ctx(), 'simple', null);
    expect(prompt, isNot(contains('Guide answer length')));
  });

  test('length anchor keeps the brief exception visible', () {
    const guide = 'alpha beta gamma delta';
    final prompt = structuredUserPrompt(
        _ctx(guideUnitText: guide), 'simple', 'ছোট করে বুঝিয়ে দাও');
    expect(prompt, contains('Guide answer length: 4 words'));
    expect(prompt, contains('brief explanation'));
    expect(prompt, contains('Student follow-up: ছোট করে বুঝিয়ে দাও'));
  });
}
