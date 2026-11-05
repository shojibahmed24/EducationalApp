// Route: /quiz. Tap option -> Submit checks it -> Next/Prev
// navigate, Finish saves and goes to results. Elapsed time counts
// up, stops on finish. 'স্যারের সহজ ব্যাখ্যা' comes from
// explanation_service: book-grounded Edge AI, a labelled DEMO
// fallback with no server path, never a substituted guess.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/explanation_service.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/core/services/quiz_explanation_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/quiz_explanation_body.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/features/practice/widgets/quiz_footer_actions.dart';
import 'package:yes_sir_ai/features/practice/widgets/quiz_source_header.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/quiz_question_strings.dart';
import '../../theme/themed_scaffold.dart';

class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({super.key});
  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen>
    with WidgetsBindingObserver {
  late List<QuizItem> _items;
  final Map<int, int> _answers = {};
  final Set<int> _checked = {};
  int _index = 0, _elapsed = 0;
  Timer? _timer;
  // Phase 17 (L3): count-up pauses in background (old: kept counting).
  bool _inBackground = false;
  bool _finishing = false;
  // Explanation state per question index (live / DEMO / missing),
  // cached across Prev/Next like the answers.
  final Map<int, String> _explanations = {};
  final Map<int, String> _explanationKind = {}; // live|demo|demo-bank|missing
  // Attribution per index, from the Edge response (see
  // GenResult); cleared with the other per-question state on
  // bank-switch, so a stale label never sticks to a new item.
  final Map<int, String> _explanationProvider = {};
  final Map<int, String?> _explanationModel = {};
  final Set<int> _loadingExplanation = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (PracticeSession.quizItems.isEmpty) {
      // Deep-link fallback: a bank set, labelled as such.
      PracticeSession.quizItems =
          practiceService.dailyQuizFor(PracticeSession.selectedSubject);
      PracticeSession.quizSource = 'bankFallback';
      PracticeSession.quizShortfall = 0;
    }
    _items = PracticeSession.quizItems;
    PracticeSession.quizItems = _items;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_inBackground) setState(() => _elapsed++);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _inBackground = state != AppLifecycleState.resumed;

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _timer?.cancel(); super.dispose(); }
  QuizItem get _q => _items[_index];
  bool get _isChecked => _checked.contains(_index);
  bool get _isLast => _index == _items.length - 1;
  String get _clock => '${(_elapsed ~/ 60).toString().padLeft(2, '0')}:${(_elapsed % 60).toString().padLeft(2, '0')}';

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    var correct = 0;
    for (final e in _answers.entries) {
      if (_items[e.key].isCorrect(e.value)) correct++;
    }
    final attempt = Attempt(kind: 'quiz', testId: 'quiz-${PracticeSession.selectedSubject}',
        subject: PracticeSession.selectedSubject, chapter: PracticeSession.selectedSubject,
        correct: correct, total: _items.length, seconds: _elapsed,
        date: PracticeSession.today(),
        answers: {for (final e in _answers.entries) _items[e.key].id: e.value},
        // Phase 2: persist the actual wrong items (guide items
        // included) so weak chapters + revision can use them.
        wrongItems: [for (final e in _answers.entries)
          if (!_items[e.key].isCorrect(e.value)) _items[e.key]]);
    await practiceService.recordAttempt(attempt);
    // Phase 17 (L8): best-effort server progress write, local first.
    await progressService.syncToServer();
    PracticeSession.lastItems = _items;
    if (mounted) context.go('/quiz-results');
  }

  void _primary() {
    if (!_isChecked) {
      if (!_answers.containsKey(_index)) {
        final bangla = languageNotifier.value.languageCode == 'bn';
        final msg = bangla ? quizQuestionStringsBn['selectFirst']! : quizQuestionStringsEn['selectFirst']!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      setState(() => _checked.add(_index));
      _loadExplanation(_index);
    } else if (_isLast) {
      _finish();
    } else {
      setState(() => _index++);
    }
  }

  /// Fetches 'স্যারের সহজ ব্যাখ্যা' for one checked question.
  /// Live-but-unmatched stays 'missing' (DEMO bank never substituted).
  Future<void> _loadExplanation(int index) async {
    if (_explanations.containsKey(index) ||
        _explanationKind.containsKey(index) ||
        _loadingExplanation.contains(index)) {
      return;
    }
    setState(() => _loadingExplanation.add(index));
    final bangla = languageNotifier.value.languageCode == 'bn';
    final res = await quizExplanationService.explainQuiz(
      item: _items[index],
      subject: PracticeSession.selectedSubject,
      bangla: bangla,
    );
    if (!mounted) return;
    setState(() {
      _loadingExplanation.remove(index);
      if (res.outcome == ExplanationOutcome.live) {
        _explanations[index] = res.text;
        _explanationKind[index] = 'live';
        _explanationProvider[index] = res.aiProvider;
        _explanationModel[index] = res.aiModel;
      } else if (res.outcome == ExplanationOutcome.demo) {
        _explanations[index] = res.text;
        _explanationKind[index] =
            res.demoKind == 'bank' ? 'demo-bank' : 'demo';
      } else if (res.serverKeyMissing) {
        _explanationKind[index] = 'serverKeyMissing';
      } else if (res.guideMissing) {
        _explanationKind[index] = 'guideMissing';
      } else {
        _explanationKind[index] = 'missing';
      }
    });
  }

  /// Bank button (short guide set): rebuild the set from the
  /// bank with the same seed and reset all per-question state.
  void _switchToBank() {
    final items = practiceService.dailyQuizFor(
        PracticeSession.selectedSubject,
        seedKey: PracticeSession.quizSeedKey,
        count: 20);
    PracticeSession.quizItems = items;
    PracticeSession.quizSource = 'bankFallback';
    PracticeSession.quizShortfall = 0;
    setState(() {
      _items = items;
      _answers.clear();
      _checked.clear();
      _explanations.clear();
      _explanationKind.clear();
      _explanationProvider.clear();
      _explanationModel.clear();
      _loadingExplanation.clear();
      _index = 0;
      _elapsed = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? quizQuestionStringsBn : quizQuestionStringsEn;
      final bangla = locale.languageCode == 'bn';
      final chosen = _answers[_index];
      return ThemedScaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/practice'),
          ),
          title: Text(s['title']!),
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          QuizSourceHeader(
            source: PracticeSession.quizSource,
            shortfall: PracticeSession.quizShortfall,
            count: _items.length,
            isRevision: PracticeSession.quizIsRevision,
            s: s,
            onBankSet: _switchToBank,
          ),
          const SizedBox(height: 8),
          Row(children: [Text("${s['qLabel']!} ${_index + 1}/${_items.length}", style: Theme.of(context).textTheme.headlineMedium), const Spacer(), Chip(label: Text(_clock))]),
          const SizedBox(height: 8),
          Text(practiceService.chapterOf(_q.id, bangla), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(bangla ? _q.questionBn : _q.questionEn, style: Theme.of(context).textTheme.bodyLarge))),
          const SizedBox(height: 12),
          for (int i = 0; i < _q.options.length; i++) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OptionTile(label: bangla ? 'কখগঘ'[i] : 'ABCD'[i], text: _q.options[i], selected: chosen == i,
                correct: _isChecked ? _q.isCorrect(i) : null,
                onTap: _isChecked ? null : () => setState(() => _answers[_index] = i)),
          ),
          if (_isChecked) ...[
            const SizedBox(height: 8),
            QuizCheckedCard(
              correct: chosen != null && _q.isCorrect(chosen),
              s: s,
              loading: _loadingExplanation.contains(_index),
              kind: _explanationKind[_index],
              text: _explanations[_index],
              aiProvider:
                  _explanationProvider[_index] ?? 'unknown',
              aiModel: _explanationModel[_index],
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _index > 0 ? () => setState(() => _index--) : null, child: Text(s['prev']!))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: _primary, child: Text(!_isChecked ? s['submit']! : (_isLast ? s['finish']! : s['next']!)))),
          ]),
          const SizedBox(height: 8),
          QuizFooterActions(
            questionId: _q.id,
            s: s,
            onSkip: () {
              _answers.remove(_index);
              if (_isLast) { _finish(); } else { setState(() => _index++); }
            },
          ),
        ]),
      );
    });
  }
}
