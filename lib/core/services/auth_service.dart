// Auth: Supabase when configured, DEMO mode otherwise (DEMO never
// pretends to be a real account). Phone OTP is real via
// auth_phone_service.dart; it still needs a Twilio/Vonage provider
// in the Supabase dashboard (see BACKEND_DETAILS_LIST.md).
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/parent/parent_pin_store.dart';
import 'app_config.dart';
import 'auth_result.dart';
import 'local_store.dart';
import 'supabase_client.dart';

export 'auth_result.dart';

class AuthService {
  AuthMode get mode => backendReady ? AuthMode.supabase : AuthMode.demo;
  bool get isDemo => mode == AuthMode.demo;

  String? get currentUserId {
    final client = supabaseOrNull;
    return client?.auth.currentUser?.id;
  }

  /// False with no client id: login hides the button, no fake path.
  bool get googleSignInAvailable => AppConfig.googleOAuthClientId.isNotEmpty;

  static const _sessionKey = 'ys_session_user_id';
  static const _onboardingKey = 'ys_onboarding_seen';
  static const _resetContactKey = 'ys_reset_contact';

  Future<void> saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<bool> hasLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey) != null;
  }

  /// Splash session validation: refreshes an expired-but-
  /// refreshable session, false when no LIVE session exists.
  /// Splash must call this instead of trusting the prefs key
  /// alone. Offline with a still-valid cached session (expiry-
  /// checked) still counts as valid, so a dead network never
  /// logs a signed-in user out.
  Future<bool> validateSession() async {
    final client = supabaseOrNull;
    if (client == null) return false;
    try {
      final res = await client.auth.refreshSession();
      return res.session != null;
    } catch (_) {
      final s = client.auth.currentSession;
      if (s == null) return false;
      final exp = s.expiresAt;
      if (exp == null) return true;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 < exp;
    }
  }

  Future<bool> onboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<void> saveResetContact(String contact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resetContactKey, contact);
  }

  Future<String?> readResetContact() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_resetContactKey);
  }

  Future<AuthResult> signInEmail(String email, String password) async {
    final client = supabaseOrNull;
    if (client == null) {
      return const AuthResult(ok: true, userId: 'demo-user', mode: AuthMode.demo);
    }
    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AuthResult(
        ok: res.user != null,
        userId: res.user?.id,
        mode: AuthMode.supabase,
      );
    } on AuthException catch (e) {
      // 'email_not_confirmed' = unconfirmed address (resend path).
      final notConfirmed = e.code == 'email_not_confirmed' ||
          e.message.toLowerCase().contains('not confirmed');
      return AuthResult(
        ok: false,
        error: e.message,
        mode: AuthMode.supabase,
        emailNotConfirmed: notConfirmed,
        errorKind: classifySignInError(e),
      );
    } on Exception catch (e) {
      // Network failures land here, not as AuthException.
      return AuthResult(ok: false, mode: AuthMode.supabase, errorKind: classifySignInError(e));
    }
  }

  Future<AuthResult> signUpEmail(String email, String password) async {
    final client = supabaseOrNull;
    if (client == null) {
      return const AuthResult(ok: true, userId: 'demo-user', mode: AuthMode.demo);
    }
    try {
      final res = await client.auth.signUp(email: email, password: password, emailRedirectTo: AppConfig.emailConfirmationRedirectTo);
      // With "Confirm email" on, Supabase returns a user but NO
      // session: the account exists but is not signed in until the
      // confirmation link is clicked. Callers must show the pending
      // state for this case, never a session or /home.
      return AuthResult(
        ok: res.user != null,
        userId: res.user?.id,
        mode: AuthMode.supabase,
        confirmationPending: res.user != null && res.session == null,
      );
    } on AuthException catch (e) {
      return AuthResult(ok: false, error: e.message, mode: AuthMode.supabase);
    }
  }

  /// Resends the sign-up confirmation email. Used when sign-in fails
  /// with email-not-confirmed and when registration is pending
  /// confirmation. In DEMO mode there is no real account, so this is
  /// a labelled no-op success like the other DEMO paths.
  Future<AuthResult> resendConfirmationEmail(String email) async {
    final client = supabaseOrNull;
    if (client == null) {
      return const AuthResult(ok: true, mode: AuthMode.demo);
    }
    try {
      await client.auth.resend(email: email, type: OtpType.signup, emailRedirectTo: AppConfig.emailConfirmationRedirectTo);
      return const AuthResult(ok: true, mode: AuthMode.supabase);
    } on AuthException catch (e) {
      return AuthResult(ok: false, error: e.message, mode: AuthMode.supabase);
    }
  }

  /// Phase 16 (M11): sign-out wipes the previous user's local data
  /// — profile, saved questions, voice minutes/period, practice
  /// history, learn recents, notification state (LocalStore.
  /// clearUserData) and the parent PIN (ParentPinStore.clearPin) —
  /// so the next account inherits none of it. Device prefs
  /// (language/theme/font) and onboarding-seen are deliberately
  /// kept. The parent PIN is cleared here on purpose, NOT via the
  /// forgot-PIN path, which remains blocked without identity check.
  Future<void> signOut() async {
    final client = supabaseOrNull;
    if (client != null) {
      await client.auth.signOut();
    }
    await clearSession();
    await LocalStore.setPremiumLocal(false);
    await LocalStore.clearUserData();
    await parentPinStore.clearPin();
  }

  /// Sends the password-recovery email. The redirectTo brings the
  /// link back into the app (manifest scheme filter +
  /// auth_recovery_listener routes it to /reset-password) instead
  /// of a web page. Without the dashboard allow-listing, Supabase
  /// rejects the redirect and the error surfaces honestly.
  Future<AuthResult> resetPassword(String email) async {
    final client = supabaseOrNull;
    if (client == null) {
      return const AuthResult(ok: true, mode: AuthMode.demo);
    }
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConfig.passwordRecoveryRedirectTo,
      );
      return const AuthResult(ok: true, mode: AuthMode.supabase);
    } on AuthException catch (e) {
      return AuthResult(ok: false, error: e.message, mode: AuthMode.supabase);
    }
  }

  /// Password change for a signed-in user. In DEMO mode there is no
  /// real account, so the change is accepted locally and the UI shows
  /// its done state labelled DEMO by the banner; it is not a real
  /// Supabase password change.
  Future<AuthResult> updatePassword(String newPassword) async {
    final client = supabaseOrNull;
    if (client == null) {
      return const AuthResult(ok: true, mode: AuthMode.demo);
    }
    try {
      final res = await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return AuthResult(
        ok: res.user != null,
        mode: AuthMode.supabase,
      );
    } on AuthException catch (e) {
      return AuthResult(ok: false, error: e.message, mode: AuthMode.supabase);
    }
  }

  /// Google sign-in via Supabase OAuth (Supabase holds the real
  /// client id/secret; GOOGLE_OAUTH_CLIENT_ID is only the button
  /// gate). Returns googleLaunched, never ok:true: the session
  /// arrives via the signedIn event and only then may the caller
  /// navigate. Launch failure maps to a Bangla-safe errorKind.
  Future<AuthResult> signInWithGoogle() async {
    final client = supabaseOrNull;
    if (client == null || AppConfig.googleOAuthClientId.isEmpty) {
      // No real OAuth path: never a fake success (button hidden too).
      return AuthResult(ok: false, mode: client == null ? AuthMode.demo : AuthMode.supabase, googleNotConfigured: true);
    }
    try {
      final launched = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.googleOAuthRedirectTo,
      );
      return AuthResult(
        ok: false,
        mode: AuthMode.supabase,
        googleLaunched: launched,
        errorKind: launched ? AuthErrorKind.none : AuthErrorKind.unknown,
      );
    } on AuthException catch (e) {
      return AuthResult(ok: false, error: e.message, mode: AuthMode.supabase, errorKind: classifySignInError(e));
    } catch (e) {
      return AuthResult(ok: false, error: e.toString(), mode: AuthMode.supabase, errorKind: classifySignInError(e));
    }
  }
}

final authService = AuthService();
