import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../home_design.dart';

/// Destination for a home subject tile: ALWAYS the new search
/// flow, with the tapped subject preselected (Step 4). The old
/// guide-only branch (/guide-chapters) is gone: guide-only tiles
/// land on the search screen too, which defaults their source to
/// guide because the textbook is locked.
String homeSubjectRoute(String subjectId) =>
    '/search-flow?subject=$subjectId';

/// One subject tile on Home. Tapping goes to the new search
/// flow with this subject preselected (guide-only or not: the
/// search screen picks the default source from the lock state).
class HomeSubjectTile extends StatelessWidget {
  const HomeSubjectTile({
    super.key,
    required this.name,
    required this.chaptersLabel,
    this.subjectId = 'math',
  });
  final String name;
  final String chaptersLabel;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    // Batch 2, item 2: clip so nothing can ever paint outside the
    // card even at large font scales; the name wraps (no truncation)
    // and the grid row sizes to the tallest tile.
    // UI palette (গ): the icon sits in a subject-colour chip.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.subjectColorFor(subjectId, dark: dark);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(HomeDesign.cardRadius),
        onTap: () => context.go(homeSubjectRoute(subjectId)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_outlined,
                    size: 28, color: accent),
              ),
              const SizedBox(height: 8),
              Text(name, style: Theme.of(context).textTheme.headlineMedium),
              Text(chaptersLabel, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
