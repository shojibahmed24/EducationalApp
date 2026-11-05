// Server-profile restore after a real-mode sign-in (2026-11-01
// login/profile-loss fix). Before this, name/class/progress lived
// ONLY in SharedPreferences and login never fetched the server
// profile, so a fresh install showed an empty profile even for a
// valid account. Restore runs after sign-in, before /home, never
// throws (each phase best-effort); DEMO users skip silently.
import 'dart:convert';
import 'google_profile.dart';
import 'local_store.dart';
import 'profile_picture_service.dart';
import 'profile_service.dart';
import 'profile_source.dart';
import 'supabase_client.dart';

/// Server side of a restore, behind an interface so tests can use
/// a fake without initialising Supabase.
abstract class ProfileRestoreBackend {
  String? get currentUserId;
  GoogleSignInInfo? get currentGoogleUser;
  Future<Map<String, dynamic>?> fetchProfileRow();
  Future<bool> upsertProfileRow(Map<String, dynamic> remote);
  Future<List<String>> fetchSavedQuestionIds();
  Future<Map<String, int>?> fetchProgressRow();
}

/// Real backend: the signed-in user's own rows (RLS: auth.uid()).
/// Query shape follows progress_service: select + limit(1) + first.
class SupabaseProfileRestoreBackend implements ProfileRestoreBackend {
  @override
  String? get currentUserId => supabaseOrNull?.auth.currentUser?.id;

  @override
  GoogleSignInInfo? get currentGoogleUser {
    final user = supabaseOrNull?.auth.currentUser;
    if (user == null) return null;
    return GoogleSignInInfo(
      provider: (user.appMetadata['provider'] as String?) ?? '',
      email: user.email,
      metadata: Map<String, dynamic>.from(user.userMetadata ?? {}),
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchProfileRow() async {
    final client = supabaseOrNull;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return null;
    final rows =
        await client.from('profiles').select().eq('id', uid).limit(1);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  @override
  Future<bool> upsertProfileRow(Map<String, dynamic> remote) async {
    final client = supabaseOrNull;
    if (client == null) return false;
    return upsertProfileRemote(client, remote);
  }

  @override
  Future<List<String>> fetchSavedQuestionIds() async {
    final client = supabaseOrNull;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return [];
    final rows = await client
        .from('saved_questions')
        .select('question_id')
        .eq('user_id', uid);
    return [
      for (final r in rows)
        if ((r as Map)['question_id'] is String) r['question_id'] as String,
    ];
  }

  @override
  Future<Map<String, int>?> fetchProgressRow() async {
    final client = supabaseOrNull;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return null;
    final rows = await client
        .from('progress')
        .select('streak_days, chapters_done, average_score')
        .eq('user_id', uid)
        .limit(1);
    if (rows.isEmpty) return null;
    final r = rows.first as Map;
    return {
      'streak_days': (r['streak_days'] as num?)?.toInt() ?? 0,
      'chapters_done': (r['chapters_done'] as num?)?.toInt() ?? 0,
      'average_score': (r['average_score'] as num?)?.toInt() ?? 0,
    };
  }
}

/// Merge rule (pure, tested): server columns win, EXCEPT local-only
/// keys (avatar_local_path, anything outside profileRemoteColumns);
/// nulls never clobber. Guardian (migration 014) merges like name.
Map<String, dynamic> mergeServerProfile(
  Map<String, dynamic> server,
  Map<String, dynamic>? local,
) {
  final merged = <String, dynamic>{};
  if (local != null) {
    for (final e in local.entries) {
      if (profileRemoteColumns.contains(e.key)) merged[e.key] = e.value;
    }
  }
  for (final e in server.entries) {
    if (profileRemoteColumns.contains(e.key) && e.value != null) {
      merged[e.key] = e.value;
    }
  }
  if (local != null) {
    for (final e in local.entries) {
      if (!profileRemoteColumns.contains(e.key)) merged[e.key] = e.value;
    }
  }
  return merged;
}

class ProfileRestoreResult {
  final bool skipped;
  final bool profileRestored;
  final bool profileBackfilled;
  final int savedCount;
  final bool progressCached;
  const ProfileRestoreResult({
    required this.skipped,
    required this.profileRestored,
    required this.profileBackfilled,
    required this.savedCount,
    required this.progressCached,
  });
}

class ProfileRestoreService {
  final ProfileRestoreBackend _backend;
  ProfileRestoreService({ProfileRestoreBackend? backend})
      : _backend = backend ?? SupabaseProfileRestoreBackend();

  /// Restores server data into local storage after sign-in.
  /// Never throws. DEMO users (null / 'demo-user' id) skip silently.
  Future<ProfileRestoreResult> restoreAfterSignIn() async {
    final uid = _backend.currentUserId;
    if (uid == null || uid == 'demo-user') {
      return const ProfileRestoreResult(
        skipped: true,
        profileRestored: false,
        profileBackfilled: false,
        savedCount: 0,
        progressCached: false,
      );
    }
    var restored = false;
    var backfilled = false;
    var savedCount = 0;
    var progressCached = false;
    // Phase 1: profile — server row wins, else backfill local up.
    try {
      final serverRow = await _backend.fetchProfileRow();
      final local = await profileService.loadProfile();
      if (serverRow != null) {
        final merged = mergeServerProfile(serverRow, local);
        merged['id'] = uid;
        await LocalStore.saveProfile(jsonEncode(merged));
        profileNotifier.value = Map<String, dynamic>.of(merged);
        restored = true;
      } else if (local != null && local.isNotEmpty) {
        // Heals the never-retried "online sync pending" case: a
        // local-only profile finally reaches the server. The id
        // MUST be the real uid, never a stale local 'demo-user'.
        final remote = <String, dynamic>{
          for (final k in profileRemoteColumns)
            if (local.containsKey(k)) k: local[k],
          'id': uid,
        };
        backfilled = await _backend.upsertProfileRow(remote);
        profileNotifier.value = Map<String, dynamic>.of(local);
      }
    } catch (_) {}
    // Phase 1b: retry a local-only photo upload (best-effort).
    try { await profilePictureService.retryUploadIfLocalOnly(); } catch (_) {}
    // Phase 2: saved questions — union, never wipe local saves.
    try {
      final serverIds = await _backend.fetchSavedQuestionIds();
      final localSaved = await LocalStore.savedQuestions();
      final union = <String>{...localSaved, ...serverIds}.toList();
      if (union.length != localSaved.length) {
        await LocalStore.setSavedQuestions(union);
      }
      savedCount = union.length;
    } catch (_) {}
    // Phase 3: progress row cached for the offline summary fallback.
    try {
      final row = await _backend.fetchProgressRow();
      if (row != null) {
        await LocalStore.saveServerProgress(row);
        progressCached = true;
      }
    } catch (_) {}
    return ProfileRestoreResult(
      skipped: false,
      profileRestored: restored,
      profileBackfilled: backfilled,
      savedCount: savedCount,
      progressCached: progressCached,
    );
  }

  /// First-Google-login bootstrap: after signedIn, before restore.
  /// Skips unless the user came via Google AND has no server row:
  /// then it seeds the local profile from Google metadata (fill-
  /// empty only) and upserts the same fields under the real uid.
  /// An existing server row always wins (restore merges it).
  /// Guardian info is not seeded from Google; the local photo path
  /// is device-only and never sent. Never throws.
  Future<bool> ensureGoogleProfile() async {
    final info = _backend.currentGoogleUser;
    final uid = _backend.currentUserId;
    final isGoogle = info != null && info.provider == 'google';
    if (!isGoogle || uid == null || uid == 'demo-user') return false;
    try {
      if (await _backend.fetchProfileRow() != null) return false;
      final local = await profileService.loadProfile() ?? <String, dynamic>{};
      final seed = googleProfileFields(info.metadata, info.email);
      var seeded = false;
      for (final e in seed.entries) {
        final cur = local[e.key];
        if (cur is! String || cur.trim().isEmpty) {
          local[e.key] = e.value;
          seeded = true;
        }
      }
      if (!seeded) return false;
      await LocalStore.saveProfile(jsonEncode(local));
      profileNotifier.value = Map<String, dynamic>.of(local);
      final remote = <String, dynamic>{'id': uid};
      for (final k in profileRemoteColumns) {
        if (local.containsKey(k) && local[k] != null) remote[k] = local[k];
      }
      await _backend.upsertProfileRow(remote);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final profileRestoreService = ProfileRestoreService();
