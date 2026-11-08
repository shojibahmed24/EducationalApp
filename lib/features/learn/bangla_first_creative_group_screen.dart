// Creative group detail: the English pattern, rebuilt on the
// shared pieces instead of copied. Stimulus pinned above, part
// chips to jump to any question, the selected part's guide
// answer + on-demand AI explanation below, prev/next at the
// bottom. Part loading, ordering and answer rendering reuse
// guide_creative_part_loader, guide_creative_parts and
// GuideAnswerBody; only the selection state lives here (the
// shared grouped view owns its own selection and cannot be
// driven from outside, so prev/next need this screen).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_first_fetch.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_first_strings.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../../l10n/pages/lesson_strings.dart';
import 'bangla_first_creative_group_body.dart';
import 'guide_answer_screen_body.dart';
import 'widgets/guide_creative_part_loader.dart';
import 'widgets/guide_creative_parts.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class BanglaFirstCreativeGroupScreen extends StatefulWidget {
  const BanglaFirstCreativeGroupScreen({
    super.key,
    required this.parts,
    required this.stimulusText,
    required this.returnTo,
  });
  final List<GuideBankQuestion> parts;
  final String stimulusText;
  final String returnTo;

  @override
  State<BanglaFirstCreativeGroupScreen> createState() =>
      _BanglaFirstCreativeGroupScreenState();
}

class _BanglaFirstCreativeGroupScreenState
    extends State<BanglaFirstCreativeGroupScreen> {
  late final List<GuideBankQuestion> _parts =
      orderedCreativeParts(widget.parts);
  final _states = <String, CreativePartState>{};
  int _selected = 0;
  double _fontSize = 16;

  bool get _bn => languageNotifier.value.languageCode == 'bn';

  @override
  void initState() {
    super.initState();
    if (_parts.isNotEmpty) _loadPart(_parts.first);
  }

  CreativePartState _stateOf(GuideBankQuestion p) =>
      _states.putIfAbsent(p.id, () => CreativePartState());

  Future<void> _loadPart(GuideBankQuestion part) async {
    final st = _stateOf(part);
    if (st.loading || st.loaded) return;
    st.loading = true;
    try {
      final result = await defaultCreativePartLoader(
        part: part,
        subjectId: 'bangla',
        schoolClass: BanglaFirstFetch.schoolClass,
        bn: _bn,
        onStage1: (stage1) {
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
        },
      );
      if (!mounted) return;
      setState(() {
        st.verbatimKind = result.verbatimKind;
        st.verbatimText = result.verbatimText;
        st.correctionNote = result.correctionNote;
        st.guideError = result.guideError;
        st.grounding = result.grounding;
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

  Future<void> _requestPartExplanation(GuideBankQuestion part) async {
    var st = _stateOf(part);
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
    final attempt = await runCreativePartExplanation(st.grounding!, _bn);
    if (!mounted) return;
    setState(() {
      st.explaining = false;
      st.attempt = attempt;
    });
  }

  String get _effectiveStimulus {
    if (widget.stimulusText.isNotEmpty) return widget.stimulusText;
    for (final p in _parts) {
      if (p.stimulusText?.isNotEmpty == true) return p.stimulusText!;
    }
    return '';
  }

  void _select(int i) {
    if (i == _selected) return;
    setState(() => _selected = i);
    _loadPart(_parts[i]);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? guideBankStringsBn : guideBankStringsEn;
        final ls = bn ? lessonStringsBn : lessonStringsEn;
        final bs = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(widget.returnTo),
            ),
            title: Text(bs['creativeTitle']!),
          ),
          body: _parts.isEmpty
              ? Center(child: Text(bs['creativeEmpty']!))
              : BanglaFirstCreativeGroupBody(
                  parts: _parts,
                  selected: _selected,
                  stateOf: _stateOf,
                  fontSize: _fontSize,
                  stimulusText: _effectiveStimulus,
                  s: s,
                  ls: ls,
                  bs: bs,
                  bn: bn,
                  onSurface: onSurface,
                  onSelect: _select,
                  onPrev: _selected > 0
                      ? () => _select(_selected - 1)
                      : null,
                  onNext: _selected < _parts.length - 1
                      ? () => _select(_selected + 1)
                      : null,
                  onFontSmaller: () => setState(
                      () => _fontSize = (_fontSize - 1).clamp(12, 24)),
                  onFontLarger: () => setState(
                      () => _fontSize = (_fontSize + 1).clamp(12, 24)),
                  onExplainDetailed: (st) => setState(() {
                    st.showExplanation = true;
                    st.stepsOnly = false;
                  }),
                  onExplainSteps: (st) => setState(() {
                    st.showExplanation = true;
                    st.stepsOnly = true;
                  }),
                  onRequestExplanation: _requestPartExplanation,
                  onAskAi: (q) => openGuideChat(context, q),
                ),
        );
      },
    );
  }
}
