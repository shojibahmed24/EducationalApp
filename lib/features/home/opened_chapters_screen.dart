// Route: /home/opened-chapters — detail behind Home's second stat.
// Lists chaptersList() keys ('subject|chapter') grouped by subject:
// subject groups in first-seen order, chapters in numeric order
// within a group. Malformed keys are skipped silently, never shown
// as invented rows. Tap goes to that subject's textbook chapters
// screen (/home/subjects/<subject>/chapters).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/home_strings.dart';
import '../learn/learn_store.dart';
import '../learn/widgets/digits.dart';
import '../learn/widgets/mock_data.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class OpenedChapterGroup {
  const OpenedChapterGroup({required this.subject, required this.chapters});
  final String subject;
  final List<int> chapters;
}

/// Pure grouping: first-seen subject order, numeric chapter order,
/// duplicates dropped, malformed keys ('subject|chapter' with an
/// empty subject or a non-positive/non-numeric chapter) skipped.
List<OpenedChapterGroup> groupOpenedChapters(List<String> keys) {
  final order = <String>[];
  final bySubject = <String, Set<int>>{};
  for (final key in keys) {
    final parts = key.split('|');
    if (parts.length != 2 || parts[0].isEmpty) continue;
    final chapter = int.tryParse(parts[1]);
    if (chapter == null || chapter < 1) continue;
    if (!bySubject.containsKey(parts[0])) {
      order.add(parts[0]);
      bySubject[parts[0]] = <int>{};
    }
    bySubject[parts[0]]!.add(chapter);
  }
  return [
    for (final subject in order)
      OpenedChapterGroup(
        subject: subject,
        chapters: (bySubject[subject]!.toList()..sort()),
      ),
  ];
}

class OpenedChaptersScreen extends StatefulWidget {
  const OpenedChaptersScreen({super.key});
  @override
  State<OpenedChaptersScreen> createState() => _OpenedChaptersScreenState();
}

class _OpenedChaptersScreenState extends State<OpenedChaptersScreen> {
  late final Future<List<OpenedChapterGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future = LearnStore.chaptersList().then(groupOpenedChapters);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? homeStringsBn : homeStringsEn;
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            title: Text(s['openedChaptersTitle']!),
          ),
          body: FutureBuilder<List<OpenedChapterGroup>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final groups = snap.data ?? const [];
              if (groups.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(s['openedChaptersEmpty']!,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: Text(s['home']!),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final group in groups) ...[
                    Text(subjectNameFor(group.subject, bn),
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    for (final chapter in group.chapters)
                      Card(
                        child: ListTile(
                          title: Text(
                            '${bn ? 'অধ্যায়' : 'Chapter'} '
                            '${numStr(chapter, bn)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go(
                            '/home/subjects/${group.subject}/chapters',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
