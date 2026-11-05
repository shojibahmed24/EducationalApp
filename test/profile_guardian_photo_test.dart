// Migration 014 tests: guardian is a server field, photo reliability.
// - guardian round-trip: server->phone restore merge, phone->server
//   backfill, Settings edit saves guardian locally (server upsert is
//   the same remote map, covered by the backfill assertion).
// - photo retry-upload after restore, and removal clearing remote.
// All fakes; no live database, no Supabase initialisation.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/services/google_profile.dart';
import 'package:yes_sir_ai/core/services/local_store.dart';
import 'package:yes_sir_ai/core/services/profile_picture_service.dart';
import 'package:yes_sir_ai/core/services/profile_restore_service.dart';
import 'package:yes_sir_ai/core/services/profile_service.dart';

class FakeGuardianBackend implements ProfileRestoreBackend {
  String? uid;
  Map<String, dynamic>? profileRow;
  Map<String, dynamic>? lastUpsert;

  FakeGuardianBackend({this.uid});

  @override
  String? get currentUserId => uid;

  @override
  GoogleSignInInfo? get currentGoogleUser => null;

  @override
  Future<Map<String, dynamic>?> fetchProfileRow() async => profileRow;

  @override
  Future<bool> upsertProfileRow(Map<String, dynamic> remote) async {
    lastUpsert = remote;
    return true;
  }

  @override
  Future<List<String>> fetchSavedQuestionIds() async => [];

  @override
  Future<Map<String, int>?> fetchProgressRow() async => null;
}

class FakePictureBackend implements PictureBackend {
  String? uid;
  String cannedUrl;
  List<String> uploads = [];
  List<int> uploadedBytes = [];
  List<String> removals = [];
  Map<String, String> savedUrls = {};

  FakePictureBackend({this.uid, this.cannedUrl = 'https://cdn.test/a.jpg'});

  @override
  String? get currentUserId => uid;

  @override
  Future<void> uploadAvatar(String userId, Uint8List bytes) async {
    uploads.add(userId);
    uploadedBytes.add(bytes.length);
  }

  @override
  String publicAvatarUrl(String userId) => cannedUrl;

  @override
  Future<void> removeAvatar(String userId) async {
    removals.add(userId);
  }

  @override
  Future<bool> saveAvatarUrl(String userId, String url) async {
    savedUrls[userId] = url;
    return true;
  }
}

Future<File> _tempPhoto(List<int> bytes) async {
  final dir = await Directory.systemTemp.createTemp('avatar_test');
  final file = File('${dir.path}/pic.jpg');
  await file.writeAsBytes(bytes);
  addTearDown(() async {
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });
  return file;
}

Future<Map<String, dynamic>> _localProfile() async {
  final json = await LocalStore.readProfile();
  return jsonDecode(json!) as Map<String, dynamic>;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('guardian merge: server guardian wins over local', () {
    final merged = mergeServerProfile(
      {'guardian_name': 'Server Abba', 'guardian_phone': '111'},
      {'guardian_name': 'Local Abba', 'guardian_phone': '222'},
    );
    expect(merged['guardian_name'], 'Server Abba');
    expect(merged['guardian_phone'], '111');
  });

  test('guardian merge: local guardian survives when server lacks it',
      () {
    final merged = mergeServerProfile(
      {'full_name': 'S'},
      {'guardian_name': 'Abba', 'guardian_phone': '999'},
    );
    expect(merged['guardian_name'], 'Abba');
    expect(merged['guardian_phone'], '999');
  });

  test('guardian backfill: missing server row carries guardian up',
      () async {
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'id': 'demo-user',
        'full_name': 'Local Name',
        'guardian_name': 'Abba',
        'guardian_phone': '01700000000',
      }),
    });
    final backend = FakeGuardianBackend(uid: 'real-uid-9')..profileRow = null;
    final res = await ProfileRestoreService(backend: backend)
        .restoreAfterSignIn();
    expect(res.profileBackfilled, isTrue);
    expect(backend.lastUpsert!['id'], 'real-uid-9');
    expect(backend.lastUpsert!['guardian_name'], 'Abba');
    expect(backend.lastUpsert!['guardian_phone'], '01700000000');
  });

  test('guardian edit: updateProfileFields saves guardian locally',
      () async {
    final ok = await profileService.updateProfileFields(
      guardianName: 'Maa',
      guardianPhone: '01800000000',
    );
    expect(ok, isTrue);
    final saved = await _localProfile();
    expect(saved['guardian_name'], 'Maa');
    expect(saved['guardian_phone'], '01800000000');
  });

  test('photo retry: local-only photo uploads and saves URL', () async {
    final photo = await _tempPhoto([1, 2, 3, 4]);
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'avatar_local_path': photo.path,
      }),
    });
    final backend = FakePictureBackend(uid: 'uid-1');
    final ok =
        await ProfilePictureService(backend: backend).retryUploadIfLocalOnly();
    expect(ok, isTrue);
    expect(backend.uploads, ['uid-1']);
    expect(backend.uploadedBytes, [4]);
    expect((await _localProfile())['avatar_url'], backend.cannedUrl);
  });

  test('photo retry: skips when a remote URL already exists', () async {
    final photo = await _tempPhoto([1, 2, 3]);
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'avatar_local_path': photo.path,
        'avatar_url': 'https://cdn.test/old.jpg',
      }),
    });
    final backend = FakePictureBackend(uid: 'uid-1');
    final ok =
        await ProfilePictureService(backend: backend).retryUploadIfLocalOnly();
    expect(ok, isFalse);
    expect(backend.uploads, isEmpty);
  });

  test('photo retry: skips when not signed in', () async {
    final photo = await _tempPhoto([1, 2, 3]);
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'avatar_local_path': photo.path,
      }),
    });
    final backend = FakePictureBackend(uid: null);
    final ok =
        await ProfilePictureService(backend: backend).retryUploadIfLocalOnly();
    expect(ok, isFalse);
    expect(backend.uploads, isEmpty);
  });

  test('photo retry: skips when the local file is gone', () async {
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'avatar_local_path': '/tmp/does-not-exist-avatar.jpg',
      }),
    });
    final backend = FakePictureBackend(uid: 'uid-1');
    final ok =
        await ProfilePictureService(backend: backend).retryUploadIfLocalOnly();
    expect(ok, isFalse);
    expect(backend.uploads, isEmpty);
  });

  test('photo removal: deletes storage object and clears remote URL',
      () async {
    final photo = await _tempPhoto([9, 9]);
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'avatar_local_path': photo.path,
        'avatar_url': 'https://cdn.test/old.jpg',
      }),
    });
    final backend = FakePictureBackend(uid: 'uid-1');
    await ProfilePictureService(backend: backend).removePicture();
    expect(await photo.exists(), isFalse);
    expect(backend.removals, ['uid-1']);
    expect(backend.savedUrls['uid-1'], '');
    final saved = await _localProfile();
    expect(saved.containsKey('avatar_local_path'), isFalse);
    expect(saved.containsKey('avatar_url'), isFalse);
  });

  test('photo removal: demo user clears local only, no remote calls',
      () async {
    final photo = await _tempPhoto([9, 9]);
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'avatar_local_path': photo.path,
        'avatar_url': 'https://cdn.test/old.jpg',
      }),
    });
    final backend = FakePictureBackend(uid: 'demo-user');
    await ProfilePictureService(backend: backend).removePicture();
    expect(backend.removals, isEmpty);
    expect(backend.savedUrls, isEmpty);
    expect((await _localProfile()).containsKey('avatar_url'), isFalse);
  });
}
