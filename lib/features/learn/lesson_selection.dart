// In-memory selection shared by Search -> Lesson -> Chat -> NoMatch
// and Books viewer -> Lesson. No router change needed: screens read
// this holder instead of route parameters. It is session-only; the
// persisted parts (recents, last lesson) live in learn_store.dart.
// NOTE: no bKash here or anywhere in Area 2 — deliberately absent:
// Play Billing only, per the locked rule.
class LessonSelection {
  LessonSelection({
    required this.subject,
    required this.chapter,
    required this.page,
    required this.problem,
    this.bookId,
    this.queryText = '',
    this.questionId,
    this.schoolClass,
    this.guideQuestionId,
    this.stimulusText,
    this.stimulusQuestionId,
    this.guideOptions = const [],
    this.returnTo = '/lesson',
  });
  final String subject;
  final int chapter;
  final int page;
  final int problem;
  final String? bookId;
  final String queryText;

  /// Textbook chapter-list id. When set, the lesson resolves by id
  /// (textbook_chapter_service.resolveById) instead of by
  /// page/problem; page/problem may then be 0 (unknown) and must
  /// never be displayed as a real number.
  final String? questionId;

  /// The class this selection belongs to, when known (chapter
  /// list / search). Null = not chosen yet: callers fall back to
  /// the saved profile class, never a silent 6.
  final int? schoolClass;

  /// Guide bank row id (2026-11-01): when set, chat resolves
  /// via Mode G (resolveGuide) instead of textbook grounding,
  /// and page/problem 0 is never looked up in the book index.
  final String? guideQuestionId;

  /// Creative stimulus (উদ্দীপক) for a guide chat open, when
  /// the opening question object carries one. The chat AI
  /// prompt gains it (see withChatStimulus); the displayed
  /// question never changes. Null/empty = no stimulus.
  final String? stimulusText;

  /// Ownership of [stimulusText] (2026-11-03 chat fix): the id of
  /// the question the stimulus belongs to. withChatStimulus
  /// applies the stimulus ONLY when this equals the resolved
  /// guide question id — a stimulus from any other question can
  /// never leak into this chat's prompt, and a fused
  /// stimulus-as-question can never recur.
  final String? stimulusQuestionId;

  /// Verbatim option texts of the opening guide question, when
  /// the opening list row carries them (2026-11-03 chat fix).
  /// The chat prompt quotes these exactly; Mode G options win
  /// when both exist (same DB row, same texts).
  final List<String> guideOptions;

  /// Where chat's back button (and system back via the route's
  /// BackScope) returns: '/lesson' for textbook flows, the
  /// guide answer route for guide flows. Never invented per tap.
  final String returnTo;

  /// Same selection with the class stamped in; every other field
  /// (including questionId and guide fields) is preserved.
  LessonSelection copyWith({int? schoolClass, String? stimulusText}) =>
      LessonSelection(
        subject: subject,
        chapter: chapter,
        page: page,
        problem: problem,
        bookId: bookId,
        queryText: queryText,
        questionId: questionId,
        schoolClass: schoolClass ?? this.schoolClass,
        guideQuestionId: guideQuestionId,
        stimulusText: stimulusText ?? this.stimulusText,
        stimulusQuestionId: stimulusQuestionId,
        guideOptions: guideOptions,
        returnTo: returnTo,
      );

  String get key => '$subject|$chapter|$page|$problem';
  String get chapterKey => '$subject|$chapter';
}

/// The current selection. Defaults to the one grounded DEMO lesson
/// (Maths, chapter 3, page 45, question 5) so a bare /lesson tap
/// still shows a real grounded answer instead of a blank screen.
class LessonSelectionHolder {
  static LessonSelection current = LessonSelection(
    subject: 'math',
    chapter: 3,
    page: 45,
    problem: 5,
  );

  /// True once any screen has explicitly set a selection. The
  /// untouched app default (math 3/45/5) is NOT a user choice, so
  /// Search treats it as fresh (page/problem 1/1) instead of
  /// presenting the demo question as the user's selection.
  static bool touched = false;
  static void set(LessonSelection sel) {
    current = sel;
    touched = true;
  }
}

/// Chapter-list navigation state, consumed once by the
/// /chapter-questions route builder (see learn_routes.dart).
/// schoolClass null = route was opened directly: the chapter
/// screen then loads the saved class (loadSchoolClass ?? 6).
/// bannerPage = the page the search shortcut could not resolve,
/// shown as a banner on the chapter list, never as a no-match.
class ChapterListHolder {
  static int? schoolClass;
  static int? bannerPage;
  static void set({int? schoolClass, int? bannerPage}) {
    ChapterListHolder.schoolClass = schoolClass;
    ChapterListHolder.bannerPage = bannerPage;
  }

  static void clear() {
    schoolClass = null;
    bannerPage = null;
  }
}

/// Search "সমাধান দেখো" shortcut decision (pure, tested without
/// the Edge): exact resolve wins -> lesson; otherwise the chapter
/// list (with the page banner) when the chapter exists; no-match
/// ONLY when the chapter itself does not exist.
enum SearchShortcut { lesson, chapterList, noMatch }

SearchShortcut decideSearchShortcut({
  required bool exactFound,
  required bool chapterExists,
}) {
  if (exactFound) return SearchShortcut.lesson;
  if (chapterExists) return SearchShortcut.chapterList;
  return SearchShortcut.noMatch;
}

/// The book currently open in the viewer (subject + last page).
class BookSelectionHolder {
  static String subject = 'math';
  static String bookId = 'class6-math-bn';
  static int page = 45;
  static void set(String s, String id, int p) {
    subject = s;
    bookId = id;
    page = p;
  }
}
