// Static class 9-10 math chapter/lesson titles: integrity checks.
// Sources are documented in lib/core/data/class9_10_math_chapters.dart.
// These tests pin the verified values so a typo or a guessed title
// cannot slip in silently.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/class9_10_math_chapters.dart';

void main() {
  test('chapter numbers are exactly the verified contiguous set 1-17', () {
    expect(class9_10MathChapterTitles.keys.toList(), [
      for (var n = 1; n <= 17; n++) n,
    ]);
  });

  test('no chapter title is empty or whitespace-only', () {
    for (final entry in class9_10MathChapterTitles.entries) {
      expect(
        entry.value.trim(),
        isNotEmpty,
        reason: 'chapter ${entry.key} title must not be empty',
      );
    }
  });

  test('guide-covered chapters match the textbook TOC names', () {
    expect(class9_10MathChapterTitles[2], 'সেট ও ফাংশন');
    expect(class9_10MathChapterTitles[3], 'বীজগাণিতিক রাশি');
    expect(class9_10MathChapterTitles[7], 'ব্যবহারিক জ্যামিতি');
    expect(class9_10MathChapterTitles[8], 'বৃত্ত');
    expect(class9_10MathChapterTitles[9], 'ত্রিকোণমিতিক অনুপাত');
    expect(class9_10MathChapterTitles[11], 'বীজগাণিতিক অনুপাত ও সমানুপাত');
    expect(class9_10MathChapterTitles[16], 'পরিমিতি');
    expect(class9_10MathChapterTitles[17], 'পরিসংখ্যান');
  });

  test('chapter-2 lesson titles match the pilot page_maps', () {
    expect(chapter2LessonTitles, {
      '2.1': 'সেট',
      '2.2': 'অন্বয় ও ফাংশন এবং ডোমেন ও রেঞ্জ',
    });
  });

  test('guide lesson titles are non-empty and never overlap ch. 2', () {
    for (final entry in guideLessonTitles.entries) {
      expect(
        entry.value.trim(),
        isNotEmpty,
        reason: 'lesson ${entry.key} title must not be empty',
      );
      expect(
        entry.key.startsWith('2.'),
        isFalse,
        reason: 'guide map must not contain chapter-2 lessons',
      );
    }
    expect(guideLessonTitles['3.1'], 'বর্গ সংবলিত সূত্রাবলি ও প্রয়োগ');
    expect(guideLessonTitles['3.3'], 'উৎপাদকে বিশ্লেষণ');
    expect(guideLessonTitles['7.1'], 'ত্রিভুজ অঙ্কন');
    expect(guideLessonTitles['7.2'], 'চতুর্ভুজ অঙ্কন');
    expect(guideLessonTitles['8.1'], 'বৃত্তের জ্যা ও ব্যাস সংক্রান্ত উপপাদ্য');
    expect(
      guideLessonTitles['8.5'],
      'বৃত্ত সম্পর্কীয় সম্পাদ্য ও বৃত্তের স্পর্শক অঙ্কন',
    );
    expect(guideLessonTitles['9.1'], 'ত্রিকোণমিতিক অনুপাত ও অনুপাতের সম্পর্ক');
    expect(guideLessonTitles['9.2'], 'বিভিন্ন কোণের ত্রিকোণমিতিক অনুপাত');
    expect(guideLessonTitles['11.1'], 'বীজগাণিতিক অনুপাত ও সমানুপাত');
    expect(guideLessonTitles['11.2'], 'ধারাবাহিক অনুপাত ও সমানুপাতিক ভাগ');
    expect(guideLessonTitles['16.1'], 'ত্রিভুজক্ষেত্রের ক্ষেত্রফল');
    expect(guideLessonTitles['16.4'], 'আয়তাকার ঘনবস্তু');
    // Appendix is not a numbered lesson, so it has no entry.
    expect(guideLessonTitles.containsKey('পরিশিষ্ট'), isFalse);
  });
}
