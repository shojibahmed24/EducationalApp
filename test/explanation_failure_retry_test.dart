// 2026-11-01 explanation-failure diagnosis (worker A): live probes
// showed long Bengali structured output never completing on the
// slow free model (tiny prompt: 200 in 9.7s/24.6s, parses; long
// prompt: connection dropped at ~54s twice; medium: dropped at
// ~151s with no response), while the screen's 45s timeout made
// any slow call a guaranteed "ব্যাখ্যা তৈরি করা যায়নি". The fix
// retries a failed attempt with a trimmed prompt + halved budget
// and salvages complete steps out of truncated JSON as prose.
// These unit tests pin the two pure functions behind that fix;
// no network is involved (the GEN transport itself is probed
// live, not in unit tests).
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/structured_parse.dart';
import 'package:yes_sir_ai/core/services/structured_prompts.dart';

GroundedContext ctxWith({
  String guideUnitText = '',
  List<String> chunks = const [],
}) =>
    GroundedContext(
      bookTitle: 'গণিত',
      chapterTitle: 'সেট',
      subject: 'math',
      schoolClass: 9,
      chapterNumber: 1,
      page: 0,
      problem: 0,
      questionText: 'A ∪ B নির্ণয় কর।',
      source: 'guide',
      chunkTexts: chunks,
      guideUnitText: guideUnitText,
    );

void main() {
  test('salvage keeps complete steps from truncated JSON', () {
    const truncated = '{"summary": "পরিকল্পনা", "steps": ['
        '{"n": 1, "title": "সংযোগ", "text": "সব উপাদান একবার করে নিই।"}, '
        '{"n": 2, "title": "ছেদ", "text": "শুধু সাধারণ উপাদান নিই।"}, '
        '{"n": 3, "title": "যাচাই", "text": "অসমাপ্ত ধাপ';
    final salvaged = salvageTruncatedJsonText(truncated);
    expect(salvaged, contains('1. সব উপাদান একবার করে নিই।'));
    expect(salvaged, contains('2. শুধু সাধারণ উপাদান নিই।'));
    expect(salvaged, isNot(contains('{')));
    expect(salvaged, isNot(contains('অসমাপ্ত ধাপ')));
  });

  test('salvage returns empty when no complete step text exists', () {
    expect(salvageTruncatedJsonText('{"summary": "x", "steps": ['),
        isEmpty);
    expect(salvageTruncatedJsonText('সাধারণ গদ্য, JSON নয়'), isEmpty);
  });

  test('trimmed prompt caps guide unit and keeps only first chunk', () {
    final longUnit = 'ক' * 3000;
    final ctx = ctxWith(
      guideUnitText: longUnit,
      chunks: ['খ' * 2000, 'গ' * 2000, 'ঘ' * 2000],
    );
    final full = structuredUserPrompt(ctx, 'steps', null);
    final trimmed = structuredUserPrompt(ctx, 'steps', null, trimmed: true);
    expect(full, contains(longUnit));
    expect(trimmed, isNot(contains(longUnit)));
    expect(trimmed.length, lessThan(full.length));
    // First chunk present (capped), later chunks dropped.
    expect(trimmed, contains('খ' * 800));
    expect(trimmed, isNot(contains('গ' * 2000)));
    expect(trimmed, isNot(contains('ঘ' * 2000)));
    // Question + style still present: trimming never drops them.
    expect(trimmed, contains('A ∪ B নির্ণয় কর।'));
    expect(trimmed, contains('Style: steps.'));
  });

  test('untrimmed prompt is unchanged (full grounding first)', () {
    final ctx = ctxWith(
      guideUnitText: 'সম্পূর্ণ সমাধান',
      chunks: ['অধ্যায়ের পাঠ ১', 'অধ্যায়ের পাঠ ২'],
    );
    final prompt = structuredUserPrompt(ctx, 'steps', null);
    expect(prompt, contains('সম্পূর্ণ সমাধান'));
    expect(prompt, contains('অধ্যায়ের পাঠ ১'));
    expect(prompt, contains('অধ্যায়ের পাঠ ২'));
  });
}
