// Route: /onboarding-3
// Design: stitch-reference/_6/code.html (quiz + progress).
// Flow: /onboarding-3 -> /login ; Skip -> /login.
// Both Next and Skip mark onboarding as seen (persisted), so splash
// sends this returning user to /login, never back to onboarding.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/onboarding_step3_strings.dart';
import '../../theme/app_theme.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingStep3Screen extends StatelessWidget {
  const OnboardingStep3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s =
            isBangla ? onboardingStep3StringsBn : onboardingStep3StringsEn;
        return OnboardingShell(
          stepLabel: s['step']!,
          title: s['title']!,
          subtitle: s['subtitle']!,
          step: 3,
          nextLabel: s['start']!,
          skipLabel: s['skip']!,
          onNext: () async {
            await authService.markOnboardingSeen();
            if (context.mounted) context.go('/login');
          },
          onBack: () => context.go('/onboarding-2'),
          onSkip: () async {
            await authService.markOnboardingSeen();
            if (context.mounted) context.go('/login');
          },
          content: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stat(context, Icons.local_fire_department, s['streak']!,
                      s['streakDetail']!),
                  const SizedBox(height: 12),
                  _stat(context, Icons.verified, s['quiz']!, s['quizDetail']!),
                  const SizedBox(height: 16),
                  Text('• ${s['point1']!}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text('• ${s['point2']!}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stat(
      BuildContext context, IconData icon, String title, String detail) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
