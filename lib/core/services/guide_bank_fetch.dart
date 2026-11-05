// Shared guide fetch: bulk-first, then parallel paging
// (quick-load plan, Phases 0-2). One place owns the fetch
// shape so chapter, set, and chapterless-bank callers share
// the same speed and the same failure semantics.
//
// - Bulk first: one 'bulk' call (new Edge action) for the
//   whole scope. Old servers answer non-200 -> edgePost null
//   -> caller falls back to paging. Never partial: a bulk
//   answer with fewer rows than its total is treated as a
//   miss, so paging refetches the whole scope exactly.
// - Paging fallback: page 1 learns the total, remaining
//   pages run in concurrent batches (default 5). Pages merge
//   in OFFSET order, never arrival order, so row order is
//   identical to sequential paging. Any page failing fails
//   the whole fetch (null = unavailable, never partial).
// - Dedupe: concurrent identical fetches share one future,
//   so a double-open never doubles the network calls.
// - Timing: debug-only LoadTimer (Phase 0); silent in release.
import 'dart:convert';

import 'load_timing.dart';

typedef GuideFetchPost = Future<Map<String, dynamic>?> Function(
  Map<String, dynamic> body, {
  String? endpoint,
});

class FetchedRows {
  const FetchedRows({required this.rows, required this.total});
  final List<Map<String, dynamic>> rows;
  final int total;
}

final Map<String, Future<FetchedRows?>> _inFlight = {};

String _key(String kind, Map<String, dynamic> base, int pageSize) =>
    '$kind:${jsonEncode({...base, 'pageSize': pageSize})}';

List<Map<String, dynamic>> _asRowMaps(Object? rows) {
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
      .toList();
}

/// One-call whole-scope fetch. Null = no bulk support on this
/// server, bulk answer incomplete, bulk answer malformed, or
/// the post itself threw (a throwing post must never crash the
/// caller: it falls back to paging). Callers fall back to
/// [fetchAllListRows] on null.
Future<FetchedRows?> fetchBulkRows({
  required GuideFetchPost post,
  required Map<String, dynamic> baseBody,
  String label = 'bulk',
}) async {
  final timer = LoadTimer(label);
  Map<String, dynamic>? res;
  try {
    res = await post({'action': 'bulk', ...baseBody});
  } catch (_) {
    res = null;
  }
  if (res == null || res['found'] != true) {
    timer.lap('bulk unavailable, paging fallback');
    timer.done();
    return null;
  }
  final rows = _asRowMaps(res['questions']);
  final total = (res['total'] as num?)?.toInt() ?? rows.length;
  if (rows.isEmpty && total > 0) {
    timer.lap('bulk empty despite total $total');
    timer.done();
    return null;
  }
  if (rows.length < total) {
    // PostgREST clamping or a partial answer: never serve it
    // as complete. Paging refetches the scope exactly.
    timer.lap('bulk partial ${rows.length}/$total, paging fallback');
    timer.done();
    return null;
  }
  timer.lap('bulk ${rows.length}/$total');
  timer.done();
  return FetchedRows(rows: rows, total: total);
}

/// Whole-scope fetch via the list action, parallel-paged.
/// [baseBody] carries classId/subject plus exactly one scope
/// (chapter, setId, chapterless, or board). Null = unreachable
/// or any page failed (fail-closed, never partial).
Future<FetchedRows?> fetchAllListRows({
  required GuideFetchPost post,
  required Map<String, dynamic> baseBody,
  int pageSize = 50,
  int maxRows = 2000,
  int concurrency = 5,
  String label = 'paged',
}) {
  final key = _key('paged', baseBody, pageSize);
  final existing = _inFlight[key];
  if (existing != null) return existing;
  final fut = _fetchAllListRowsInner(
    post: post,
    baseBody: baseBody,
    pageSize: pageSize,
    maxRows: maxRows,
    concurrency: concurrency,
    label: label,
  );
  _inFlight[key] = fut;
  // Cleanup without forking an error: then() with onError
  // handles BOTH outcomes, so no derivative future ever
  // fails unhandled (the caller awaits [fut] and handles it).
  // Block bodies matter: an expression body would return the
  // removed (failed) future and the derivative would adopt
  // its error.
  fut.then<void>((_) {
    _inFlight.remove(key);
  }, onError: (_) {
    _inFlight.remove(key);
  });
  return fut;
}

Future<FetchedRows?> _fetchAllListRowsInner({
  required GuideFetchPost post,
  required Map<String, dynamic> baseBody,
  required int pageSize,
  required int maxRows,
  required int concurrency,
  required String label,
}) async {
  final timer = LoadTimer(label);
  Future<FetchedRows?> onePage(int offset) async {
    Map<String, dynamic>? res;
    try {
      res = await post({
        'action': 'list',
        ...baseBody,
        'offset': offset,
        'limit': pageSize,
      });
    } catch (_) {
      return null;
    }
    if (res == null || res['found'] != true) return null;
    final rows = _asRowMaps(res['questions']);
    final total = (res['total'] as num?)?.toInt() ?? rows.length;
    return FetchedRows(rows: rows, total: total);
  }

  final first = await onePage(0);
  if (first == null) {
    timer.lap('page 0 failed');
    timer.done();
    return null;
  }
  final total = first.total;
  final all = <Map<String, dynamic>>[...first.rows];
  if (all.length >= total || first.rows.length < pageSize) {
    timer.lap('paged ${all.length}/$total in 1 call');
    timer.done();
    return FetchedRows(rows: all, total: total);
  }
  final offsets = <int>[];
  for (var off = pageSize; off < total && off < maxRows; off += pageSize) {
    offsets.add(off);
  }
  var calls = 1;
  for (var i = 0; i < offsets.length; i += concurrency) {
    final batch = offsets.sublist(
      i,
      i + concurrency > offsets.length ? offsets.length : i + concurrency,
    );
    final pages = await Future.wait(batch.map(onePage));
    if (pages.any((p) => p == null)) {
      timer.lap('a page failed, discarding partial');
      timer.done();
      return null;
    }
    for (final p in pages) {
      all.addAll(p!.rows);
    }
    calls += batch.length;
  }
  timer.lap('paged ${all.length}/$total in $calls calls');
  timer.done();
  return FetchedRows(rows: all, total: total);
}

/// Full single row by id (quick-load Phase 3): the tap-side
/// companion of slim list rows. Null = unreachable, unknown
/// id, old server (no 'get' action), or a throwing post —
/// callers fall back to the slim row instead of blocking the open.
Future<Map<String, dynamic>?> fetchFullRowById({
  required GuideFetchPost post,
  required String id,
}) async {
  Map<String, dynamic>? res;
  try {
    res = await post({'action': 'get', 'id': id});
  } catch (_) {
    return null;
  }
  if (res == null || res['found'] != true) return null;
  final q = res['question'];
  if (q is! Map) return null;
  return q.map((k, v) => MapEntry(k.toString(), v));
}
