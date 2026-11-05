// Section picker for Bangla 1st Paper: goddo / poddo / uponnas
// from the verified lesson map, plus a fallback entry when the
// server returns lesson titles the map does not know. Known
// sections render immediately; the fallback appears only when
// the fetch proves unmapped titles exist (a failed fetch hides
// nothing — it just shows the three known sections).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/bangla_first_lessons.dart';
import '../../core/services/bangla_first_fetch.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_first_strings.dart';

class BanglaFirstSectionsScreen extends StatefulWidget {
  const BanglaFirstSectionsScreen({super.key});

  @override
  State<BanglaFirstSectionsScreen> createState() =>
      _BanglaFirstSectionsScreenState();
}

class _BanglaFirstSectionsScreenState
    extends State<BanglaFirstSectionsScreen> {
  List<String>? _unmapped;

  @override
  void initState() {
    super.initState();
    banglaFirstFetch.fetchServerLessons().then((lessons) {
      if (!mounted) return;
      setState(() {
        _unmapped =
            lessons == null ? null : banglaFirstUnmappedLessons(lessons.keys);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
        final showOther = _unmapped != null && _unmapped!.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/search-flow'),
            ),
            title: Text(s['title']!),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(s['sectionsTitle']!,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final section in banglaFirstSections)
                _SectionCard(
                  title: banglaFirstSectionName(section, s),
                  subtitle:
                      '${banglaFirstLessonsFor(section).length} ${s['lessonsSuffix']!}',
                  onTap: () => context
                      .go('/bangla-first-section?section=$section'),
                ),
              if (showOther)
                _SectionCard(
                  title: s['otherLessons']!,
                  subtitle:
                      '${_unmapped!.length} ${s['lessonsSuffix']!}',
                  onTap: () => context.go(
                    '/bangla-first-section?section=other',
                    extra: {'lessons': _unmapped},
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
