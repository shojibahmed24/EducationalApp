// Chapterless guide lists (Phase 1): Bangla lesson browsing and
// Paper-II section browsing have no chapter number, so they use
// the Edge list chapterless scope directly. The shared list
// service is chapter-gated and untouched (its fetchPage requires
// an int chapter); this loader is the chapter-free equivalent:
// one server page (20 rows) at the given offset, with the exact
// filtered total. No type-derived section is ever applied here:
// the generic type->section mapping is Math's (mcq_bank etc.)
// and would return wrong/empty lists for Bangla/Paper-II — the
// caller passes an explicit section (Paper-II) or none (Bangla
// lesson browsing shows every row of the lesson).
import '../../core/services/app_config.dart';
import '../../core/services/edge_post.dart';
import '../../core/services/guide_flow_client_scan.dart';
import '../../core/services/guide_flow_list_service.dart';

/// One chapterless page. [lesson] and [section] are the exact
/// Edge filters (lesson sent verbatim, as returned by
/// guideLessons). found:false with pilot-columns-missing maps
/// to filterPending, like the shared service; anything else
/// unreachable maps to unavailable — never demo rows.
Future<GuideFlowPage> fetchChapterlessLessonPage({
  required String subject,
  required int schoolClass,
  String? lesson,
  String? section,
  int offset = 0,
}) async {
  const unavailable = GuideFlowPage(
      rows: [],
      total: null,
      hasMore: false,
      mode: GuideFlowMode.unavailable,
      nextScanOffset: 0);
  if (AppConfig.guideBankEndpoint.isEmpty) return unavailable;
  final res = await edgePost({
    'action': 'list',
    'classId': schoolClass,
    'subject': subject,
    'chapterless': true,
    if (lesson != null) 'lesson': lesson,
    if (section != null) 'section': section,
    'offset': offset,
    'limit': GuideFlowListService.pageSize,
  }, endpoint: AppConfig.guideBankEndpoint)
      .catchError((_) => null);
  if (res == null) return unavailable;
  if (res['found'] != true) {
    return GuideFlowPage(
        rows: [],
        total: null,
        hasMore: false,
        mode: res['reason'] == 'pilot-columns-missing'
            ? GuideFlowMode.filterPending
            : GuideFlowMode.unavailable,
        nextScanOffset: 0);
  }
  final rows = guideFlowRows(res);
  final total = (res['total'] as num?)?.toInt();
  return GuideFlowPage(
      rows: rows,
      total: total,
      hasMore: total != null
          ? offset + rows.length < total
          : rows.length >= GuideFlowListService.pageSize,
      mode: GuideFlowMode.serverFiltered,
      nextScanOffset: 0);
}
