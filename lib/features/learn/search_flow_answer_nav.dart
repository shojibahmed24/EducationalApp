// Step 7 split (keeps search_flow_list_screen.dart under the
// 250-line cap): the new-flow list URL + the two guide-answer
// openings from that list, plus the textbook answer opening.
// The list URL carries the exact filters (subject/class/source
// /chapter/type/lesson/question number/section, plus the Phase
// 1 setId/chapterless modes); paging itself restarts at the
// first 20 on return — the holder carries filters, not
// scroll/load-more state.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/app_config.dart';
import '../../core/services/edge_post.dart';
import '../../core/services/guide_bank_fetch.dart';
import '../../core/services/guide_bank_service.dart';
import '../../core/services/textbook_chapter_service.dart';
import 'guide_answer_holder.dart';
import 'lesson_selection.dart';

String searchFlowListUrl({
  required String subjectId,
  required int schoolClass,
  required String source,
  required int chapterNumber,
  required String typeName,
  String? lesson,
  int? questionNumber,
  String? section,
  String? setId,
  bool chapterless = false,
  bool board = false,
}) {
  final q = StringBuffer('/search-flow-list?subject=$subjectId'
      '&class=$schoolClass&source=$source'
      '&chapter=$chapterNumber&type=$typeName');
  if (lesson != null) q.write('&lesson=${Uri.encodeComponent(lesson)}');
  if (questionNumber != null) q.write('&questionNumber=$questionNumber');
  if (section != null) q.write('&section=$section');
  if (setId != null) q.write('&setId=$setId');
  if (chapterless) q.write('&chapterless=true');
  if (board) q.write('&board=true');
  return q.toString();
}

bool _unlocked(bool isPremium, int index) =>
    guideBankService.isUnlocked(
        isPremium: isPremium, index: index,
        freeLimit: AppConfig.freeGuideLimit);

/// Single-question open: holder.set() + /guide-answer, with
/// returnTo pointing back at this list. Slim rows (Phase 3)
/// fetch their full row first; any failure falls back to the
/// slim row itself instead of blocking the open.
Future<void> openSearchFlowGuideAnswer(
  BuildContext context, {
  required bool isPremium,
  required int index,
  required GuideBankQuestion q,
  required String subjectId,
  required int chapterNumber,
  required int schoolClass,
  required String returnTo,
}) async {
  if (!_unlocked(isPremium, index)) {
    context.go('/premium');
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
  GuideAnswerHolder.set(q: open, subject: subjectId,
      chapter: chapterNumber, schoolClass: schoolClass,
      returnTo: returnTo);
  context.go('/guide-answer');
}

/// Fix A: creative group open — the exact Step 6 contract
/// (all loaded parts of the stimulus via route extra). The
/// paywall gate is the first part's index, as for singles.
void openSearchFlowGuideGroupAnswer(
  BuildContext context, {
  required bool isPremium,
  required int firstIndex,
  required List<GuideBankQuestion> parts,
  required String stimulusText,
  required String subjectId,
  required int chapterNumber,
  required int schoolClass,
  required String returnTo,
}) {
  if (!_unlocked(isPremium, firstIndex)) {
    context.go('/premium');
    return;
  }
  context.go('/guide-answer', extra: {
    'group': parts,
    'stimulusText': stimulusText,
    'subjectId': subjectId,
    'chapterNumber': chapterNumber,
    'schoolClass': schoolClass,
    'returnTo': returnTo,
  });
}

/// Textbook answer open (moved from the list screen for the
/// line cap): holder.set() + /lesson, same as the old path.
void openSearchFlowBookAnswer(
  BuildContext context, {
  required TextbookChapterQuestion q,
  required String subjectId,
  required int chapterNumber,
  required int schoolClass,
}) {
  LessonSelectionHolder.set(LessonSelection(
      subject: subjectId,
      chapter: chapterNumber,
      page: q.page,
      problem: q.problem ?? 0,
      questionId: q.id,
      schoolClass: schoolClass));
  context.go('/lesson');
}
