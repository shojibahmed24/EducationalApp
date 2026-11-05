import 'package:go_router/go_router.dart';
import '../core/widgets/back_scope.dart';
import '../features/practice/practice_screen.dart';
import '../features/practice/practice_tab_screen.dart';
import '../features/practice/quiz_question_screen.dart';
import '../features/practice/quiz_results_screen.dart';
import '../features/practice/model_test_list_screen.dart';
import '../features/practice/model_test_exam_screen.dart';
import '../features/practice/model_test_results_screen.dart';
import '../features/books/book_library_screen.dart';
import '../features/books/book_page_viewer_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/progress/achievements_screen.dart';
import '../features/progress/saved_questions_screen.dart';

// Practice + Books + Progress routes, verified against screen headers.
final List<GoRoute> practiceRoutes = [
  GoRoute(path: '/practice', builder: (c, s) => BackScope(parent: '/home', child: const PracticeScreen())),
  GoRoute(path: '/practice-tab', builder: (c, s) => BackScope(parent: '/practice', child: const PracticeTabScreen())),
  GoRoute(path: '/quiz', builder: (c, s) => BackScope(parent: '/practice', child: const QuizQuestionScreen())),
  GoRoute(path: '/quiz-results', builder: (c, s) => BackScope(parent: '/practice', child: const QuizResultsScreen())),
  GoRoute(path: '/model-tests', builder: (c, s) => BackScope(parent: '/practice', child: const ModelTestListScreen())),
  GoRoute(path: '/model-test-exam', builder: (c, s) => BackScope(parent: '/model-tests', child: const ModelTestExamScreen())),
  GoRoute(path: '/model-test-results', builder: (c, s) => BackScope(parent: '/model-tests', child: const ModelTestResultsScreen())),
  GoRoute(path: '/books', builder: (c, s) => BackScope(parent: '/home', child: const BookLibraryScreen())),
  GoRoute(path: '/books/viewer', builder: (c, s) => BackScope(parent: '/books', child: const BookPageViewerScreen())),
  GoRoute(path: '/progress', builder: (c, s) => BackScope(parent: '/home', child: const ProgressScreen())),
  GoRoute(path: '/achievements', builder: (c, s) => BackScope(parent: '/progress', child: const AchievementsScreen())),
  GoRoute(path: '/saved', builder: (c, s) => BackScope(parent: '/profile', child: const SavedQuestionsScreen())),
];
