// Lesson grounding resolution, split out of lesson_screen.dart
// to keep it under the 250-line limit. A questionId selection
// resolves BY ID instead of by page/problem; anything else
// resolves via the Edge Function (Mode A).
import '../../core/services/explanation_service.dart';
import '../../core/services/textbook_chapter_service.dart';
import 'lesson_selection.dart';

Future<Grounding> resolveLessonGrounding(LessonSelection sel, bool bn) {
  if (sel.questionId != null) {
    // By-id Edge payload carries no classId, so the KNOWN class
    // rides only in the client context object: resolveById
    // already threads its schoolClass into GroundedContext, but
    // it was never passed here, so every by-id question (e.g. a
    // class-7 chapter-list row) was labelled with the default 6.
    // Null = not known here: keep the service default (6) rather
    // than inventing a class; callers that know the class (the
    // chapter list sets it) now forward it.
    return textbookChapterService.resolveById(
      sel.questionId!,
      bn,
      subject: sel.subject,
      schoolClass: sel.schoolClass ?? 6,
    );
  }
  return explanationService.resolve(
    subject: sel.subject,
    chapter: sel.chapter,
    page: sel.page,
    problem: sel.problem,
    bangla: bn,
  );
}
