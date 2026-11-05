// Home lower sections (weak chapters, recommendations, recent
// books), split out of home_screen.dart to keep it under the
// 250-line cap. Behaviour matches the old inline sections, except
// empty states are now HomeEmptyState cards with an action instead
// of a bare "nothing yet" line (dashboard redesign, Phase 4).
import 'package:flutter/material.dart';

import '../learn/lesson_selection.dart';
import '../learn/widgets/digits.dart';
import '../learn/widgets/mock_data.dart';
import 'home_design.dart';
import 'widgets/home_empty_state.dart';

class HomeLowerSections extends StatelessWidget {
  const HomeLowerSections({
    super.key,
    required this.bn,
    required this.s,
    required this.last,
    required this.heroSubject,
    required this.heroTopic,
    required this.recentBooks,
    required this.onOpenLesson,
    required this.onOpenBook,
    required this.onSearch,
    required this.onSeeSubjects,
  });
  final bool bn;
  final Map<String, String> s;
  final LessonSelection? last;
  final String heroSubject;
  final String heroTopic;
  final List<String> recentBooks;
  final VoidCallback onOpenLesson;
  final void Function(String entry) onOpenBook;
  final VoidCallback onSearch;
  final VoidCallback onSeeSubjects;

  String _subjectName(String id) => subjectNameFor(id, bn);

  @override
  Widget build(BuildContext context) {
    final lastLesson = last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s['weakChapters']!,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (lastLesson == null)
          HomeEmptyState(
            message: s['noWeakYet']!,
            actionLabel: s['findQuestions']!,
            onAction: onSearch,
          )
        else
          Card(
            child: ListTile(
              title: Text(
                '${_subjectName(lastLesson.subject)} · '
                '${bn ? 'অধ্যায়' : 'Chapter'} '
                '${numStr(lastLesson.chapter, bn)}',
              ),
              subtitle: Text(s['practiceAgain']!),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenLesson,
            ),
          ),
        const SizedBox(height: HomeDesign.tightGap),
        Text(
          s['recommendations']!,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (lastLesson == null)
          HomeEmptyState(
            message: s['noDataYet']!,
            actionLabel: s['findQuestions']!,
            onAction: onSearch,
          )
        else
          Card(
            child: ListTile(
              title: Text(heroTopic),
              subtitle: Text(heroSubject),
              onTap: onOpenLesson,
            ),
          ),
        const SizedBox(height: HomeDesign.tightGap),
        Text(
          s['recentBooks']!,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (recentBooks.isEmpty)
          HomeEmptyState(
            message: s['noRecentBook']!,
            actionLabel: s['seeAll']!,
            onAction: onSeeSubjects,
          )
        else
          ...recentBooks.map((e) {
            final parts = e.split('|');
            final title = bn && parts.length > 1
                ? parts[1]
                : (parts.length > 2 ? parts[2] : e);
            return Card(
              child: ListTile(
                title: Text(title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenBook(e),
              ),
            );
          }),
      ],
    );
  }
}
