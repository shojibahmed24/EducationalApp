// English guide section filter tests (ENGLISH_REDO_PLAN §3).
// Vocabulary exactness (Paper-I only — Paper-II is a separate
// subject, never a filter here) + section scan behavior. No Edge,
// no I/O: fake list responses only.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/english_guide_sections.dart';
import 'package:yes_sir_ai/core/services/guide_flow_list_service.dart';
import 'package:yes_sir_ai/core/services/guide_flow_section_scan.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

Map<String, dynamic> _row(String id, String? section) => {
      'id': id,
      'questionText': 'Q $id',
      'questionType': section ?? '',
      'options': <String>[],
      'section': section,
    };

/// Fake list endpoint: slices [rows] by offset/limit, reports the
/// full total, and echoes `lesson` only when [echoLesson] is true.
GuideFlowPost _fake(List<Map<String, dynamic>> rows,
    {bool echoLesson = false, List<Map<String, dynamic>>? seen}) {
  return (Map<String, dynamic> body, {String? endpoint}) async {
    seen?.add(body);
    final offset = (body['offset'] as num?)?.toInt() ?? 0;
    final limit = (body['limit'] as num?)?.toInt() ?? 50;
    final lesson = body['lesson'];
    final sliced = rows.skip(offset).take(limit).toList();
    return {
      'found': true,
      'questions': sliced,
      'total': rows.length,
      if (lesson != null && echoLesson) 'lesson': lesson,
    };
  };
}

void main() {
  test('vocabulary is exactly the 17 locked Paper-I values, in order', () {
    expect(englishPaperOneSections, [
      'mcq',
      'true-false',
      'short',
      'gapfill',
      'table',
      'summary',
      'matching',
      'rearranging',
      'poem',
      'story',
      'writing-story',
      'writing-dialogue',
      'writing-paragraph',
      'writing-letter',
      'writing-graph',
      'writing-composition',
      'writing-email',
    ]);
    expect(englishPaperOneSections.toSet().length, 17);
  });

  test('true-false is a real section (owner rule: never mcq)', () {
    expect(isEnglishPaperOneSection('true-false'), isTrue);
    expect(englishSectionStringKey('true-false'), 'sectionTrueFalse');
  });

  test('Paper-II values are absent (separate subject, never a filter)',
      () {
    for (final v in [
      'gapbox',
      'prefix',
      'suffix',
      'tag',
      'transform',
      'verbs',
      'connector',
      'preposition',
      'punctuation',
    ]) {
      expect(englishPaperOneSections.contains(v), isFalse, reason: v);
      expect(isEnglishPaperOneSection(v), isFalse, reason: v);
    }
    expect(isEnglishPaperOneSection('gapfill'), isTrue);
    expect(isEnglishPaperOneSection(null), isFalse);
  });

  test('section page returns only matching rows, in order', () async {
    final rows = [
      _row('g1', 'gapfill'),
      _row('t1', 'table'),
      _row('g2', 'gapfill'),
      _row('n1', null),
      _row('g3', 'gapfill'),
    ];
    final page = await guideFlowSectionPage(
        fetch: _fake(rows),
        subject: 'english',
        schoolClass: 9,
        chapter: 1,
        section: 'gapfill',
        lesson: null,
        scanOffset: 0);
    expect(page.mode, GuideFlowMode.clientFiltered);
    expect(page.rows.map((r) => r.id).toList(), ['g1', 'g2', 'g3']);
    expect(page.hasMore, isFalse);
  });

  test('section page with lesson but no lesson echo is filterPending',
      () async {
    final page = await guideFlowSectionPage(
        fetch: _fake([_row('g1', 'gapfill')], echoLesson: false),
        subject: 'english',
        schoolClass: 9,
        chapter: 1,
        section: 'gapfill',
        lesson: '1.1',
        scanOffset: 0);
    expect(page.mode, GuideFlowMode.filterPending);
    expect(page.rows, isEmpty);
  });

  test('mid-scan failure keeps matched rows and the scan offset',
      () async {
    var calls = 0;
    final rows = List.generate(
        50, (i) => _row('r$i', i % 10 == 0 ? 'gapfill' : 'table'));
    final fetch = (Map<String, dynamic> body, {String? endpoint}) async {
      calls++;
      if (calls > 1) return null;
      final offset = (body['offset'] as num?)?.toInt() ?? 0;
      final limit = (body['limit'] as num?)?.toInt() ?? 50;
      return {
        'found': true,
        'questions': rows.skip(offset).take(limit).toList(),
        'total': 100,
      };
    };
    final page = await guideFlowSectionPage(
        fetch: fetch,
        subject: 'english',
        schoolClass: 9,
        chapter: 1,
        section: 'gapfill',
        lesson: null,
        scanOffset: 0);
    expect(page.rows.length, 5);
    expect(page.hasMore, isTrue);
    expect(page.nextScanOffset, 50);
  });

  test('section jump returns the Nth match, notFound beyond the end',
      () async {
    final rows = [
      _row('g1', 'gapfill'),
      _row('t1', 'table'),
      _row('g2', 'gapfill'),
    ];
    final second = await guideFlowSectionJump(
        fetch: _fake(rows),
        subject: 'english',
        schoolClass: 9,
        chapter: 1,
        section: 'gapfill',
        lesson: null,
        position: 2);
    expect(second.outcome, GuideFlowJumpOutcome.found);
    expect(second.question!.id, 'g2');
    final beyond = await guideFlowSectionJump(
        fetch: _fake(rows),
        subject: 'english',
        schoolClass: 9,
        chapter: 1,
        section: 'gapfill',
        lesson: null,
        position: 3);
    expect(beyond.outcome, GuideFlowJumpOutcome.notFound);
  });

  // Phase 2 SUPERSEDES the old rule: the section key IS sent
  // now (the Edge allowlist accepts the 13 English sections).
  // A server that echoes it filters server-side; a server that
  // does not echo falls back to the client scan, which still
  // filters to matching rows only.
  test('fetchPage section override sends the section key first, '
      'scan filters when the server does not echo', () async {
    final seen = <Map<String, dynamic>>[];
    final rows = [_row('g1', 'gapfill'), _row('t1', 'table')];
    final service =
        GuideFlowListService(post: _fake(rows, seen: seen));
    final page = await service.fetchPage(
        subject: 'english',
        schoolClass: 9,
        chapter: 1,
        type: SearchFlowType.mcq,
        section: 'gapfill');
    expect(page.rows.map((r) => r.id).toList(), ['g1']);
    expect(seen, isNotEmpty);
    expect(seen.any((b) => b['section'] == 'gapfill'), isTrue);
  });

  test('fetchPage section override uses the server echo when present',
      () async {
    final seen = <Map<String, dynamic>>[];
    final rows = [_row('g1', 'gapfill'), _row('t1', 'table')];
    Future<Map<String, dynamic>?> echoing(
        Map<String, dynamic> body, {String? endpoint}) async {
      seen.add(body);
      final section = body['section'] as String?;
      final filtered =
          rows.where((r) => r['section'] == section).toList();
      final offset = (body['offset'] as num?)?.toInt() ?? 0;
      final limit = (body['limit'] as num?)?.toInt() ?? 50;
      return {
        'found': true,
        'questions': filtered.skip(offset).take(limit).toList(),
        'total': filtered.length,
        'section': section,
      };
    }

    final service = GuideFlowListService(post: echoing);
    final page = await service.fetchPage(
        subject: 'english',
        schoolClass: 9,
        chapter: 1,
        type: SearchFlowType.mcq,
        section: 'gapfill');
    expect(page.rows.map((r) => r.id).toList(), ['g1']);
    expect(page.mode, GuideFlowMode.serverFiltered);
    // Direct hit: exactly one request, no scan pages after it.
    expect(seen.length, 1);
  });
}
