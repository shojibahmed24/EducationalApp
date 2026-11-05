// Lesson-screen helpers, split out to keep lesson_screen.dart
// under the 250-line file limit. No UI here, only lookups.
import '../../core/services/learn_service.dart';
import '../../l10n/pages/lesson_strings.dart';
import 'lesson_selection.dart';

/// The full garden problem text lives in the lesson strings and
/// matches the grounded area lesson (math 3/45/5); other grounded
/// lessons use the service answer verbatim.
String baseLessonAnswer(LessonSelection sel, bool bn) {
  if (sel.key == 'math|3|45|5') {
    final s = bn ? lessonStringsBn : lessonStringsEn;
    return '${s['step1Body']!} ${s['step2Body']!}';
  }
  final r = learnService.resolve(
    subject: sel.subject,
    chapter: sel.chapter,
    page: sel.page,
    problem: sel.problem,
  );
  return bn ? r.answerBn : r.answerEn;
}

/// Sync (DEMO-index) grounding check. The screen replaces this
/// with the async Edge Function result when it arrives.
bool syncGrounded(LessonSelection sel) => learnService
    .resolve(
      subject: sel.subject,
      chapter: sel.chapter,
      page: sel.page,
      problem: sel.problem,
    )
    .found;

/// DEMO-index question label, used only until the async result
/// arrives so the heading never flashes empty.
String syncQuestion(LessonSelection sel) => learnService
    .resolve(
      subject: sel.subject,
      chapter: sel.chapter,
      page: sel.page,
      problem: sel.problem,
    )
    .question;
