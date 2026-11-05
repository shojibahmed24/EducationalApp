// Gemini Live voice - PREMIUM-ONLY and ISOLATED.
// Called ONLY from VoiceTutorScreen, never from lesson, practice,
// quiz or text chat screens. NO audio is stored anywhere.
// No key lives in the app (2026-10-30: keys moved server-side):
// the live audio transport is unwired, so every session is a
// local timed DEMO practice session, labelled as such and never
// presented as a Gemini Live call. The timed session + budget
// counting are real. VoiceState.ready is currently unreachable;
// it activates only when the ephemeral-token endpoint + live
// transport land (see BACKEND_DETAILS_LIST.md).
import '../models/backend_models.dart';
import 'app_config.dart';
import 'auth_service.dart';
import 'billing_service.dart';
import 'local_store.dart';
import 'supabase_client.dart';

enum VoiceState { ready, demo, notPremium, noMinutes }

class AiVoiceService {
  Future<VoiceBudget> budget() async {
    final used = await LocalStore.voiceUsedMinutes();
    return VoiceBudget(
      usedMinutes: used,
      capMinutes: AppConfig.voiceCapMinutesPerPeriod,
    );
  }

  /// Voice gate, in order. (1) Real premium: minutes checked,
  /// then demo (live transport unwired — never ready). (2) DEMO-ONLY
  /// test path: in DEMO mode with the Settings DEMO test switch
  /// ON, the gate opens for testing — but the session is ALWAYS
  /// VoiceState.demo, never ready, even if a Gemini key happens
  /// to be set, so a test session can never be presented as a
  /// live Gemini call or as real premium. The 30-min budget
  /// still applies on the test path. (3) Otherwise notPremium.
  Future<VoiceState> canStartCall() async {
    if (await billingService.isPremium()) {
      if (!(await budget()).hasMinutes) return VoiceState.noMinutes;
      return VoiceState.demo;
    }
    if (await billingService.isDemoVoiceTestEnabled()) {
      if (!(await budget()).hasMinutes) return VoiceState.noMinutes;
      return VoiceState.demo;
    }
    return VoiceState.notPremium;
  }

  /// Gate only: returns the session kind. The screen owns the
  /// timer; endCall() owns the minute count. Nothing here fakes
  /// audio, and no path yields `ready` until live transport lands.
  Future<VoiceState> startCall() => canStartCall();

  /// Local minutes are always counted (period-aware, see
  /// LocalStore). The server row is written ONLY when a live
  /// Supabase auth uid exists: voice_sessions.user_id is NOT NULL,
  /// a uuid FK to profiles(id), and RLS requires
  /// auth.uid() = user_id, so only that uid can pass. The local
  /// session id is deliberately NOT used here: in DEMO it is the
  /// non-uuid string 'demo-user', and without a Supabase session
  /// RLS would reject any id anyway. With no uid the server
  /// insert is honestly skipped instead of sending a row that
  /// must fail (the old code inserted without user_id and its
  /// failure was swallowed by catch). A missing profiles row can
  /// still fail the FK; then too the local count stands.
  Future<void> endCall(int minutesUsed) async {
    if (minutesUsed > 0) {
      await LocalStore.addVoiceMinutes(minutesUsed);
    }
    final client = supabaseOrNull;
    final userId = authService.currentUserId;
    if (client == null || userId == null) return;
    try {
      await client.from('voice_sessions').insert({
        'user_id': userId,
        'minutes_used': minutesUsed,
      });
    } catch (_) {
      // Server log failed: minutes are already counted locally.
    }
  }
}

final aiVoiceService = AiVoiceService();
