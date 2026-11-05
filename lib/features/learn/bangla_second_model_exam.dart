// Timed-exam start for a Bangla 2nd MCQ model set, shared
// by the model-tests lesson screen. Mirrors the Bangla 1st
// _startExam pattern with the printed Bangla 2nd MCQ time:
// 30 minutes for the MCQ paper (not Bangla 1st's 15).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/app_config.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../core/services/guide_quiz_service.dart';
import '../practice/practice_store.dart';

Future<void> startBanglaSecondModelExam(
  BuildContext context, {
  required List<GuideBankQuestion> rows,
  required String setId,
  required bool isPremium,
  required bool bn,
  required String noKeyedLabel,
  required VoidCallback onStart,
  required VoidCallback onDone,
}) async {
  if (!isPremium && AppConfig.freeGuideLimit >= 0) {
    context.go('/premium');
    return;
  }
  onStart();
  final candidates = rows
      .where(
          (q) => q.questionType == 'mcq' && q.serverHasKey && !q.guideError)
      .map((q) => GuideQuizCandidate(q, 0))
      .toList();
  final items = await guideQuizService.resolveKeys(candidates,
      subject: 'bangla',
      schoolClass: BanglaSecondFetch.schoolClass,
      bangla: bn,
      limit: candidates.length);
  if (!context.mounted) return;
  if (items.isEmpty) {
    onDone();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(noKeyedLabel)));
    return;
  }
  PracticeSession.modelTestId = 'guide:$setId';
  PracticeSession.modelSubject = 'bangla';
  PracticeSession.modelChapter = '';
  PracticeSession.modelItems = items;
  PracticeSession.modelMinutes = 30;
  PracticeSession.modelIsGuide = true;
  PracticeSession.clearModelExam();
  onDone();
  context.go('/model-test-exam');
}
