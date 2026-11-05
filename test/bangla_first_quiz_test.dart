// Quiz card tests: printed question + guide answer below it.
// Fake loaders stand in for Mode G; the card never hides the
// question, whatever the loader returns (answer / missing /
// error / still loading).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/bangla_first_quiz_card.dart';
import 'package:yes_sir_ai/l10n/pages/bangla_first_strings.dart';

GuideBankQuestion q(String id) => GuideBankQuestion(
    id: id, questionText: 'quiz q $id', questionType: 'quiz');

Widget card(QuizAnswerLoader loader) => MaterialApp(
      home: Scaffold(
        body: BanglaFirstQuizCard(
          q: q('1'),
          loader: loader,
          bn: true,
          s: banglaFirstStringsBn,
        ),
      ),
    );

void main() {
  testWidgets('verbatim answer shows below the question', (t) async {
    await t.pumpWidget(
        card((_, __) async => const QuizAnswer(text: 'উত্তর লেখা')));
    await t.pumpAndSettle();
    expect(find.text('quiz q 1'), findsOneWidget);
    expect(find.text(banglaFirstStringsBn['quizAnswer']!), findsOneWidget);
    expect(find.text('উত্তর লেখা'), findsOneWidget);
  });

  testWidgets('pending load shows a spinner, question stays', (t) async {
    final gate = Completer<QuizAnswer>();
    await t.pumpWidget(card((_, __) => gate.future));
    await t.pump();
    expect(find.text('quiz q 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete(const QuizAnswer(text: 'উত্তর লেখা'));
    await t.pumpAndSettle();
    expect(find.text('উত্তর লেখা'), findsOneWidget);
  });

  testWidgets('no verbatim shows missing note + retry, then reloads',
      (t) async {
    var calls = 0;
    await t.pumpWidget(card((_, __) async {
      calls++;
      return const QuizAnswer(text: null);
    }));
    await t.pumpAndSettle();
    expect(find.text('quiz q 1'), findsOneWidget);
    expect(find.text(banglaFirstStringsBn['quizNoAnswer']!), findsOneWidget);
    await t.tap(find.text(banglaFirstStringsBn['retry']!));
    await t.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('loader error shows retry, question stays', (t) async {
    await t.pumpWidget(card((_, __) async => throw Exception('boom')));
    await t.pumpAndSettle();
    expect(find.text('quiz q 1'), findsOneWidget);
    expect(find.text(banglaFirstStringsBn['retry']!), findsOneWidget);
  });
}
