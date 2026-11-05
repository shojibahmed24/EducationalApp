// Tests for the SolutionRenderer source toggle: question view
// shows ONLY the verbatim question, explanation view shows the
// summary/final answer, and switching is a local state change
// (no network call is made by the widget itself).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/solution_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_renderer.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

const s = {
  'solutionSummary': 'সারাংশ',
  'showFullSolution': 'পুরো সমাধান দেখো',
  'showSummaryOnly': 'শুধু সারাংশ দেখো',
  'finalAnswer': 'চূড়ান্ত উত্তর',
  'marksWord': 'নম্বর',
  'whyCorrect': 'কেন সঠিক',
  'whyOthersWrong': 'কেন বাকিগুলো ভুল',
};

const solution = StructuredSolution(
  summary: 'সারাংশের লেখা এখানে।',
  steps: [],
  finalAnswer: 'চূড়ান্ত উত্তরের লেখা এখানে।',
);

Widget renderer() => const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SolutionRenderer(
            solution: solution,
            sourceChips: ['বইয়ের প্রশ্ন (হুবহু)', 'AI ব্যাখ্যা (বইয়ের ভিত্তিতে)'],
            fontSize: 16,
            s: s,
            marksPrinted: false,
            isMcq: true,
            questionText: 'মূল প্রশ্নের লেখা এখানে।',
            questionLabel: 'বইয়ের প্রশ্ন (হুবহু)',
            explanationLabel: 'AI ব্যাখ্যা (বইয়ের ভিত্তিতে)',
          ),
        ),
      ),
    );

// Summary/final answers render as RichText, not Text widgets,
// so assertions must read RichText plain text.
bool richContains(WidgetTester tester, String needle) =>
    tester.widgetList<RichText>(find.byType(RichText)).any(
          (w) => w.text.toPlainText().contains(needle),
        );

void main() {
  testWidgets('explanation shown by default, question hidden',
      (tester) async {
    await tester.pumpWidget(renderer());
    await tester.pump();
    expect(richContains(tester, 'সারাংশের লেখা এখানে।'), isTrue);
    expect(richContains(tester, 'চূড়ান্ত উত্তরের লেখা এখানে।'), isTrue);
    expect(find.text('মূল প্রশ্নের লেখা এখানে।', findRichText: true), findsNothing);
  });

  testWidgets('tapping question shows only the question, back restores',
      (tester) async {
    await tester.pumpWidget(renderer());
    await tester.pump();
    await tester.tap(find.text('বইয়ের প্রশ্ন (হুবহু)').first);
    await tester.pump();
    expect(find.text('মূল প্রশ্নের লেখা এখানে।', findRichText: true), findsOneWidget);
    expect(richContains(tester, 'সারাংশের লেখা এখানে।'), isFalse);
    expect(richContains(tester, 'চূড়ান্ত উত্তরের লেখা এখানে।'), isFalse);
    await tester.tap(find.text('AI ব্যাখ্যা (বইয়ের ভিত্তিতে)').first);
    await tester.pump();
    expect(richContains(tester, 'সারাংশের লেখা এখানে।'), isTrue);
    expect(find.text('মূল প্রশ্নের লেখা এখানে।', findRichText: true), findsNothing);
  });

  testWidgets('no toggle when question text is absent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SolutionRenderer(
              solution: solution,
              sourceChips: [],
              fontSize: 16,
              s: s,
              marksPrinted: false,
              isMcq: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ChoiceChip), findsNothing);
    expect(richContains(tester, 'সারাংশের লেখা এখানে।'), isTrue);
  });

  testWidgets('final-answer body carries heroTintOn', (tester) async {
    await tester.pumpWidget(renderer());
    await tester.pump();
    final rich = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((w) => w.text.toPlainText())
        .toList();
    final idx =
        rich.indexWhere((t) => t.contains('চূড়ান্ত উত্তরের লেখা'));
    expect(idx, isNot(-1));
    final widget =
        tester.widgetList<RichText>(find.byType(RichText)).elementAt(idx);
    expect(widget.text.style!.color, AppTheme.heroTintOn);
  });
}
