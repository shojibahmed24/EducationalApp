// One-page-ahead prefetch for search-flow lists (quick-load
// plan, Phase 5) + the direct server-filtered section attempt
// (Phase 2: the 13 English sections are server-filterable now,
// so a section page no longer needs the client scan).
//
// Prefetch rules: only serverFiltered pages, only one page
// ahead, only on WiFi (fail-closed), never failing the visible
// list. A prefetched page is served once, then dropped; the
// following page is prefetched in its place. Prefetch never
// chains by itself — each step is triggered by a real page
// the user actually opened.
import 'guide_flow_client_scan.dart';
import 'guide_flow_models.dart';
import 'load_connectivity.dart';

class GuideFlowPrefetchedPage {
  const GuideFlowPrefetchedPage({required this.page, required this.nextBody});
  final GuideFlowPage page;

  /// Request body for the page AFTER [page] (offset already
  /// advanced past this page's rows).
  final Map<String, dynamic> nextBody;
}

class GuideFlowPageCache {
  final _pages = <String, GuideFlowPrefetchedPage>{};

  GuideFlowPrefetchedPage? take(String key) => _pages.remove(key);

  void put(String key, GuideFlowPrefetchedPage entry) {
    _pages[key] = entry;
  }
}

/// Direct server-filtered section page. Null when the server
/// cannot filter by section (old server: no section echo, or
/// unreachable) — the caller falls back to the client scan.
/// Section pages stay FULL rows (no slim): poem/story opens
/// need the complete row, and slim would break them.
Future<GuideFlowPage?> fetchDirectSectionPage({
  required GuideFlowPost fetch,
  required String subject,
  required int schoolClass,
  required int chapter,
  required String section,
  required String? lesson,
  required int offset,
  required int pageSize,
}) async {
  final body = <String, dynamic>{
    'action': 'list',
    'classId': schoolClass,
    'subject': subject,
    'chapter': chapter,
    'lesson': lesson,
    'section': section,
    'offset': offset,
    'limit': pageSize,
  };
  final res = await fetch(body);
  if (res == null || res['found'] != true) return null;
  if (res['section'] != section) return null;
  final rows = guideFlowRows(res);
  final total = (res['total'] as num?)?.toInt();
  final hasMore =
      total != null ? offset + rows.length < total : rows.length >= pageSize;
  return GuideFlowPage(
    rows: rows,
    total: total,
    hasMore: hasMore,
    mode: GuideFlowMode.serverFiltered,
    nextScanOffset: 0,
  );
}

/// Prefetch one page ([body] carries its own offset) into
/// [cache] under `identity@offset`. Unawaited by callers;
/// every failure path simply leaves nothing cached. Echoes are
/// verified (a body section/lesson must match the response
/// echo) so a prefetch never caches unfiltered rows as filtered.
void prefetchGuideFlowPage({
  required GuideFlowPost fetch,
  required GuideFlowPageCache cache,
  required String identity,
  required Map<String, dynamic> body,
  required int pageSize,
}) {
  final offset = body['offset'];
  if (offset is! int) return;
  () async {
    try {
      if (!await isWifiOnlyPrefetchAllowed()) return;
      final res = await fetch(body);
      if (res == null || res['found'] != true) return;
      final section = body['section'];
      if (section is String && section.isNotEmpty &&
          res['section'] != section) {
        return;
      }
      final lesson = body['lesson'];
      if (lesson is String && lesson.isNotEmpty &&
          res['lesson'] != lesson) {
        return;
      }
      final rows = guideFlowRows(res);
      if (rows.isEmpty) return;
      final total = (res['total'] as num?)?.toInt();
      final hasMore = total != null
          ? offset + rows.length < total
          : rows.length >= pageSize;
      if (!hasMore) return;
      cache.put(
        '$identity@$offset',
        GuideFlowPrefetchedPage(
          page: GuideFlowPage(
            rows: rows,
            total: total,
            hasMore: hasMore,
            mode: GuideFlowMode.serverFiltered,
            nextScanOffset: 0,
          ),
          nextBody: {...body, 'offset': offset + rows.length},
        ),
      );
    } catch (_) {
      // Prefetch never fails the visible list.
    }
  }();
}
