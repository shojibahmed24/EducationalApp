// Step 3+5 pure-logic tests: type -> section mapping, textbook
// type matching, question-number normalisation, lesson-step
// skipping, verified chapter titles.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

void main() {
  test('guide section mapping covers exactly the 5 options', () {
    expect(searchFlowGuideSection(SearchFlowType.mcq), 'mcq_bank');
    expect(searchFlowGuideSection(SearchFlowType.short), 'short');
    expect(searchFlowGuideSection(SearchFlowType.creative), 'creative');
    expect(
      searchFlowGuideSection(SearchFlowType.practiceWork),
      'practice_work',
    );
    expect(
      searchFlowGuideSection(SearchFlowType.textbookExercise),
      'textbook_exercise',
    );
    expect(SearchFlowType.values.length, 5);
  });

  test('old-server legacy questionType exists only for mcq/short/creative', () {
    expect(searchFlowLegacyQuestionType(SearchFlowType.mcq), 'mcq');
    expect(searchFlowLegacyQuestionType(SearchFlowType.short), 'short');
    expect(searchFlowLegacyQuestionType(SearchFlowType.creative), 'creative');
    expect(searchFlowLegacyQuestionType(SearchFlowType.practiceWork), isNull);
    expect(
      searchFlowLegacyQuestionType(SearchFlowType.textbookExercise),
      isNull,
    );
  });

  test('textbook matching: named types exact, exercise is the rest', () {
    expect(searchFlowTextbookMatches(SearchFlowType.mcq, 'mcq'), isTrue);
    expect(searchFlowTextbookMatches(SearchFlowType.mcq, 'short'), isFalse);
    expect(searchFlowTextbookMatches(SearchFlowType.short, 'short'), isTrue);
    expect(
      searchFlowTextbookMatches(SearchFlowType.creative, 'creative'),
      isTrue,
    );
    // Practice work is 'task' only — boxed_kaj is NOT folded in.
    expect(
      searchFlowTextbookMatches(SearchFlowType.practiceWork, 'task'),
      isTrue,
    );
    expect(
      searchFlowTextbookMatches(SearchFlowType.practiceWork, 'boxed_kaj'),
      isFalse,
    );
    // Textbook exercise = everything the other four do not cover.
    for (final v in [
      'problem',
      'fill_blank',
      'descriptive',
      'boxed_kaj',
      'other',
      'exercise',
      null,
    ]) {
      expect(
        searchFlowTextbookMatches(SearchFlowType.textbookExercise, v),
        isTrue,
        reason: 'exercise should include $v',
      );
    }
    for (final v in ['mcq', 'short', 'creative', 'task']) {
      expect(
        searchFlowTextbookMatches(SearchFlowType.textbookExercise, v),
        isFalse,
        reason: 'exercise must exclude $v',
      );
    }
  });

  test('question-number normalisation: Latin + Bangla digits', () {
    expect(normalizeQuestionNumber('5'), 5);
    expect(normalizeQuestionNumber('৫'), 5);
    expect(normalizeQuestionNumber('১২'), 12);
    expect(normalizeQuestionNumber(' ৭ '), 7);
    expect(normalizeQuestionNumber(''), isNull);
    expect(normalizeQuestionNumber('0'), isNull);
    expect(normalizeQuestionNumber('০'), isNull);
    expect(normalizeQuestionNumber('abc'), isNull);
    expect(normalizeQuestionNumber('1a'), isNull);
    expect(normalizeQuestionNumber('-3'), isNull);
  });

  test('lesson step: DB-backed math chapters have lessons', () {
    final ch2 = lessonsForChapter('math', 9, 2);
    expect(ch2.keys, ['2.1', '2.2']);
    expect(ch2['2.1'], 'সেট');
    expect(lessonsForChapter('math', 10, 2).keys, ['2.1', '2.2']);
    expect(lessonsForChapter('math', 9, 3).keys, [
      '3.1',
      '3.2',
      '3.3',
      '3.4',
      '3.5',
      'পরিশিষ্ট',
    ]);
    expect(lessonsForChapter('math', 9, 3)['3.3'], 'উৎপাদকে বিশ্লেষণ');
    expect(lessonsForChapter('math', 9, 7).keys, ['7.1', '7.2']);
    expect(lessonsForChapter('math', 9, 8).keys, [
      '8.1',
      '8.2',
      '8.3',
      '8.4',
      '8.5',
    ]);
    expect(lessonsForChapter('math', 9, 9).keys, ['9.1', '9.2']);
    expect(lessonsForChapter('math', 9, 11).keys, ['11.1', '11.2']);
    expect(
      lessonsForChapter('math', 9, 11)['11.1'],
      'বীজগাণিতিক অনুপাত ও সমানুপাত',
    );
    expect(lessonsForChapter('math', 9, 16).keys, [
      '16.1',
      '16.2',
      '16.3',
      '16.4',
    ]);
    expect(lessonsForChapter('math', 9, 16)['16.3'], 'বৃত্ত সংক্রান্ত পরিমাপ');
    // No sub-lessons: ch17's only DB value is '17' (whole chapter).
    expect(lessonsForChapter('math', 9, 17), isEmpty);
    // appendix is its own row since 11/10/2026, after 3.1-3.5
    final ch3 = lessonsForChapter('math', 9, 3);
    expect(ch3.keys.toList(),
        ['3.1', '3.2', '3.3', '3.4', '3.5', 'পরিশিষ্ট']);
    expect(lessonsForChapter('math', 9, 7).containsKey('পরিশিষ্ট'), isFalse);
    // Other subjects, classes and chapters skip the lesson step.
    expect(lessonsForChapter('science', 9, 2), isEmpty);
    expect(lessonsForChapter('math', 6, 2), isEmpty);
    expect(lessonsForChapter('math', 9, 99), isEmpty);
  });

  test('verified chapter titles: real names, no invented titles', () {
    expect(verifiedChapterTitle('math', 9, 2), 'সেট ও ফাংশন');
    expect(verifiedChapterTitle('math', 10, 17), 'পরিসংখ্যান');
    expect(verifiedChapterTitle('science', 9, 2), isNull);
    expect(verifiedChapterTitle('math', 9, 99), isNull);
  });
}
