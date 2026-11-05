import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// One step of an AI lesson answer, with adjustable font size.
/// Title and body colours resolve from the theme (onSurface):
/// ink in light mode, a light colour in dark mode — never a
/// forced dark colour on a dark card.
/// UI palette (গ): a 4px accent strip on the left (brand blue
/// by default, or the caller's [accent]); layout is unchanged.
class LessonStepCard extends StatelessWidget {
  const LessonStepCard({
    super.key,
    required this.title,
    required this.body,
    required this.fontSize,
    this.accent,
  });
  final String title;
  final String body;
  final double fontSize;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final strip = accent ?? AppTheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: strip),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.7,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
