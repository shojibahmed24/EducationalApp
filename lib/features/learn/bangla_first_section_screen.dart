// Lesson list of one Bangla 1st Paper section, with the section's
// Model test entry BELOW the list. 'other' lists the unmapped
// server titles passed via route extra and has no model-test
// entry: no setId prefix exists for lessons outside the map.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/bangla_first_lessons.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_first_strings.dart';

class BanglaFirstSectionScreen extends StatelessWidget {
  const BanglaFirstSectionScreen({
    super.key,
    required this.section,
    this.extraLessons,
  });
  final String section;
  final List<String>? extraLessons;

  bool get _isOther => section == 'other';

  String _lessonUrl(String title) =>
      '/bangla-first-lesson?section=$section&lesson=${Uri.encodeComponent(title)}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
        final known = banglaFirstLessonsFor(section);
        final titles = _isOther
            ? (extraLessons ?? const <String>[])
            : known.map((l) => l.title).toList();
        final authors = _isOther
            ? const <String, String>{}
            : {for (final l in known) l.title: l.author};
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/bangla-first'),
            ),
            title: Text(banglaFirstSectionName(section, s)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final title in titles)
                Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: authors[title] == null
                        ? null
                        : Text(authors[title]!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(_lessonUrl(title)),
                  ),
                ),
              if (!_isOther) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(s['modelTestsEntry']!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(
                        '/bangla-first-model-tests?section=$section'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
