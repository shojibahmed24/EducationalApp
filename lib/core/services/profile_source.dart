// Batch 2, item 6: the single profile source, shared by
// profile_service and every screen that shows a name or picture.
// One stored JSON (LocalStore demo_profile_json) + this broadcast:
// readers use loadProfile() or profileNotifier, never their own
// stored name/picture copy. Field keys live here exactly once.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Broadcast of the saved profile. Every profile write updates it,
/// so Profile/Settings refresh the moment an edit lands instead of
/// showing an initState copy until reopened.
final ValueNotifier<Map<String, dynamic>?> profileNotifier =
    ValueNotifier<Map<String, dynamic>?>(null);

/// Canonical profile field readers. Local path is device-only; the
/// remote URL is the Supabase Storage public URL ('' = none).
class ProfileFields {
  static String name(Map<String, dynamic>? p) =>
      (p?['full_name'] as String?) ?? '';
  static String? localPicture(Map<String, dynamic>? p) =>
      p?['avatar_local_path'] as String?;
  static String? remotePicture(Map<String, dynamic>? p) {
    final u = p?['avatar_url'] as String?;
    return (u == null || u.isEmpty) ? null : u;
  }
}

/// Columns the profiles table actually has (migrations 001 + 006
/// + 014). An upsert is built from this list only, so local-only
/// keys (avatar_local_path) can never fail a cloud save. Guardian
/// joined this list with migration 014; until 014 is applied live,
/// an upsert carrying guardian keys fails (local copy still kept),
/// while profiles without guardian values upsert as before.
const profileRemoteColumns = {
  'id',
  'full_name',
  'nickname',
  'gender',
  'school_class',
  'medium',
  'school_name',
  'district',
  'phone',
  'email',
  'daily_goal_minutes',
  'avatar_url',
  'guardian_name',
  'guardian_phone',
};

/// Upsert [remote]; if it fails only because the live table has no
/// avatar_url column yet (migration 006 unapplied), retry without
/// it so a name edit is never blocked by the picture.
Future<bool> upsertProfileRemote(
  SupabaseClient client,
  Map<String, dynamic> remote,
) async {
  try {
    await client.from('profiles').upsert(remote);
    return true;
  } catch (_) {
    if (!remote.containsKey('avatar_url')) return false;
    try {
      await client.from('profiles').upsert(
        Map<String, dynamic>.of(remote)..remove('avatar_url'),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
