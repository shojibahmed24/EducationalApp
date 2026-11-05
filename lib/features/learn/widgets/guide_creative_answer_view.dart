// Creative grouped view (step 6, §3): stimulus pinned above the
// part tabs (stays visible across switches); only the answer
// area below changes, always the SELECTED part's own stage-1 +
// explanation. Each part loads/caches its own grounding; a part
// with no printed solution shows the AI-first card for it.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import 'guide_answer_body.dart';
import 'guide_creative_part_loader.dart';
import 'guide_creative_parts.dart';
import 'guide_creative_stimulus_header.dart';
import 'guide_explanation_section.dart';

class GuideCreativeAnswerView extends StatefulWidget {
  const GuideCreativeAnswerView({
    super.key,
    required this.parts,
    required this.stimulusText,
    required this.subjectId,
    required this.chapterNumber,
    required this.schoolClass,
    required this.bn,
    required this.s,
    required this.ls,
    required this.onAskAi,
    this.loader,
  });

  /// All parts of one stimulus, in any order (ordered here).
  final List<GuideBankQuestion> parts;

  /// Stimulus text; empty = no pinned header (body shows the
  /// part question instead — nothing is invented).
  final String stimulusText;
  final String subjectId;
  final int chapterNumber;
  final int schoolClass;
  final bool bn;
  final Map<String, String> s;
  final Map<String, String> ls;

  /// Ask-AI for the tapped part (screen opens grounded chat).
  final void Function(GuideBankQuestion part) onAskAi;

  /// Null = the real per-part loader; tests inject a fake.
  final CreativePartLoader? loader;

  @override
  State<GuideCreativeAnswerView> createState() =>
      _GuideCreativeAnswerViewState();
}

class _GuideCreativeAnswerViewState extends State<GuideCreativeAnswerView> {
  late final List<GuideBankQuestion> _parts =
      orderedCreativeParts(widget.parts);
  final _states = <String, CreativePartState>{};
  int _selected = 0;
  double _fontSize = 16;

  @override
  void initState() {
    super.initState();
    _loadPart(_parts.first);
  }

  CreativePartState _stateOf(GuideBankQuestion p) =>
      _states.putIfAbsent(p.id, () => CreativePartState());
  Future<void> _loadPart(GuideBankQuestion part) async {
    final st = _stateOf(part);
    if (st.loading || st.loaded) return;
    st.loading = true;
    final loader = widget.loader ??
        (p, bn, onStage1) => defaultCreativePartLoader(
              part: p,
              subjectId: widget.subjectId,
              schoolClass: widget.schoolClass,
              bn: bn,
              onStage1: onStage1,
            );
    try {
      final result = await loader(part, widget.bn, (stage1) {
        if (!mounted) return;
        setState(() {
          st.verbatimKind = stage1.verbatimKind;
          st.verbatimText = stage1.verbatimText;
          st.correctionNote = stage1.correctionNote;
          st.guideError = stage1.guideError;
          st.showExplanation = !stage1.hasVerbatim;
          st.grounding = stage1.grounding;
          st.stage1Seen = true;
          st.loaded = true;
        });
      });
      if (!mounted) return;
      setState(() {
        st.verbatimKind = result.verbatimKind;
        st.verbatimText = result.verbatimText;
        st.correctionNote = result.correctionNote;
        st.guideError = result.guideError;
        st.grounding = result.grounding;
        // No stage-1 callback (e.g. an injected loader): derive
        // the initial explanation visibility from the record.
        // With stage-1 seen, keep the user's button taps.
        if (!st.stage1Seen) st.showExplanation = !result.hasVerbatim;
        st.loading = false;
        st.loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        st.loading = false;
        st.loaded = true;
      });
    }
  }

  /// On-demand explanation for one part (2026-11-03 fix): runs
  /// ONLY after the student taps "ব্যাখ্যা দেখুন" (or retry).
  /// A part without grounding reloads first, then chains into
  /// the explanation in the same tap; a failed reload shows the
  /// failed row, whose retry is this method again.
  Future<void> _requestPartExplanation(GuideBankQuestion part) async {
    var st = _stateOf(part);
    if (st.explaining) return;
    if (st.grounding == null) {
      _states[part.id] = CreativePartState();
      await _loadPart(part);
      if (!mounted) return;
      st = _stateOf(part);
      if (st.grounding == null) {
        setState(() => st.explanationRequested = true);
        return;
      }
    }
    setState(() {
      st.explanationRequested = true;
      st.explaining = true;
    });
    final attempt = await runCreativePartExplanation(
      st.grounding!,
      widget.bn,
    );
    if (!mounted) return;
    setState(() {
      st.explaining = false;
      st.attempt = attempt;
    });
  }

  String? _keyText(GuideBankQuestion q) {
    if (q.hasKey) return q.options[q.correctOptionIndex!];
    if (q.answerKeyText.isNotEmpty) return q.answerKeyText;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _parts[_selected];
    final st = _stateOf(selected);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.stimulusText.isNotEmpty)
          GuideCreativeStimulusHeader(
            stimulusText: widget.stimulusText,
            fontSize: _fontSize,
            title: widget.s['stimulusTitle']!,
            color: onSurface,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < _parts.length; i++)
                ChoiceChip(
                  label: Text(creativePartLabel(i)),
                  selected: i == _selected,
                  onSelected: (_) {
                    if (i == _selected) return;
                    setState(() => _selected = i);
                    _loadPart(_parts[i]);
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: st.loaded
              ? GuideAnswerBody(
                  q: selected,
                  // Stimulus is pinned above the tabs; the header
                  // must not render it a second time per part.
                  showStimulus: false,
                  attempt: st.attempt,
                  keyText: _keyText(selected),
                  chips: [
                    widget.ls['sourceGuideQuestion']!,
                    if (_keyText(selected) != null)
                      widget.ls['sourceGuideKey']!,
                    widget.ls['sourceAiExplanation']!,
                  ],
                  fontSize: _fontSize,
                  onFontSmaller: () => setState(
                      () => _fontSize = (_fontSize - 1).clamp(12, 24)),
                  onFontLarger: () => setState(
                      () => _fontSize = (_fontSize + 1).clamp(12, 24)),
                  verbatimKind: st.verbatimKind,
                  verbatimText: st.verbatimText,
                  correctionNote: st.correctionNote,
                  guideError: st.guideError,
                  showExplanation: st.showExplanation,
                  stepsOnly: st.stepsOnly,
                  onExplainDetailed: () => setState(() {
                    st.showExplanation = true;
                    st.stepsOnly = false;
                  }),
                  onExplainSteps: () => setState(() {
                    st.showExplanation = true;
                    st.stepsOnly = true;
                  }),
                  explanation: ExplanationSectionInput(
                    requested: st.explanationRequested,
                    pending: st.explaining,
                    // Creative parts carry no options.
                    unavailable: false,
                    onRequest: () => _requestPartExplanation(selected),
                    onRetry: () => _requestPartExplanation(selected),
                  ),
                  onAskAi: () => widget.onAskAi(selected),
                  subjectId: widget.subjectId,
                  chapterNumber: widget.chapterNumber,
                  bn: widget.bn,
                  s: widget.s,
                  ls: widget.ls,
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
