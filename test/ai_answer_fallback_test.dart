// AI-first fallback (2026-10-31): when a guide question has no
// trusted verbatim text, the first card must be an AI answer
// card — clearly labelled AI, never labelled as the guide's
// answer. Guide answers keep their own label and first place.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/widgets/verbatim_answer_card.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';

Widget _card({
  required String kind,
  required bool guideError,
}) {
  return MaterialApp(
    home: Scaffold(
      body: VerbatimAnswerCard(
        kind: kind,
        text: kind == 'guide' ? 'গাইডের সমাধান' : '',
        correctionNote: '',
        guideError: guideError,
        fontSize: 16,
        s: guideBankStringsBn,
        explanationShown: true,
        onExplainDetailed: () {},
        onExplainSteps: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('none without error shows AI answer card, never guide label',
      (tester) async {
    await tester.pumpWidget(_card(kind: 'none', guideError: false));
    expect(find.text('AI ব্যাখ্যা (গাইডে ছাপা নেই)'), findsOneWidget);
    expect(find.textContaining('AI লিখেছে'), findsOneWidget);
    expect(find.textContaining('গাইডের লেখা নয়'), findsOneWidget);
    expect(find.text('গাইডের উত্তর'), findsNothing);
  });

  testWidgets('none with guide error shows AI card plus error note',
      (tester) async {
    await tester.pumpWidget(_card(kind: 'none', guideError: true));
    expect(find.text('AI ব্যাখ্যা (গাইডে ছাপা নেই)'), findsOneWidget);
    expect(find.textContaining('ভুল প্রমাণিত'), findsOneWidget);
    expect(find.text('গাইডের উত্তর'), findsNothing);
  });

  testWidgets('guide kind keeps guide label, never AI label',
      (tester) async {
    await tester.pumpWidget(_card(kind: 'guide', guideError: false));
    expect(find.text('গাইডের উত্তর'), findsOneWidget);
    expect(find.text('AI ব্যাখ্যা (গাইডে ছাপা নেই)'), findsNothing);
  });
}
