import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/guide_bank_service.dart';

/// Search footer, split out to keep search_screen.dart under the
/// 250-line cap. Guide sourcing (all classes): when the selected
/// subject's textbook is locked BUT the guide has chapters for
/// this class+subject, a prominent guide button appears above the
/// usual note + Guide Bank link — so a locked subject is no
/// longer a dead end. When the textbook is unlocked, or when no
/// guide exists, only the note + link render (previous behavior).
/// The guide check is one Edge guideChapters call (null = no
/// guide / unreachable, never a guessed true).
class SearchGuideSection extends StatelessWidget {
  const SearchGuideSection({
    super.key,
    required this.subject,
    required this.schoolClass,
    required this.locked,
    required this.note,
    required this.linkLabel,
    required this.buttonLabel,
  });
  final String subject;
  final int schoolClass;
  final bool locked;
  final String note;
  final String linkLabel;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locked)
          FutureBuilder<Map<int, int>?>(
            future: guideBankService.fetchGuideChapters(
              subject,
              schoolClass: schoolClass,
            ),
            builder: (context, snap) {
              final chapters = snap.data;
              if (chapters == null || chapters.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  // Step 7: old /guide-chapters deleted; the
                  // new search flow defaults to guide when
                  // the textbook is locked (this branch).
                  onPressed: () => context.go(
                    '/search-flow?subject=$subject',
                  ),
                  child: Text(buttonLabel),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        Text(note, style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          // Step 7: see above — old route deleted.
          onPressed: () =>
              context.go('/search-flow?subject=$subject'),
          child: Text(linkLabel),
        ),
      ],
    );
  }
}
