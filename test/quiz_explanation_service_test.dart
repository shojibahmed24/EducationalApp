// Phase 2 quiz explanation (pure, offline): bank-id detection
// and the option-wise prompt builder. The live Mode G path
// needs the Edge and is covered by the phone checklist, not
// by unit tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/quiz_explanation_service.dart';

QuizItem _item() => const QuizItem(
      id: 'pilot3-mcq_bank-015',
      questionBn: 'q',
      questionEn: 'q',
      options: ['১৫', '২০', '২৪', '২৫'],
      correctIndex: 2,
    );

void main() {
  group('isBankQuizId', () {
    test('bank prefixes are bank ids', () {
      for (final id in ['mq1', 'mm6', 'mp2', 'sq1', 'sm8', 'sp1']) {
        expect(isBankQuizId(id), isTrue, reason: id);
      }
    });
    test('guide ids are not bank ids', () {
      expect(isBankQuizId('pilot3-mcq_bank-015'), isFalse);
      expect(isBankQuizId('class7-math-bn-guide-ch2-p44-ex21-mcq18'),
          isFalse);
      expect(isBankQuizId(''), isFalse);
    });
  });

  group('optionWiseInstruction', () {
    test('bangla names every option + the verified key + LaTeX', () {
      final text = optionWiseInstruction(
          item: _item(), correctLetter: 'গ', bangla: true);
      expect(text, contains('ক) ১৫'));
      expect(text, contains('খ) ২০'));
      expect(text, contains('গ) ২৪'));
      expect(text, contains('ঘ) ২৫'));
      expect(text, contains('সঠিক উত্তর: গ'));
      expect(text, contains(r'$...$'));
      expect(text, contains(r'\frac{}{}'));
    });
    test('english names every option + the verified key + LaTeX', () {
      final text = optionWiseInstruction(
          item: _item(), correctLetter: 'C', bangla: false);
      expect(text, contains('A) ১৫'));
      expect(text, contains('B) ২০'));
      expect(text, contains('C) ২৪'));
      expect(text, contains('D) ২৫'));
      expect(text, contains('Correct answer: C'));
      expect(text, contains(r'$...$'));
    });
  });
}
