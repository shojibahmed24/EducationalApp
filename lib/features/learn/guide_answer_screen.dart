// Route: /guide-answer — answer for one guide bank question
// (via GuideAnswerHolder). Mode G resolveGuide grounding;
// honestly reports unavailable, never demo data as real.
// Verbatim-first: the guide's own answer shows first when the
// server marks it verbatim, else the AI explanation directly
// (or behind detail/steps buttons when verbatim exists).
// ON-DEMAND (2026-11-03 fix): the AI explanation runs ONLY
// after the student taps "ব্যাখ্যা দেখুন" — opening the screen
// never starts a generation call.
import 'package:flutter/material.dart';

import '../../core/services/explanation_service.dart';
import '../../core/services/structured_explanation_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../../l10n/pages/lesson_strings.dart';
import 'guide_answer_holder.dart';
import 'guide_answer_screen_body.dart';
import 'widgets/guide_message_state.dart';
import 'widgets/guide_translate_switch.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class GuideAnswerScreen extends StatefulWidget {
  const GuideAnswerScreen({super.key});

  @override
  State<GuideAnswerScreen> createState() => _GuideAnswerScreenState();
}

class _GuideAnswerScreenState extends State<GuideAnswerScreen> {
  bool _loading = true;
  bool _unavailable = false;
  StructuredAttempt? _attempt;
  // On-demand explanation state: _explaining covers the window
  // of a REQUESTED run only; the section shows the button until
  // the student taps it, never a pending row on screen open.
  bool _explaining = false;
  bool _explanationRequested = false;
  Grounding? _grounding;
  List<String> _modeGOptions = const [];
  double _fontSize = 16;
  String _verbatimKind = 'none';
  String _verbatimText = '';
  String _guideExplanation = '';
  String _answerKeyLetter = '';
  String _correctionNote = '';
  bool _guideError = false;
  bool _showExplanation = true;
  bool _stepsOnly = false;

  @override
  void initState() {
    super.initState();
    // Group mode loads its own parts; skip the duplicate single _load.
    if (GuideAnswerHolder.group == null) _load();
  }

  Future<void> _load() async {
    final q = GuideAnswerHolder.question;
    if (q == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
      }
      return;
    }
    final bn = languageNotifier.value.languageCode == 'bn';
    // resolveGuide 45s. Stage-1 renders first; the AI explanation
    // is NOT started here (on-demand: the student taps for it).
    // Failures -> honest failed state + retry; found=false ->
    // unavailable; demo data is never shown as real.
    try {
      final grounding = await structuredExplanationService
          .resolveGuide(
            guideQuestionId: q.id,
            subject: GuideAnswerHolder.subjectId,
            schoolClass: GuideAnswerHolder.schoolClass,
            bangla: bn,
          )
          .timeout(const Duration(seconds: 45));
      if (!mounted) return;
      if (!grounding.found) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
        return;
      }
      final ctx = grounding.context;
      if (ctx != null) {
        _verbatimKind = ctx.verbatimKind;
        _verbatimText = ctx.verbatimText;
        _guideExplanation = ctx.guideExplanation;
        _answerKeyLetter = ctx.answerKey;
        _correctionNote = ctx.correctionNote;
        _guideError = ctx.guideError;
        _showExplanation = !ctx.hasVerbatim;
        _modeGOptions = ctx.options;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _grounding = grounding;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _attempt = null;
      });
    }
  }

  /// On-demand explanation (2026-11-03 fix): runs ONLY after the
  /// student taps "ব্যাখ্যা দেখুন" (or retry). A missing
  /// grounding reloads first, then chains into the explanation
  /// in the same tap; an option-less MCQ never calls the model
  /// (the section shows the honest note instead).
  Future<void> _requestExplanation() async {
    if (_explaining) return;
    var grounding = _grounding;
    if (grounding == null || !grounding.found) {
      if (mounted) setState(() => _loading = true);
      await _load();
      if (!mounted) return;
      grounding = _grounding;
    }
    if (grounding == null || !grounding.found) {
      if (mounted) {
        setState(() {
          _loading = false;
          _explanationRequested = true;
        });
      }
      return;
    }
    final q = GuideAnswerHolder.question;
    final ctx = grounding.context;
    if (q != null &&
        ctx != null &&
        ctx.mcqOptionsMissing &&
        q.options.isEmpty) {
      if (mounted) setState(() => _explanationRequested = true);
      return;
    }
    final bn = languageNotifier.value.languageCode == 'bn';
    if (mounted) {
      setState(() {
        _explanationRequested = true;
        _explaining = true;
      });
    }
    try {
      final attempt = await structuredExplanationService
          .explainStructured(grounding: grounding, style: 'steps', bangla: bn)
          .timeout(const Duration(seconds: 120));
      if (!mounted) return;
      setState(() {
        _explaining = false;
        _attempt = attempt;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _explaining = false;
        _attempt = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? guideBankStringsBn : guideBankStringsEn;
        final ls = bn ? lessonStringsBn : lessonStringsEn;
        final q = GuideAnswerHolder.question;
        return ThemedScaffold(calm: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => goGuideBack(context),
            ),
            title: Text(s['title']!),
            // Translator switch, English flow only: same
            // preference as the reader switch, so turning it
            // on here also turns it on in the reader and
            // vice versa. Other subjects never see it.
            actions: [
              if (GuideAnswerHolder.subjectId == 'english')
                const GuideTranslateSwitch(),
            ],
          ),
          body: guideGroupBody(context, bn, s, ls) ??
              (_loading
              ? Center(child: Text(s['loading']!))
              : (_unavailable || q == null)
              ? GuideMessageState(
                  title: s['answerUnavailable']!,
                  buttonLabel: s['back']!,
                  onPressed: () => goGuideBack(context),
                )
              : guideAnswerScreenBody(
                  q: q,
                  bn: bn,
                  s: s,
                  ls: ls,
                  attempt: _attempt,
                  answerKeyLetter: _answerKeyLetter,
                  modeGOptions: _modeGOptions,
                  fontSize: _fontSize,
                  onFontSmaller: () => setState(
                      () => _fontSize = (_fontSize - 1).clamp(12, 24)),
                  onFontLarger: () => setState(
                      () => _fontSize = (_fontSize + 1).clamp(12, 24)),
                  verbatimKind: _verbatimKind,
                  verbatimText: _verbatimText,
                  guideExplanation: _guideExplanation,
                  correctionNote: _correctionNote,
                  guideError: _guideError,
                  showExplanation: _showExplanation,
                  explanationRequested: _explanationRequested,
                  explaining: _explaining,
                  stepsOnly: _stepsOnly,
                  onExplainDetailed: () => setState(() {
                    _showExplanation = true;
                    _stepsOnly = false;
                  }),
                  onExplainSteps: () => setState(() {
                    _showExplanation = true;
                    _stepsOnly = true;
                  }),
                  onRequestExplanation: _requestExplanation,
                  onAskAi: () => openGuideChat(context, q),
                  subjectId: GuideAnswerHolder.subjectId,
                  chapterNumber: GuideAnswerHolder.chapterNumber,
                )),
        );
      },
    );
  }
}
