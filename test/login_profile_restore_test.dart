// 2026-11-01 login/profile-loss fix tests:
// - merge rule (server wins, local-only keys survive)
// - server-row restore, missing-row backfill, demo-user skip
// - Google guard (no fake ok:true, button hidden without client id)
// - Bangla/English error mapping (never raw SDK text in UI)
// - progress summary falls back to the cached server row offline.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yes_sir_ai/core/services/auth_service.dart';
import 'package:yes_sir_ai/core/services/google_profile.dart';
import 'package:yes_sir_ai/core/services/local_store.dart';
import 'package:yes_sir_ai/core/services/profile_restore_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/features/auth/login_screen.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';

class FakeRestoreBackend implements ProfileRestoreBackend {
  String? uid;
  Map<String, dynamic>? profileRow;
  List<String> savedIds = [];
  Map<String, int>? progressRow;
  int fetchProfileCalls = 0;
  Map<String, dynamic>? lastUpsert;

  FakeRestoreBackend({this.uid});

  @override
  String? get currentUserId => uid;

  // Extended interface (Google bootstrap): unused by these tests.
  @override
  GoogleSignInInfo? get currentGoogleUser => null;

  @override
  Future<Map<String, dynamic>?> fetchProfileRow() async {
    fetchProfileCalls++;
    return profileRow;
  }

  @override
  Future<bool> upsertProfileRow(Map<String, dynamic> remote) async {
    lastUpsert = remote;
    return true;
  }

  @override
  Future<List<String>> fetchSavedQuestionIds() async => savedIds;

  @override
  Future<Map<String, int>?> fetchProgressRow() async => progressRow;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    setLanguage('en');
  });
  tearDown(() {
    setLanguage('bn');
  });

  test('merge: server columns win, local-only keys survive', () {
    final merged = mergeServerProfile(
      {
        'id': 'u1',
        'full_name': 'Server Name',
        'school_class': 9,
        'created_at': '2026-01-01',
      },
      {
        'full_name': 'Local Name',
        'school_class': 7,
        'guardian_name': 'Abba',
        'avatar_local_path': '/tmp/pic.jpg',
      },
    );
    expect(merged['full_name'], 'Server Name');
    expect(merged['school_class'], 9);
    expect(merged['guardian_name'], 'Abba');
    expect(merged['avatar_local_path'], '/tmp/pic.jpg');
    expect(merged.containsKey('created_at'), isFalse);
  });

  test('merge: null server value never clobbers a local value', () {
    final merged = mergeServerProfile(
      {'gender': null, 'full_name': 'S'},
      {'gender': 'boy', 'full_name': 'L'},
    );
    expect(merged['gender'], 'boy');
    expect(merged['full_name'], 'S');
  });

  test('restore: server row merges over local, saves union, caches progress',
      () async {
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'full_name': 'Local Name',
        'school_class': 7,
        'guardian_name': 'Abba',
        'avatar_local_path': '/tmp/pic.jpg',
      }),
      'saved_questions': ['q0'],
    });
    final backend = FakeRestoreBackend(uid: 'real-uid-1')
      ..profileRow = {
        'id': 'real-uid-1',
        'full_name': 'Server Name',
        'school_class': 9,
      }
      ..savedIds = ['q1']
      ..progressRow = {
        'streak_days': 5,
        'chapters_done': 3,
        'average_score': 80,
      };
    final res = await ProfileRestoreService(backend: backend)
        .restoreAfterSignIn();
    expect(res.skipped, isFalse);
    expect(res.profileRestored, isTrue);
    expect(res.profileBackfilled, isFalse);
    expect(res.savedCount, 2);
    expect(res.progressCached, isTrue);
    final saved = jsonDecode((await LocalStore.readProfile())!);
    expect(saved['full_name'], 'Server Name');
    expect(saved['school_class'], 9);
    expect(saved['guardian_name'], 'Abba');
    expect(saved['avatar_local_path'], '/tmp/pic.jpg');
    expect(await LocalStore.savedQuestions(), ['q0', 'q1']);
    expect(await LocalStore.readServerProgress(), {
      'streak_days': 5,
      'chapters_done': 3,
      'average_score': 80,
    });
  });

  test('restore: missing server row + local profile triggers backfill',
      () async {
    SharedPreferences.setMockInitialValues({
      'demo_profile_json': jsonEncode({
        'id': 'demo-user',
        'full_name': 'Local Name',
        'school_class': 8,
        'guardian_name': 'Abba',
      }),
    });
    final backend = FakeRestoreBackend(uid: 'real-uid-2')..profileRow = null;
    final res = await ProfileRestoreService(backend: backend)
        .restoreAfterSignIn();
    expect(res.profileRestored, isFalse);
    expect(res.profileBackfilled, isTrue);
    // The upsert id MUST be the real uid, never the stale local one.
    expect(backend.lastUpsert!['id'], 'real-uid-2');
    expect(backend.lastUpsert!['full_name'], 'Local Name');
    expect(backend.lastUpsert!['school_class'], 8);
    // Guardian is a profiles column (migration 014): backfill carries it.
    expect(backend.lastUpsert!['guardian_name'], 'Abba');
  });

  test('restore: demo-user skips silently without backend calls', () async {
    final backend = FakeRestoreBackend(uid: 'demo-user');
    final res = await ProfileRestoreService(backend: backend)
        .restoreAfterSignIn();
    expect(res.skipped, isTrue);
    expect(backend.fetchProfileCalls, 0);
  });

  test('restore: null uid skips silently', () async {
    final backend = FakeRestoreBackend(uid: null);
    final res = await ProfileRestoreService(backend: backend)
        .restoreAfterSignIn();
    expect(res.skipped, isTrue);
    expect(backend.fetchProfileCalls, 0);
  });

  test('google: no client id means unavailable, never a fake ok:true',
      () async {
    expect(authService.googleSignInAvailable, isFalse);
    final res = await authService.signInWithGoogle();
    expect(res.ok, isFalse);
    expect(res.googleNotConfigured, isTrue);
    expect(signInErrorStringKey(res), 'googleUnavailable');
  });

  test('error mapping: invalid credentials, network, unknown', () {
    expect(
      classifySignInError(
        const AuthException(
          'Invalid login credentials',
          code: 'invalid_login_credentials',
        ),
      ),
      AuthErrorKind.invalidCredentials,
    );
    expect(
      classifySignInError(
        const SocketException('Failed host lookup: example.com'),
      ),
      AuthErrorKind.network,
    );
    expect(
      classifySignInError(Exception('boom')),
      AuthErrorKind.unknown,
    );
    expect(
      signInErrorStringKey(
        const AuthResult(
          ok: false,
          mode: AuthMode.supabase,
          errorKind: AuthErrorKind.invalidCredentials,
        ),
      ),
      'invalidCredentials',
    );
    expect(
      signInErrorStringKey(
        const AuthResult(
          ok: false,
          mode: AuthMode.supabase,
          errorKind: AuthErrorKind.network,
        ),
      ),
      'networkError',
    );
    expect(
      signInErrorStringKey(
        const AuthResult(ok: false, mode: AuthMode.supabase),
      ),
      'loginFailed',
    );
  });

  test('progress summary falls back to the cached server row offline',
      () async {
    await LocalStore.saveServerProgress(
      {'streak_days': 5, 'chapters_done': 3, 'average_score': 80},
    );
    final sum = await progressService.summary();
    expect(sum.streakDays, 5);
    expect(sum.chaptersDone, 3);
    expect(sum.averageScore, 80);
  });

  testWidgets('login screen hides the Google button without a client id',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoginScreen())),
    );
    // FadeSlide entrance delays (max 300ms) leave pending timers
    // that fail the test at teardown unless fake time advances.
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsNothing);
    // Sanity: the screen itself still rendered.
    expect(find.text('Log in'), findsOneWidget);
  });
}
