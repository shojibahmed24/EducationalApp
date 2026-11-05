import 'package:go_router/go_router.dart';
import '../core/widgets/back_scope.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/profile/notifications_screen.dart';
import '../features/profile/help_faq_screen.dart';
import '../features/profile/about_screen.dart';
import '../features/parent/parent_pin_screen.dart';
import '../features/parent/parent_dashboard_screen.dart';
import '../features/premium/premium_paywall_screen.dart';
import '../features/premium/voice_tutor_screen.dart';

// Profile + Parent + Premium routes, verified against screen headers.
final List<GoRoute> profileRoutes = [
  GoRoute(path: '/profile', builder: (c, s) => BackScope(parent: '/home', child: const ProfileScreen())),
  GoRoute(path: '/settings', builder: (c, s) => BackScope(parent: '/profile', child: const SettingsScreen())),
  GoRoute(path: '/notifications', builder: (c, s) => BackScope(parent: '/home', child: const NotificationsScreen())),
  GoRoute(path: '/help', builder: (c, s) => const HelpFaqScreen()),
  GoRoute(path: '/about', builder: (c, s) => BackScope(parent: '/home', child: const AboutScreen())),
  GoRoute(path: '/parent-pin', builder: (c, s) => BackScope(parent: '/profile', child: const ParentPinScreen())),
  GoRoute(path: '/parent-dashboard', builder: (c, s) => BackScope(parent: '/profile', child: const ParentDashboardScreen())),
  GoRoute(path: '/premium', builder: (c, s) => const PremiumPaywallScreen()),
  GoRoute(path: '/voice', builder: (c, s) => const VoiceTutorScreen()),
];
