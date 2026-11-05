// Key-gate tests (2026-11-03): matching is option-level,
// never raw-string. Stored keys are roman ('ii'); the screen
// shows Bengali letters, and the model may answer with either
// label system or the option text. No Edge, no I/O.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/solution_model.dart';

const _options = ['Painting', 'Photography', 'Chess', 'Yoga'];

StructuredSolution sol({String? claim, String finalAnswer = ''}) =>
    StructuredSolution(
        summary: 'plan', steps: const [], finalAnswer: finalAnswer,
        correctOption: claim);

void main() {
  test('stored roman ii matches Bengali label খ', () {
    expect(solutionMatchesKey(sol(claim: 'খ'), 'ii', _options), isTrue);
  });
  test('stored roman ii matches option text', () {
    expect(solutionMatchesKey(sol(claim: 'Photography'), 'ii', _options),
        isTrue);
  });
  test('stored roman ii matches label-led phrase', () {
    expect(
        solutionMatchesKey(sol(claim: 'খ. Photography'), 'ii', _options),
        isTrue);
    expect(solutionMatchesKey(sol(claim: 'খ (ii)'), 'ii', _options), isTrue);
    expect(solutionMatchesKey(sol(claim: 'Option ii'), 'ii', _options),
        isTrue);
  });
  test('stored roman ii matches Latin label B', () {
    expect(solutionMatchesKey(sol(claim: 'B'), 'ii', _options), isTrue);
    expect(solutionMatchesKey(sol(claim: 'B'), 'i', _options), isFalse);
  });
  test('different option is still a mismatch', () {
    expect(solutionMatchesKey(sol(claim: 'গ'), 'ii', _options), isFalse);
    expect(
        solutionMatchesKey(sol(claim: 'Chess'), 'ii', _options), isFalse);
  });
  test('sentence claim naming the option matches', () {
    expect(
        solutionMatchesKey(
            sol(claim: 'The correct option is খ (ii)'), 'ii', _options),
        isTrue);
  });
  test('finalAnswer fallback when correctOption is empty', () {
    expect(
        solutionMatchesKey(
            sol(finalAnswer: 'Photography is the skill not learnt yet.'),
            'ii',
            _options),
        isTrue);
    expect(
        solutionMatchesKey(
            sol(finalAnswer: 'She learnt everything.'), 'ii', _options),
        isFalse);
  });
  test('stored key as option text or number also maps', () {
    expect(solutionMatchesKey(sol(claim: 'খ'), 'Photography', _options),
        isTrue);
    expect(solutionMatchesKey(sol(claim: 'খ'), '2', _options), isTrue);
  });
  test('no options keeps the old exact-string gate', () {
    expect(solutionMatchesKey(sol(claim: 'খ'), 'খ', const []), isTrue);
    expect(solutionMatchesKey(sol(), 'খ', const []), isFalse);
  });
}
