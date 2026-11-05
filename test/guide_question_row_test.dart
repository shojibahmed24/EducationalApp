// Widget tests for Batch 2, item 3: the 'চাবি নেই' chip appears
// ONLY on MCQ rows without a key. Problem/creative rows have no
// key by design (AI-rewrite answers) and must show no key chip.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_question_row.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';

Widget rowFor(GuideBankQuestion q) => MaterialApp(
      home: Scaffold(
        body: GuideQuestionRow(
          question: q,
          locked: false,
          s: guideBankStringsBn,
          subjectId: 'math',
          chapterNumber: 2,
          onTap: () {},
        ),
      ),
    );

void main() {
  testWidgets('MCQ row without a key shows the key-missing chip',
      (tester) async {
    await tester.pumpWidget(rowFor(const GuideBankQuestion(
      id: 'q1',
      questionText: 'একটি MCQ প্রশ্ন',
      questionType: 'mcq',
    )));
    await tester.pump();
    expect(find.text('চাবি নেই'), findsOneWidget);
  });

  testWidgets('problem row without a key shows no key chip',
      (tester) async {
    await tester.pumpWidget(rowFor(const GuideBankQuestion(
      id: 'q2',
      questionText: 'একটি গাণিতিক সমস্যা',
      questionType: 'problem',
    )));
    await tester.pump();
    expect(find.text('চাবি নেই'), findsNothing);
  });

  testWidgets('creative row without a key shows no key chip',
      (tester) async {
    await tester.pumpWidget(rowFor(const GuideBankQuestion(
      id: 'q3',
      questionText: 'একটি সৃজনশীল প্রশ্ন',
      questionType: 'creative',
    )));
    await tester.pump();
    expect(find.text('চাবি নেই'), findsNothing);
  });

  testWidgets('MCQ row with a server key shows no key chip',
      (tester) async {
    await tester.pumpWidget(rowFor(const GuideBankQuestion(
      id: 'q4',
      questionText: 'একটি চাবিযুক্ত MCQ',
      questionType: 'mcq',
      serverHasKey: true,
    )));
    await tester.pump();
    expect(find.text('চাবি নেই'), findsNothing);
  });
}
