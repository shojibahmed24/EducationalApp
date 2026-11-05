// English reader screen (redesign 2026-11-03, revised same day):
// a sticky passage box on top (280 high, paragraph groups
// with prev/next inside it), one sub-question at a time below,
// and the question nav + jump bar at the END of the scrolled
// page (never fixed over content, so a long explanation always
// has scroll room below it). The passage box follows the
// CURRENT question's own passage and falls back to the test's
// dominant passage when that question carries none; after the
// last question an end card shows the seen count.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/english_reader_shape.dart';
import '../../core/data/english_redesign.dart';
import '../../core/services/english_reader_service.dart';
import '../../core/services/english_translation_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/english_search_flow_strings.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../../l10n/pages/lesson_strings.dart';
import '../../l10n/pages/search_flow_strings.dart';
import 'widgets/english_reader_end_card.dart';
import 'widgets/english_reader_jump_bar.dart';
import 'widgets/english_reader_passage_box.dart';
import 'widgets/english_reader_question_card.dart';
import 'widgets/english_reader_question_nav.dart';
import 'widgets/guide_message_state.dart';

class EnglishReaderScreen extends StatefulWidget {
  const EnglishReaderScreen({
    super.key,
    required this.schoolClass,
    required this.kind,
    required this.title,
    this.setId,
    this.lesson,
    this.stimulusRef,
    this.workName,
    this.readerService,
    this.translationService,
  });
  final int schoolClass;
  final EnglishReaderKind kind;
  final String title;
  final String? setId;
  final String? lesson;
  final String? stimulusRef;
  final String? workName;
  final EnglishReaderService? readerService;
  final EnglishTranslationService? translationService;

  @override
  State<EnglishReaderScreen> createState() => _EnglishReaderScreenState();
}

class _EnglishReaderScreenState extends State<EnglishReaderScreen> {
  // Shared service for screens opened without an injected one:
  // its scan caches (sets, set rows, bank rows) survive across
  // opens, so a second poem/story/bucket open reuses the first
  // open's fetches instead of refetching 100+ paged calls.
  static final _sharedService = EnglishReaderService();
  late final EnglishReaderService _service;
  // Translator switch (2026-11-03): OFF shows the guide English,
  // ON shows the Bangla translation of every reader field. The
  // choice persists (SharedPreferences) and the shared service
  // keeps its translation cache across opens.
  static final _sharedTranslationService = EnglishTranslationService();
  late final EnglishTranslationService _translationService;
  bool _translate = false;
  EnglishReaderData? _data;
  bool _loading = true;
  bool _unavailable = false;
  int _partIndex = 0;
  int _groupIndex = 0;
  int _questionIndex = 0;
  bool _showEnd = false;
  final _seen = <int>{};

  @override
  void initState() {
    super.initState();
    _service = widget.readerService ?? _sharedService;
    _translationService =
        widget.translationService ?? _sharedTranslationService;
    _translationService.loadEnabled().then((v) {
      if (mounted) setState(() => _translate = v);
    });
    _load();
  }

  Future<void> _load() async {
    final data = await _service.load(EnglishReaderRequest(
      kind: widget.kind,
      schoolClass: widget.schoolClass,
      setId: widget.setId,
      lesson: widget.lesson,
      stimulusRef: widget.stimulusRef,
      workName: widget.workName,
    ));
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _unavailable = data == null;
      if (data != null && data.groups.isNotEmpty) _seen.add(0);
    });
  }

  void _retry() {
    setState(() {
      _loading = true;
      _unavailable = false;
      _data = null;
      _partIndex = _groupIndex = _questionIndex = 0;
      _showEnd = false;
      _seen.clear();
    });
    _load();
  }

  void _jump(int groupIndex) {
    setState(() {
      _groupIndex = groupIndex;
      _questionIndex = 0;
      _partIndex = 0;
      _showEnd = false;
      _seen.add(groupIndex);
    });
  }

  void _nextQuestion() {
    final groups = _data!.groups;
    if (_questionIndex + 1 < groups[_groupIndex].questions.length) {
      setState(() {
        _questionIndex++;
        _partIndex = 0;
      });
    } else if (_groupIndex + 1 < groups.length) {
      setState(() {
        _groupIndex++;
        _questionIndex = 0;
        _partIndex = 0;
        _seen.add(_groupIndex);
      });
    } else {
      setState(() {
        _showEnd = true;
        _partIndex = 0;
      });
    }
  }

  void _prevQuestion() {
    if (_questionIndex > 0) {
      setState(() {
        _questionIndex--;
        _partIndex = 0;
      });
    } else if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _questionIndex = _data!.groups[_groupIndex].questions.length - 1;
        _partIndex = 0;
      });
    }
  }

  /// Passage parts for the CURRENT question: its own stimulus
  /// text when it carries one, else the test's dominant parts.
  /// A multi-passage test therefore shows each question's own
  /// passage instead of one passage for every question.
  List<String> _currentParts() {
    final data = _data;
    if (data == null || data.groups.isEmpty) return const [];
    final q =
        data.groups[_groupIndex].questions[_questionIndex];
    final t = q.stimulusText;
    if (t != null && t.trim().isNotEmpty) {
      return splitPassageParts(t);
    }
    return data.parts;
  }

  /// Chip labels: Q-numbers for tests, section labels for
  /// practice, set labels for poems/stories; empty while loading.
  List<String> _chipLabels(bool bn, Map<String, String> fs) {
    final data = _data;
    if (data == null) return const [];
    return [
      for (final g in data.groups)
        if (widget.kind == EnglishReaderKind.model ||
            widget.kind == EnglishReaderKind.special)
          englishTestQuestionLabel(g.section ?? '') ?? g.section ?? ''
        else if (widget.kind == EnglishReaderKind.poem ||
            widget.kind == EnglishReaderKind.story)
          setDisplayLabel(g.setId, bn)
        else
          fs[englishRedesignSectionStringKey(g.section ?? '')] ??
              g.section ?? ''
    ];
  }

  String _header(bool bn, List<String> labels) {
    final sub =
        bn ? bnDigits(_questionIndex + 1) : '${_questionIndex + 1}';
    return '${labels[_groupIndex]} · $sub';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final es = bn
            ? englishSearchFlowStringsBn
            : englishSearchFlowStringsEn;
        final gs = bn ? guideBankStringsBn : guideBankStringsEn;
        final ls = bn ? lessonStringsBn : lessonStringsEn;
        final fs = bn ? searchFlowStringsBn : searchFlowStringsEn;
        final labels = _chipLabels(bn, fs);
        final parts = _showEnd ? _data!.parts : _currentParts();
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/search-flow?subject=english&class=${widget.schoolClass}')),
            title: Text(widget.title),
            actions: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(es['readerTranslate']!),
                  Switch(
                    value: _translate,
                    onChanged: (v) {
                      setState(() => _translate = v);
                      _translationService.setEnabled(v);
                    },
                  ),
                ],
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _unavailable || _data == null || _data!.groups.isEmpty
                  ? GuideMessageState(
                      title: es['unavailable']!,
                      buttonLabel: es['setsRetry']!,
                      onPressed: _retry,
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 280,
                          child: EnglishReaderPassageBox(
                            title: (widget.kind == EnglishReaderKind.poem ||
                                    widget.kind == EnglishReaderKind.story)
                                ? (widget.workName ?? es['readerPassage']!)
                                : es['readerPassage']!,
                            parts: parts,
                            partIndex: _partIndex,
                            bn: bn,
                            s: es,
                            onPrevPart: () => setState(() => _partIndex--),
                            onNextPart: () => setState(() => _partIndex++),
                            translate: _translate,
                            translationService: _translationService,
                            failedNote: es['readerTranslateFailed']!,
                            retryLabel: es['readerTranslateRetry']!,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (_showEnd)
                                  EnglishReaderEndCard(
                                      seenCount: _seen.length,
                                      groupCount: _data!.groups.length,
                                      s: es,
                                      onBack: () => context.go(
                                          '/search-flow?subject=english&class=${widget.schoolClass}'))
                                else
                                  EnglishReaderQuestionCard(
                                    header: _header(bn, labels),
                                    question: _data!.groups[_groupIndex]
                                        .questions[_questionIndex],
                                    schoolClass: widget.schoolClass,
                                    bn: bn, es: es, gs: gs, ls: ls,
                                    translate: _translate,
                                    translationService: _translationService,
                                  ),
                                if (!_showEnd)
                                  EnglishReaderQuestionNav(
                                    canPrev:
                                        _groupIndex > 0 || _questionIndex > 0,
                                    s: es,
                                    onPrev: _prevQuestion,
                                    onNext: _nextQuestion,
                                  ),
                                EnglishReaderJumpBar(
                                  labels: labels,
                                  current: _groupIndex,
                                  seen: _seen,
                                  onJump: _jump,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}
