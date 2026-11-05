// Route: /practice-tab. Three REAL tabs: Quiz, Model Tests, Progress.
// Quiz tab: daily quiz starts the generated set for the user's
// class + subject (labelled practice bank until a scorable book
// pool exists); weak-chapter practice starts ONLY the user's actual
// wrong answers, and its button is disabled with an honest empty
// state when there truly are none. Model tests start the generated
// fixed-count sets from practice_service.modelTests().
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/model_test_service.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/profile_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/widgets/guide_fallback_dialog.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/practice_strings.dart';
import 'package:yes_sir_ai/l10n/pages/practice_tab_strings.dart';

class PracticeTabScreen extends StatefulWidget {
  const PracticeTabScreen({super.key});

  @override
  State<PracticeTabScreen> createState() => _PracticeTabScreenState();
}

class _PracticeTabScreenState extends State<PracticeTabScreen> {
  // Same Batch 2, item 1 fix as PracticeScreen._startDaily: spinner
  // + disabled button while generating, honest error + retry on
  // failure, 60s timeout so the button can never hang silently.
  bool _startingDaily = false;

  Future<void> _startDaily(
    BuildContext context,
    String subject,
    bool bangla,
    Map<String, String> s,
  ) async {
    if (_startingDaily) return;
    setState(() => _startingDaily = true);
    // Same finally rule as PracticeScreen._startDaily: the flag
    // clears on every non-navigation exit; navigation is exempt.
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

  void _startRevision(BuildContext context, List<QuizItem> items) {
    PracticeSession.quizItems = items;
    PracticeSession.quizSource = 'bankFallback';
    PracticeSession.quizShortfall = 0;
    PracticeSession.quizSeedKey = '';
    PracticeSession.quizIsRevision = true;
    context.go('/quiz');
  }

  void _startModel(BuildContext context, ModelTest t) {
    PracticeSession.modelTestId = t.id;
    PracticeSession.modelSubject = t.subject;
    PracticeSession.modelItems = t.items;
    PracticeSession.modelMinutes = t.minutes;
    PracticeSession.modelIsGuide = false;
    PracticeSession.clearModelExam();
    context.go('/model-test-exam');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? practiceTabStringsBn : practiceTabStringsEn;
      final bangla = locale.languageCode == 'bn';
      return DefaultTabController(length: 3, child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/practice'),
          ),
          title: Text(s['title']!), bottom: TabBar(tabs: [
          Tab(text: s['tabQuiz']!), Tab(text: s['tabModel']!), Tab(text: s['tabProgress']!),
        ])),
        body: FutureBuilder<ProgressSummary>(future: progressService.summary(), builder: (context, snap) {
          final sum = snap.data ?? ProgressSummary.empty;
          final recent = sum.attempts.reversed.take(5).toList();
          final weakItems = sum.weakItems;
          final weak = sum.weakChapters.isEmpty ? null : sum.weakChapters.first;
          final countText = bangla
              ? '${weakItems.length}${s['wrongQuestions']!}'
              : '${weakItems.length} ${s['wrongQuestions']!}';
          final weakSub = weakItems.isEmpty
              ? (weak == null ? s['weakNone']! : s['weakUnavailable']!)
              : (weak == null ? countText : '$countText · ${weak.label(bangla)}');
          Widget recentList() => recent.isEmpty
              ? Text(s['noResults']!, style: Theme.of(context).textTheme.bodyMedium)
              : Column(children: [for (final a in recent) Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: PracticeCard(title: '${a.kind == 'model' ? s['modelTest']! : s['quiz']!} · ${a.correct}/${a.total}', subtitle: '${a.percent}%', icon: Icons.history))]);
          return TabBarView(children: [
            ListView(padding: const EdgeInsets.all(16), children: [
              PracticeCard(title: s['quiz']!, subtitle: '${s['dailyCount']!} · ${s['bankNote']!}', icon: Icons.timer,
                  trailing: ElevatedButton(
                      onPressed: _startingDaily ? null : () => _startDaily(context, PracticeSession.selectedSubject, bangla, s),
                      child: _startingDaily
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(s['start']!))),
              // Progress text reuses practice_strings (this tab's
              // own string file gains no new key, per the brief).
              if (_startingDaily) Padding(padding: const EdgeInsets.only(top: 8), child: Text(bangla ? practiceStringsBn['preparingGuide']! : practiceStringsEn['preparingGuide']!, style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(height: 12),
              PracticeCard(title: s['weak']!, subtitle: weakSub, icon: Icons.warning_amber,
                  trailing: TextButton(onPressed: weakItems.isEmpty ? null : () => _startRevision(context, weakItems), child: Text(s['weakStart']!))),
              const SizedBox(height: 12),
              Text(s['recent']!, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8), recentList(),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.go('/quiz-results'), child: Text(s['results']!)),
            ]),
            ListView(padding: const EdgeInsets.all(16), children: [
              for (final t in modelTestService.modelTests()) ...[
                PracticeCard(title: '${s['modelTest']!} · ${t.subject == 'math' ? s['maths']! : (t.subject == 'science' ? s['science']! : s['english']!)}', subtitle: '${t.items.length} ${s['questions']!} · ${t.minutes} min', icon: Icons.assignment,
                    trailing: t.locked ? null : ElevatedButton(onPressed: () => _startModel(context, t), child: Text(s['start']!))),
                const SizedBox(height: 12),
              ],
              OutlinedButton(onPressed: () => context.go('/model-tests'), child: Text(s['modelTest']!)),
            ]),
            ListView(padding: const EdgeInsets.all(16), children: [
              PracticeCard(title: '${sum.streakDays} ${s['streak']!}', subtitle: sum.goalMinutes == 0 ? s['noGoal']! : '${s['goal']!}: ${sum.todayMinutes}/${sum.goalMinutes} ${s['minutes']!}', icon: Icons.local_fire_department),
              const SizedBox(height: 12),
              ProgressBar(value: sum.goalProgress),
              const SizedBox(height: 12),
              Text(s['recent']!, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8), recentList(),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.go('/progress'), child: Text(s['tabProgress']!)),
            ]),
          ]);
        }),
      ));
    });
  }
}
