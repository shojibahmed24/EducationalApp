// Route: /onboarding-2
// Design: stitch-reference/_4/code.html (AI teacher, step 2/3).
// Flow: /onboarding-2 -> /onboarding-3 ; Skip -> /login.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/onboarding_step2_strings.dart';
import '../../theme/app_theme.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingStep2Screen extends StatelessWidget {
  const OnboardingStep2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s =
            isBangla ? onboardingStep2StringsBn : onboardingStep2StringsEn;
        return OnboardingShell(
          stepLabel: s['step']!,
          title: s['title']!,
          subtitle: s['subtitle']!,
          step: 2,
          nextLabel: s['next']!,
          skipLabel: s['skip']!,
          onNext: () => context.go('/onboarding-3'),
          onBack: () => context.go('/onboarding-1'),
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
                  Text(s['tip']!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.secondary,
                          )),
                  const SizedBox(height: 4),
                  Text(s['tipText']!,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  _point(context, Icons.lightbulb, s['point1']!,
                      s['point1Detail']!),
                  const SizedBox(height: 12),
                  _point(context, Icons.mic, s['point2']!, s['point2Detail']!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _point(
      BuildContext context, IconData icon, String title, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primary),
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
