import 'package:go_router/go_router.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/onboarding_step1_screen.dart';
import '../features/auth/onboarding_step2_screen.dart';
import '../features/auth/onboarding_step3_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/reset_password_screen.dart';

// Auth routes. Paths verified against each screen file header.
final List<GoRoute> authRoutes = [
  GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
  // Root: anything that lands on '/' (including the old error page's
  // Home button) goes to splash, which routes by session state.
  GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
  // Email-confirmation deep link (AppConfig.emailConfirmationRedirectTo
  // = com.yessirai.app://email-confirmed). Without this route, tapping
  // the confirmation email produced GoException "no routes for
  // location" instead of returning to the app. Splash routes home as
  // soon as the SDK has built the session from the link (its signedIn
  // listener fires first; its 2.5s check covers a session that lands
  // a moment later); with no session it falls through to login /
  // onboarding like any other splash visit.
  GoRoute(path: '/email-confirmed', builder: (c, s) => const SplashScreen()),
  GoRoute(path: '/onboarding-1', builder: (c, s) => const OnboardingStep1Screen()),
  GoRoute(path: '/onboarding-2', builder: (c, s) => const OnboardingStep2Screen()),
  GoRoute(path: '/onboarding-3', builder: (c, s) => const OnboardingStep3Screen()),
  GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
  GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
  // OTP origin (Phase 6, H1): ?from=/login or ?from=/forgot-password.
  // Unknown/absent values fall back to /forgot-password (old behaviour).
  GoRoute(
    path: '/otp',
    builder: (c, s) {
      final from = s.uri.queryParameters['from'];
      return OtpScreen(
        returnTo: from == '/login' ? '/login' : '/forgot-password',
      );
    },
  ),
  GoRoute(path: '/reset-password', builder: (c, s) => const ResetPasswordScreen()),
];
