import 'package:go_router/go_router.dart';
import '../core/models/guide_bank_model.dart';
import '../core/services/english_reader_service.dart';
import '../core/widgets/back_scope.dart';
import '../features/learn/guide_answer_holder.dart';
import '../features/home/home_screen.dart';
import '../features/home/opened_chapters_screen.dart';
import '../features/home/today_lessons_screen.dart';
import '../features/home/subjects_screen.dart';
import '../features/learn/chapters_screen.dart';
import '../features/learn/search_screen.dart';
import '../features/learn/chapter_questions_screen.dart';
import '../features/learn/lesson_selection.dart';
import '../features/learn/book_lookup_screen.dart';
import '../features/learn/lesson_screen.dart';
import '../features/learn/chat_screen.dart';
import '../features/learn/no_match_screen.dart';
import '../features/learn/guide_answer_screen.dart';
import '../features/learn/search_flow_board_sections.dart';
import '../features/learn/search_flow_list_screen.dart';
import '../features/learn/search_flow_screen.dart';
import '../features/learn/english_search_flow_list_screen.dart';
import '../features/learn/english_reader_screen.dart';
import '../features/learn/search_flow_types.dart';
import '../features/practice/guide_model_test_list_screen.dart';

// Home + Learn routes. Chapters uses :subjectId; screens default to 'math'
// when no id is given, so both /home/subjects/math/chapters (used by
// subjects tiles) and the bare param route resolve to the same screen.
final List<GoRoute> learnRoutes = [
  GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
  // Home stat detail screens: system back returns to /home,
  // same BackScope pattern as /search above.
  GoRoute(path: '/home/today-lessons', builder: (c, s) => BackScope(parent: '/home', child: const TodayLessonsScreen())),
  GoRoute(path: '/home/opened-chapters', builder: (c, s) => BackScope(parent: '/home', child: const OpenedChaptersScreen())),
  GoRoute(path: '/home/subjects', builder: (c, s) => BackScope(parent: '/home', child: const SubjectsScreen())),
  GoRoute(
    path: '/home/subjects/:subjectId/chapters',
    builder: (c, s) => BackScope(
      parent: '/home/subjects',
      child: ChaptersScreen(
        subjectId: s.pathParameters['subjectId'] ?? 'math',
      ),
    ),
  ),
  // Step 6 group contract (Step 7: the old /guide-bank and
  // /guide-chapters routes are deleted): context.go(
  // '/guide-answer', extra: {'group': List<GuideBankQuestion>
  // (all parts of one stimulus), 'stimulusText': String,
  // 'subjectId': String, 'chapterNumber': int,
  // 'schoolClass': int?, 'returnTo': String (list URL)}).
  // Absent keys fall back to the holder's current values; no
  // extra at all leaves the holder untouched (single-question
  // callers use GuideAnswerHolder.set() directly, which clears
  // group mode and may set returnTo itself).
  GoRoute(
    path: '/guide-answer',
    builder: (c, s) {
      final extra = s.extra;
      if (extra is Map) {
        final g = extra['group'];
        if (g is List && g.every((e) => e is GuideBankQuestion)) {
          final parts = g.cast<GuideBankQuestion>();
          final stim = extra['stimulusText'];
          final rt = extra['returnTo'];
          GuideAnswerHolder.setGroup(
            parts: parts,
            subject: extra['subjectId'] as String? ??
                GuideAnswerHolder.subjectId,
            chapter: extra['chapterNumber'] as int? ??
                GuideAnswerHolder.chapterNumber,
            schoolClass: extra['schoolClass'] as int? ??
                GuideAnswerHolder.schoolClass,
            stimulusText: stim is String
                ? stim
                : (parts.first.stimulusText ?? ''),
            returnTo: rt is String ? rt : null,
          );
        }
      }
      return BackScope(
        parent: '/home/subjects',
        child: const GuideAnswerScreen(),
      );
    },
  ),
  GoRoute(
    path: '/guide-model-tests',
    builder: (c, s) => BackScope(
      parent: '/practice',
      child: const GuideModelTestListScreen(),
    ),
  ),
  // New search flow (Steps 3+5): home tiles land here, never on
  // the old chapters/guide-chapters screens. Query params carry
  // subject (+ class when the caller knows it); without params
  // the screen falls back to the saved class and math.
  GoRoute(
    path: '/search-flow',
    builder: (c, s) => BackScope(
      parent: '/home',
      child: SearchFlowScreen(
        initialSubjectId: s.uri.queryParameters['subject'] ?? 'math',
        initialSchoolClass:
            int.tryParse(s.uri.queryParameters['class'] ?? ''),
      ),
    ),
  ),
  GoRoute(
    path: '/search-flow-list',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      var type = SearchFlowType.mcq;
      for (final t in SearchFlowType.values) {
        if (t.name == q['type']) type = t;
      }
      return BackScope(
        parent: '/search-flow',
        child: SearchFlowListScreen(
          subjectId: q['subject'] ?? 'math',
          schoolClass: int.tryParse(q['class'] ?? '') ?? 6,
          source: q['source'] ?? 'guide',
          chapterNumber: int.tryParse(q['chapter'] ?? '') ?? 1,
          type: type,
          lesson: q['lesson'],
          questionNumber: int.tryParse(q['questionNumber'] ?? ''),
          section: q['section'],
          setId: q['setId'],
          chapterless: q['chapterless'] == 'true',
          board: q['board'] == 'true',
        ),
      );
    },
  ),
  // Board sub-sections (Board revision 2026-11-02): the Board
  // tile lands here, never straight on a mixed list. The
  // screen re-fetches Board counts and hides zero sections.
  GoRoute(
    path: '/search-flow-board',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      return BackScope(
        parent: '/search-flow',
        child: SearchFlowBoardSectionsScreen(
          subjectId: q['subject'] ?? 'math',
          schoolClass: int.tryParse(q['class'] ?? '') ?? 6,
        ),
      );
    },
  ),
  // No separate English picker (2026-11-05): English guide goes
  // through the main /search-flow global picker (subject=english);
  // the old /english-search-flow route was removed. The list and
  // reader routes below stay as destinations reached from it.
  GoRoute(
    path: '/english-search-flow-list',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      return BackScope(
        parent: '/search-flow',
        child: EnglishSearchFlowListScreen(
          schoolClass: int.tryParse(q['class'] ?? '') ?? 9,
          setId: q['setId'],
          section: q['section'],
          lesson: q['lesson'],
        ),
      );
    },
  ),
  // Redesigned English reader (2026-11-03): one collection
  // (model test, practice serial, poem, story) with a sticky
  // passage box, one sub-question at a time, and a jump bar.
  GoRoute(
    path: '/english-reader',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      var kind = EnglishReaderKind.model;
      for (final k in EnglishReaderKind.values) {
        if (k.name == q['kind']) kind = k;
      }
      return BackScope(
        parent: '/search-flow',
        child: EnglishReaderScreen(
          schoolClass: int.tryParse(q['class'] ?? '') ?? 9,
          kind: kind,
          title: q['title'] ?? '',
          setId: q['setId'],
          lesson: q['lesson'],
          stimulusRef: q['ref'],
          workName: q['work'],
        ),
      );
    },
  ),
  // shows it instead of discarding it (see SearchScreen).
  GoRoute(path: '/search', builder: (c, s) => BackScope(parent: '/home', child: SearchScreen(initialQuery: s.uri.queryParameters['q'] ?? ''))),
  // Second step: textbook chapter list. schoolClass/bannerPage
  // come from ChapterListHolder (set by Search); a direct route
  // entry passes null, and the screen loads the saved class.
  GoRoute(
    path: '/chapter-questions/:subjectId/:chapter',
    builder: (c, s) {
      final schoolClass = ChapterListHolder.schoolClass;
      final bannerPage = ChapterListHolder.bannerPage;
      ChapterListHolder.clear();
      return BackScope(
        parent: '/search',
        child: ChapterQuestionsScreen(
          subjectId: s.pathParameters['subjectId'] ?? 'math',
          chapterNumber:
              int.tryParse(s.pathParameters['chapter'] ?? '') ?? 1,
          schoolClass: schoolClass,
          bannerPage: bannerPage,
        ),
      );
    },
  ),
  GoRoute(path: '/book-lookup', builder: (c, s) => BackScope(parent: '/search', child: const BookLookupScreen())),
  GoRoute(path: '/lesson', builder: (c, s) => BackScope(parent: '/search', child: const LessonScreen())),
  // Chat back destination follows the selection: textbook flows
  // return to /lesson (default); guide flows return to the guide
  // answer route set by the guide screen before navigating here.
  GoRoute(
    path: '/lesson/chat',
    builder: (c, s) => BackScope(
      parent: LessonSelectionHolder.current.returnTo,
      child: const ChatScreen(),
    ),
  ),
  GoRoute(path: '/lesson/no-match', builder: (c, s) => BackScope(parent: '/search', child: const NoMatchScreen())),
];
