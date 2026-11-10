// Lazy per-lesson counts: loads only on request, one entry per
// lesson (+ "all"), unknown never guessed, subtitle line format.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/guide_flow_count_service.dart';
import 'package:yes_sir_ai/features/learn/search_flow_lesson_counts.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

const _s = {
  'typeMcq': 'বহুনির্বাচনি',
  'typeShort': 'সংক্ষিপ্ত',
  'typeCreative': 'সৃজনশীল',
  'typePracticeWork': 'অনুশীলনীমূলক কাজ',
  'typeTextbookExercise': 'পাঠ্যবইয়ের অনুশীলনী',
};

GuideFlowCountService _svc(int Function(Map<String, dynamic>) totalOf,
        [List<Map<String, dynamic>>? log]) =>
    GuideFlowCountService(post: (b, {endpoint}) async {
      log?.add(b);
      return {
        'found': true,
        'total': totalOf(b),
        'lesson': b['lesson'],
        'section': b['section'],
      };
    });

void main() {
  test('nothing is requested until load is called', () {
    final log = <Map<String, dynamic>>[];
    final lc = SearchFlowLessonCounts(onChanged: () {}, service: _svc((b) => 1, log));
    expect(lc.of(3, '3.1'), isNull);
    expect(log, isEmpty);
  });

  test('load fills the all row and each lesson, then notifies', () async {
    var notified = 0;
    final lc = SearchFlowLessonCounts(
      onChanged: () => notified++,
      service: _svc((b) => b['section'] == 'creative' ? 7 : 3),
    );
    await lc.load(
        subject: 'math', schoolClass: 9, chapter: 3, lessons: ['3.1', '3.2']);
    expect(lc.of(3, null)![SearchFlowType.creative], 7);
    expect(lc.of(3, '3.1')![SearchFlowType.mcq], 3);
    expect(lc.of(3, '3.2'), isNotNull);
    expect(lc.of(3, '3.9'), isNull);
    expect(notified, 3);
  });

  test('reopening a chapter reuses the result (no second request)',
      () async {
    final log = <Map<String, dynamic>>[];
    final lc = SearchFlowLessonCounts(onChanged: () {}, service: _svc((b) => 2, log));
    await lc.load(subject: 'math', schoolClass: 9, chapter: 2, lessons: ['2.1']);
    final first = log.length;
    await lc.load(subject: 'math', schoolClass: 9, chapter: 2, lessons: ['2.1']);
    expect(log.length, first);
  });

  test('an unknown reply stores nothing and is retried next open',
      () async {
    var up = false;
    final lc = SearchFlowLessonCounts(
      onChanged: () {},
      service: GuideFlowCountService(post: (b, {endpoint}) async {
        if (!up) return null;
        return {'found': true, 'total': 4, 'lesson': b['lesson'], 'section': b['section']};
      }),
    );
    await lc.load(subject: 'math', schoolClass: 9, chapter: 7, lessons: ['7.1']);
    expect(lc.of(7, '7.1'), isNull);
    up = true;
    await lc.load(subject: 'math', schoolClass: 9, chapter: 7, lessons: ['7.1']);
    expect(lc.of(7, '7.1')![SearchFlowType.creative], 4);
  });

  group('lessonCountsLine', () {
    test('creative, mcq, short in that order, Bangla digits', () {
      final line = lessonCountsLine({
        SearchFlowType.mcq: 237,
        SearchFlowType.creative: 102,
        SearchFlowType.short: 15,
      }, _s, true);
      expect(line, 'সৃজনশীল ১০২ · বহুনির্বাচনি ২৩৭ · সংক্ষিপ্ত ১৫');
    });
    test('zero and unknown types are left out', () {
      final line = lessonCountsLine({
        SearchFlowType.creative: 0,
        SearchFlowType.mcq: 5,
        SearchFlowType.short: null,
      }, _s, false);
      expect(line, 'বহুনির্বাচনি 5');
    });
    test('null when nothing is known or all are zero', () {
      expect(lessonCountsLine(null, _s, true), isNull);
      expect(lessonCountsLine({SearchFlowType.mcq: 0}, _s, true), isNull);
    });
  });

  test('the no-lesson sentinel is sent as the lesson filter, and a '
      'server that matches none leaves the row without a line', () async {
    final log = <Map<String, dynamic>>[];
    final lc = SearchFlowLessonCounts(
      onChanged: () {},
      service: _svc((b) => b['lesson'] == kNoLessonFilter ? 0 : 4, log),
    );
    await lc.load(
        subject: 'math',
        schoolClass: 9,
        chapter: 2,
        lessons: [kNoLessonFilter]);
    expect(log.any((b) => b['lesson'] == '__none__'), isTrue);
    expect(lessonCountsLine(lc.of(2, kNoLessonFilter), _s, true), isNull);
  });
}
