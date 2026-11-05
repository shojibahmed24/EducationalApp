// Route: /model-test-exam. REAL countdown (Timer.periodic, mm:ss),
// per-question navigation via chips / prev / next with answered state
// marked, flag toggle, confirm-before-submit, auto-submit at 00:00,
// timer stopped on submit. The run is saved before going to results.
// Batch 2 (item 4): submit can never die silently again — the
// in-memory attempt is set before any disk write, disk failures are
// caught (navigation still happens, with a snackbar note), and the
// in-flight guard resets on failure instead of latching forever.
// Batch 2 (item 5): flags are real — a flagged list with jump chips
// sits above Submit, the confirm dialog lists flagged + unanswered
// counts, and flagged ids ride the Attempt to the results screen.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/model_test_service.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/core/services/resolve_school_class.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/widgets/model_test_flagged_card.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/model_test_exam_strings.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';
import '../../theme/themed_scaffold.dart';

class ModelTestExamScreen extends StatefulWidget {
  const ModelTestExamScreen({super.key});
  @override
  State<ModelTestExamScreen> createState() => _ModelTestExamScreenState();
}

class _ModelTestExamScreenState extends State<ModelTestExamScreen> {
  late List<QuizItem> _items;
  late int _seconds;
  final Map<int, int> _answers = {};
  final Set<int> _flagged = {};
  int _index = 0;
  Timer? _timer;
  bool _submitted = false;
  // In-flight guard (reset on failure) + dialog-open flag so the
  // countdown never auto-submits while the user is deciding in the
  // confirm dialog.
  bool _submitting = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _items = PracticeSession.modelItems.isNotEmpty
        ? PracticeSession.modelItems
        : modelTestService.modelTests().first.items;
    _seconds = (PracticeSession.modelMinutes > 0 ? PracticeSession.modelMinutes : 15) * 60;
    // Restore a saved run (e.g. after Ask-AI chat navigation
    // disposed this screen) instead of restarting the exam.
    if (PracticeSession.modelExamTestId == PracticeSession.modelTestId &&
        PracticeSession.modelExamSecondsLeft >= 0) {
      _seconds = PracticeSession.modelExamSecondsLeft;
      _index = PracticeSession.modelExamIndex.clamp(0, _items.length - 1);
      _answers.addAll(Map.fromEntries(PracticeSession.modelExamAnswers.entries.where((e) => e.key >= 0 && e.key < _items.length)));
      _flagged.addAll(PracticeSession.modelExamFlagged.where((i) => i >= 0 && i < _items.length));
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _submitted || _submitting || _dialogOpen) return;
      if (_seconds > 0) {
        setState(() => _seconds--);
        _persist();
      } else {
        _submit(auto: true);
      }
    });
  }

  /// In-memory progress save (answers, flags, clock, position).
  void _persist() => PracticeSession.saveModelExam(
      answers: _answers, flagged: _flagged,
      secondsLeft: _seconds, index: _index);

  /// Ask-AI (guide exams only): Phase 1 guide-chat path — row
  /// id + return to this exam, never the textbook index.
  Future<void> _askAi(bool bangla) async {
    final q = _items[_index];
    final schoolClass = await resolveSchoolClass();
    if (!mounted) return;
    _persist();
    LessonSelectionHolder.set(LessonSelection(
      subject: PracticeSession.modelSubject, chapter: 0,
      page: 0, problem: 0,
      queryText: bangla ? q.questionBn : q.questionEn,
      schoolClass: schoolClass,
      guideQuestionId: q.id, returnTo: '/model-test-exam'));
    context.go('/lesson/chat');
  }

  @override
  void dispose() { _timer?.cancel(); if (!_submitted) _persist(); super.dispose(); }
  String get _clock => '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
  int get _totalSeconds => (PracticeSession.modelMinutes > 0 ? PracticeSession.modelMinutes : 15) * 60;

  Future<void> _submit({bool auto = false}) async {
    if (_submitted || _submitting) return;
    _submitting = true;
    _timer?.cancel();
    if (mounted) setState(() {});
    var correct = 0;
    for (final e in _answers.entries) {
      if (_items[e.key].isCorrect(e.value)) correct++;
    }
    final flaggedIds = _flagged.toList()..sort();
    final attempt = Attempt(kind: 'model', testId: PracticeSession.modelTestId.isNotEmpty ? PracticeSession.modelTestId : 'mt-math',
        subject: PracticeSession.modelSubject, chapter: PracticeSession.modelSubject,
        correct: correct, total: _items.length, seconds: _totalSeconds - _seconds,
        date: PracticeSession.today(),
        answers: {for (final e in _answers.entries) _items[e.key].id: e.value},
        flagged: [for (final i in flaggedIds) _items[i].id],
        // Phase 2: same persistence as the quiz screen.
        wrongItems: [for (final e in _answers.entries)
          if (!_items[e.key].isCorrect(e.value)) _items[e.key]]);
    // In-memory first: the results screen can always show this run,
    // even if the disk write below fails (see practice_store).
    // A submitted exam never restores its old progress.
    PracticeSession.clearModelExam();
    PracticeSession.lastAttempt = attempt;
    PracticeSession.lastItems = _items;
    try {
      await practiceService.recordAttempt(attempt);
      // Phase 17 (L8): best-effort server progress write, local first.
      await progressService.syncToServer();
    } catch (_) {
      // Never block navigation on a save failure: the run is already
      // in memory, and the results screen reads it first. Tell the
      // user instead of silently doing nothing (the old bug).
      if (mounted) {
        final s = languageNotifier.value.languageCode == 'bn' ? modelTestExamStringsBn : modelTestExamStringsEn;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s['submitFailed']!)));
      }
    }
    _submitted = true;
    _submitting = false;
    if (!mounted) return;
    if (auto) {
      // Phase 17 (L3): keep the snackbar, but ALSO set the flag so
      // the results screen shows the time-up message persistently —
      // a snackbar shown just before navigation can be missed.
      PracticeSession.timeUpAutoSubmit = true;
      final s = languageNotifier.value.languageCode == 'bn' ? modelTestExamStringsBn : modelTestExamStringsEn;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s['timeUp']!)));
    }
    context.go('/model-test-results');
  }

  Future<void> _confirmSubmit(Map<String, String> s) async {
    if (_submitted || _submitting) return;
    final flaggedNums = _flagged.toList()..sort();
    final unanswered = _items.length - _answers.length;
    _dialogOpen = true;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(s['confirmTitle']!),
      content: Text("${s['confirmMsg']!}\n${_answers.length}/${_items.length} ${s['answered']!}"
          "\n$unanswered ${s['unanswered']!}"
          "\n${s['flaggedLabel']!}: ${flaggedNums.isEmpty ? s['flaggedNone']! : flaggedNums.map((i) => '${i + 1}').join(', ')}"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s['confirmNo']!)),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s['confirmYes']!)),
      ],
    ));
    _dialogOpen = false;
    if (ok == true) await _submit();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? modelTestExamStringsBn : modelTestExamStringsEn;
      final bangla = locale.languageCode == 'bn';
      final q = _items[_index];
      final chosen = _answers[_index];
      return ThemedScaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(PracticeSession.modelIsGuide
                ? '/guide-model-tests'
                : '/model-tests'),
          ),
          title: Text(s['title']!),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Chip(label: Text(_clock)),
            ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text("${s['qLabel']!} ${_index + 1}/${_items.length}", style: Theme.of(context).textTheme.headlineMedium),
          Text(practiceService.chapterOf(q.id, bangla), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(bangla ? q.questionBn : q.questionEn, style: Theme.of(context).textTheme.bodyLarge))),
          const SizedBox(height: 12),
          for (int i = 0; i < q.options.length; i++) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OptionTile(label: bangla ? 'কখগঘ'[i] : 'ABCD'[i], text: q.options[i], selected: chosen == i,
                onTap: () => setState(() => _answers[_index] = i)),
          ),
          const SizedBox(height: 12),
          if (PracticeSession.modelIsGuide) ...[
            OutlinedButton.icon(onPressed: _submitting ? null : () => _askAi(bangla), icon: const Icon(Icons.chat_bubble_outline), label: Text(s['askAi']!)),
            const SizedBox(height: 12),
          ],
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: !_submitting && _index > 0 ? () => setState(() => _index--) : null, child: Text(s['prev']!))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: !_submitting && _index < _items.length - 1 ? () => setState(() => _index++) : null, child: Text(s['next']!))),
          ]),
          const SizedBox(height: 12),
          if (_flagged.isNotEmpty) ...[
            ModelTestFlaggedCard(
              flagged: _flagged.toList()..sort(),
              s: s,
              disabled: _submitting,
              onClear: () => setState(() => _flagged.clear()),
              onJump: (i) => setState(() => _index = i),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
              onPressed: _submitting ? null : () => _confirmSubmit(s),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s['submit']!)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _submitting ? null : () => setState(() {
            if (_flagged.contains(_index)) { _flagged.remove(_index); } else { _flagged.add(_index); }
          }), child: Text(_flagged.contains(_index) ? s['flaggedBtn']! : s['flagBtn']!)),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: List.generate(_items.length, (i) {
            final answered = _answers.containsKey(i);
            final flagged = _flagged.contains(i);
            return ActionChip(
              label: Text('${i + 1}${flagged ? ' ⚑' : ''}'),
              backgroundColor: i == _index ? AppTheme.primary.withValues(alpha: 0.25) : (answered ? AppTheme.success.withValues(alpha: 0.2) : null),
              onPressed: _submitting ? null : () => setState(() => _index = i));
          })),
        ]),
      );
    });
  }
}
