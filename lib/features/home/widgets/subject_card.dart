import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';

/// Subject card on SubjectsScreen. Locked subjects show the locked
/// message and do NOT navigate to chapters (book not supplied yet).
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.name,
    required this.chapters,
    required this.done,
    required this.locked,
    required this.chaptersLabel,
    required this.lockedLabel,
    this.subjectId = 'math',
  });
  final String subjectId;
  final String name;
  final int chapters;
  final int done;
  final bool locked;
  final String chaptersLabel;
  final String lockedLabel;

  @override
  Widget build(BuildContext context) {
    final progress = chapters == 0 ? 0.0 : done / chapters;
    // UI palette (গ): subject-colour accent dot + progress bar;
    // locked cards keep the muted lock look, no colour tease.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = locked
        ? AppTheme.inkMuted
        : AppTheme.subjectColorFor(subjectId, dark: dark);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: locked ? null : () => context.go('/home/subjects/$subjectId/chapters'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, style: Theme.of(context).textTheme.headlineMedium)),
                  if (locked) const Icon(Icons.lock_outlined, color: AppTheme.inkMuted),
                ],
              ),
              const SizedBox(height: 4),
              Text('$chapters $chaptersLabel', style: Theme.of(context).textTheme.bodySmall),
              if (locked) Text(lockedLabel, style: const TextStyle(color: AppTheme.error)),
              if (!locked) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
