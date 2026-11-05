// Backend configuration - PUBLIC config only. Real secrets live
// server-side as Edge Function secrets, NEVER in the app (APK
// strings are extractable). Supply public values with
// --dart-define at build time, e.g.:
// flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co
// --dart-define=SUPABASE_ANON_KEY=...
// Without them the app runs in clearly-marked DEMO mode.
class AppConfig {
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const googleOAuthClientId =
      String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID', defaultValue: '');
  static const playProductId = String.fromEnvironment(
    'PLAY_SUBSCRIPTION_PRODUCT_ID',
    defaultValue: 'yes_sir_ai_premium_monthly',
  );

  /// Locked display price. The real price lives in Play Console.
  static const premiumDisplayPrice = '\$5 / month';

  /// Deep-link target for the password-recovery email. The Android
  /// manifest has a plain scheme filter for com.yessirai.app, so the
  /// link reopens the app and the SDK reports a passwordRecovery
  /// event (see auth_recovery_listener.dart). This exact URL must
  /// also be allow-listed in Supabase Auth URL Configuration, or
  /// Supabase will not redirect to it. Not a secret - just a scheme.
  static const passwordRecoveryRedirectTo =
      'com.yessirai.app://reset-password';

  /// Deep-link target for the sign-up confirmation email. Same
  /// scheme-only manifest filter as the recovery link, so the link
  /// reopens the app and the SDK establishes the session from it
  /// (detectSessionInUri defaults to true). This exact URL must
  /// also be allow-listed in Supabase Auth URL Configuration, or
  /// Supabase will not redirect to it. Not a secret - just a scheme.
  static const emailConfirmationRedirectTo =
      'com.yessirai.app://email-confirmed';

  /// Deep-link target for the Google OAuth callback. Same scheme
  /// filter as the other two links (see AndroidManifest.xml), so
  /// the browser returns to the app and the SDK emits signedIn.
  /// Must also be allow-listed in Supabase Auth URL Configuration.
  static const googleOAuthRedirectTo = 'com.yessirai.app://login-callback';

  /// Guide bank gate (FREE since user order 2026-10-30; premium
  /// decision deferred): how many guide questions per chapter a
  /// free user may open. -1 = free-open (whole bank, no paywall);
  /// re-lock later by setting this back to 0 (whole bank
  /// premium) or N (first N per chapter free). One number only,
  /// no UI rebuild needed. isUnlocked() treats < 0 as unlimited.
  static const freeGuideLimit = -1;
  static const voiceCapMinutesPerPeriod = 30;

  static bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Text AI path = the explain-question Edge Function (Mode GEN).
  /// The client cannot verify the Edge secret is set — a missing
  /// secret surfaces as an honest call-time error, never a fake
  /// answer. So "configured" here means the backend path exists.
  static bool get aiTextConfigured => supabaseConfigured;

  /// Voice transport is unwired (demo practice only): there is no
  /// key concept any more. False until the ephemeral-token
  /// endpoint + live transport land.
  static bool get aiVoiceConfigured => false;

  /// H5 banner rule: fully live only when text AND voice are live.
  /// Voice is unwired, so the banner always shows while the
  /// backend is connected (partial-text row). See demo_banner.dart.
  static bool get aiFullyConfigured =>
      aiTextConfigured && aiVoiceConfigured;

  /// Edge Function that reads book_questions with the service role.
  /// Override with --dart-define=EXPLAIN_FUNCTION_URL=...; otherwise
  /// derived from SUPABASE_URL. Empty when Supabase is unconfigured.
  /// NOTE: a non-empty URL does NOT mean the function is deployed —
  /// a 404 falls back honestly (see explanation_service.dart).
  static const explainFunctionUrlOverride =
      String.fromEnvironment('EXPLAIN_FUNCTION_URL', defaultValue: '');
  static String get explainEndpoint => explainFunctionUrlOverride.isNotEmpty
      ? explainFunctionUrlOverride
      : (supabaseUrl.isEmpty
          ? ''
          : '$supabaseUrl/functions/v1/explain-question');

  /// Edge Function that lists guide bank rows (chapter lists +
  /// model-test set metadata). Override with
  /// --dart-define=GUIDE_BANK_FUNCTION_URL=...; otherwise derived
  /// from SUPABASE_URL. NOTE: a non-empty URL does NOT mean the
  /// function is deployed — a 404 falls back honestly (the bank
  /// service returns null => unavailable state, never demo data).
  static const guideBankFunctionUrlOverride =
      String.fromEnvironment('GUIDE_BANK_FUNCTION_URL', defaultValue: '');
  static String get guideBankEndpoint =>
      guideBankFunctionUrlOverride.isNotEmpty
          ? guideBankFunctionUrlOverride
          : (supabaseUrl.isEmpty
              ? ''
              : '$supabaseUrl/functions/v1/guide-bank');

  /// True when NO backend is configured - the app must show DEMO mode
  /// and keep working on local mock data instead of crashing.
  static bool get demoMode => !supabaseConfigured;
}
