// Route: /splash
// Design: stitch-reference/splash_screen/code.html
// Real routing: restores saved language/theme/font, then:
// signed-in (Supabase session OR saved DEMO session) -> /home;
// returning user who finished/skipped onboarding -> /login;
// first-run user -> /onboarding-1. A confirmation link tapped
// while splash is up routes home via the signedIn listener below
// (see auth_signin_listener); if the session lands after splash
// already left, /login's listener covers it.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/auth_signin_listener.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/splash_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_mode.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/fade_slide.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  void Function()? _cancelAuthListener;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    // Confirmation-link cold start: the SDK may still be exchanging
    // the link when _route checks, so a signedIn event arriving
    // while splash is up routes home at once. If it arrives after
    // splash already left, /login's listener covers it.
    _cancelAuthListener = listenForFreshSignIn((_) {
      if (mounted) context.go('/home');
    });
    // Previously every launch forced onboarding, even for a signed-in
    // returning user. Now persisted state decides: Supabase session
    // or a saved DEMO session -> home; onboarding seen -> login.
    _route();
  }

  Future<void> _route() async {
    await restoreLanguage();
    await restoreAppearance();
    final seen = await authService.onboardingSeen();
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    // DEMO mode: no Supabase session exists to validate, so the
    // saved demo session keeps the existing behaviour (Home
    // shows the DEMO banner for it).
    if (authService.isDemo) {
      if (await authService.hasLocalSession()) {
        context.go('/home');
      } else if (seen) {
        context.go('/login');
      } else {
        context.go('/onboarding-1');
      }
      return;
    }
    // Configured backend: trust the LIVE session, never the
    // prefs key alone — an expired/invalid session routes to
    // login, never to home with a dead session.
    final valid = await authService.validateSession();
    if (!mounted) return;
    if (!valid) await authService.clearSession();
    if (valid) {
      context.go('/home');
    } else if (seen) {
      context.go('/login');
    } else {
      context.go('/onboarding-1');
    }
  }

  @override
  void dispose() {
    _cancelAuthListener?.call();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s = isBangla ? splashStringsBn : splashStringsEn;
        return AuthScaffold(
          showBack: false,
          // Phase 16 (M9): scrollable, so short phones / 1.25x font
          // cannot overflow (AuthScaffold gives this an Expanded,
          // i.e. bounded, slot, so scrolling is well-defined).
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(_pulse),
                  child: Image.asset(
                    'assets/logo/yes-sir-ai-icon.png',
                    width: 128,
                    height: 128,
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlide(
                  child: Text(s['appName']!,
                      style: Theme.of(context).textTheme.displayLarge),
                ),
                FadeSlide(
                  delayMs: 120,
                  child: Text(s['appNameBn']!,
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                const SizedBox(height: 8),
                FadeSlide(
                  delayMs: 200,
                  child: Text(s['tagline']!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.inkSecondary,
                          )),
                ),
                const SizedBox(height: 16),
                FadeSlide(
                  delayMs: 280,
                  child: Text(s['detail']!, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 12),
                Text(s['loading']!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 24),
                Text(s['curriculum']!,
                    style: Theme.of(context).textTheme.bodySmall),
                Text(s['safe']!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}
