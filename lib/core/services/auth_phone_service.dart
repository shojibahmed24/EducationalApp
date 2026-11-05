// Phone OTP via the Supabase SDK (real SMS path).
// Requires a Twilio / Vonage provider configured in the Supabase
// dashboard (see BACKEND_DETAILS_LIST.md). Without one, Supabase
// returns an error, which callers show honestly — never faked as
// success. In DEMO mode (backend unconfigured) these return the
// labelled DEMO results like the other auth methods; otp_screen.dart
// keeps its local DEMO completion and does not call these in DEMO.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supabase_client.dart';

/// E.164 phone check: '+' followed by 7-15 digits, first digit
/// non-zero. Supabase requires international format; a local 01…
/// number is rejected with a plain format error, never guessed.
bool isValidE164Phone(String phone) {
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone);
}

class AuthPhoneService {
  /// Sends a 6-digit SMS code to [phone] (E.164 format).
  Future<AuthResult> sendPhoneOtp(String phone) async {
    final client = supabaseOrNull;
    if (client == null) {
      return const AuthResult(ok: true, mode: AuthMode.demo);
    }
    try {
      await client.auth.signInWithOtp(phone: phone);
      return const AuthResult(ok: true, mode: AuthMode.supabase);
    } on AuthException catch (e) {
      return AuthResult(ok: false, error: e.message, mode: AuthMode.supabase);
    }
  }

  /// Verifies [code] for [phone]. On success Supabase establishes a
  /// session (verifyOTP throws when no session results), so the
  /// caller may treat the user as signed in.
  Future<AuthResult> verifyPhoneOtp(String phone, String code) async {
    final client = supabaseOrNull;
    if (client == null) {
      return const AuthResult(ok: true, userId: 'demo-user', mode: AuthMode.demo);
    }
    try {
      final res = await client.auth.verifyOTP(
        phone: phone,
        token: code,
        type: OtpType.sms,
      );
      return AuthResult(
        ok: res.user != null,
        userId: res.user?.id,
        mode: AuthMode.supabase,
      );
    } on AuthException catch (e) {
      return AuthResult(ok: false, error: e.message, mode: AuthMode.supabase);
    }
  }
}

final authPhoneService = AuthPhoneService();
