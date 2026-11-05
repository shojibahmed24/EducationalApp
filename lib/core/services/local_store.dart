// Local fallback store (DEMO mode + offline cache).
// Uses SharedPreferences so DEMO data survives a restart and is not lost.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'saved_sync_service.dart';

class LocalStore {
  static const _profileKey = 'demo_profile_json';
  static const _savedKey = 'saved_questions';
  static const _premiumKey = 'demo_premium';
  static const _voiceUsedKey = 'voice_used_minutes';
  static const _voicePeriodKey = 'voice_period_key';

  static Future<void> saveProfile(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, json);
  }

  static Future<String?> readProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileKey);
  }

  static Future<List<String>> savedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedKey) ?? const [];
  }

  /// Overwrites the saved-question list wholesale. Used ONLY by the
  /// sign-in restore (server pull unions with local, then writes
  /// once) — never by save/unsave, which sync one id at a time.
  static Future<void> setSavedQuestions(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedKey, ids);
  }

  /// Cached server progress row (streak/chapters/average) written by
  /// the sign-in restore, so a fresh install still shows progress
  /// when the server is unreachable at summary time. Live server
  /// data always wins over this cache; it is only an offline
  /// fallback, never a second source of truth.
  static const _serverProgressKey = 'ys_server_progress_json';

  static Future<void> saveServerProgress(Map<String, int> row) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverProgressKey, jsonEncode(row));
  }

  static Future<Map<String, int>?> readServerProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_serverProgressKey);
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) return null;
      return {
        'streak_days': (decoded['streak_days'] as num?)?.toInt() ?? 0,
        'chapters_done': (decoded['chapters_done'] as num?)?.toInt() ?? 0,
        'average_score': (decoded['average_score'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return null;
    }
  }

  /// Saves [id]; returns true only when it was newly added.
  /// A repeat save is a no-op returning false, so callers must
  /// not claim 'saved' on a duplicate tap (H3). List is copied
  /// first: the empty fallback is const and cannot be appended to.
  static Future<bool> saveQuestion(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(await savedQuestions());
    if (list.contains(id)) return false;
    list.add(id);
    await prefs.setStringList(_savedKey, list);
    // Phase 16 (M10): local first, then a best-effort cloud write.
    await savedSyncService.syncSave(id);
    return true;
  }

  /// Removes [id]; returns true only when it was actually present.
  static Future<bool> unsaveQuestion(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(await savedQuestions());
    final removed = list.remove(id);
    if (removed) {
      await prefs.setStringList(_savedKey, list);
      await savedSyncService.syncUnsave(id);
    }
    return removed;
  }

  /// DEMO voice-gate test flag ONLY (item 7), stored under the
  /// legacy 'demo_premium' key. It is NOT a premium entitlement
  /// and must never be read as one: BillingService.isPremium()
  /// never reads it, and isDemoVoiceTestEnabled() only honours
  /// it in DEMO mode. Default false; sign-out clears it.
  static Future<bool> isPremiumLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  static Future<void> setPremiumLocal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
  }

  /// Current local period key: calendar month (YYYY-MM, local
  /// time). The server voice_minute_budgets table keys by
  /// period_start date instead; when a server-verified
  /// subscription period exists it is the source of truth and
  /// this local key is only the DEMO/offline fallback.
  static String currentVoicePeriodKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Minutes used in the CURRENT period only. When the stored
  /// period differs from the current month the counter resets to
  /// 0 — 30 min/month, not 30 min/lifetime. First run after this
  /// change has no stored period: the old lifetime count is kept
  /// for the current month only, then resets next month.
  static Future<int> voiceUsedMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_voicePeriodKey);
    final current = currentVoicePeriodKey();
    if (stored == null) {
      await prefs.setString(_voicePeriodKey, current);
      return prefs.getInt(_voiceUsedKey) ?? 0;
    }
    if (stored != current) {
      await prefs.setString(_voicePeriodKey, current);
      await prefs.setInt(_voiceUsedKey, 0);
      return 0;
    }
    return prefs.getInt(_voiceUsedKey) ?? 0;
  }

  /// Phase 16 (M11): wipe one account's local data on sign-out so
  /// the next account does not inherit it. Keys owned by other
  /// stores are removed here by literal key (same strings those
  /// stores use) to avoid a core -> feature import cycle. KEPT on
  /// purpose: language, theme, font scale (device prefs, not user
  /// data) and onboarding-seen (device-level). Session + premium
  /// are cleared separately by AuthService.signOut; the parent PIN
  /// is cleared there via ParentPinStore.clearPin().
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in const [
      _profileKey,
      _savedKey,
      _premiumKey,
      _voiceUsedKey,
      _voicePeriodKey,
      'ys_reset_contact',
      // LearnStore (area2_*): lessons, chapters, saved ids, recents.
      'area2_lessons',
      'area2_lessons_today',
      'area2_today',
      'area2_chapters',
      'area2_saved_ids',
      'area2_recent_books',
      'area2_recent_searches',
      'area2_last_lesson',
      'area2_photo_notes',
      // PracticeStore: saved attempts + activity dates.
      'ys_attempts_json',
      'ys_activity_dates',
      // Cached server progress row (per-account, must not leak
      // to the next account like the other keys above).
      _serverProgressKey,
      // Notifications read/cleared state (per-account view state).
      'ys_notif_read',
      'ys_notif_cleared',
    ]) {
      await prefs.remove(key);
    }
  }

  static Future<void> addVoiceMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final used = await voiceUsedMinutes();
    await prefs.setString(_voicePeriodKey, currentVoicePeriodKey());
    await prefs.setInt(_voiceUsedKey, used + minutes);
  }
}
