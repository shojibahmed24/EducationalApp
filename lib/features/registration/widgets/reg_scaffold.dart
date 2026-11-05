// Shared scaffold for every registration step. Warm Paper style via
// AppTheme only - no new colours. Slide-in animation on mount;
// route-level slide transitions are added by the integration agent
// (CustomTransitionPage) or by RegistrationWizard (AnimatedSwitcher).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/language_provider.dart';

class RegScaffold extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final Widget child;
  final String nextLabel;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String? nextRoute;
  final bool showSkip;
  final VoidCallback? onSkip;
  final String? skipRoute;
  final bool nextEnabled;

  const RegScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.nextLabel,
    this.onNext,
    this.onBack,
    this.nextRoute,
    this.showSkip = false,
    this.onSkip,
    this.skipRoute,
    this.nextEnabled = true,
  });

  void _next(BuildContext context) {
    if (onNext != null) {
      onNext!();
    } else if (nextRoute != null) {
      context.go(nextRoute!);
    }
  }

  // Previous step for each route-mode step. Without this, Back was
  // dead in route mode: go_router go() does not push, so canPop() is
  // false and tapping Back did nothing on steps 2-13.
  static const _previousRoutes = <int, String>{
    2: '/register/welcome',
    3: '/register/name',
    4: '/register/gender',
    5: '/register/class',
    6: '/register/medium',
    7: '/register/school',
    8: '/register/contact',
    9: '/register/password',
    10: '/register/otp',
    11: '/register/goal',
    12: '/register/guardian',
    13: '/register/review',
  };

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (_previousRoutes.containsKey(step)) {
      context.go(_previousRoutes[step]!);
    } else if (context.canPop()) {
      context.pop();
    }
  }

  void _skip(BuildContext context) {
    if (onSkip != null) {
      onSkip!();
    } else if (skipRoute != null) {
      context.go(skipRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phase 6 (H1): step 1 previously had no back at all (L6) — it
    // returns to /login, the only place registration starts from.
    // Step 13 is terminal: back to review would allow re-confirming
    // a completed registration, so it shows no back; its system
    // back goes forward to /home, matching its Next button.
    final scaffold = Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        elevation: 0,
        leading: step == 13
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.ink),
                onPressed: () => step == 1
                    ? context.go('/login')
                    : _back(context),
              ),
        actions: [
          // Language toggle - works on every step via languageNotifier.
          TextButton(
            onPressed: () =>
                setLanguage(isBangla ? 'en' : 'bn'),
            child: Text(
              isBangla ? 'English' : 'বাংলা',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.15, end: 0),
        duration: const Duration(milliseconds: 300),
        builder: (context, offset, childWidget) {
          return Transform.translate(
            offset: Offset(
              MediaQuery.of(context).size.width * offset,
              0,
            ),
            child: Opacity(
              opacity: 1 - offset / 0.15 * 0.3,
              child: childWidget,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $step / 13',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: step / 13,
                  minHeight: 8,
                  backgroundColor: AppTheme.card,
                  color: AppTheme.amber,
                ),
              ),
              const SizedBox(height: 24),
              Text(title,
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              child,
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      nextEnabled ? () => _next(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(nextLabel),
                ),
              ),
              // Phase 17 (L6): Skip must be visibly distinct from
              // Next, not a second identical-looking path. Next is a
              // full-width filled button; Skip is a small grey
              // outlined button with a skip icon, and on optional
              // steps it discards the step's input (see step 11:
              // Skip no longer saves guardian data, unlike Next).
              if (showSkip) ...[
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _skip(context),
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: Text(isBangla ? 'Skip করো' : 'Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.inkSecondary,
                      side: const BorderSide(color: AppTheme.inkSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    // System back follows the visible back (go() stack has no entry
    // to pop). Step 13 goes to /home, steps 1-12 to their back target.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (step == 13) {
          context.go('/home');
        } else if (step == 1) {
          context.go('/login');
        } else {
          _back(context);
        }
      },
      child: scaffold,
    );
  }
}
