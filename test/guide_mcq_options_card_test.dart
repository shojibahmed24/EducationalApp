// MCQ try-first options card (2026-11-01): options render,
// the first tap locks the pick and reports the attempt, and
// display-only mode (null key) never offers feedback.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_mcq_options_card.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';

Widget wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('tap wrong option shows wrong feedback and reports once',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(wrap(GuideMcqOptionsCard(
      options: const ['2', '4', '6', '8'],
      correctOptionIndex: 1,
      fontSize: 16,
      s: guideBankStringsBn,
      onAttempted: () => attempts++,
    )));
    expect(find.text('একটি অপশন বাছো — তারপর সঠিক উত্তর দেখা যাবে'),
        findsOneWidget);
    await tester.tap(find.text('2', findRichText: true));
    await tester.pump();
    expect(attempts, 1);
    expect(find.text('ভুল হয়েছে — সঠিক উত্তরটি দেখো'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    // Second tap locks: no second attempt, no state change.
    await tester.tap(find.text('6', findRichText: true));
    await tester.pump();
    expect(attempts, 1);
  });

  testWidgets('tap correct option shows correct feedback',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(wrap(GuideMcqOptionsCard(
      options: const ['2', '4', '6', '8'],
      correctOptionIndex: 1,
      fontSize: 16,
      s: guideBankStringsBn,
      onAttempted: () => attempts++,
    )));
    await tester.tap(find.text('4', findRichText: true));
    await tester.pump();
    expect(attempts, 1);
    expect(find.text('ঠিক উত্তর!'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsNothing);
  });

  testWidgets('display-only mode shows options without pick or feedback',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(wrap(GuideMcqOptionsCard(
      options: const ['2', '4', '6', '8'],
      correctOptionIndex: null,
      fontSize: 16,
      s: guideBankStringsBn,
      onAttempted: () => attempts++,
    )));
    expect(find.text('2', findRichText: true), findsOneWidget);
    expect(find.text('একটি অপশন বাছো — তারপর সঠিক উত্তর দেখা যাবে'),
        findsNothing);
    await tester.tap(find.text('2', findRichText: true));
    await tester.pump();
    expect(attempts, 0);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
