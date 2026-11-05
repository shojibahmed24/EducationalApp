// Recents section, split out of search_screen.dart to keep it
// under the 250-line file cap. Recents are real persisted
// searches, recorded only when a solution is actually viewed,
// most recent first, with a Clear button. A recent tap re-runs
// the search shortcut (exact resolve, else chapter list, else
// no-match) instead of blindly opening a lesson.
import 'package:flutter/material.dart';
import '../../../core/services/profile_service.dart';
import '../learn_store.dart';
import '../lesson_selection.dart';

class SearchRecentsSection extends StatefulWidget {
  const SearchRecentsSection({
    super.key,
    required this.s,
    required this.onRecentTap,
  });
  final Map<String, String> s;
  final void Function(LessonSelection sel, String label) onRecentTap;

  @override
  State<SearchRecentsSection> createState() => _SearchRecentsSectionState();
}

class _SearchRecentsSectionState extends State<SearchRecentsSection> {
  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s['recent']!,
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            TextButton(
              onPressed: () async {
                await LearnStore.clearRecentSearches();
                if (!context.mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s['recentCleared']!)),
                );
              },
              child: Text(s['clearRecent']!),
            ),
          ],
        ),
        FutureBuilder<LearnSummary>(
          future: LearnStore.summary(),
          builder: (context, snap) {
            final recents = snap.data?.recentSearches ?? const [];
            if (recents.isEmpty) {
              return Text(s['noRecentSearch']!);
            }
            return Column(
              children: recents.map((e) {
                final parts = e.split('|');
                final label = parts.first;
                final key = parts.length > 1
                    ? parts.sublist(1).join('|')
                    : '';
                return Card(
                  child: ListTile(
                    title: Text(label),
                    onTap: () async {
                      final kp = key.split('|');
                      if (kp.length != 4) return;
                      // Class stamp: saved profile class when
                      // available (Search re-stamps it too); null
                      // = no class known, never a silent 6.
                      final schoolClass =
                          await profileService.loadSchoolClass();
                      widget.onRecentTap(
                        LessonSelection(
                          subject: kp[0],
                          chapter: int.tryParse(kp[1]) ?? 1,
                          page: int.tryParse(kp[2]) ?? 1,
                          problem: int.tryParse(kp[3]) ?? 1,
                          schoolClass: schoolClass,
                        ),
                        label,
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
