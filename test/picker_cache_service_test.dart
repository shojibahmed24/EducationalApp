// Picker cache service: one layer, same rules for every
// picker path — disk persistence, stale-readable entries,
// versioned keys, per-subject/all invalidation, and
// in-flight dedupe. Uses the SharedPreferences mock, so no
// device storage is touched.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/picker_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const chaptersKey = 'picker_cache:v1:9:math:bn:guideChapters';
  const setsKey = 'picker_cache:v1:9:math:all:sets';

  test('key format carries version, class, subject, lang, kind', () {
    expect(
      pickerCacheKey(9, 'math', 'bn', pickerCacheKindGuideChapters),
      chaptersKey,
    );
    expect(
      pickerCacheKey(10, 'bangla', 'all', pickerCacheKindSets),
      'picker_cache:v1:10:bangla:all:sets',
    );
  });

  test('write then read round-trips, and is fresh', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = PickerCacheService();
    await svc.write(chaptersKey, encodeChapterTuples([(1, 'এক'), (2, 'দুই')]));
    final data = await svc.read(chaptersKey);
    expect(data, isNotNull);
    expect(decodeChapterTuples(data!), [(1, 'এক'), (2, 'দুই')]);
    expect(await svc.isFresh(chaptersKey), isTrue);
  });

  test('sets and lessons codecs round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = PickerCacheService();
    final sets = [
      const GuideModelSetInfo(
          setId: 'model-1', totalCount: 30, keyedCount: 30,
          gradeBands: {'A': [1, 2]}),
      const GuideModelSetInfo(
          setId: 'model-2', totalCount: 28, keyedCount: 20),
    ];
    await svc.write(setsKey, encodeModelSets(sets));
    final setsData = await svc.read(setsKey);
    final decodedSets = decodeModelSets(setsData!);
    expect(decodedSets, isNotNull);
    expect(decodedSets!.length, 2);
    expect(decodedSets.first.setId, 'model-1');
    expect(decodedSets.first.gradeBands, {'A': [1, 2]});
    expect(decodedSets.last.keyedCount, 20);

    const lessonsKey = 'picker_cache:v1:10:bangla:bn:serverLessons';
    await svc.write(lessonsKey, encodeServerLessons({'পাঠ': 5}));
    final lessonsData = await svc.read(lessonsKey);
    expect(decodeServerLessons(lessonsData!), {'পাঠ': 5});
  });

  test('corrupt or foreign-version entries read as null', () async {
    SharedPreferences.setMockInitialValues({
      'picker_cache:v1:9:math:bn:guideChapters': 'not-json',
      'picker_cache:v1:9:math:bn:textbookChapters':
          jsonEncode({'v': 99, 'savedAt': 0, 'data': {}}),
      'picker_cache:v1:9:math:bn:sets':
          jsonEncode({'v': 1, 'savedAt': 0}),
    });
    final svc = PickerCacheService();
    expect(
        await svc.read('picker_cache:v1:9:math:bn:guideChapters'), isNull);
    expect(
        await svc.read('picker_cache:v1:9:math:bn:textbookChapters'),
        isNull);
    expect(await svc.read('picker_cache:v1:9:math:bn:sets'), isNull);
  });

  test('stale entries still read, but are not fresh', () async {
    final old = DateTime.now().millisecondsSinceEpoch -
        const Duration(hours: 25).inMilliseconds;
    SharedPreferences.setMockInitialValues({
      chaptersKey: jsonEncode({
        'v': 1,
        'savedAt': old,
        'data': encodeChapterTuples([(3, 'তিন')]),
      }),
    });
    final svc = PickerCacheService();
    final data = await svc.read(chaptersKey);
    expect(decodeChapterTuples(data!), [(3, 'তিন')]);
    expect(await svc.isFresh(chaptersKey), isFalse);
  });

  test('invalidateSubject removes only that subject', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = PickerCacheService();
    await svc.write(chaptersKey, encodeChapterTuples([(1, 'এক')]));
    await svc.write(
        'picker_cache:v1:9:physics:bn:guideChapters',
        encodeChapterTuples([(1, 'এক')]));
    await svc.invalidateSubject(9, 'math', 'bn');
    expect(await svc.read(chaptersKey), isNull);
    expect(
        await svc.read('picker_cache:v1:9:physics:bn:guideChapters'),
        isNotNull);
  });

  test('invalidateAll clears every picker entry only', () async {
    SharedPreferences.setMockInitialValues({
      'unrelated_key': 'keep-me',
    });
    final svc = PickerCacheService();
    await svc.write(chaptersKey, encodeChapterTuples([(1, 'এক')]));
    await svc.write(setsKey, encodeModelSets([]));
    await svc.invalidateAll();
    expect(await svc.read(chaptersKey), isNull);
    expect(await svc.read(setsKey), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('unrelated_key'), 'keep-me');
  });

  test('dedupe shares one run, then runs again', () async {
    final svc = PickerCacheService();
    var runs = 0;
    Future<int> run() async {
      runs++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return 7;
    }

    final results = await Future.wait([
      svc.dedupe('k', run),
      svc.dedupe('k', run),
    ]);
    expect(results, [7, 7]);
    expect(runs, 1);
    expect(await svc.dedupe('k', run), 7);
    expect(runs, 2);
  });

  test('dedupe drops failed runs so the next call retries', () async {
    final svc = PickerCacheService();
    var runs = 0;
    Future<int> fail() async {
      runs++;
      throw StateError('boom');
    }

    await expectLater(svc.dedupe('k', fail), throwsStateError);
    await expectLater(svc.dedupe('k', fail), throwsStateError);
    expect(runs, 2);
  });
}
