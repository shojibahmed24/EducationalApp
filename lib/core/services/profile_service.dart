// Profile creation from the registration wizard.
// Supabase: upsert into profiles (guardian included since migration
// 014; parent_links is history only and no longer written).
// Local: the same data is always saved as JSON (LocalStore) so the
// home/profile screens show the registered user even when Supabase
// is unconfigured or unreachable. A Supabase failure NEVER blocks
// registration success once the local copy is saved - Step 13
// labels that case honestly as "online sync pending".
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../features/registration/registration_data.dart';
import 'auth_service.dart';
import 'local_store.dart';
import 'profile_source.dart';
import 'supabase_client.dart';

/// Outcome of a profile save. `localSaved` is what decides success:
/// home/profile screens read the local copy. `supabasePending` means
/// the local copy exists but the Supabase upsert did not go through.
class ProfileSaveResult {
  final bool localSaved;
  final bool supabaseAttempted;
  final bool supabaseSaved;
  const ProfileSaveResult({
    required this.localSaved,
    required this.supabaseAttempted,
    required this.supabaseSaved,
  });

  bool get saved => localSaved;
  bool get supabasePending => supabaseAttempted && !supabaseSaved;
}

/// True when the last registration save kept only a local copy and
/// the Supabase upsert failed. Step 13 reads this to label the
/// outcome honestly; it is in-memory only, for the step 12 -> 13
/// transition, not a retry queue.
final ValueNotifier<bool> profileSupabasePendingNotifier = ValueNotifier<bool>(
  false,
);

class ProfileService {
  /// Single source of truth for the student's class (batch 2,
  /// item 3). Home, Settings and Profile must all read the SAME
  /// saved profile key ('school_class' in LocalStore's
  /// demo_profile_json, via loadProfile) — never a hardcoded
  /// class, and never a second copy. The value is parsed
  /// defensively: registration and Settings write an int, but a
  /// String ('6') from any other writer must not silently drop
  /// the class (the old Home top bar only accepted `is int`, so
  /// a String class showed as "no class" on Home while Settings
  /// still showed it). Null / unparseable = no class chosen.
  static int? parseSchoolClass(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// The saved class, or null when no class has been chosen yet.
  Future<int?> loadSchoolClass() async {
    final profile = await loadProfile();
    if (profile == null) return null;
    return parseSchoolClass(profile['school_class']);
  }

  /// Remote shape: exactly the public.profiles columns. Guardian is
  /// a profiles column since migration 014 (it used to live in
  /// parent_links only), so it belongs in the upsert like any other
  /// field - and the login backfill can heal older local copies.
  Map<String, dynamic> toMap(RegistrationData d, String userId) {
    return {
      'id': userId,
      'full_name': d.fullName,
      'nickname': d.nickname,
      'gender': d.gender,
      'school_class': d.schoolClass,
      'medium': d.medium,
      'school_name': d.schoolName,
      'district': d.district,
      'phone': d.phone,
      'email': d.email,
      'daily_goal_minutes': d.dailyGoalMinutes,
      'guardian_name': d.guardianName,
      'guardian_phone': d.guardianPhone,
    };
  }

  /// Saved profile (local copy, or the last Supabase-synced copy).
  /// Profile + Settings screens read this, so an edit made in Settings
  /// shows on Profile immediately and survives a restart.
  Future<Map<String, dynamic>?> loadProfile() async {
    final json = await LocalStore.readProfile();
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) {
        profileNotifier.value = Map<String, dynamic>.of(decoded);
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// Edit name / school / daily goal / class / guardian from
  /// Settings (the ONLY place class may change). Merges into the
  /// saved profile, tries a Supabase upsert when configured, and
  /// always keeps the local copy so the edit is never lost. Returns
  /// false only when Supabase was configured but the upsert failed.
  /// Guardian keys are profiles columns since migration 014, so they
  /// flow through the remote map like name/school (profile_source
  /// builds the remote map from the real column list, with an avatar
  /// retry). Null params leave the field untouched.
  Future<bool> updateProfileFields({
    String? fullName,
    String? schoolName,
    int? dailyGoalMinutes,
    int? schoolClass,
    String? guardianName,
    String? guardianPhone,
    // Batch 2, item 6: picture keys. avatarUrl sets the remote URL;
    // clearAvatarUrl drops it (new picture kept local-only);
    // clearAvatar drops both picture keys (remove-photo action).
    String? avatarLocalPath,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    bool clearAvatar = false,
  }) async {
    final current = await loadProfile() ?? <String, dynamic>{};
    if (fullName != null) current['full_name'] = fullName;
    if (schoolName != null) current['school_name'] = schoolName;
    if (dailyGoalMinutes != null) {
      current['daily_goal_minutes'] = dailyGoalMinutes;
    }
    if (schoolClass != null) current['school_class'] = schoolClass;
    if (guardianName != null) current['guardian_name'] = guardianName;
    if (guardianPhone != null) current['guardian_phone'] = guardianPhone;
    if (clearAvatar) {
      current.remove('avatar_local_path');
      current.remove('avatar_url');
    } else {
      if (avatarLocalPath != null) {
        current['avatar_local_path'] = avatarLocalPath;
      }
      if (clearAvatarUrl) current.remove('avatar_url');
      if (avatarUrl != null) current['avatar_url'] = avatarUrl;
    }
    await LocalStore.saveProfile(jsonEncode(current));
    profileNotifier.value = Map<String, dynamic>.of(current);
    final client = supabaseOrNull;
    if (client == null) return true;
    final remote = <String, dynamic>{
      for (final k in profileRemoteColumns)
        if (current.containsKey(k)) k: current[k],
    };
    return upsertProfileRemote(client, remote);
  }

  /// Persist the wizard data. [userId] should be the id from Step 12
  /// sign-up when one exists, so the profile row id matches the saved
  /// session (falling back to the signed-in user, then 'demo-user').
  /// Local save always happens first in effect: the local copy holds
  /// every wizard field, including guardian name/phone, which the
  /// profiles table holds too since migration 014. Supabase is
  /// attempted when configured (profiles upsert, guardian included);
  /// on failure the local copy is kept and the result reports
  /// supabasePending instead of failing registration. Never throws.
  Future<ProfileSaveResult> createProfile(
    RegistrationData d, {
    String? userId,
  }) async {
    final effectiveId = userId ?? authService.currentUserId ?? 'demo-user';
    final remote = toMap(d, effectiveId);
    // Batch 2, item 6: a re-registration must not wipe a picture set
    // earlier — avatar keys live in the same profile JSON, so carry
    // them into the new local copy (remote upsert ignores them
    // except avatar_url, which is a real column after migration 006).
    final existing = await loadProfile();
    final local = <String, dynamic>{
      ...remote,
      'guardian_name': d.guardianName,
      'guardian_phone': d.guardianPhone,
      if (existing != null && existing['avatar_local_path'] is String)
        'avatar_local_path': existing['avatar_local_path'],
      if (existing != null && existing['avatar_url'] is String)
        'avatar_url': existing['avatar_url'],
    };
    Future<bool> saveLocal() async {
      try {
        await LocalStore.saveProfile(jsonEncode(local));
        profileNotifier.value = Map<String, dynamic>.of(local);
        return true;
      } catch (_) {
        return false;
      }
    }

    final client = supabaseOrNull;
    if (client == null) {
      final ok = await saveLocal();
      profileSupabasePendingNotifier.value = false;
      return ProfileSaveResult(
        localSaved: ok,
        supabaseAttempted: false,
        supabaseSaved: false,
      );
    }
    try {
      // profiles upsert only: parent_links is history from migration
      // 014 on and is no longer written (its latest row per student
      // was backfilled into the guardian columns by the migration).
      await client.from('profiles').upsert(remote);
      final ok = await saveLocal();
      profileSupabasePendingNotifier.value = false;
      return ProfileSaveResult(
        localSaved: ok,
        supabaseAttempted: true,
        supabaseSaved: true,
      );
    } catch (_) {
      // Supabase failed: keep the local copy, do not lose registration,
      // and do not block Step 13 on the network failure.
      final ok = await saveLocal();
      profileSupabasePendingNotifier.value = ok;
      return ProfileSaveResult(
        localSaved: ok,
        supabaseAttempted: true,
        supabaseSaved: false,
      );
    }
  }
}

final profileService = ProfileService();
