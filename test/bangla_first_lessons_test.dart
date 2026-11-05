// Pure-data tests: Bangla 1st Paper lesson map (book order,
// sections, setId prefixes). No widgets, no I/O.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/bangla_first_lessons.dart';

void main() {
  test('18 lessons: 9 goddo, 8 poddo, 1 uponnas, in book order', () {
    expect(banglaFirstLessons.length, 18);
    expect(banglaFirstLessonsFor('goddo').length, 9);
    expect(banglaFirstLessonsFor('poddo').length, 8);
    expect(banglaFirstLessonsFor('uponnas').length, 1);
    expect(banglaFirstLessons.first.title, 'প্রত্যুপকার');
    expect(banglaFirstLessons.last.title, '১৯৭১');
    expect(banglaFirstSections, ['goddo', 'poddo', 'uponnas']);
  });

  test('titles and slugs unique; every lesson has author + section', () {
    final titles = banglaFirstLessons.map((l) => l.title).toSet();
    final slugs = banglaFirstLessons.map((l) => l.slug).toSet();
    expect(titles.length, 18);
    expect(slugs.length, 18);
    for (final l in banglaFirstLessons) {
      expect(l.author.isNotEmpty, true);
      expect(banglaFirstSections.contains(l.section), true);
    }
  });

  test('title lookup exact; unmapped server titles reported, not hidden',
      () {
    expect(banglaFirstLessonByTitle('সুভা')?.section, 'goddo');
    expect(banglaFirstLessonByTitle('কপোতাক্ষ নদ')?.section, 'poddo');
    expect(banglaFirstLessonByTitle('১৯৭১')?.section, 'uponnas');
    expect(banglaFirstLessonByTitle('নেই'), null);
    expect(
        banglaFirstUnmappedLessons(['সুভা', 'নতুন পাঠ']), ['নতুন পাঠ']);
    expect(banglaFirstUnmappedLessons(['সুভা']), isEmpty);
  });

  test('model-test setId prefix per section', () {
    expect(banglaFirstSetPrefix('goddo'), 'ban1-goddo-');
    expect(banglaFirstSetPrefix('poddo'), 'ban1-poddo-');
    expect(banglaFirstSetPrefix('uponnas'), 'ban1-uponnas-');
  });
}
