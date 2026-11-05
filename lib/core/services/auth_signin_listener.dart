// Scoped fresh-sign-in listener for email-confirmation links.
// The SDK emits initialSession for a restored session on subscribe
// and signedIn only for a fresh sign-in (e.g. a confirmation link
// tapped while the screen is open), so reacting to signedIn alone
// never bounces a user who simply opened the screen. Returns a
// cancel function, or null in DEMO mode; callers cancel in dispose.
// Deliberately NOT global: a blanket listener would hijack the
// registration wizard mid-flow when confirmation is OFF and sign-up
// establishes a session immediately.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// Calls [onSignedIn] for a fresh sign-in only. Returns a cancel
/// function, or null when no backend is configured (DEMO mode).
void Function()? listenForFreshSignIn(void Function(User user) onSignedIn) {
  final client = supabaseOrNull;
  if (client == null) return null;
  final sub = client.auth.onAuthStateChange.listen((state) {
    final session = state.session;
    if (state.event == AuthChangeEvent.signedIn && session != null) {
      onSignedIn(session.user);
    }
  });
  return sub.cancel;
}
