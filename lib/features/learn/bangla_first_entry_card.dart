// Entry card to the Bangla 1st Paper section picker, shown in
// the search flow's Bangla guide view (below the Board tile).
// Resolves its own page strings so the host screen needs only
// one widget line, no string plumbing.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_first_strings.dart';

class BanglaFirstEntryCard extends StatelessWidget {
  const BanglaFirstEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(s['entryTitle']!),
            subtitle: Text(s['entrySub']!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/bangla-first'),
          ),
        );
      },
    );
  }
}
