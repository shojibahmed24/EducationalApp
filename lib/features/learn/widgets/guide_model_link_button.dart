// 'Model answer' link (Phase 3): on a Q10-12 test row, opens
// the linked bank model row's answer. The model row's text
// comes from Mode G (resolveGuide by id); the holder is
// single-slot, so back from the model answer returns to the
// list (holder.returnTo is left untouched), never to the test
// row. A failed resolve navigates nowhere.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/structured_explanation_service.dart';
import '../../../l10n/language_provider.dart';
import '../guide_answer_holder.dart';

class GuideModelLinkButton extends StatefulWidget {
  final String modelQuestionId;
  final String label;
  const GuideModelLinkButton({
    super.key,
    required this.modelQuestionId,
    required this.label,
  });

  @override
  State<GuideModelLinkButton> createState() => _GuideModelLinkButtonState();
}

class _GuideModelLinkButtonState extends State<GuideModelLinkButton> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final grounding = await structuredExplanationService
          .resolveGuide(
            guideQuestionId: widget.modelQuestionId,
            subject: GuideAnswerHolder.subjectId,
            schoolClass: GuideAnswerHolder.schoolClass,
            bangla: languageNotifier.value.languageCode == 'bn',
          )
          .timeout(const Duration(seconds: 45));
      if (!mounted) return;
      final ctx = grounding.context;
      if (!grounding.found || ctx == null) return;
      GuideAnswerHolder.set(
        q: GuideBankQuestion(
          id: widget.modelQuestionId,
          questionText: ctx.questionText,
          questionType: ctx.questionType,
        ),
        subject: GuideAnswerHolder.subjectId,
        chapter: GuideAnswerHolder.chapterNumber,
        schoolClass: GuideAnswerHolder.schoolClass,
      );
      if (!mounted) return;
      context.go('/guide-answer');
    } catch (_) {
      // Stay on the test answer; nothing navigated.
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _opening ? null : _open,
      icon: _opening
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.menu_book_outlined),
      label: Text(widget.label),
    );
  }
}
