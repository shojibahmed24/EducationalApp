// Board guide lists (migration 018 flag, Board revision
// 2026-11-02): flagged board rows live under Board
// sub-sections, not under any chapter number and not under an
// "Others" bucket — so they use the Edge list board scope
// directly, like the chapterless loader uses the chapterless
// scope. The shared list service is chapter-gated and
// untouched (its fetchPage requires an int chapter); this
// loader is the flag-scoped equivalent: one server page
// (20 rows) at the given offset, with the exact filtered
// total. The section narrows to one sub-section (board-mcq
// or board-creative); no type-derived section is ever
// applied here: the generic type->section mapping is Math's
// and would return wrong/empty lists for Biology board rows.
import '../../core/services/app_config.dart';
import '../../core/services/edge_post.dart';
import '../../core/services/guide_flow_client_scan.dart';
import '../../core/services/guide_flow_list_service.dart';

/// One Board page. found:false with pilot-columns-missing maps
/// to filterPending, like the shared service; anything else
/// unreachable maps to unavailable — never demo rows.
Future<GuideFlowPage> fetchBoardPage({
  required String subject,
  required int schoolClass,
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
    'board': true,
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
