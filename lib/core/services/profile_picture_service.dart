// Batch 2, item 6: Settings profile picture.
// Pick (gallery/camera) -> copy into app documents -> save the path
// in the SAME profile JSON every screen reads (profile_service /
// LocalStore demo_profile_json, keys avatar_local_path/avatar_url —
// never a second copy) -> best-effort Supabase Storage upload when
// signed in and configured. Upload failure, DEMO mode, picker cancel
// and permission denial are all non-crashes: the local picture is
// kept and the caller is told honestly that no upload happened.
// Crop: image_picker has no crop step, so there is none — the avatar
// widget clips the image to a circle, which is the square crop the
// eye sees. A real cropper (image_cropper + native config) is a
// separate, explicitly-scoped addition, not silently faked here.
//
// Migration 014 follow-up: the server copy is no longer fire-and-
// forget. A local-only photo (upload never succeeded) gets one more
// upload attempt after sign-in restore, and removing a photo deletes
// the Storage object AND clears avatar_url explicitly — otherwise a
// fresh install would resurrect a deleted photo from a stale URL.
// Storage calls go through PictureBackend so tests can use a fake
// without initialising Supabase.
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'profile_source.dart';
import 'supabase_client.dart';

const _avatarBucket = 'avatars';

/// Server side of avatar storage, behind an interface so tests can
/// use a fake without initialising Supabase.
abstract class PictureBackend {
  String? get currentUserId;
  Future<void> uploadAvatar(String userId, Uint8List bytes);
  String publicAvatarUrl(String userId);
  Future<void> removeAvatar(String userId);
  Future<bool> saveAvatarUrl(String userId, String url);
}

/// Real backend: the signed-in user's own '<uid>/avatar.jpg' object
/// (Storage policies restrict each user to their own path). Throws
/// when Supabase is not initialised, so callers must treat every
/// call as best-effort — except saveAvatarUrl, which returns false.
class SupabasePictureBackend implements PictureBackend {
  @override
  String? get currentUserId => authService.currentUserId;

  SupabaseClient _client() {
    final client = supabaseOrNull;
    if (client == null) throw StateError('Supabase not initialised');
    return client;
  }

  @override
  Future<void> uploadAvatar(String userId, Uint8List bytes) async {
    await _client().storage.from(_avatarBucket).uploadBinary(
          '$userId/avatar.jpg',
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
  }

  @override
  String publicAvatarUrl(String userId) =>
      _client().storage.from(_avatarBucket).getPublicUrl('$userId/avatar.jpg');

  @override
  Future<void> removeAvatar(String userId) async {
    await _client().storage.from(_avatarBucket).remove(['$userId/avatar.jpg']);
  }

  @override
  Future<bool> saveAvatarUrl(String userId, String url) async {
    final client = supabaseOrNull;
    if (client == null) return false;
    return upsertProfileRemote(client, {'id': userId, 'avatar_url': url});
  }
}

/// Outcome of a picture pick. [cancelled] = user backed out (no
/// change, no message). [denied] = permission refused. [unavailable]
/// = picker/camera/storage failed. [picked] carries the saved paths;
/// [uploaded] is true ONLY when the Storage upload really succeeded.
enum PictureOutcome { picked, cancelled, denied, unavailable }

class PictureResult {
  final PictureOutcome outcome;
  final String? localPath;
  final String? remoteUrl;
  final bool uploaded;
  const PictureResult({
    required this.outcome,
    this.localPath,
    this.remoteUrl,
    this.uploaded = false,
  });
  const PictureResult.cancelled() : this(outcome: PictureOutcome.cancelled);
  const PictureResult.denied() : this(outcome: PictureOutcome.denied);
  const PictureResult.unavailable()
      : this(outcome: PictureOutcome.unavailable);
}

class ProfilePictureService {
  static const _fileName = 'profile_picture.jpg';

  final PictureBackend _backend;
  ProfilePictureService({PictureBackend? backend})
      : _backend = backend ?? SupabasePictureBackend();

  final ImagePicker _picker = ImagePicker();

  /// Pick, store locally, and upload when possible. Never throws:
  /// every failure maps to a PictureResult the UI can report.
  Future<PictureResult> pickAndSave(ImageSource source) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      // image_picker reports refusals with these codes; anything
      // else (no camera, missing activity) is 'unavailable'.
      if (e.code.contains('denied') || e.code.contains('permission')) {
        return const PictureResult.denied();
      }
      return const PictureResult.unavailable();
    } catch (_) {
      return const PictureResult.unavailable();
    }
    if (picked == null) return const PictureResult.cancelled();

    String localPath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saved = await File(picked.path).copy('${dir.path}/$_fileName');
      localPath = saved.path;
    } catch (_) {
      return const PictureResult.unavailable();
    }

    // Best-effort upload: signed-in Supabase user only. Any failure
    // (no bucket, no policy, offline) keeps the local picture and
    // reports uploaded=false — the UI must say so, never claim an
    // upload. The old remote URL is cleared for a local-only picture
    // so Profile never shows the previous person's photo.
    String? remoteUrl;
    var uploaded = false;
    final userId = _backend.currentUserId;
    if (userId != null && userId != 'demo-user') {
      try {
        final bytes = await File(localPath).readAsBytes();
        await _backend.uploadAvatar(userId, bytes);
        remoteUrl = _backend.publicAvatarUrl(userId);
        uploaded = true;
      } catch (_) {
        uploaded = false;
      }
    }
    await profileService.updateProfileFields(
      avatarLocalPath: localPath,
      avatarUrl: remoteUrl,
      clearAvatarUrl: !uploaded,
    );
    return PictureResult(
      outcome: PictureOutcome.picked,
      localPath: localPath,
      remoteUrl: remoteUrl,
      uploaded: uploaded,
    );
  }

  /// Retry a local-only photo upload (called after sign-in restore).
  /// True only when the upload really succeeded and the URL was
  /// saved; every other case — no local file, remote URL already
  /// present, not signed in, upload failure — returns false and
  /// never throws, so login can never break on a picture.
  Future<bool> retryUploadIfLocalOnly() async {
    try {
      final userId = _backend.currentUserId;
      if (userId == null || userId == 'demo-user') return false;
      final profile = await profileService.loadProfile();
      final localPath = ProfileFields.localPicture(profile);
      if (localPath == null) return false;
      if (ProfileFields.remotePicture(profile) != null) return false;
      final file = File(localPath);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      await _backend.uploadAvatar(userId, bytes);
      final url = _backend.publicAvatarUrl(userId);
      await profileService.updateProfileFields(avatarUrl: url);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove-photo: delete the local copy, the Storage object, and
  /// the server URL. The explicit '' upsert matters: clearAvatar
  /// omits avatar_url from its upsert, which would leave the old
  /// server value untouched as a stale URL. Never throws.
  Future<void> removePicture() async {
    try {
      final profile = await profileService.loadProfile();
      final path = ProfileFields.localPicture(profile);
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    final userId = _backend.currentUserId;
    if (userId != null && userId != 'demo-user') {
      try {
        await _backend.removeAvatar(userId);
      } catch (_) {}
    }
    await profileService.updateProfileFields(clearAvatar: true);
    if (userId != null && userId != 'demo-user') {
      try {
        await _backend.saveAvatarUrl(userId, '');
      } catch (_) {}
    }
  }
}

final profilePictureService = ProfilePictureService();
