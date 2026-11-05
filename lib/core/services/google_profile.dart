// Google sign-in profile data (2026-11-01 full Google sign-in).
// Google sends full_name + avatar_url, sometimes the older name +
// picture keys. Only remote columns are ever produced here, so
// guardian_* and avatar_local_path (local-only keys) can never
// come from Google and are never touched by the merge in
// profile_restore_service.dart. No schema is invented: avatar_url
// is an existing profiles column (migrations 001 + 006).
import 'profile_source.dart';

/// What the signed-in user carries from Google (null = not signed
/// in). Provider comes from appMetadata: 'google' for OAuth users,
/// 'email' for password users — the gate for Google-only seeding.
class GoogleSignInInfo {
  final String provider;
  final String? email;
  final Map<String, dynamic> metadata;
  const GoogleSignInInfo({
    required this.provider,
    this.email,
    required this.metadata,
  });
}

/// Google metadata → profile fields (pure, tested). Precedence:
/// full_name over name, avatar_url over picture, account email
/// over metadata email. Empty strings become absent, never stored.
/// The result holds remote columns only; callers fill empty local
/// fields from it and never overwrite guardian info or a local
/// photo (those keys are not in this map at all).
Map<String, dynamic> googleProfileFields(
  Map<String, dynamic> metadata,
  String? email,
) {
  final fields = <String, dynamic>{};
  final name =
      _nonEmpty(metadata['full_name']) ?? _nonEmpty(metadata['name']);
  if (name != null) fields['full_name'] = name;
  final photo =
      _nonEmpty(metadata['avatar_url']) ?? _nonEmpty(metadata['picture']);
  if (photo != null) fields['avatar_url'] = photo;
  final mail = _nonEmpty(email) ?? _nonEmpty(metadata['email']);
  if (mail != null) fields['email'] = mail;
  // Defence: only real profiles columns may leave this function.
  fields.removeWhere((k, _) => !profileRemoteColumns.contains(k));
  return fields;
}

String? _nonEmpty(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}
