import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_recovery_listener.dart';
import '../features/auth/splash_screen.dart';
import '../features/parent/parent_session.dart';
import 'auth_routes.dart';
import 'registration_routes.dart';
import 'learn_routes.dart';
import 'bangla_first_routes.dart';
import 'bangla_second_routes.dart';
import 'practice_routes.dart';
import 'profile_routes.dart';

// Full route table, assembled from the per-group route files above.
// Keep this file small: new routes go in their group file, not here.
// Parent gate (H7): /parent-dashboard redirects to /parent-pin
// unless parentSession was verified by the PIN screen in this
// session. refreshListenable re-runs the redirect when the flag
// changes (verify / sign-out / restart clears it: in-memory only).
// Password-recovery gate: while recoveryPending is true (Supabase
// reported a password-recovery session), every navigation goes to
// /reset-password - so a recovery link that cold-starts the app is
// not hijacked by splash's session -> /home routing. The reset
// screen clears the flag when it is left.
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  // Unknown deep links (e.g. a mistyped confirmation link) must not
  // dead-end on go_router's default error page, whose Home button
  // pointed at '/' — itself unrouted. Splash routes by session state.
  errorBuilder: (context, state) => const SplashScreen(),
  refreshListenable: Listenable.merge([parentSession, recoveryPending]),
  redirect: (context, state) {
    if (state.matchedLocation == '/parent-dashboard' &&
        !parentSession.verified) {
      return '/parent-pin';
    }
    if (recoveryPending.value &&
        state.matchedLocation != '/reset-password') {
      return '/reset-password';
    }
    return null;
  },
  routes: [
    ...authRoutes,
    ...registrationRoutes,
    ...learnRoutes,
    ...banglaFirstRoutes,
    ...banglaSecondRoutes,
    ...practiceRoutes,
    ...profileRoutes,
  ],
);
