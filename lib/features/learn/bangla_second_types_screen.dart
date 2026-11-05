// Type picker for Bangla 2nd Paper: the eleven অধ্যায় items in
// the exact user order (2026-11-04 refinement: চিঠিপত্র is a
// single item, not separate চিঠি/আবেদনপত্র; অনুবাদ and সাজেশন
// added after রচনা, মডেল টেস্ট stays last). No fetch here —
// the items are fixed by the list, and each tap opens its
// lesson screen (routes in bangla_second_routes.dart). Back
// returns to the search flow.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_second_types.dart';

class BanglaSecondTypesScreen extends StatelessWidget {
  const BanglaSecondTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaSecondStringsBn : banglaSecondStringsEn;
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
              Text(s['typesTitle']!,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final type in banglaSecondTypesInOrder)
                Card(
                  child: ListTile(
                    title: Text(banglaSecondTypeLabel(type, s)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(banglaSecondRoute(type)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
