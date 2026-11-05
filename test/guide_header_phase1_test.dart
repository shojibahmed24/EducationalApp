// Phase 1 (2026-11-01): answer-header chapter line + flag note.
// Chapter 0 (English flow, no chapter step) renders NO chapter
// line; a real chapter still renders. A row's flag_note renders
// verbatim when present, nothing when absent. Model round-trips
// flagNote through toJson/fromJson/fromServerJson.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_question_header.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';

const _q = GuideBankQuestion(
  id: 't1',
  questionText: 'নকল প্রশ্ন?',
  questionType: 'problem',
);

Widget _header(GuideBankQuestion q, int chapter) => MaterialApp(
      home: Scaffold(
        body: GuideQuestionHeader(
          question: q,
          chapterNumber: chapter,
          fontSize: 16,
          s: guideBankStringsBn,
          color: Colors.black,
        ),
      ),
    );

void main() {
  group('GuideQuestionHeader chapter line', () {
    testWidgets('chapter 0 renders no chapter line', (tester) async {
      await tester.pumpWidget(_header(_q, 0));
      expect(find.textContaining('অধ্যায়'), findsNothing);
    });

    testWidgets('real chapter still renders', (tester) async {
      await tester.pumpWidget(_header(_q, 3));
      expect(find.text('অধ্যায় 3'), findsOneWidget);
    });
  });

  group('GuideQuestionHeader flag note', () {
    testWidgets('flag note renders verbatim when present',
        (tester) async {
      const noted = GuideBankQuestion(
        id: 't2',
        questionText: 'নকল প্রশ্ন?',
        questionType: 'problem',
        flagNote: 'ছাপার নোট',
      );
      await tester.pumpWidget(_header(noted, 2));
      expect(find.text('ছাপার নোট'), findsOneWidget);
    });

    testWidgets('no note renders when absent', (tester) async {
      await tester.pumpWidget(_header(_q, 2));
      expect(find.text('ছাপার নোট'), findsNothing);
    });
  });

  group('GuideBankQuestion flagNote round-trip', () {
    test('toJson/fromJson keeps flagNote', () {
      const q = GuideBankQuestion(
        id: 't3',
        questionText: 'নকল প্রশ্ন?',
        questionType: 'problem',
        flagNote: 'ছাপার নোট',
      );
      final back = GuideBankQuestion.fromJson(q.toJson());
      expect(back.flagNote, 'ছাপার নোট');
    });

    test('fromServerJson reads flagNote, absent means null', () {
      final withNote = GuideBankQuestion.fromServerJson({
        'id': 't4',
        'questionText': 'নকল প্রশ্ন?',
        'questionType': 'problem',
        'flagNote': 'ছাপার নোট',
      });
      expect(withNote.flagNote, 'ছাপার নোট');
      final withoutNote = GuideBankQuestion.fromServerJson({
        'id': 't5',
        'questionText': 'নকল প্রশ্ন?',
        'questionType': 'problem',
      });
      expect(withoutNote.flagNote, isNull);
    });
  });
}
