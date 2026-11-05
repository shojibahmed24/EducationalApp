// Password-recovery routing (forgot -> email link -> back into app).
// The Supabase SDK already observes deep links (detectSessionInUri
// defaults to true) and turns a recovery link into an
// AuthChangeEvent.passwordRecovery with a session. What was missing
// was app-side routing for that event: nothing sent the user to
// /reset-password, and splash would have sent a recovery session to
// /home instead. This listener only raises a flag; app_router's
// redirect does the routing, so both warm links and cold starts
// (link tapped while the app is closed) land on /reset-password.
// The flag is in-memory only: leaving the reset screen (done ->
// login, or back -> login) clears it, and an app kill clears it too
// (a fresh link re-enters the flow). DEMO mode: no client, no-op.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// True from the password-recovery event until the reset screen is
/// left. While true, app_router redirects every navigation to
/// /reset-password.
final recoveryPending = ValueNotifier<bool>(false);

StreamSubscription<AuthState>? _subscription;

void startAuthRecoveryListener() {
  final client = supabaseOrNull;
  if (client == null || _subscription != null) return;
  _subscription = client.auth.onAuthStateChange.listen((state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      recoveryPending.value = true;
    }
  });
}

void clearRecoveryPending() {
  recoveryPending.value = false;
}
