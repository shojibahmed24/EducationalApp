import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/auth_recovery_listener.dart';
import 'core/services/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DEMO mode if no Supabase keys are configured - never crashes.
  await initBackend();
  // No-op in DEMO mode; in real mode it routes password-recovery
  // email links to /reset-password (see auth_recovery_listener).
  startAuthRecoveryListener();
  runApp(const ProviderScope(child: YesSirApp()));
}
