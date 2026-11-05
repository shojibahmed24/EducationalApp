// Nirmiti screen "প্রশ্ন দেখুন" opener (split out to keep the
// nirmiti screen under the 250-line cap). All kinds use the
// single-question answer flow, EXCEPT onubad: a translation
// needs its English passage visible, and the single flow never
// renders a row's stimulusText. So onubad opens the existing
// passage-pinned group flow with the single row as its only
// part: passage pinned above, Bangla translation as the part's
// guide answer (Mode G, verbatim). Slim rows fetch their full
// row first so the passage is never lost.
import 'package:flutter/material.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/app_config.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../core/services/edge_post.dart';
import '../../core/services/guide_bank_fetch.dart';
import 'search_flow_answer_nav.dart';

Future<void> openBanglaSecondNirmitiAnswer(
  BuildContext context, {
  required String kind,
  required bool isPremium,
  required int index,
  required GuideBankQuestion q,
  required String returnTo,
}) async {
  if (kind != 'onubad') {
    await openSearchFlowGuideAnswer(
      context,
      isPremium: isPremium,
      index: index,
      q: q,
      subjectId: 'bangla',
      chapterNumber: 0,
      schoolClass: BanglaSecondFetch.schoolClass,
      returnTo: returnTo,
    );
    return;
  }
  var open = q;
  if (q.slim && AppConfig.guideBankEndpoint.isNotEmpty) {
    final full = await fetchFullRowById(
        post: (body, {endpoint}) =>
            edgePost(body, endpoint: AppConfig.guideBankEndpoint),
        id: q.id);
    if (full != null) open = GuideBankQuestion.fromServerJson(full);
  }
  openSearchFlowGuideGroupAnswer(
    context,
    isPremium: isPremium,
    firstIndex: index,
    parts: [open],
    stimulusText: open.stimulusText ?? '',
    subjectId: 'bangla',
    chapterNumber: 0,
    schoolClass: BanglaSecondFetch.schoolClass,
    returnTo: returnTo,
  );
}
