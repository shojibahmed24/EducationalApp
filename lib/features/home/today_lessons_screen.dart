// Route: /home/today-lessons — detail behind Home's first stat.
// Lists TODAY's lessons only, from LearnStore.lessonsTodayList().
// Keys are 'subject|chapter|page|problem'. Malformed keys are
// skipped silently, never shown as invented rows and never a
// crash. Tap sets a page/problem LessonSelection with the saved
// profile class (by-id resolution is impossible from a bare key);
// if that grounding fails, LessonScreen's own honest no-match
// path handles it — no lesson is ever guessed here.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/profile_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/home_strings.dart';
import '../learn/learn_store.dart';
import '../learn/lesson_selection.dart';
import '../learn/widgets/digits.dart';
import '../learn/widgets/mock_data.dart';

/// Strict parse: exactly 4 parts, non-empty subject, and positive
/// chapter/page/problem. Anything else is malformed -> null
/// (caller skips it). No ?? 1 fallbacks: a fallback would display
/// a chapter/page/problem the user never opened.
LessonSelection? parseTodayLessonKey(String key) {
  final parts = key.split('|');
  if (parts.length != 4 || parts[0].isEmpty) return null;
  final chapter = int.tryParse(parts[1]);
  final page = int.tryParse(parts[2]);
  final problem = int.tryParse(parts[3]);
  if (chapter == null || page == null || problem == null) return null;
  if (chapter < 1 || page < 1 || problem < 1) return null;
  return LessonSelection(
    subject: parts[0],
    chapter: chapter,
    page: page,
    problem: problem,
  );
}

class TodayLessonsScreen extends StatefulWidget {
  const TodayLessonsScreen({super.key});
  @override
  State<TodayLessonsScreen> createState() => _TodayLessonsScreenState();
}

class _TodayLessonsScreenState extends State<TodayLessonsScreen> {
  late final Future<List<LessonSelection>> _future;

  @override
  void initState() {
    super.initState();
    _future = LearnStore.lessonsTodayList().then(
      (keys) => keys
          .map(parseTodayLessonKey)
          .whereType<LessonSelection>()
          .toList(),
    );
  }

  String _rowText(LessonSelection lesson, bool bn) {
    final chapterWord = bn ? 'অধ্যায়' : 'Chapter';
    final pageWord = bn ? 'পৃষ্ঠা' : 'Page';
    final questionWord = bn ? 'প্রশ্ন' : 'Question';
    return '${subjectNameFor(lesson.subject, bn)} · $chapterWord '
        '${numStr(lesson.chapter, bn)} · $pageWord '
        '${numStr(lesson.page, bn)} · $questionWord '
        '${numStr(lesson.problem, bn)}';
  }

  Future<void> _open(LessonSelection lesson) async {
    final schoolClass = await profileService.loadSchoolClass();
    if (!mounted) return;
    LessonSelectionHolder.set(LessonSelection(
      subject: lesson.subject,
      chapter: lesson.chapter,
      page: lesson.page,
      problem: lesson.problem,
      schoolClass: schoolClass,
    ));
    context.go('/lesson');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? homeStringsBn : homeStringsEn;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            title: Text(s['todayLessonsTitle']!),
          ),
          body: FutureBuilder<List<LessonSelection>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final lessons = snap.data ?? const [];
              if (lessons.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(s['todayLessonsEmpty']!,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/search'),
                      child: Text(s['startFromSearch']!),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lessons.length,
                itemBuilder: (context, i) {
                  final lesson = lessons[i];
                  return Card(
                    child: ListTile(
                      title: Text(_rowText(lesson, bn)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(lesson),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
