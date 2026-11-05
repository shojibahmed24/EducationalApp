// Quick-load implementation tests: bulk-first fetch, parallel
// paging order + failure, dedupe, disk cache round-trip +
// version gate, slim parsing, direct section pages, and the
// WiFi fail-closed prefetch. No live server, no real device.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/guide_bank_disk_cache.dart';
import 'package:yes_sir_ai/core/services/guide_bank_fetch.dart';
import 'package:yes_sir_ai/core/services/guide_flow_models.dart';
import 'package:yes_sir_ai/core/services/guide_flow_prefetch.dart';

Map<String, dynamic> _row(int i) => {
      'id': 'r$i',
      'questionText': 'Q $i',
      'questionType': 'mcq',
      'options': ['a', 'b'],
      'marks': 1,
      'important': false,
      'setId': null,
      'hasKey': true,
      'guideError': false,
      'lesson': null,
      'section': 'mcq_bank',
    };

void main() {
  test('bulk: complete answer wins, partial falls back, null is a miss',
      () async {
    Future<Map<String, dynamic>?> complete(Map<String, dynamic> b,
        {String? endpoint}) async {
      if (b['action'] == 'bulk') {
        return {
          'found': true,
          'total': 3,
          'questions': [_row(0), _row(1), _row(2)],
        };
      }
      return null;
    }

    final ok = await fetchBulkRows(
        post: complete, baseBody: {'classId': 9, 'subject': 'math'});
    expect(ok, isNotNull);
    expect(ok!.rows.length, 3);
    expect(ok.total, 3);

    Future<Map<String, dynamic>?> partial(Map<String, dynamic> b,
        {String? endpoint}) async {
      return {
        'found': true,
        'total': 10,
        'questions': [_row(0), _row(1)],
      };
    }
    final miss = await fetchBulkRows(
        post: partial, baseBody: {'classId': 9, 'subject': 'math'});
    expect(miss, isNull);

    Future<Map<String, dynamic>?> down(Map<String, dynamic> b,
        {String? endpoint}) async =>
        null;
    expect(
        await fetchBulkRows(
            post: down, baseBody: {'classId': 9, 'subject': 'math'}),
        isNull);
  });

  test('paging: merges in offset order, fails closed on a bad page',
      () async {
    final all = List.generate(125, _row);
    var calls = 0;
    Future<Map<String, dynamic>?> paged(Map<String, dynamic> b,
        {String? endpoint}) async {
      calls++;
      final offset = (b['offset'] as num).toInt();
      final limit = (b['limit'] as num).toInt();
      return {
        'found': true,
        'total': all.length,
        'questions': all.skip(offset).take(limit).toList(),
      };
    }
    final res = await fetchAllListRows(
        post: paged,
        baseBody: {'classId': 9, 'subject': 'math', 'chapter': 2});
    expect(res, isNotNull);
    expect(res!.rows.length, 125);
    expect(res.rows.first['id'], 'r0');
    expect(res.rows.last['id'], 'r124');
    expect(calls, 3);

    Future<Map<String, dynamic>?> flaky(Map<String, dynamic> b,
        {String? endpoint}) async {
      if ((b['offset'] as num).toInt() > 0) return null;
      return {
        'found': true,
        'total': 125,
        'questions': all.take(50).toList(),
      };
    }
    expect(
        await fetchAllListRows(
            post: flaky,
            baseBody: {'classId': 9, 'subject': 'math', 'chapter': 3}),
        isNull);
  });

  test('dedupe: concurrent identical fetches share one network run',
      () async {
    final all = List.generate(120, _row);
    var calls = 0;
    Future<Map<String, dynamic>?> paged(Map<String, dynamic> b,
        {String? endpoint}) async {
      calls++;
      final offset = (b['offset'] as num).toInt();
      final limit = (b['limit'] as num).toInt();
      return {
        'found': true,
        'total': all.length,
        'questions': all.skip(offset).take(limit).toList(),
      };
    }
    final base = {'classId': 9, 'subject': 'math', 'chapter': 4};
    final results = await Future.wait([
      fetchAllListRows(post: paged, baseBody: base),
      fetchAllListRows(post: paged, baseBody: base),
    ]);
    expect(results[0]!.rows.length, 120);
    expect(results[1]!.rows.length, 120);
    expect(calls, 3);
  });

  test('disk cache: rows + index round-trip, old version ignored',
      () async {
    final tmp = await Directory.systemTemp.createTemp('ql_');
    try {
      final cache = GuideBankDiskCache(rootOverride: tmp);
      final file = cache.chapterFile(9, 'math', 2);
      expect(await cache.readRows(file), isNull);
      final rows = [_row(0), _row(1)];
      await cache.writeRows(file, rows);
      final back = await cache.readRows(file);
      expect(back, isNotNull);
      expect(back!.length, 2);
      expect(back.first['id'], 'r0');
      await cache.writeIndex(cache.indexFile(9, 'math'), {2: 2, 3: 5});
      expect(await cache.readIndex(cache.indexFile(9, 'math')),
          {2: 2, 3: 5});
      // Hand-written old-version file must not parse.
      final stale = File('${tmp.path}/$file');
      await stale.writeAsString('{"version": 999, "rows": []}');
      expect(await cache.readRows(file), isNull);
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  test('slim rows parse with the flag and no options', () {
    final q = GuideBankQuestion.fromServerJson({
      'id': 's1',
      'questionText': 'Q',
      'questionType': 'mcq',
      'marks': 1,
      'important': false,
      'setId': null,
      'hasKey': true,
      'guideError': false,
      'lesson': null,
      'section': 'mcq_bank',
      'slim': true,
    });
    expect(q.slim, isTrue);
    expect(q.options, isEmpty);
    final full = GuideBankQuestion.fromServerJson(_row(0));
    expect(full.slim, isFalse);
  });

  test('direct section page needs the section echo', () async {
    Future<Map<String, dynamic>?> echo(Map<String, dynamic> b,
        {String? endpoint}) async {
      return {
        'found': true,
        'total': 2,
        'section': 'story',
        'questions': [_row(0), _row(1)],
      };
    }
    final page = await fetchDirectSectionPage(
        fetch: echo,
        subject: 'english',
        schoolClass: 9,
        chapter: 1,
        section: 'story',
        lesson: null,
        offset: 0,
        pageSize: 20);
    expect(page, isNotNull);
    expect(page!.mode, GuideFlowMode.serverFiltered);
    expect(page.rows.length, 2);

    Future<Map<String, dynamic>?> silent(Map<String, dynamic> b,
        {String? endpoint}) async {
      return {
        'found': true,
        'total': 2,
        'questions': [_row(0), _row(1)],
      };
    }
    expect(
        await fetchDirectSectionPage(
            fetch: silent,
            subject: 'english',
            schoolClass: 9,
            chapter: 1,
            section: 'story',
            lesson: null,
            offset: 0,
            pageSize: 20),
        isNull);
  });

  test('prefetch cache serves once, then drops', () {
    final cache = GuideFlowPageCache();
    const page = GuideFlowPage(
        rows: [], total: 0, hasMore: false, mode: GuideFlowMode.serverFiltered,
        nextScanOffset: 0);
    cache.put('k@20',
        const GuideFlowPrefetchedPage(page: page, nextBody: {'offset': 20}));
    expect(cache.take('k@20'), isNotNull);
    expect(cache.take('k@20'), isNull);
  });

  test('prefetch without WiFi stores nothing and calls nothing',
      () async {
    var calls = 0;
    Future<Map<String, dynamic>?> fetch(Map<String, dynamic> b,
        {String? endpoint}) async {
      calls++;
      return {
        'found': true,
        'total': 40,
        'questions': List.generate(20, _row),
      };
    }
    final cache = GuideFlowPageCache();
    prefetchGuideFlowPage(
        fetch: fetch,
        cache: cache,
        identity: 'k',
        body: {'action': 'list', 'offset': 0, 'limit': 20},
        pageSize: 20);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(calls, 0);
    expect(cache.take('k@0'), isNull);
  });
}
