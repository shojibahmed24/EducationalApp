// One sub-question card for the English reader (redesign).
// Question, options (MCQ) or printed answer (other types,
// verbatim-first: a 'none' verbatim kind never shows a wrong
// printed answer as trusted), and the on-demand AI explanation.
// Grounding resolves via Mode G on view; the model is called
// ONLY after "ব্যাখ্যা দেখুন" is tapped, and an option-less
// MCQ never calls it (honest note instead).
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/english_translation_service.dart';
import '../../../core/services/explanation_service.dart';
import '../../../core/services/structured_explanation_service.dart';
import 'english_translated_text.dart';
import 'guide_explanation_section.dart';

const _optionLetters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];

class EnglishReaderQuestionCard extends StatefulWidget {
  const EnglishReaderQuestionCard({
    super.key,
    required this.header,
    required this.question,
    required this.schoolClass,
    required this.bn,
    required this.es,
    required this.gs,
    required this.ls,
    this.translate = false,
    this.translationService,
  });
  final String header;
  final GuideBankQuestion question;
  final int schoolClass;
  final bool bn;
  final Map<String, String> es; // english search-flow strings
  final Map<String, String> gs; // guide-bank strings
  final Map<String, String> ls; // lesson strings
  // Translator switch (2026-11-03): when on, question, options
  // and the printed answer go through Bangla translation. The
  // AI explanation still follows the app language, not the
  // switch — it is already Bangla under the Bangla UI.
  final bool translate;
  final EnglishTranslationService? translationService;

  @override
  State<EnglishReaderQuestionCard> createState() =>
      _EnglishReaderQuestionCardState();
}

class _EnglishReaderQuestionCardState
    extends State<EnglishReaderQuestionCard> {
  Grounding? _grounding;
  bool _groundingLoading = true;
  bool _explRequested = false;
  bool _explaining = false;
  StructuredAttempt? _attempt;

  @override
  void initState() {
    super.initState();
    _loadGrounding();
  }

  @override
  void didUpdateWidget(EnglishReaderQuestionCard old) {
    super.didUpdateWidget(old);
    if (old.question.id != widget.question.id) {
      _grounding = null;
      _groundingLoading = true;
      _explRequested = _explaining = false;
      _attempt = null;
      _loadGrounding();
    }
  }

  Future<void> _loadGrounding() async {
    final id = widget.question.id;
    if (id.isEmpty) {
      if (mounted) setState(() => _groundingLoading = false);
      return;
    }
    final grounding = await structuredExplanationService.resolveGuide(
        guideQuestionId: id,
        subject: 'english',
        schoolClass: widget.schoolClass,
        bangla: widget.bn);
    if (!mounted) return;
    setState(() {
      _grounding = grounding;
      _groundingLoading = false;
    });
  }

  List<String> get _options {
    final opts = _grounding?.context?.options;
    return opts != null && opts.isNotEmpty
        ? opts
        : widget.question.options;
  }

  int? get _correctIndex => _grounding?.context?.correctOptionIndex;

  bool get _isMcq => widget.question.questionType == 'mcq';

  bool get _explanationUnavailable =>
      _isMcq && _options.isEmpty && !_groundingLoading;

  /// Question/option/answer text: plain when no translation
  /// service was injected, translated-field widget otherwise.
  Widget _text(String value, TextStyle? style) {
    final service = widget.translationService;
    if (service == null) return Text(value, style: style);
    return EnglishTranslatedText(
      text: value,
      translate: widget.translate,
      service: service,
      failedNote: widget.es['readerTranslateFailed']!,
      retryLabel: widget.es['readerTranslateRetry']!,
      style: style,
    );
  }

  Future<void> _requestExplanation() async {
    if (_explaining) return;
    var grounding = _grounding;
    if (grounding == null || !grounding.found) {
      setState(() => _groundingLoading = true);
      await _loadGrounding();
      if (!mounted) return;
      grounding = _grounding;
    }
    if (grounding == null || !grounding.found) {
      setState(() {
        _groundingLoading = false;
        _explRequested = true;
      });
      return;
    }
    final ctx = grounding.context;
    if (ctx != null &&
        ctx.mcqOptionsMissing &&
        widget.question.options.isEmpty) {
      setState(() => _explRequested = true);
      return;
    }
    setState(() {
      _explRequested = true;
      _explaining = true;
    });
    try {
      final attempt = await structuredExplanationService
          .explainStructured(
              grounding: grounding, style: 'steps', bangla: widget.bn)
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
    final q = widget.question;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ctx = _grounding?.context;
    final verbatim = ctx != null &&
        ctx.verbatimKind != 'none' && ctx.verbatimText.trim().isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.header,
                style:
                    text.titleMedium?.copyWith(fontFamily: 'HindSiliguri')),
            const SizedBox(height: 8),
            _text(q.questionText,
                text.bodyLarge?.copyWith(fontFamily: 'HindSiliguri')),
            if (q.marks != null)
              Text('${q.marks} ${widget.es['marksSuffix']!}',
                  style: text.bodySmall),
            if (_options.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (var i = 0; i < _options.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _correctIndex == i
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${i < _optionLetters.length ? _optionLetters[i] : '${i + 1}'}. ',
                          style: text.bodyMedium?.copyWith(
                              fontFamily: 'HindSiliguri')),
                      Expanded(
                        child: _text(_options[i],
                            text.bodyMedium?.copyWith(
                                fontFamily: 'HindSiliguri')),
                      ),
                      if (_correctIndex == i)
                        const Icon(Icons.check, size: 20),
                    ],
                  ),
                ),
            ],
            if (!_isMcq) ...[
              const SizedBox(height: 12),
              if (_groundingLoading)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else if (verbatim)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.es['readerPrintedAnswer']!,
                          style: text.labelMedium?.copyWith(
                              fontFamily: 'HindSiliguri')),
                      const SizedBox(height: 4),
                      _text(ctx.verbatimText,
                          text.bodyMedium?.copyWith(
                              fontFamily: 'HindSiliguri')),
                    ],
                  ),
                )
              else
                Text(widget.es['readerAnswerUnavailable']!),
            ],
            const SizedBox(height: 12),
            GuideExplanationSection(
              attempt: _attempt,
              question: q,
              chips: const [],
              fontSize: 16,
              s: widget.gs,
              ls: widget.ls,
              stepsOnly: false,
              explanation: ExplanationSectionInput(
                requested: _explRequested, pending: _explaining,
                unavailable: _explanationUnavailable,
                onRequest: _requestExplanation,
                onRetry: _requestExplanation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
