// One lesson: three options — MCQ, creative questions, Quiz.
// Model tests live on the section screen, never here (per the
// design spec: MCQ screen = bank MCQ only, creative screen =
// lesson creative only, Quiz screen = lesson quiz only).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/bangla_first_lessons.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_first_strings.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class BanglaFirstLessonScreen extends StatelessWidget {
  const BanglaFirstLessonScreen({
    super.key,
    required this.section,
    required this.lessonTitle,
  });
  final String section;
  final String lessonTitle;

  String get _mcqUrl =>
      '/bangla-first-mcq?section=$section&lesson=${Uri.encodeComponent(lessonTitle)}';
  String get _creativeUrl =>
      '/bangla-first-creative?section=$section&lesson=${Uri.encodeComponent(lessonTitle)}';
  String get _quizUrl =>
      '/bangla-first-quiz?section=$section&lesson=${Uri.encodeComponent(lessonTitle)}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
        final lesson = banglaFirstLessonByTitle(lessonTitle);
        return ThemedScaffold(calm: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.go('/bangla-first-section?section=$section'),
            ),
            title: Text(lessonTitle),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (lesson != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    lesson.author,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              _OptionCard(
                title: s['lessonMcq']!,
                icon: Icons.list,
                onTap: () => context.go(_mcqUrl),
              ),
              _OptionCard(
                title: s['lessonCreative']!,
                icon: Icons.edit_note,
                onTap: () => context.go(_creativeUrl),
              ),
              _OptionCard(
                title: s['lessonQuiz']!,
                icon: Icons.quiz,
                onTap: () => context.go(_quizUrl),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard(
      {required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
