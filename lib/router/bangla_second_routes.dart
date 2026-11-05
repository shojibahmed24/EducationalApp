// Bangla 2nd Paper picker routes. BackScope parents mirror
// each screen's AppBar back button.
import 'package:go_router/go_router.dart';

import '../features/learn/bangla_second_mcq_questions_screen.dart';
import '../features/learn/bangla_second_mcq_screen.dart';
import '../features/learn/bangla_second_model_tests_screen.dart';
import '../features/learn/bangla_second_nirmiti_screen.dart';
import '../features/learn/bangla_second_set_rows_screen.dart';
import '../features/learn/bangla_second_suggestion_detail_screen.dart';
import '../features/learn/bangla_second_suggestion_screen.dart';
import '../features/learn/bangla_second_types_screen.dart';

final banglaSecondRoutes = <RouteBase>[
  GoRoute(
    path: '/bangla-second-suggestion',
    builder: (context, state) =>
        const BanglaSecondSuggestionScreen(),
  ),
  GoRoute(
    path: '/bangla-second-suggestion-detail',
    builder: (context, state) =>
        BanglaSecondSuggestionDetailScreen(
      id: state.uri.queryParameters['id'] ?? '',
    ),
  ),
  GoRoute(
    path: '/bangla-second',
    builder: (context, state) => const BanglaSecondTypesScreen(),
  ),
  GoRoute(
    path: '/bangla-second-mcq',
    builder: (context, state) => const BanglaSecondMcqScreen(),
  ),
  GoRoute(
    path: '/bangla-second-mcq-questions',
    builder: (context, state) => BanglaSecondMcqQuestionsScreen(
      group: state.uri.queryParameters['group'] ?? '',
      sub: state.uri.queryParameters['sub'] ?? 'all',
    ),
  ),
  GoRoute(
    path: '/bangla-second-nirmiti',
    builder: (context, state) => BanglaSecondNirmitiScreen(
      kind: state.uri.queryParameters['kind'] ?? '',
    ),
  ),
  GoRoute(
    path: '/bangla-second-model-tests',
    builder: (context, state) => const BanglaSecondModelTestsScreen(),
  ),
  GoRoute(
    path: '/bangla-second-set-rows',
    builder: (context, state) => BanglaSecondSetRowsScreen(
      group: state.uri.queryParameters['group'] ?? '',
      setId: state.uri.queryParameters['setId'] ?? '',
    ),
  ),
];
