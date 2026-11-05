// Multi-key quiz wiring (Phase 2 gap plan): QuizItem accepts an
// accepted-indices set with a single-key fallback, its JSON
// round-trip preserves the set (old caches without the key still
// load), and result screens can list every accepted variant.
// resolveKeys itself is not unit-tested here: it calls the live
// Edge Mode G path, so the mapping it performs is pinned below
// through the same pool helpers it calls.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/guide_quiz_pool.dart';

QuizItem _item({List<int> accepted = const []}) => QuizItem(
      id: 'q1',
      questionBn: 'q',
      questionEn: 'q',
      options: const ['A', 'B', 'C', 'D'],
      correctIndex: 1,
      correctIndices: accepted,
    );

void main() {
  group('QuizItem.isCorrect', () {
    test('single-key item: only correctIndex is correct', () {
      final q = _item();
      expect(q.isCorrect(1), isTrue);
      expect(q.isCorrect(0), isFalse);
      expect(q.isCorrect(2), isFalse);
    });

    test('multi-key item: any accepted index is correct', () {
      final q = _item(accepted: [1, 3]);
      expect(q.isCorrect(1), isTrue);
      expect(q.isCorrect(3), isTrue);
      expect(q.isCorrect(0), isFalse);
      expect(q.isCorrect(2), isFalse);
    });

    test('empty accepted set always falls back to correctIndex', () {
      final q = _item(accepted: []);
      expect(q.correctIndices, isEmpty);
      expect(q.isCorrect(1), isTrue);
      expect(q.isCorrect(3), isFalse);
    });
  });

  group('QuizItem JSON round-trip', () {
    test('correctIndices survive toJson/fromJson', () {
      final q = _item(accepted: [0, 2]);
      final back = QuizItem.fromJson(q.toJson());
      expect(back.correctIndices, [0, 2]);
      expect(back.correctIndex, 1);
      expect(back.isCorrect(2), isTrue);
      expect(back.isCorrect(1), isFalse);
    });

    test('old JSON without correctIndices loads as single-key', () {
      final back = QuizItem.fromJson({
        'id': 'old',
        'questionBn': 'q',
        'questionEn': 'q',
        'options': ['A', 'B'],
        'correctIndex': 0,
      });
      expect(back.correctIndices, isEmpty);
      expect(back.isCorrect(0), isTrue);
      expect(back.isCorrect(1), isFalse);
    });

    test('non-numeric correctIndices entries are ignored', () {
      final back = QuizItem.fromJson({
        'id': 'x',
        'questionBn': 'q',
        'questionEn': 'q',
        'options': ['A', 'B', 'C'],
        'correctIndex': 0,
        'correctIndices': [2, 'nope', 1],
      });
      expect(back.correctIndices, [2, 1]);
    });
  });

  group('QuizItem.acceptedOptionTexts', () {
    test('single-key item yields exactly the correct option', () {
      expect(_item().acceptedOptionTexts, ['B']);
    });

    test('multi-key item yields every accepted text in order', () {
      expect(_item(accepted: [3, 1]).acceptedOptionTexts, ['D', 'B']);
    });

    test('out-of-range indices are filtered, never crash', () {
      expect(_item(accepted: [1, 9]).acceptedOptionTexts, ['B']);
    });
  });

  group('resolveKeys mapping contract', () {
    test('JSON-list key maps to every accepted option index', () {
      const options = ['have', 'enjoy', 'go', 'play'];
      final accepted = acceptedOptionIndices(
          parseAcceptedAnswerKeys('["have", "enjoy"]'), options);
      expect(accepted, [0, 1]);
      final item = QuizItem(
          id: 'mk',
          questionBn: 'q',
          questionEn: 'q',
          options: options,
          correctIndex: accepted.first,
          correctIndices: accepted);
      expect(item.isCorrect(0), isTrue);
      expect(item.isCorrect(1), isTrue);
      expect(item.isCorrect(2), isFalse);
    });

    test('single letter key maps to exactly one index, as before', () {
      const options = ['A', 'B', 'C', 'D'];
      final accepted =
          acceptedOptionIndices(parseAcceptedAnswerKeys('খ'), options);
      expect(accepted, [1]);
    });

    test('unmappable key maps to nothing (resolveKeys drops it)', () {
      const options = ['A', 'B', 'C', 'D'];
      expect(
          acceptedOptionIndices(
              parseAcceptedAnswerKeys('a full sentence key'), options),
          isEmpty);
    });
  });
}
