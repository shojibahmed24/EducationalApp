// Cache-once home subjects: persisted last-good list, set-based
// English visibility, honest load-failed state. No Edge, no DB:
// injected guide fakes, SharedPreferences mock, fake BooksService.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/books_service.dart';
import 'package:yes_sir_ai/core/services/guide_subject_flags.dart';
import 'package:yes_sir_ai/core/services/subjects_cache.dart';
import 'package:yes_sir_ai/features/home/widgets/home_subject_grid.dart';
import 'package:yes_sir_ai/l10n/pages/home_strings.dart';

const _failedFetch = SubjectsFetchResult(
  subjects: [],
  kind: SubjectsFetchKind.failed,
);

SubjectInfo _subject(
  String id, {
  bool locked = false,
  bool hasGuide = false,
  int chapters = 0,
  int sets = 0,
}) => SubjectInfo(
  id: id,
  nameBn: id,
  nameEn: id,
  locked: locked,
  chapterCount: chapters,
  hasGuide: hasGuide,
  guideChapterCount: chapters,
  guideSetCount: sets,
);

void main() {
  test('SubjectInfo JSON round-trip keeps guide fields', () {
    const s = SubjectInfo(
      id: 'english',
      nameBn: 'ইংরেজি',
      nameEn: 'English',
      locked: true,
      chapterCount: 0,
      hasGuide: true,
      guideSetCount: 57,
    );
    final back = SubjectInfo.fromJson(s.toJson());
    expect(back.id, 'english');
    expect(back.hasGuide, isTrue);
    expect(back.guideSetCount, 57);
    expect(back.guideChapterCount, 0);
  });

  test('SubjectInfo fromJson without guideSetCount defaults to 0', () {
    final back = SubjectInfo.fromJson({
      'id': 'math',
      'nameBn': 'গণিত',
      'nameEn': 'Maths',
      'locked': true,
      'chapterCount': 0,
      'hasGuide': true,
      'guideChapterCount': 8,
    });
    expect(back.guideSetCount, 0);
  });

  test('persisted list round-trips; corrupt cache yields null', () async {
    SharedPreferences.setMockInitialValues({});
    final key = subjectsLastGoodKey(9, true);
    final list = [
      _subject('math'),
      _subject('english', locked: true, hasGuide: true, sets: 57),
    ];
    await persistSubjectsList(key, list);
    final loaded = await loadPersistedSubjectsList(key);
    expect(loaded?.map((s) => s.id), ['math', 'english']);
    expect(loaded?[1].guideSetCount, 57);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, 'not-json{');
    expect(await loadPersistedSubjectsList(key), isNull);
    await prefs.setString(key, '[{"id": ""}]');
    expect(await loadPersistedSubjectsList(key), isNull);
  });

  test('withGuideFlags: empty chapters fall back to sets', () async {
    final result = await withGuideFlags(
      [_subject('english', locked: true)],
      9,
      fetchChapters: (s, {schoolClass = 6}) async => <int, int>{},
      fetchSetCount: (s, {schoolClass = 6}) async => 57,
    );
    expect(result.complete, isTrue);
    final english = result.subjects.single;
    expect(english.hasGuide, isTrue);
    expect(english.guideSetCount, 57);
    expect(english.guideChapterCount, 0);
  });

  test('withGuideFlags: empty sets fall back to bank presence', () async {
    final result = await withGuideFlags(
      [_subject('english', locked: true)],
      9,
      fetchChapters: (s, {schoolClass = 6}) async => <int, int>{},
      fetchSetCount: (s, {schoolClass = 6}) async => 0,
      probeBank: (s, {schoolClass = 6}) async => true,
    );
    expect(result.complete, isTrue);
    expect(result.subjects.single.hasGuide, isTrue);
    expect(result.subjects.single.guideSetCount, 0);
  });

  test('withGuideFlags: chapters present skips sets and bank', () async {
    var setCalls = 0;
    var bankCalls = 0;
    final result = await withGuideFlags(
      [_subject('math', locked: true)],
      9,
      // Map is chapter-number -> question count: 2 chapters here.
      fetchChapters: (s, {schoolClass = 6}) async => {8: 100, 9: 50},
      fetchSetCount: (s, {schoolClass = 6}) async {
        setCalls++;
        return 0;
      },
      probeBank: (s, {schoolClass = 6}) async {
        bankCalls++;
        return false;
      },
    );
    expect(result.complete, isTrue);
    expect(result.subjects.single.guideChapterCount, 2);
    expect(result.subjects.single.guideSetCount, 0);
    expect(setCalls, 0);
    expect(bankCalls, 0);
  });

  test('withGuideFlags: failed checks are incomplete, never cached', () async {
    final failed = await withGuideFlags(
      [_subject('english', locked: true)],
      9,
      fetchChapters: (s, {schoolClass = 6}) async => null,
      fetchSetCount: (s, {schoolClass = 6}) async => null,
    );
    expect(failed.complete, isFalse);
    expect(failed.subjects.single.hasGuide, isFalse);
    final rescued = await withGuideFlags(
      [_subject('english', locked: true)],
      9,
      fetchChapters: (s, {schoolClass = 6}) async => null,
      fetchSetCount: (s, {schoolClass = 6}) async => 3,
    );
    expect(rescued.complete, isTrue);
    expect(rescued.subjects.single.hasGuide, isTrue);
  });

  test('visibleHomeSubjects keeps set-based locked subjects', () {
    final out = visibleHomeSubjects([
      _subject('math'),
      _subject('english', locked: true, hasGuide: true, sets: 57),
      _subject('bgs', locked: true),
    ]);
    expect(out.map((s) => s.id), ['math', 'english']);
  });

  group('HomeSubjectGrid cache-once', () {
    Widget grid(FakeBooksService svc) => MaterialApp(
      home: Scaffold(
        body: HomeSubjectGrid(
          bn: true,
          schoolClass: 9,
          loadingLabel: 'লোড হচ্ছে',
          noSubjectsLabel: 'কোনো বিষয় পাওয়া যায়নি',
          chooseClassTitle: 'ক্লাস',
          chooseClassBody: 'বডি',
          chooseClassAction: 'অ্যাকশন',
          service: svc,
        ),
      ),
    );

    testWidgets('cached list shows instantly, no mount refetch', (
      tester,
    ) async {
      final svc = FakeBooksService(
        cached: [
          _subject('math', chapters: 14),
          _subject('english', locked: true, hasGuide: true, sets: 57),
        ],
      );
      await tester.pumpWidget(grid(svc));
      await tester.pumpAndSettle();
      expect(find.text('math'), findsOneWidget);
      // Dashboard redesign (Phase 3): class-9 'english' tiles show
      // the paper name, not the raw server name.
      expect(find.text('ইংরেজি ১ম পত্র'), findsOneWidget);
      expect(find.text('57টি সেট'), findsOneWidget);
      expect(svc.freshCalls, 0);
    });

    testWidgets('failed first load shows error, not noSubjects', (
      tester,
    ) async {
      final svc = FakeBooksService(fresh: _failedFetch);
      await tester.pumpWidget(grid(svc));
      await tester.pumpAndSettle();
      expect(find.text(homeStringsBn['subjectsLoadFailed']!), findsOneWidget);
      expect(find.text(homeStringsBn['subjectsRetry']!), findsOneWidget);
      expect(find.text('কোনো বিষয় পাওয়া যায়নি'), findsNothing);
    });

    testWidgets('retry after failure loads the list', (tester) async {
      final svc = FakeBooksService(fresh: _failedFetch);
      await tester.pumpWidget(grid(svc));
      await tester.pumpAndSettle();
      expect(find.text(homeStringsBn['subjectsLoadFailed']!), findsOneWidget);
      svc.fresh = SubjectsFetchResult(
        subjects: [_subject('math', chapters: 14)],
        kind: SubjectsFetchKind.server,
      );
      await tester.tap(find.text(homeStringsBn['subjectsRetry']!));
      await tester.pumpAndSettle();
      expect(find.text('math'), findsOneWidget);
      expect(find.text(homeStringsBn['subjectsLoadFailed']!), findsNothing);
    });
  });
}

class FakeBooksService extends BooksService {
  FakeBooksService({this.cached, this.fresh});
  final List<SubjectInfo>? cached;
  SubjectsFetchResult? fresh;
  int freshCalls = 0;

  @override
  Future<List<SubjectInfo>?> loadPersistedSubjects(
    int schoolClass,
    bool bangla,
  ) async => cached;

  @override
  Future<SubjectsFetchResult> fetchSubjectsFresh(
    int schoolClass,
    bool bangla,
  ) async {
    freshCalls++;
    return fresh ?? _failedFetch;
  }
}
