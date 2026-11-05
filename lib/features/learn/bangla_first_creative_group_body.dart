// Body of the creative group detail screen: stimulus header,
// part chips (jump to any question), the selected part's
// answer, and the prev/next row. Stateless: the parent owns
// selection + per-part state, mirroring GuideCreativeAnswerView.
import 'package:flutter/material.dart';

import '../../core/models/guide_bank_model.dart';
import 'widgets/guide_answer_body.dart';
import 'widgets/guide_creative_part_loader.dart';
import 'widgets/guide_creative_parts.dart';
import 'widgets/guide_creative_stimulus_header.dart';
import 'widgets/guide_explanation_section.dart';

class BanglaFirstCreativeGroupBody extends StatelessWidget {
  const BanglaFirstCreativeGroupBody({
    super.key,
    required this.parts,
    required this.selected,
    required this.stateOf,
    required this.fontSize,
    required this.stimulusText,
    required this.s,
    required this.ls,
    required this.bs,
    required this.bn,
    required this.onSurface,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
    required this.onFontSmaller,
    required this.onFontLarger,
    required this.onExplainDetailed,
    required this.onExplainSteps,
    required this.onRequestExplanation,
    required this.onAskAi,
  });
  final List<GuideBankQuestion> parts;
  final int selected;
  final CreativePartState Function(GuideBankQuestion) stateOf;
  final double fontSize;
  final String stimulusText;
  final Map<String, String> s;
  final Map<String, String> ls;
  final Map<String, String> bs;
  final bool bn;
  final Color onSurface;
  final void Function(int) onSelect;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onFontSmaller;
  final VoidCallback onFontLarger;
  final void Function(CreativePartState) onExplainDetailed;
  final void Function(CreativePartState) onExplainSteps;
  final void Function(GuideBankQuestion) onRequestExplanation;
  final void Function(GuideBankQuestion) onAskAi;

  String? _keyText(GuideBankQuestion q) {
    if (q.hasKey) return q.options[q.correctOptionIndex!];
    if (q.answerKeyText.isNotEmpty) return q.answerKeyText;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final part = parts[selected];
    final st = stateOf(part);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stimulusText.isNotEmpty)
          GuideCreativeStimulusHeader(
            stimulusText: stimulusText,
            fontSize: fontSize,
            title: bs['stimulusTitle']!,
            color: onSurface,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < parts.length; i++)
                ChoiceChip(
                  label: Text(creativePartLabel(i)),
                  selected: i == selected,
                  onSelected: (_) => onSelect(i),
                ),
            ],
          ),
        ),
        Expanded(
          child: st.loaded
              ? GuideAnswerBody(
                  q: part,
                  showStimulus: false,
                  attempt: st.attempt,
                  keyText: _keyText(part),
                  chips: [
                    ls['sourceGuideQuestion']!,
                    if (_keyText(part) != null) ls['sourceGuideKey']!,
                    ls['sourceAiExplanation']!,
                  ],
                  fontSize: fontSize,
                  onFontSmaller: onFontSmaller,
                  onFontLarger: onFontLarger,
                  verbatimKind: st.verbatimKind,
                  verbatimText: st.verbatimText,
                  correctionNote: st.correctionNote,
                  guideError: st.guideError,
                  showExplanation: st.showExplanation,
                  stepsOnly: st.stepsOnly,
                  onExplainDetailed: () => onExplainDetailed(st),
                  onExplainSteps: () => onExplainSteps(st),
                  explanation: ExplanationSectionInput(
                    requested: st.explanationRequested,
                    pending: st.explaining,
                    unavailable: false,
                    onRequest: () => onRequestExplanation(part),
                    onRetry: () => onRequestExplanation(part),
                  ),
                  onAskAi: () => onAskAi(part),
                  subjectId: 'bangla',
                  chapterNumber: 0,
                  bn: bn,
                  s: s,
                  ls: ls,
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
              label: Text(bs['prevQuestion']!),
            ),
            TextButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              label: Text(bs['nextQuestion']!),
            ),
          ],
        ),
      ],
    );
  }
}
