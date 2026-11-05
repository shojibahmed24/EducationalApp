// Script-garbage guard tests (2026-11-03): the model sometimes
// emits Bengali words as Latin gibberish, Arabic script, or
// accented Latin letters. Fixture strings are fake — never real
// guide content.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/solution_model.dart';
import 'package:yes_sir_ai/core/services/explanation_script_guard.dart';

void main() {
  test('clean Bangla + legitimate English passes', () {
    expect(
        explanationHasScriptGarbage(
            'প্যাসেজে বলা হয়েছে অনেক উৎসব পালন করা হয়, তাই celebrate শব্দটি উপযুক্ত।'),
        isFalse);
  });

  test('Arabic script is garbage', () {
    expect(
        explanationHasScriptGarbage('এই বাক্যে كلمة আরবি আছে'), isTrue);
  });

  test('accented Latin letter is garbage', () {
    expect(explanationHasScriptGarbage('তার বাবার মতো sindedžel'),
        isTrue);
  });

  test('mixed-script token is garbage', () {
    expect(explanationHasScriptGarbage('খালি সplace পূরণ'), isTrue);
  });

  test('Korean Hangul token is garbage', () {
    expect(explanationHasScriptGarbage('কিন্তু 그날 মেঘ জমেছিল'), isTrue);
  });

  test('Chinese token is garbage', () {
    expect(explanationHasScriptGarbage('সেদিন 天气 বদলে গেল'), isTrue);
  });

  test('Japanese kana token is garbage', () {
    expect(explanationHasScriptGarbage('সেদিন ひる মেঘ এলো'), isTrue);
  });

  test('standalone plain-Latin word still passes (prompt-only rule)', () {
    // A lone Latin word cannot be told apart from a legitimate
    // English guide term by code; the prompt's script rule is
    // the guard there. This test pins that boundary.
    expect(explanationHasScriptGarbage('উত্তর hailstorm হয়েছিল'), isFalse);
  });

  test('bullet inside a word is garbage', () {
    expect(explanationHasScriptGarbage('খালি steh•an পূরণের জন্য'),
        isTrue);
  });

  test('solution-level check covers steps and whyCorrect', () {
    const clean = StructuredSolution(
      summary: 'পরিকল্পনা',
      steps: [
        SolutionStep(n: 1, title: 'ধাপ', text: 'সাধারণ লেখা।'),
      ],
      finalAnswer: 'উত্তর',
      whyCorrect: 'Options missing',
    );
    expect(solutionHasScriptGarbage(clean), isFalse);
    const garbled = StructuredSolution(
      summary: 'পরিকল্পনা',
      steps: [
        SolutionStep(n: 1, title: 'ধাপ', text: 'তার মতো sindedžel'),
      ],
      finalAnswer: 'উত্তর',
    );
    expect(solutionHasScriptGarbage(garbled), isTrue);
  });
}
