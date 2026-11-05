// Bangla 1st Paper new-design routes. All new: no existing
// route is touched. BackScope parents mirror the visible back
// buttons (query params included where the parent needs them).
import 'package:go_router/go_router.dart';

import '../core/models/guide_bank_model.dart';
import '../core/widgets/back_scope.dart';
import '../features/learn/bangla_first_creative_group_screen.dart';
import '../features/learn/bangla_first_creative_screen.dart';
import '../features/learn/bangla_first_lesson_screen.dart';
import '../features/learn/bangla_first_mcq_screen.dart';
import '../features/learn/bangla_first_model_tests_screen.dart';
import '../features/learn/bangla_first_quiz_screen.dart';
import '../features/learn/bangla_first_section_screen.dart';
import '../features/learn/bangla_first_sections_screen.dart';

final List<GoRoute> banglaFirstRoutes = [
  GoRoute(
    path: '/bangla-first',
    builder: (c, s) => const BackScope(
        parent: '/search-flow', child: BanglaFirstSectionsScreen()),
  ),
  GoRoute(
    path: '/bangla-first-section',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      final section = q['section'] ?? '';
      List<String>? lessons;
      final extra = s.extra;
      if (extra is Map && extra['lessons'] is List) {
        lessons = (extra['lessons'] as List).whereType<String>().toList();
      }
      return BackScope(
        parent: '/bangla-first',
        child: BanglaFirstSectionScreen(
            section: section, extraLessons: lessons),
      );
    },
  ),
  GoRoute(
    path: '/bangla-first-lesson',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      final section = q['section'] ?? '';
      final lesson = q['lesson'] ?? '';
      return BackScope(
        parent: '/bangla-first-section?section=$section',
        child: BanglaFirstLessonScreen(
            section: section, lessonTitle: lesson),
      );
    },
  ),
  GoRoute(
    path: '/bangla-first-mcq',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      final section = q['section'] ?? '';
      final lesson = q['lesson'] ?? '';
      return BackScope(
        parent:
            '/bangla-first-lesson?section=$section&lesson=${Uri.encodeComponent(lesson)}',
        child:
            BanglaFirstMcqScreen(section: section, lessonTitle: lesson),
      );
    },
  ),
  GoRoute(
    path: '/bangla-first-creative',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      final section = q['section'] ?? '';
      final lesson = q['lesson'] ?? '';
      return BackScope(
        parent:
            '/bangla-first-lesson?section=$section&lesson=${Uri.encodeComponent(lesson)}',
        child: BanglaFirstCreativeScreen(
            section: section, lessonTitle: lesson),
      );
    },
  ),
  GoRoute(
    path: '/bangla-first-quiz',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      final section = q['section'] ?? '';
      final lesson = q['lesson'] ?? '';
      return BackScope(
        parent:
            '/bangla-first-lesson?section=$section&lesson=${Uri.encodeComponent(lesson)}',
        child:
            BanglaFirstQuizScreen(section: section, lessonTitle: lesson),
      );
    },
  ),
  GoRoute(
    path: '/bangla-first-creative-set',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      final section = q['section'] ?? '';
      final setId = q['setId'] ?? '';
      final title = q['title'];
      return BackScope(
        parent: '/bangla-first-model-tests?section=$section',
        child: BanglaFirstCreativeScreen(
            section: section,
            lessonTitle: '',
            setId: setId,
            setTitle: title),
      );
    },
  ),
  GoRoute(
    path: '/bangla-first-creative-group',
    builder: (c, s) {
      final extra = s.extra;
      var parts = const <GuideBankQuestion>[];
      var stimulus = '';
      var returnTo = '/bangla-first';
      if (extra is Map) {
        final p = extra['parts'];
        if (p is List && p.every((e) => e is GuideBankQuestion)) {
          parts = p.cast<GuideBankQuestion>();
        }
        final st = extra['stimulusText'];
        if (st is String) stimulus = st;
        final rt = extra['returnTo'];
        if (rt is String) returnTo = rt;
      }
      return BackScope(
        parent: returnTo,
        child: BanglaFirstCreativeGroupScreen(
            parts: parts, stimulusText: stimulus, returnTo: returnTo),
      );
    },
  ),
  GoRoute(
    path: '/bangla-first-model-tests',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      final section = q['section'] ?? '';
      return BackScope(
        parent: '/bangla-first-section?section=$section',
        child: BanglaFirstModelTestsScreen(section: section),
      );
    },
  ),
];
