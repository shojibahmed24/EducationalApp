// Route: /practice. Daily quiz + weak-topic revision are REAL:
// daily starts the generated set for the user's class + subject
// (deterministic per day, guide MCQs first, bank fallback);
// by-subject cards start random practice sets (seen questions
// excluded); revision starts ONLY the user's actual wrong
// answers, newest first. With no wrong answers the revision button
// is disabled and the card says so honestly — it never launches a
// generic quiz disguised as revision.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/profile_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/widgets/guide_fallback_dialog.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';
import 'package:yes_sir_ai/l10n/pages/practice_strings.dart';
import '../../theme/themed_scaffold.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  // Batch 2, item 1: daily generation awaits a book fetch plus
  // per-chapter Edge lists and up to 15 sequential Mode G key
  // resolves. It used to run with no loading state, no try/catch
  // and no timeout, so any throw or slow network made the button
  // look dead. Now the button shows a spinner and disables while
  // generating, failures surface an honest error with a retry
  // action, and a 60s timeout bounds the wait. Guide-first +
  // bank-fallback semantics are unchanged (they live in
  // generateDailyQuiz, not here).
  bool _startingDaily = false;

  Future<void> _startDaily(
    BuildContext context,
    String subject,
    bool bangla,
    Map<String, String> s,
  ) async {
    if (_startingDaily) return;
    setState(() => _startingDaily = true);
    // finally clears the busy flag on EVERY exit where the screen
    // stays mounted (error, unmounted-context return, profile
    // failure); the navigation-away success path is exempt via
    // [navigated], so no setState runs after context.go.
    var navigated = false;
    try {
      final schoolClass = await profileService.loadSchoolClass() ?? 6;
      final gen = await practiceService
          .generateDailyQuiz(
              subject: subject, schoolClass: schoolClass, bangla: bangla)
          .timeout(const Duration(seconds: 60));
      PracticeSession.selectedSubject = subject;
      PracticeSession.quizShortfall = gen.guideShortfall;
      PracticeSession.quizSeedKey = gen.seedKey;
      if (!context.mounted) return;
      if (gen.items.isEmpty) {
        // Guide empty: ask, never silently substitute the bank.
        // Generation is DONE, so the spinner stops here — the
        // dialog is an idle user choice, not busy work.
        if (mounted) setState(() => _startingDaily = false);
        final useBank = await showGuideFallbackDialog(context);
        if (!context.mounted) return;
        if (!useBank) return;
        PracticeSession.quizItems = practiceService.dailyQuizFor(
            subject, seedKey: gen.seedKey, count: 20);
        PracticeSession.quizSource = 'bankFallback';
        PracticeSession.quizShortfall = 0;
      } else {
        PracticeSession.quizItems = gen.items;
        PracticeSession.quizSource = gen.source.name;
      }
      PracticeSession.quizIsRevision = false;
      if (!context.mounted) return;
      navigated = true;
      context.go('/quiz');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s['dailyError']!),
          action: SnackBarAction(
            label: s['retry']!,
            onPressed: () => _startDaily(context, subject, bangla, s),
          ),
        ),
      );
    } finally {
      if (mounted && !navigated) setState(() => _startingDaily = false);
    }
  }

  /// Random practice set for one subject: guide MCQs first
  /// (seen questions excluded, refills when the pool runs dry).
  /// A short guide set ships with its shortfall; an empty guide
  /// set asks the user about a bank set (never silent).
  /// Same hardening as _startDaily (parent follow-up): the old
  /// shape had no loading state, no try/catch and no timeout, so
  /// the by-subject cards could look dead exactly like the daily
  /// button did. The busy card shows a spinner in its trailing
  /// slot and ignores further taps until the run settles.
  String? _startingSubject;

  Future<void> _startPractice(BuildContext context, String subject,
      bool bangla, Map<String, String> s) async {
    if (_startingSubject != null) return;
    setState(() => _startingSubject = subject);
    // Guide throw/timeout now falls back to the bank set inside
    // generatePracticeQuiz; this catch fires only when the bank
    // fallback (or the profile read) itself fails. Busy flag
    // clears via finally on every non-navigation exit.
    var navigated = false;
    try {
      final schoolClass = await profileService.loadSchoolClass() ?? 6;
      final gen = await practiceService
          .generatePracticeQuiz(
              subject: subject, schoolClass: schoolClass, bangla: bangla)
          .timeout(const Duration(seconds: 60));
      PracticeSession.selectedSubject = subject;
      PracticeSession.quizShortfall = gen.guideShortfall;
      PracticeSession.quizSeedKey = gen.seedKey;
      if (!context.mounted) return;
      if (gen.items.isEmpty) {
        // Guide empty: ask, never silently substitute the bank.
        // Generation is DONE, so the spinner stops here — the
        // dialog is an idle user choice, not busy work.
        if (mounted) setState(() => _startingSubject = null);
        final useBank = await showGuideFallbackDialog(context);
        if (!context.mounted) return;
        if (!useBank) return;
        PracticeSession.quizItems = practiceService.dailyQuizFor(
            subject, seedKey: gen.seedKey, count: 20);
        PracticeSession.quizSource = 'bankFallback';
        PracticeSession.quizShortfall = 0;
      } else {
        PracticeSession.quizItems = gen.items;
        PracticeSession.quizSource = gen.source.name;
      }
      PracticeSession.quizIsRevision = false;
      if (!context.mounted) return;
      navigated = true;
      context.go('/quiz');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s['dailyError']!),
          action: SnackBarAction(
            label: s['retry']!,
            onPressed: () => _startPractice(context, subject, bangla, s),
          ),
        ),
      );
    } finally {
      if (mounted && !navigated) setState(() => _startingSubject = null);
    }
  }

  void _startRevision(BuildContext context, List<QuizItem> items) {
    PracticeSession.quizItems = items;
    PracticeSession.quizSource = 'bankFallback';
    PracticeSession.quizShortfall = 0;
    PracticeSession.quizSeedKey = '';
    PracticeSession.quizIsRevision = true;
    context.go('/quiz');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? practiceStringsBn : practiceStringsEn;
      final gs = locale.languageCode == 'bn' ? guideBankStringsBn : guideBankStringsEn;
      final bangla = locale.languageCode == 'bn';
      return ThemedScaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          title: Text(s['title']!),
        ),
        body: FutureBuilder<ProgressSummary>(future: progressService.summary(), builder: (context, snap) {
          final sum = snap.data ?? ProgressSummary.empty;
          final weakItems = sum.weakItems;
          final weak = sum.weakChapters.isEmpty ? null : sum.weakChapters.first;
          final countText = bangla
              ? '${weakItems.length}${s['wrongQuestions']!}'
              : '${weakItems.length} ${s['wrongQuestions']!}';
          final weakSub = weakItems.isEmpty
              ? (weak == null ? s['weakNone']! : s['weakUnavailable']!)
              : (weak == null ? countText : '$countText · ${weak.label(bangla)}');
          return ListView(padding: const EdgeInsets.all(16), children: [
            PracticeCard(title: s['dailyQuiz']!, subtitle: '${s['dailyCount']!} · ${s['bankNote']!}', icon: Icons.timer,
                trailing: ElevatedButton(
                    onPressed: _startingDaily ? null : () => _startDaily(context, PracticeSession.selectedSubject, bangla, s),
                    child: _startingDaily
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s['startQuiz']!))),
            if (_startingDaily) Padding(padding: const EdgeInsets.only(top: 8), child: Text(s['preparingGuide']!, style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: 12),
            PracticeCard(title: s['weakTitle']!, subtitle: weakSub, icon: Icons.psychology,
                trailing: TextButton(onPressed: weakItems.isEmpty ? null : () => _startRevision(context, weakItems), child: Text(s['weakStart']!))),
            const SizedBox(height: 12),
            PracticeCard(title: gs['modelTestsTitle']!, subtitle: gs['modelTestsEntrySub']!, icon: Icons.assignment,
                trailing: OutlinedButton(onPressed: () => context.go('/guide-model-tests'), child: Text(gs['modelTestStart']!))),
            const SizedBox(height: 20),
            Text(s['bySubject']!, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            PracticeCard(title: s['maths']!, subtitle: '${s['selected']!}: ${PracticeSession.selectedSubject == 'math' ? '✓' : ''}', icon: Icons.calculate, onTap: _startingSubject != null ? null : () => _startPractice(context, 'math', bangla, s), trailing: _startingSubject == 'math' ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null),
            const SizedBox(height: 12),
            PracticeCard(title: s['science']!, subtitle: '${s['selected']!}: ${PracticeSession.selectedSubject == 'science' ? '✓' : ''}', icon: Icons.biotech, onTap: _startingSubject != null ? null : () => _startPractice(context, 'science', bangla, s), trailing: _startingSubject == 'science' ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null),
            if (_startingSubject != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(s['preparingGuide']!, style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: 12),
            Text('${s['avg']!}: ${sum.averageScore}% · ${s['done']!}: ${sum.totalAttempts}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ProgressBar(value: sum.averageScore / 100),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => context.go('/practice-tab'), child: Text(s['practiceTab']!)),
          ]);
        }),
      );
    });
  }
}
