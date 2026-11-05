// Section scan for the English guide search flow (ENGLISH_REDO_PLAN
// §2 step 6). WHY client-side: the deployed guide-bank list `section`
// parameter only accepts the five math values (list.ts
// LIST_SECTION_VALUES); any other value is HTTP 400. English Paper-I
// sections are NOT in that allowlist, and Edge code must not change
// here — so the section filter runs client-side on the row.section
// the list response already echoes. A future Edge allowlist
// extension could switch this path to server-side filtering; until
// then this scan IS the filter, and it never sends an English
// section value as the server `section` parameter.
// Lesson (a free string, no allowlist) IS sent server-side when
// given; if the server does not echo it, the filter is honestly
// filterPending. Pages are scanned 50 at a time; `total` stays
// unknown and hasMore means "the server list is not exhausted".
import '../models/guide_bank_model.dart';
import 'guide_flow_client_scan.dart';
import 'guide_flow_models.dart';

/// One display page (<= 20 matched rows) of a single section.
Future<GuideFlowPage> guideFlowSectionPage({
  required GuideFlowPost fetch,
  required String subject,
  required int schoolClass,
  required int chapter,
  required String section,
  required String? lesson,
  required int scanOffset,
}) async {
  const pageSize = 20;
  const fetchSize = 50;
  final matched = <GuideBankQuestion>[];
  var scan = scanOffset;
  var exhausted = false;
  var pages = 0;
  var first = true;
  while (matched.length < pageSize && !exhausted && pages < 50) {
    pages++;
    final res = await fetch({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      if (lesson != null) 'lesson': lesson,
      'offset': scan,
      'limit': fetchSize,
    });
    if (res == null || res['found'] != true) {
      if (first) {
        return GuideFlowPage(
            rows: const [],
            total: null,
            hasMore: false,
            mode: res != null && res['reason'] == 'pilot-columns-missing'
                ? GuideFlowMode.filterPending
                : GuideFlowMode.unavailable,
            nextScanOffset: 0);
      }
      // Mid-scan failure: return what matched, keep the scan
      // offset so "আরো দেখুন" retries the same page — never a
      // false "end of list".
      return GuideFlowPage(
          rows: matched,
          total: null,
          hasMore: true,
          mode: GuideFlowMode.clientFiltered,
          nextScanOffset: scan);
    }
    if (first && lesson != null && !res.containsKey('lesson')) {
      return const GuideFlowPage(
          rows: [],
          total: null,
          hasMore: false,
          mode: GuideFlowMode.filterPending,
          nextScanOffset: 0);
    }
    first = false;
    final rows = guideFlowRows(res);
    for (final r in rows) {
      if (r.section == section) matched.add(r);
    }
    scan += rows.length;
    final total = (res['total'] as num?)?.toInt();
    if (rows.length < fetchSize || (total != null && scan >= total)) {
      exhausted = true;
    }
  }
  return GuideFlowPage(
      rows: matched,
      total: null,
      hasMore: !exhausted,
      mode: GuideFlowMode.clientFiltered,
      nextScanOffset: scan);
}

/// Positional jump through a section scan: the Nth row of the
/// section-filtered list (guide rows have no printed number).
Future<GuideFlowJump> guideFlowSectionJump({
  required GuideFlowPost fetch,
  required String subject,
  required int schoolClass,
  required int chapter,
  required String section,
  required String? lesson,
  required int position,
}) async {
  const fetchSize = 50;
  var scan = 0;
  var seen = 0;
  var first = true;
  for (var pages = 0; pages < 100; pages++) {
    final res = await fetch({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      if (lesson != null) 'lesson': lesson,
      'offset': scan,
      'limit': fetchSize,
    });
    if (res == null || res['found'] != true) {
      if (first && res != null && res['reason'] == 'pilot-columns-missing') {
        return const GuideFlowJump(
            question: null, outcome: GuideFlowJumpOutcome.filterPending);
      }
      return const GuideFlowJump(
          question: null, outcome: GuideFlowJumpOutcome.unavailable);
    }
    if (first && lesson != null && !res.containsKey('lesson')) {
      return const GuideFlowJump(
          question: null, outcome: GuideFlowJumpOutcome.filterPending);
    }
    first = false;
    final rows = guideFlowRows(res);
    for (final r in rows) {
      if (r.section != section) continue;
      seen++;
      if (seen == position) {
        return GuideFlowJump(
            question: r, outcome: GuideFlowJumpOutcome.found);
      }
    }
    scan += rows.length;
    final total = (res['total'] as num?)?.toInt();
    if (rows.length < fetchSize || (total != null && scan >= total)) break;
  }
  return const GuideFlowJump(
      question: null, outcome: GuideFlowJumpOutcome.notFound);
}
