// Shared onboarding shell: step label, title, subtitle, content card,
// progress dots, Next + Skip. Keeps each onboarding screen small.
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'auth_buttons.dart';
import 'auth_scaffold.dart';
import 'fade_slide.dart';

class OnboardingShell extends StatelessWidget {
  final String stepLabel;
  final String title;
  final String subtitle;
  final Widget content;
  final int step; // 1..3
  final String nextLabel;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  // Phase 6 (H1): explicit back per step. go() leaves a single-entry
  // stack, so the old maybePop() back arrow did nothing. Step 1 has
  // no previous step, so its screen passes showBack: false.
  final VoidCallback? onBack;
  final bool showBack;
  const OnboardingShell({
    super.key,
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.step,
    required this.nextLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
    this.onBack,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: showBack,
      onBack: onBack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlide(
              child: Text(
                stepLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primary,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            FadeSlide(
              delayMs: 80,
              child: Text(title, style: Theme.of(context).textTheme.displayLarge),
            ),
            const SizedBox(height: 8),
            FadeSlide(
              delayMs: 160,
              child: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 20),
            FadeSlide(delayMs: 240, child: content),
            const SizedBox(height: 24),
            _dots(),
            const SizedBox(height: 24),
            FadeSlide(
              delayMs: 320,
              child: AuthPrimaryButton(label: nextLabel, onPressed: onNext),
            ),
            const SizedBox(height: 8),
            Center(child: AuthTextLink(label: skipLabel, onPressed: onSkip)),
          ],
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i + 1 == step;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.inkMuted,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
