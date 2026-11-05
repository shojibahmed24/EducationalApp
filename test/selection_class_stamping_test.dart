// Selection class stamping (item 6): creations from the books
// viewer, home, and chapter cards stamp the saved profile class
// instead of silently falling back to 6. The stamping mechanism
// is LessonSelection.copyWith; the per-file wiring is guarded by
// source checks below (these screens need a profile/router
// harness for widget tests, so the guard asserts the exact
// stamping call and the explicit-fallback comment stay in place).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';

String _lib(String path) => File('lib/$path').readAsStringSync();

void main() {
  test('unstamped selection carries no class, never a silent 6', () {
    final sel = LessonSelection(
      subject: 'math',
      chapter: 3,
      page: 45,
      problem: 5,
    );
    expect(sel.schoolClass, isNull);
  });

  test('copyWith stamps the saved class, preserving all fields', () {
    final stamped = LessonSelection(
      subject: 'math',
      chapter: 3,
      page: 48,
      problem: 15,
      bookId: 'class7-math-bn',
      queryText: 'q',
      questionId: 'class7-math-bn-ch3-p48-e15',
    ).copyWith(schoolClass: 7);
    expect(stamped.schoolClass, 7);
    expect(stamped.subject, 'math');
    expect(stamped.chapter, 3);
    expect(stamped.page, 48);
    expect(stamped.problem, 15);
    expect(stamped.bookId, 'class7-math-bn');
    expect(stamped.queryText, 'q');
    expect(stamped.questionId, 'class7-math-bn-ch3-p48-e15');
    expect(stamped.copyWith().schoolClass, 7);
  });

  test('books viewer stamps the saved profile class', () {
    final src = _lib('features/books/book_page_viewer_screen.dart');
    expect(src, contains('profileService.loadSchoolClass()'));
    expect(src, contains('schoolClass: schoolClass'));
    expect(src, contains('never a silent 6'));
  });

  test('home stamps the saved profile class from HomeData', () {
    final src = _lib('features/home/home_screen.dart');
    expect(src, contains('data?.schoolClass'));
    expect(src, contains('schoolClass: schoolClass'));
    expect(src, contains('never a silent 6'));
  });

  test('chapter card stamps the saved profile class', () {
    final src = _lib('features/learn/widgets/chapter_card.dart');
    expect(src, contains('profileService.loadSchoolClass()'));
    expect(src, contains('schoolClass: schoolClass'));
    expect(src, contains('never a silent 6'));
  });

  test('search recents stamp the saved profile class', () {
    final src = _lib('features/learn/widgets/search_recents.dart');
    expect(src, contains('profileService.loadSchoolClass()'));
    expect(src, contains('schoolClass: schoolClass'));
    expect(src, contains('never a silent 6'));
  });

  test('search stepper stamps the parent-supplied class', () {
    final src = _lib('features/learn/widgets/search_stepper.dart');
    expect(src, contains('schoolClass: widget.schoolClass'));
    // The constructor default 6 stays, but only as an explicit
    // last-resort fallback, documented at _emit.
    expect(src, contains('this.schoolClass = 6'));
    expect(src, contains('explicit last-resort fallback'));
  });

  test('today lessons already stamp the saved class on open', () {
    final src = _lib('features/home/today_lessons_screen.dart');
    expect(src, contains('profileService.loadSchoolClass()'));
    expect(src, contains('schoolClass: schoolClass'));
  });

  test('read-only screens already stamp the class (no edit needed)', () {
    expect(
      _lib('features/learn/search_screen.dart'),
      contains('schoolClass: _schoolClass'),
    );
    expect(
      _lib('features/learn/chapter_questions_screen.dart'),
      contains('schoolClass: _schoolClass'),
    );
  });
}
