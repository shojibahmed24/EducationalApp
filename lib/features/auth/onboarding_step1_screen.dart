// Route: /onboarding-1
// Design: stitch-reference/_5/code.html (find any answer).
// Flow: /onboarding-1 -> /onboarding-2 ; Skip -> /login.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/onboarding_step1_strings.dart';
import '../../theme/app_theme.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingStep1Screen extends StatelessWidget {
  const OnboardingStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s =
            isBangla ? onboardingStep1StringsBn : onboardingStep1StringsEn;
        return OnboardingShell(
          stepLabel: s['step']!,
          title: s['title']!,
          subtitle: s['subtitle']!,
          step: 1,
          // Step 1 is the onboarding entry: no previous step exists,
          // and going "back" to splash would just forward again.
          showBack: false,
          nextLabel: s['next']!,
          skipLabel: s['skip']!,
          onNext: () => context.go('/onboarding-2'),
          // Skip is a real choice: remember it so splash never shows
          // onboarding again to this returning user.
          onSkip: () async {
            await authService.markOnboardingSeen();
            if (context.mounted) context.go('/login');
          },
          content: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _row(context, s['subject']!, s['subjectValue']!),
                  const SizedBox(height: 12),
                  _row(context, s['chapter']!, s['chapterValue']!),
                  const SizedBox(height: 12),
                  _row(context, s['page']!, s['question']!),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _badge(s['badge1']!),
                      const SizedBox(width: 8),
                      _badge(s['badge2']!),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppTheme.primary)),
      ],
    );
  }

  Widget _badge(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
