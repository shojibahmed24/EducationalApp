// Auth result types, split out of auth_service.dart to keep
// it under the 250-line limit. auth_service.dart re-exports
// this file, so existing importers (e.g. auth_phone_service)
// keep working unchanged.
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthMode { supabase, demo }

/// UI-safe kind of a sign-in failure. The UI maps this to a
/// Bangla/English string and NEVER shows a raw Supabase SDK
/// message (2026-11-01 login fix: users saw English SDK text).
enum AuthErrorKind { none, invalidCredentials, network, unknown }

class AuthResult {
  final bool ok;
  final String? userId;
  final String? error;
  final AuthMode mode;

  /// True when sign-up succeeded but no session was established
  /// because email confirmation is pending (Supabase "Confirm email"
  /// on: res.user != null, res.session == null). Callers must NOT
  /// treat this as a signed-in user: no saved session, no /home.
  final bool confirmationPending;

  /// True when sign-in failed because the email address is not
  /// confirmed yet. Callers offer a resend instead of a dead end.
  final bool emailNotConfirmed;

  /// Kind of a sign-in failure (invalidCredentials / network /
  /// unknown). Kept separate from emailNotConfirmed, which has
  /// its own resend path. `none` = no failure or unclassified.
  final AuthErrorKind errorKind;

  /// True when Google sign-in was attempted but no OAuth client id
  /// is configured. Never a fake success: the login screen hides
  /// the button in that case, and the service refuses here too.
  final bool googleNotConfigured;

  /// True when the Google OAuth browser was LAUNCHED successfully.
  /// This is NOT a sign-in: no session exists yet. The login screen
  /// must wait for the signedIn auth event (see
  /// listenForFreshSignIn) and must never navigate on this alone —
  /// treating a launch as a login would be a fake success.
  final bool googleLaunched;

  const AuthResult({
    required this.ok,
    this.userId,
    this.error,
    required this.mode,
    this.confirmationPending = false,
    this.emailNotConfirmed = false,
    this.errorKind = AuthErrorKind.none,
    this.googleNotConfigured = false,
    this.googleLaunched = false,
  });
}

/// Maps a sign-in exception to a UI-safe kind (pure, tested).
/// Supabase intentionally does NOT distinguish "no such user"
/// from "wrong password": both are invalidCredentials, and the
/// UI message must not claim otherwise.
AuthErrorKind classifySignInError(Object e) {
  if (e is AuthException) {
    if (e.code == 'invalid_login_credentials' ||
        e.code == 'invalid_credentials') {
      return AuthErrorKind.invalidCredentials;
    }
  }
  final msg = e.toString().toLowerCase();
  if (msg.contains('invalid login credentials')) {
    return AuthErrorKind.invalidCredentials;
  }
  if (msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused') ||
      msg.contains('connection timed out') ||
      msg.contains('connection reset')) {
    return AuthErrorKind.network;
  }
  return AuthErrorKind.unknown;
}

/// Login-strings key for a sign-in failure, so the screen shows a
/// localised message instead of any raw SDK text.
String signInErrorStringKey(AuthResult res) {
  if (res.googleNotConfigured) return 'googleUnavailable';
  switch (res.errorKind) {
    case AuthErrorKind.invalidCredentials:
      return 'invalidCredentials';
    case AuthErrorKind.network:
      return 'networkError';
    case AuthErrorKind.none:
    case AuthErrorKind.unknown:
      return 'loginFailed';
  }
}
