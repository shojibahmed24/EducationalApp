// Attribution must come from the Edge response, never from
// the selected provider. These tests pin the honest
// defaults: no provider/model reported => 'unknown', and
// the label shows the unknown sentence, not a guessed name.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/solution_model.dart';
import 'package:yes_sir_ai/core/services/explanation_service.dart';
import 'package:yes_sir_ai/core/services/openrouter_client.dart';
import 'package:yes_sir_ai/features/learn/widgets/ai_attribution_label.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  test('GenResult defaults to unknown attribution', () {
    const r = GenResult();
    expect(r.provider, 'unknown');
    expect(r.model, isNull);
  });

  test('ExplanationResult defaults to unknown attribution', () {
    const r = ExplanationResult(outcome: ExplanationOutcome.failed);
    expect(r.aiProvider, 'unknown');
    expect(r.aiModel, isNull);
  });

  test('StructuredAttempt defaults to unknown attribution', () {
    const a = StructuredAttempt(status: StructuredStatus.failed);
    expect(a.aiProvider, 'unknown');
    expect(a.aiModel, isNull);
  });

  testWidgets('label shows Gemini + model', (t) async {
    await t.pumpWidget(_wrap(const AiAttributionLabel(
      provider: 'gemini',
      model: 'gemini-3.8-flash',
      unknownText: 'AI: unknown',
    )));
    expect(find.text('AI: Gemini • gemini-3.8-flash'), findsOneWidget);
  });

  testWidgets('label shows OpenRouter + model', (t) async {
    await t.pumpWidget(_wrap(const AiAttributionLabel(
      provider: 'openrouter',
      model: 'nvidia/nemotron-3-ultra-550b-a55b:free',
      unknownText: 'AI: unknown',
    )));
    expect(
      find.text('AI: OpenRouter • nvidia/nemotron-3-ultra-550b-a55b:free'),
      findsOneWidget,
    );
  });

  testWidgets('unknown provider shows unknown text, never a guess',
      (t) async {
    await t.pumpWidget(_wrap(const AiAttributionLabel(
      provider: 'unknown',
      model: null,
      unknownText: 'AI: unknown — server not updated',
    )));
    expect(find.text('AI: unknown — server not updated'), findsOneWidget);
    expect(find.textContaining('Gemini'), findsNothing);
  });
}
