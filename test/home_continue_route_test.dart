// Home "Continue" button target: the NEW search flow, never the
// old /lesson or /search screens that dead-end class 9 (no
// supplied textbook). Route-string unit tests: the wiring in
// home_screen.dart is a single context.go(homeContinueRoute(last)).
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/home/home_continue_route.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';

LessonSelection _last(String subject, int chapter, {int? cls}) =>
    LessonSelection(
      subject: subject,
      chapter: chapter,
      page: 1,
      problem: 1,
      schoolClass: cls,
    );

void main() {
  test('no last lesson -> plain new search flow, not old /search', () {
    expect(homeContinueRoute(null), '/search-flow');
  });

  test('math last lesson -> search flow with subject + class', () {
    expect(
      homeContinueRoute(_last('math', 3, cls: 9)),
      '/search-flow?subject=math&class=9',
    );
  });

  test('math last lesson without class -> subject only', () {
    expect(
      homeContinueRoute(_last('math', 3)),
      '/search-flow?subject=math',
    );
  });

  test('english last lesson -> main search flow, subject english', () {
    expect(
      homeContinueRoute(_last('english', 1, cls: 9)),
      '/search-flow?subject=english&class=9',
    );
    expect(
      homeContinueRoute(_last('english', 1)),
      '/search-flow?subject=english',
    );
  });

  test('other subject -> search flow with that subject', () {
    expect(
      homeContinueRoute(_last('physics', 2, cls: 10)),
      '/search-flow?subject=physics&class=10',
    );
  });

  test('continue never targets the old dead-end routes', () {
    for (final last in <LessonSelection?>[
      null,
      _last('math', 3, cls: 9),
      _last('english', 1, cls: 9),
    ]) {
      final route = homeContinueRoute(last);
      expect(route, isNot('/lesson'));
      expect(route, isNot('/search'));
      expect(route.startsWith('/lesson'), isFalse);
    }
  });
}
