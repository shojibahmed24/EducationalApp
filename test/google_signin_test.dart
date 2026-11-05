// 2026-11-01 full Google sign-in tests:
// - Google metadata mapping (precedence, empty handling, no local keys)
// - first-Google-login bootstrap (seed + upsert, never overwrite)
// - no-fake-success contract (launch is not a login)
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yes_sir_ai/core/services/auth_service.dart';
import 'package:yes_sir_ai/core/services/google_profile.dart';
import 'package:yes_sir_ai/core/services/local_store.dart';
import 'package:yes_sir_ai/core/services/profile_restore_service.dart';

class FakeGoogleBackend implements ProfileRestoreBackend {
  String? uid;
  GoogleSignInInfo? googleUser;
  Map<String, dynamic>? profileRow;
  Map<String, dynamic>? lastUpsert;
  int upsertCalls = 0;

  FakeGoogleBackend({this.uid, this.googleUser});

  @override
  String? get currentUserId => uid;

  @override
  GoogleSignInInfo? get currentGoogleUser => googleUser;

  @override
  Future<Map<String, dynamic>?> fetchProfileRow() async => profileRow;

  @override
  Future<bool> upsertProfileRow(Map<String, dynamic> remote) async {
    lastUpsert = remote;
    upsertCalls++;
    return true;
  }

  @override
  Future<List<String>> fetchSavedQuestionIds() async => [];

  @override
  Future<Map<String, int>?> fetchProgressRow() async => null;
}

GoogleSignInInfo googleUser({
  Map<String, dynamic> metadata = const {},
  String? email,
}) =>
    GoogleSignInInfo(provider: 'google', email: email, metadata: metadata);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('metadata mapping: full_name/avatar_url win, empties dropped', () {
    final f = googleProfileFields(
      {
        'full_name': '  ',
        'name': 'Google Name',
        'avatar_url': '',
        'picture': 'https://pic.example/x.jpg',
        'email': 'meta@example.com',
      },
      'account@example.com',
    );
    expect(f['full_name'], 'Google Name');
    expect(f['avatar_url'], 'https://pic.example/x.jpg');
    expect(f['email'], 'account@example.com');
    expect(f.containsKey('guardian_name'), isFalse);
    expect(f.containsKey('avatar_local_path'), isFalse);
  });

  test('metadata mapping: account email beats metadata email', () {
    final f = googleProfileFields({'email': 'm@example.com'}, null);
    expect(f['email'], 'm@example.com');
    expect(googleProfileFields({}, null), isEmpty);
  });

  test('bootstrap skips non-Google provider and demo-user', () async {
    final emailUser = FakeGoogleBackend(
      uid: 'u1',
      googleUser:
          const GoogleSignInInfo(provider: 'email', metadata: {}),
    );
    expect(
      await ProfileRestoreService(backend: emailUser).ensureGoogleProfile(),
      isFalse,
    );
    final demo = FakeGoogleBackend(
      uid: 'demo-user',
      googleUser: googleUser(),
    );
    expect(
      await ProfileRestoreService(backend: demo).ensureGoogleProfile(),
      isFalse,
    );
    expect(emailUser.upsertCalls, 0);
    expect(demo.upsertCalls, 0);
  });

  test('bootstrap skips when a server row already exists', () async {
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({'full_name': 'Local'}),
    });
    final backend = FakeGoogleBackend(
      uid: 'u2',
      googleUser: googleUser(
        metadata: {'full_name': 'Google Name'},
        email: 'g@example.com',
      ),
    )..profileRow = {'id': 'u2', 'full_name': 'Server Name'};
    expect(
      await ProfileRestoreService(backend: backend).ensureGoogleProfile(),
      isFalse,
    );
    expect(backend.upsertCalls, 0);
    final saved = jsonDecode((await LocalStore.readProfile())!);
    expect(saved['full_name'], 'Local');
  });

  test('bootstrap seeds empty local profile and upserts real uid',
      () async {
    final backend = FakeGoogleBackend(
      uid: 'real-uid-9',
      googleUser: googleUser(
        metadata: {
          'full_name': 'Google Name',
          'avatar_url': 'https://pic.example/x.jpg',
        },
        email: 'g@example.com',
      ),
    );
    expect(
      await ProfileRestoreService(backend: backend).ensureGoogleProfile(),
      isTrue,
    );
    final saved = jsonDecode((await LocalStore.readProfile())!);
    expect(saved['full_name'], 'Google Name');
    expect(saved['email'], 'g@example.com');
    expect(saved['avatar_url'], 'https://pic.example/x.jpg');
    expect(backend.lastUpsert!['id'], 'real-uid-9');
    expect(backend.lastUpsert!['full_name'], 'Google Name');
    expect(backend.lastUpsert!['avatar_url'], 'https://pic.example/x.jpg');
  });

  test('bootstrap fills only empties, keeps guardian + local photo',
      () async {
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'full_name': 'My Name',
        'guardian_name': 'Abba',
        'avatar_local_path': '/tmp/pic.jpg',
      }),
    });
    final backend = FakeGoogleBackend(
      uid: 'u3',
      googleUser: googleUser(
        metadata: {
          'full_name': 'Google Name',
          'avatar_url': 'https://pic.example/x.jpg',
        },
        email: 'g@example.com',
      ),
    );
    expect(
      await ProfileRestoreService(backend: backend).ensureGoogleProfile(),
      isTrue,
    );
    final saved = jsonDecode((await LocalStore.readProfile())!);
    expect(saved['full_name'], 'My Name');
    expect(saved['avatar_url'], 'https://pic.example/x.jpg');
    expect(saved['guardian_name'], 'Abba');
    expect(saved['avatar_local_path'], '/tmp/pic.jpg');
    // Guardian is a profiles column (migration 014): the bootstrap
    // upsert carries it; only the device-only photo path stays out.
    expect(backend.lastUpsert!['guardian_name'], 'Abba');
    expect(backend.lastUpsert!.containsKey('avatar_local_path'), isFalse);
  });

  test('bootstrap with nothing seedable does nothing', () async {
    final backend = FakeGoogleBackend(
      uid: 'u4',
      googleUser: googleUser(),
    );
    expect(
      await ProfileRestoreService(backend: backend).ensureGoogleProfile(),
      isFalse,
    );
    expect(backend.upsertCalls, 0);
  });

  test('unconfigured Google sign-in: no launch, no fake success',
      () async {
    expect(authService.googleSignInAvailable, isFalse);
    final res = await authService.signInWithGoogle();
    expect(res.ok, isFalse);
    expect(res.googleLaunched, isFalse);
    expect(res.googleNotConfigured, isTrue);
  });

  test('OAuth-style failure never maps to wrong-password', () {
    expect(
      classifySignInError(
        const AuthException('Failed to exchange code', code: 'exchange_failed'),
      ),
      AuthErrorKind.unknown,
    );
    expect(
      signInErrorStringKey(
        const AuthResult(
          ok: false,
          mode: AuthMode.supabase,
          errorKind: AuthErrorKind.unknown,
        ),
      ),
      'loginFailed',
    );
  });
}
