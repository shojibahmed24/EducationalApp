import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Attempt round-trips wrongItems, old attempts default empty', () {
    final attempt = Attempt(
      kind: 'quiz',
      testId: 'quiz-math',
      subject: 'math',
      chapter: 'math',
      correct: 4,
      total: 5,
      seconds: 60,
      date: '2026-10-31',
      answers: {'class7-math-bn-guide-ch2-p44-ex21-mcq18': 0},
      wrongItems: [
        const QuizItem(
          id: 'class7-math-bn-guide-ch2-p44-ex21-mcq18',
          questionBn: 'গাইড প্রশ্ন',
          questionEn: 'Guide question',
          options: ['ক', 'খ'],
          correctIndex: 1,
        ),
      ],
    );
    final restored = Attempt.fromJson(
        attempt.toJson().map((k, v) => MapEntry(k.toString(), v)));
    expect(restored.wrongItems.length, 1);
    expect(restored.wrongItems.first.correctIndex, 1);
    final old = Attempt.fromJson({'answers': {}, 'correct': 0, 'total': 0});
    expect(old.wrongItems, isEmpty);
  });

  test('weak revision re-asks a persisted guide wrong item', () async {
    final attempt = Attempt(
      kind: 'quiz',
      testId: 'quiz-math',
      subject: 'math',
      chapter: 'math',
      correct: 4,
      total: 5,
      seconds: 60,
      date: '2026-10-31',
      answers: {'class7-math-bn-guide-ch3-p86-mcq26': 0},
      wrongItems: [
        const QuizItem(
          id: 'class7-math-bn-guide-ch3-p86-mcq26',
          questionBn: 'গাইড প্রশ্ন',
          questionEn: 'Guide question',
          options: ['ক', 'খ'],
          correctIndex: 1,
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'ys_attempts_json': jsonEncode([attempt.toJson()]),
    });
    final items = await practiceService.weakRevisionItems();
    expect(items.map((q) => q.id),
        contains('class7-math-bn-guide-ch3-p86-mcq26'));
    expect(items.first.correctIndex, 1);
  });
}
