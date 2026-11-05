// Steps-by-default, summary==final guard, and user-stated
// marks parsing (chat_marks) + the 4-mark budget path.
// The service-side strict retry itself needs a network call, so
// it is covered here through its pure seam (summaryEqualsFinal)
// and the renderer-side duplicate skip, not a live AI call.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/solution_model.dart';
import 'package:yes_sir_ai/core/services/chat_marks.dart';
import 'package:yes_sir_ai/core/services/marks_budget.dart';
import 'package:yes_sir_ai/core/services/structured_parse.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_renderer.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';

const s = {
  'solutionSummary': 'সারাংশ',
  'showFullSolution': 'পুরো সমাধান দেখো',
  'showSummaryOnly': 'শুধু সারাংশ দেখো',
  'finalAnswer': 'চূড়ান্ত উত্তর',
  'marksWord': 'নম্বর',
  'whyCorrect': 'কেন সঠিক',
  'whyOthersWrong': 'কেন বাকিগুলো ভুল',
};

bool richContains(WidgetTester tester, String needle) =>
    tester.widgetList<RichText>(find.byType(RichText)).any(
          (w) => w.text.toPlainText().contains(needle),
        );

Widget renderer(StructuredSolution solution) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SolutionRenderer(
            solution: solution,
            sourceChips: const [],
            fontSize: 16,
            s: s,
            marksPrinted: false,
            isMcq: true,
          ),
        ),
      ),
    );

const stepped = StructuredSolution(
  summary: 'প্রথমে গ্রামকে কেজিতে রূপান্তর করি, তারপর মোট হিসাব করি।',
  steps: [
    SolutionStep(n: 1, title: 'রূপান্তর', text: '৪০০ গ্রাম = ০.৪ কেজি।'),
    SolutionStep(n: 2, title: 'মোট', text: 'দৈনিক মোট ২০.৪ কেজি।'),
  ],
  finalAnswer: 'মোট ৬১২ কেজি।',
);

const duplicate = StructuredSolution(
  summary: 'ত্রিভুজের তিনটি মধ্যমা এবং তিনটি উচ্চতা থাকে।',
  steps: [],
  finalAnswer: 'ত্রিভুজের তিনটি মধ্যমা এবং তিনটি উচ্চতা থাকে।',
);

void main() {
  group('summaryEqualsFinal guard', () {
    test('identical texts are duplicates', () {
      expect(
        summaryEqualsFinal(
          'ত্রিভুজের তিনটি মধ্যমা এবং তিনটি উচ্চতা থাকে।',
          'ত্রিভুজের তিনটি মধ্যমা এবং তিনটি উচ্চতা থাকে।',
        ),
        isTrue,
      );
    });
    test('Bangla-digit variant of the same text is a duplicate', () {
      expect(summaryEqualsFinal('উত্তর ৪০ কেজি।', 'উত্তর 40 কেজি'), isTrue);
      expect(summaryEqualsFinal('মোট ৬১২।', 'মোট 612'), isTrue);
    });
    test('trailing punctuation differences are ignored', () {
      expect(summaryEqualsFinal('উত্তর ৪০।', 'উত্তর 40'), isTrue);
    });
    test('different texts pass (not duplicates)', () {
      expect(
        summaryEqualsFinal('প্রথমে রূপান্তর করি।', 'মোট ৬১২ কেজি।'),
        isFalse,
      );
    });
    test('empty sides never count as duplicates', () {
      expect(summaryEqualsFinal('', ''), isFalse);
      expect(summaryEqualsFinal('কিছু লেখা।', ''), isFalse);
    });
  });

  group('parseUserMarks', () {
    test('Bangla patterns', () {
      expect(parseUserMarks('এর মার্ক ৪'), 4);
      expect(parseUserMarks('৪ মার্ক'), 4);
      expect(parseUserMarks('৪ নম্বর'), 4);
      expect(parseUserMarks('মার্ক ১০'), 10);
    });
    test('ASCII / Banglish patterns', () {
      expect(parseUserMarks('4 marks'), 4);
      expect(parseUserMarks('marks 3'), 3);
    });
    test('clamps to 1..10', () {
      expect(parseUserMarks('মার্ক ১২'), 10);
      expect(parseUserMarks('মার্ক ০'), 1);
    });
    test('no marks pattern returns null', () {
      expect(parseUserMarks('২০ কেজি চাল, প্রতিদিন ৪০০ গ্রাম'), isNull);
      expect(parseUserMarks('আমার ৫টি কলম আছে'), isNull);
      expect(parseUserMarks('ত্রিভুজের মধ্যমা কয়টি?'), isNull);
      expect(parseUserMarks(''), isNull);
    });
  });

  group('marks budget for user-stated 4 marks', () {
    test('parsed 4 feeds the existing 4-mark budget', () {
      final parsed = parseUserMarks('এর মার্ক ৪');
      final budget = marksBudgetFor(marks: parsed, questionType: 'textbook');
      expect(budget.marks, 4);
      expect(budget.maxSteps, 10);
      expect(budget.guidance, contains('closing check'));
    });
    test('direct 4-mark budget', () {
      final budget = marksBudgetFor(marks: 4, questionType: 'textbook');
      expect(budget.maxSteps, 10);
      expect(budget.guidance, contains('reasoning'));
    });
  });

  group('SolutionRenderer steps-by-default + duplicate skip', () {
    testWidgets('steps are expanded by default', (tester) async {
      await tester.pumpWidget(renderer(stepped));
      await tester.pump();
      expect(richContains(tester, '৪০০ গ্রাম = ০.৪ কেজি।'), isTrue);
      expect(richContains(tester, 'দৈনিক মোট ২০.৪ কেজি।'), isTrue);
    });

    testWidgets('toggle still collapses to summary-only', (tester) async {
      await tester.pumpWidget(renderer(stepped));
      await tester.pump();
      await tester.tap(find.text('শুধু সারাংশ দেখো'));
      await tester.pump();
      expect(richContains(tester, '৪০০ গ্রাম = ০.৪ কেজি।'), isFalse);
      expect(richContains(tester, 'প্রথমে গ্রামকে কেজিতে'), isTrue);
      expect(richContains(tester, 'মোট ৬১২ কেজি।'), isTrue);
      await tester.tap(find.text('পুরো সমাধান দেখো'));
      await tester.pump();
      expect(richContains(tester, '৪০০ গ্রাম = ০.৪ কেজি।'), isTrue);
    });

    testWidgets('duplicate summary card is skipped', (tester) async {
      await tester.pumpWidget(renderer(duplicate));
      await tester.pump();
      expect(find.text('সারাংশ'), findsNothing);
      expect(
        richContains(tester, 'ত্রিভুজের তিনটি মধ্যমা'),
        isTrue,
      );
    });

    testWidgets('distinct summary card still shows', (tester) async {
      await tester.pumpWidget(renderer(stepped));
      await tester.pump();
      expect(find.text('সারাংশ'), findsOneWidget);
    });

    testWidgets('step numbers use Bengali digits in the Bangla UI',
        (tester) async {
      languageNotifier.value = const Locale('bn');
      addTearDown(() => languageNotifier.value = const Locale('en'));
      await tester.pumpWidget(renderer(stepped));
      await tester.pump();
      expect(find.text('১'), findsOneWidget);
      expect(find.text('২'), findsOneWidget);
    });
  });
}
