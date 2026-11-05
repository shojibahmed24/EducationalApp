// Route: /lesson — AI Answer Reader, TEXT ONLY. Grounded via the
// Edge Function; a questionId selection resolves BY ID instead
// of by page/problem. No bKash — deliberately absent, Play only.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/solution_model.dart';
import '../../core/services/explanation_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/lesson_strings.dart';
import 'learn_store.dart';
import 'lesson_answer_body.dart';
import 'lesson_bookmark_button.dart';
import 'lesson_grounding.dart';
import 'lesson_helpers.dart';
import 'lesson_selection.dart';
import 'lesson_style_runner.dart';
import 'widgets/digits.dart';
import 'widgets/mock_data.dart';
import '../../theme/themed_scaffold.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  double _fontSize = 15;
  bool _saved = false;
  bool _loading = false;
  bool _autoFetched = false;
  String? _displayText;
  String? _fallbackText;
  String? _keyMismatchKey;
  StructuredSolution? _solution;
  // pending | demo | live | unverified. NOTHING is ever shown
  // under "verified": demo text is "demo", failed-AI book text
  // is "unverified", live AI is "live".
  String _source = 'pending';
  String _aiProvider = 'unknown';
  String? _aiModel;
  Grounding? _grounding; // async Edge result; null = not arrived yet

  LessonSelection get _sel => LessonSelectionHolder.current;

  bool get _syncGrounded => syncGrounded(_sel);

  /// Auto-fetch running with no answer on screen yet: the body
  /// shows a loading state instead of the local base answer, so
  /// un-fetched text never sits under any source label.
  bool get _awaitingAnswer =>
      _loading &&
      _solution == null &&
      _displayText == null &&
      _fallbackText == null &&
      _keyMismatchKey == null;

  @override
  void initState() {
    super.initState();
    // Only grounded lessons count as opened (no-match visits
    // must not inflate Home stats); async result records too.
    if (_syncGrounded) LearnStore.recordLesson(_sel.key, _sel.chapterKey);
    LearnStore.isSaved(_sel.key).then((v) { if (mounted) setState(() => _saved = v); });
    resolveLessonGrounding(
      _sel,
      languageNotifier.value.languageCode == 'bn',
    ).then((g) {
      if (!mounted) return;
      setState(() => _grounding = g);
      if (g.found && !_syncGrounded) {
        LearnStore.recordLesson(_sel.key, _sel.chapterKey);
      }
      // Auto-fetch on open: a grounded lesson shows its live
      // structured explanation without waiting for a style chip.
      // Ungrounded lessons keep the not-indexed branch below.
      if (g.found && !_autoFetched) {
        _autoFetched = true;
        _applyStyle('steps', languageNotifier.value.languageCode == 'bn');
      }
    });
  }

  Future<void> _applyStyle(String style, bool bn) async {
    final s = bn ? lessonStringsBn : lessonStringsEn;
    setState(() => _loading = true);
    final r = await runLessonStyle(
      grounding: _grounding,
      sel: _sel,
      style: style,
      bn: bn,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _solution = r.solution;
      _displayText = r.displayText;
      _fallbackText = r.fallbackText;
      _keyMismatchKey = r.keyMismatchKey;
      _source = r.source;
      _aiProvider = r.aiProvider;
      _aiModel = r.aiModel;
    });
    switch (r.outcome) {
      case 'noMatch':
        context.go('/lesson/no-match');
        return;
      case 'serverKeyMissing':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s['aiServerKeyMissing']!)),
        );
        return;
      case 'failed':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s['aiFailed']!)),
        );
        return;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? lessonStringsBn : lessonStringsEn;
        // Async Edge result wins when arrived (no no-match flash).
        // By-id stays "pending" until its result arrives; a 0
        // problem is never displayed.
        final g = _grounding;
        final isGrounded = _sel.questionId != null
            ? (g?.found ?? true)
            : (g != null ? g.found : _syncGrounded);
        final chapterOnly = g != null && g.reason == 'chapter-only';
        final edgeQuestion = g?.context?.questionText ?? '';
        final questionText = _sel.key == 'math|3|45|5'
            ? s['question']!
            : (edgeQuestion.isNotEmpty ? edgeQuestion : syncQuestion(_sel));
        final chip = '${subjectNameFor(_sel.subject, bn)} · '
            '${bn ? 'অধ্যায়' : 'Chapter'} ${numStr(_sel.chapter, bn)} · '
            '${bn ? 'পৃষ্ঠা' : 'Page'} ${numStr(_sel.page, bn)}${_sel.problem == 0 ? '' : ' · ${bn ? 'প্রশ্ন' : 'Question'} ${numStr(_sel.problem, bn)}'}';
        final ctx = g?.context;
        return ThemedScaffold(
          calm: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/search'),
            ),
            title: Text(s['title']!),
            actions: [
              LessonBookmarkButton(
                sel: _sel,
                saved: _saved,
                s: s,
                onSavedChanged: (v) => setState(() => _saved = v),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(chip)),
                const SizedBox(height: 12),
                if (!isGrounded) ...[
                  Text(
                      chapterOnly ? s['chapterOnly']! : s['notIndexed']!,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/lesson/no-match'),
                    child: Text(s['goToNoMatch']!),
                  ),
                ] else if (_awaitingAnswer) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 12),
                  Center(child: Text(s['loadingAnswer']!)),
                ] else
                  LessonAnswerBody(
                    s: s,
                    sel: _sel,
                    bn: bn,
                    questionText: questionText,
                    sourceLabel: _source == 'demo'
                        ? s['demoAnswer']!
                        : _source == 'live'
                            ? s['liveAnswer']!
                            : _source == 'pending'
                                ? s['loadingAnswer']!
                                : s['unverifiedAnswer']!,
                    fontSize: _fontSize,
                    onFontSmaller: () => setState(
                        () => _fontSize = (_fontSize - 1).clamp(13, 20)),
                    onFontLarger: () => setState(
                        () => _fontSize = (_fontSize + 1).clamp(13, 20)),
                    loading: _loading,
                    displayText: _displayText,
                    solution: _solution,
                    fallbackText: _fallbackText,
                    keyMismatchKey: _keyMismatchKey,
                    isGuide: ctx?.source == 'guide',
                    hasAnswerKey: ctx?.answerKey.isNotEmpty ?? false,
                    showSourceChips: _solution != null ||
                        _fallbackText != null,
                    marksPrinted: ctx?.marksPrinted ?? false,
                    aiProvider: _aiProvider,
                    aiModel: _aiModel,
                    onStyle: (style) => _applyStyle(style, bn),
                    onPractice: () => context.go('/practice'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
