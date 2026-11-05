// Target route for the home hero card's "Continue" button.
//
// Continue ALWAYS opens the NEW search flow, never the old
// textbook screens: the old /search screen shows class 9 the
// dead-end note ("book not supplied yet, lesson cannot open"),
// and the old /lesson screen needs a supplied textbook too.
// The new flow accepts subject + class query params; it has NO
// chapter param, so the chapter is NOT prefilled — the user
// picks it in the flow (one tap). English has no chapter step
// anywhere, so an English last-lesson goes to the main flow
// with subject=english, where the global picker serves the
// English guide. With no last lesson, plain /search-flow falls
// back to the saved class and math.
import '../learn/lesson_selection.dart';

String homeContinueRoute(LessonSelection? last) {
  if (last == null) return '/search-flow';
  final cls = last.schoolClass;
  if (last.subject == 'english') {
    return cls == null
        ? '/search-flow?subject=english'
        : '/search-flow?subject=english&class=$cls';
  }
  final query = 'subject=${last.subject}';
  return cls == null ? '/search-flow?$query' : '/search-flow?$query&class=$cls';
}
