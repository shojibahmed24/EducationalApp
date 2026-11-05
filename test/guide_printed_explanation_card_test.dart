// Printed explanation card (migration 017, 2026-11-02): the
// guide's own explanation paragraph renders under its own
// label, verbatim. Test strings here are invented for the
// test only — no guide content is copied.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_printed_explanation_card.dart';
import 'package:yes_sir_ai/l10n/pages/lesson_strings.dart';

Widget wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the printed-explanation label and body',
      (tester) async {
    await tester.pumpWidget(wrap(GuidePrintedExplanationCard(
      explanation: 'এটি একটি পরীক্ষামূলক ব্যাখ্যা',
      fontSize: 16,
      ls: lessonStringsBn,
    )));
    expect(find.text('গাইডের ব্যাখ্যা'), findsOneWidget);
    expect(find.byType(GuidePrintedExplanationCard), findsOneWidget);
    expect(
        find.text('এটি একটি পরীক্ষামূলক ব্যাখ্যা',
            findRichText: true),
        findsOneWidget);
  });

  testWidgets('renders with the English label map', (tester) async {
    await tester.pumpWidget(wrap(GuidePrintedExplanationCard(
      explanation: 'A test explanation paragraph',
      fontSize: 16,
      ls: lessonStringsEn,
    )));
    expect(find.text('Guide explanation'), findsOneWidget);
    expect(
        find.text('A test explanation paragraph',
            findRichText: true),
        findsOneWidget);
  });
}
