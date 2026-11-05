import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../home_design.dart';

/// Continue-learning hero card ("আগের পড়া চালিয়ে যাও").
///
/// UI palette (গ): deep blue → purple gradient with white text
/// in both modes, and a white Continue button (a blue button
/// would vanish into the gradient). Text colours are set
/// explicitly — the theme's body text assumes the paper
/// background, not a gradient card.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    super.key,
    required this.title,
    required this.subject,
    required this.topic,
    required this.progressLabel,
    required this.continueLabel,
    this.onContinue,
  });
  final String title;
  final String subject;
  final String topic;
  final String progressLabel;
  final String continueLabel;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    // UI palette (গ): hero gradient (deep blue → purple) with
    // white text in both modes. The old solid tint is kept in
    // AppTheme.heroTint for other callers; this card gradients.
    final dark = Theme.of(context).brightness == Brightness.dark;
    const fg = Colors.white;
    final sub = Colors.white.withValues(alpha: 0.85);
    return Container(
      decoration: BoxDecoration(
        gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(HomeDesign.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: fg),
            ),
            const SizedBox(height: 4),
            Text(
              subject,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: sub),
            ),
            const SizedBox(height: 2),
            Text(
              topic,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: fg),
            ),
            const SizedBox(height: 4),
            Text(
              progressLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: sub),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryDark,
                ),
                onPressed: onContinue ?? () => context.go('/lesson'),
                child: Text(continueLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
