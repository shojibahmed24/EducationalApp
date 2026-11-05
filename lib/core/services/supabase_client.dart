// Supabase initialisation. DEMO mode = no initialisation, no crash.
// Call initBackend() from main() before runApp().
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

bool _initialised = false;

Future<bool> initBackend() async {
  if (!AppConfig.supabaseConfigured) return false;
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _initialised = true;
    return true;
  } catch (_) {
    // Configured but unreachable: fall back to DEMO mode, never crash.
    return false;
  }
}

bool get backendReady => _initialised;

SupabaseClient? get supabaseOrNull =>
    _initialised ? Supabase.instance.client : null;
