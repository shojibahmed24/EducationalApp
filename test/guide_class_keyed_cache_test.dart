// Class-keyed guide cache reads + class resolution priority:
// saved profile class first, then the explicit route/selection
// class, then the documented fallback 6 only when neither is
// known. A class-7 row must never be served to a class-6 read
// (and vice versa), at the chapter and the index level.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/guide_bank_service.dart';
import 'package:yes_sir_ai/core/services/resolve_school_class.dart';

GuideBankQuestion row(String id) => GuideBankQuestion(
      id: id,
      questionText: 'q $id',
      questionType: 'short',
    );

void main() {
  group('class-keyed chapter cache', () {
    test('same subject+chapter keeps classes separate', () async {
      SharedPreferences.setMockInitialValues(
          {'guide_bank_cache_version': 2});
      await guideBankService.cacheChapter(
          'math', 3, [row('c6-q')], schoolClass: 6);
      await guideBankService.cacheChapter(
          'math', 3, [row('c7-q')], schoolClass: 7);
      final six = await guideBankService.cachedChapter('math', 3,
          schoolClass: 6);
      final seven = await guideBankService.cachedChapter('math', 3,
          schoolClass: 7);
      final eight = await guideBankService.cachedChapter('math', 3,
          schoolClass: 8);
      expect(six!.map((q) => q.id), ['c6-q']);
      expect(seven!.map((q) => q.id), ['c7-q']);
      expect(eight, isNull);
    });

    test('subject index is class-keyed too', () async {
      SharedPreferences.setMockInitialValues(
          {'guide_bank_cache_version': 2});
      await guideBankService.cacheChapter(
          'math', 3, [row('c6-q')], schoolClass: 6);
      await guideBankService.cacheChapter(
          'math', 3, [row('c7-a'), row('c7-b')],
          schoolClass: 7);
      expect(
          await guideBankService.subjectChapterCounts('math',
              schoolClass: 6),
          {3: 1});
      expect(
          await guideBankService.subjectChapterCounts('math',
              schoolClass: 7),
          {3: 2});
      expect(
          await guideBankService.subjectChapterCounts('math',
              schoolClass: 8),
          isNull);
    });
  });

  group('resolveSchoolClass priority', () {
    test('no saved class and no explicit class -> documented 6',
        () async {
      SharedPreferences.setMockInitialValues(
          {'guide_bank_cache_version': 2});
      expect(await resolveSchoolClass(), 6);
    });

    test('explicit class wins when nothing is saved', () async {
      SharedPreferences.setMockInitialValues(
          {'guide_bank_cache_version': 2});
      expect(await resolveSchoolClass(explicit: 8), 8);
    });

    test('saved class beats the explicit class', () async {
      SharedPreferences.setMockInitialValues({
        'guide_bank_cache_version': 2,
        'demo_profile_json': '{"school_class": 7}',
      });
      expect(await resolveSchoolClass(explicit: 8), 7);
      expect(await resolveSchoolClass(), 7);
    });

    test('saved class stored as a string still parses', () async {
      SharedPreferences.setMockInitialValues({
        'guide_bank_cache_version': 2,
        'demo_profile_json': '{"school_class": "7"}',
      });
      expect(await resolveSchoolClass(explicit: 6), 7);
    });
  });
}
