// Audit-fix tests (Worker B, 2026-10-31): class-keyed guide
// cache + legacy migration, guide-id chapter labels, lessons-
// today dedupe, photo-note cap, fence stripping, partial
// structured parse, and the shared Edge POST guard rails.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/solution_model.dart';
import 'package:yes_sir_ai/core/services/edge_post.dart';
import 'package:yes_sir_ai/core/services/guide_bank_cache.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/structured_parse.dart';
import 'package:yes_sir_ai/features/learn/learn_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('guide-bank cache keys + migration', () {
    test('keys differ by class', () {
      expect(guideChapterKey(6, 'math', 3),
          isNot(guideChapterKey(7, 'math', 3)));
      expect(guideIndexKey(6, 'math'), isNot(guideIndexKey(7, 'math')));
      expect(guideSetsKey(6, 'math'), isNot(guideSetsKey(7, 'math')));
      expect(guideChapterKey(6, 'math', 3), 'guide_bank_chapter_6_math_3');
    });

    test('migration deletes class-less keys, keeps class-keyed ones',
        () async {
      SharedPreferences.setMockInitialValues({
        'guide_bank_chapter_math_3': '[]',
        'guide_bank_index_math': '{}',
        'guide_bank_chapter_6_math_3': '[]',
        'unrelated_key': 'keep',
      });
      await ensureGuideCacheMigrated();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('guide_bank_chapter_math_3'), isFalse);
      expect(prefs.containsKey('guide_bank_index_math'), isFalse);
      expect(prefs.containsKey('guide_bank_chapter_6_math_3'), isTrue);
      expect(prefs.containsKey('unrelated_key'), isTrue);
      expect(prefs.getInt('guide_bank_cache_version'),
          guideBankCacheVersion);
    });

    test('invalidate drops all guide cache keys', () async {
      SharedPreferences.setMockInitialValues({
        'guide_bank_chapter_6_math_3': '[]',
        'guide_bank_sets_7_math': '[]',
        'unrelated_key': 'keep',
      });
      await invalidateGuideBankCache();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('guide_bank_chapter_6_math_3'), isFalse);
      expect(prefs.containsKey('guide_bank_sets_7_math'), isFalse);
      expect(prefs.containsKey('unrelated_key'), isTrue);
    });
  });

  group('practice chapter labels', () {
    test('guide ids parse to their real chapter', () {
      expect(
          practiceService.chapterOf(
              'class7-math-bn-guide-ch2-p44-ex21-mcq18', true),
          'অধ্যায় ২');
      expect(
          practiceService.chapterOf(
              'class7-math-bn-guide-ch10-p242-ex101smcq12', false),
          'Chapter 10');
    });

    test('bank ids keep their coarse chapter', () {
      expect(practiceService.chapterOf('mq1', true),
          'গণিত · পরিমাপ ও অনুপাত');
      expect(practiceService.chapterOf('sq1', false),
          'Science · Motion & Matter');
    });

    test('unparseable ids get no label, never a wrong one', () {
      expect(practiceService.chapterOf('zzz-unknown', true), '');
      expect(practiceService.chapterOf('zzz-unknown', false), '');
      expect(practiceService.chapterOf('', true), '');
    });
  });

  group('learn store counts + caps', () {
    test('lessons-today counts NEW lessons only', () async {
      SharedPreferences.setMockInitialValues({});
      await LearnStore.recordLesson('math|3|45|5', 'math|3');
      await LearnStore.recordLesson('math|3|45|5', 'math|3');
      await LearnStore.recordLesson('math|3|46|1', 'math|3');
      final summary = await LearnStore.summary();
      expect(summary.lessonsToday, 2);
      expect(summary.lessonsOpened, 2);
    });

    test('photo notes cap at 50, oldest dropped first', () async {
      SharedPreferences.setMockInitialValues({});
      for (var i = 1; i <= 55; i++) {
        await LearnStore.addPhotoNote('n$i');
      }
      final notes = await LearnStore.photoNotes();
      expect(notes.length, 50);
      expect(notes.first, 'n6');
      expect(notes.last, 'n55');
    });
  });

  group('structured parse honesty', () {
    test('fence stripping removes json + plain fences', () {
      expect(stripStructuredFences('```json\n{"a": 1}\n```'),
          '{"a": 1}');
      expect(stripStructuredFences('```\nplain text\n```'), 'plain text');
      expect(stripStructuredFences('plain text'), 'plain text');
      expect(stripStructuredFences('  ```json\ntext\n```  '), 'text');
    });

    test('partial parse keeps valid steps, drops the bad one', () {
      final payload = {
        'summary': 's',
        'finalAnswer': '42',
        'steps': [
          {'n': 1, 'title': 'one', 'text': 'first'},
          {'n': 'bad', 'title': 'bad', 'text': 'broken'},
          {'n': 3, 'title': 'three', 'text': ''},
          {'n': 4, 'title': 'four', 'text': 'fourth'},
        ],
      };
      // Strict contract still rejects the payload as a whole.
      expect(parseStructuredSolution(payload), isNull);
      final partial = parsePartialStructuredSolution(payload);
      expect(partial, isNotNull);
      expect(partial!.steps.map((s) => s.n).toList(), [1, 4]);
      expect(partial.summary, 's');
      expect(partial.finalAnswer, '42');
    });

    test('partial parse fails without summary/answer/valid step', () {
      expect(
          parsePartialStructuredSolution({
            'summary': '',
            'finalAnswer': '42',
            'steps': [
              {'n': 1, 'text': 'ok'}
            ],
          }),
          isNull);
      expect(
          parsePartialStructuredSolution({
            'summary': 's',
            'finalAnswer': '42',
            'steps': [
              {'n': 'bad', 'text': 'broken'}
            ],
          }),
          isNull);
    });

    test('strict parse still accepts fully-valid payloads', () {
      final payload = {
        'summary': 's',
        'finalAnswer': '42',
        'steps': [
          {'n': 1, 'title': 'one', 'text': 'first'},
        ],
      };
      expect(parseStructuredSolution(payload), isNotNull);
    });
  });

  group('shared edge post guards', () {
    test('empty endpoint returns null without a request', () async {
      expect(await edgePost({'a': 1}, endpoint: ''), isNull);
    });

    test('unreachable host returns null (no hang)', () async {
      expect(await edgePost({'a': 1},
          endpoint: 'http://127.0.0.1:1/edge'), isNull);
    });
  });
}
