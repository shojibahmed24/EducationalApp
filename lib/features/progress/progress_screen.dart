// Route: /progress. Bars, streak, goal ring and tasks are all
// COMPUTED from saved runs — a fresh install honestly shows 0.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/progress/widgets/progress_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/progress_strings.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  List<String> _last7Labels(bool bangla) {
    // Last 7 calendar days, oldest first; today is the last label.
    const bn = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি'];
    const en = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final days = <String>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      days.add((bangla ? bn : en)[d.weekday % 7]);
    }
    return days;
  }

  List<bool> _last7Active(ProgressSummary sum) {
    final set = sum.activityDates.toSet();
    final out = <bool>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      out.add(set.contains('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? progressStringsBn : progressStringsEn;
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
          // Phase 17 (L8): the old branch hid the Supabase fallback
          // numbers entirely — totalAttempts == 0 was treated as
          // 'no data' even when the server row held a real streak /
          // chapters / average. Empty state only when BOTH local
          // runs and server numbers are absent.
          final hasServerNumbers = sum.streakDays > 0 ||
              sum.chaptersDone > 0 ||
              sum.averageScore > 0;
          if (sum.totalAttempts == 0 && !hasServerNumbers) {
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(s['noData']!, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8), Text(s['noDataSub']!),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/practice'), child: Text(s['startPractice']!)),
            ]);
          }
          final today = PracticeSession.today();
          final didQuizToday = sum.attempts.any((a) => a.kind == 'quiz' && a.date == today);
          final didModelToday = sum.attempts.any((a) => a.kind == 'model' && a.date == today);
          final tasksDone = (didQuizToday ? 1 : 0) + (didModelToday ? 1 : 0) + (sum.goalProgress >= 1 ? 1 : 0);
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (sum.totalAttempts == 0 && hasServerNumbers)
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(s['serverNote']!))),
            if (sum.totalAttempts == 0 && hasServerNumbers)
              const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              const Icon(Icons.workspace_premium), const SizedBox(width: 8),
              Expanded(child: Text("${s['level']!} ${sum.level} · ${sum.xp} XP", style: Theme.of(context).textTheme.headlineMedium)),
            ]))),
            const SizedBox(height: 12),
            StreakRow(days: _last7Labels(bangla), active: _last7Active(sum), label: '${sum.streakDays} ${s['streak']!}'),
            const SizedBox(height: 12),
            // Phase 16 (M6): goal in the user's own minutes; no goal
            // saved => honest no-goal text, never a hardcoded ring.
            if (sum.goalMinutes == 0)
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(s['noGoal']!)))
            else
              GoalRing(done: sum.todayMinutes, goal: sum.goalMinutes, label: "${s['goalTitle']!} (${s['minutes']!})"),
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['week']!, style: Theme.of(context).textTheme.headlineMedium),
              // Phase 17 (L8): with no local runs, show the server
              // numbers themselves — not '0 runs · avg 0%'.
              Text(sum.totalAttempts == 0
                  ? '${sum.streakDays} ${s['streak']!} · ${sum.chaptersDone} ${s['chapters']!} · ${s['avg']!}: ${sum.averageScore}%'
                  : '${sum.totalAttempts} ${s['runs']!} · ${s['avg']!}: ${sum.averageScore}% · ${sum.totalAnswered} ${s['questions']!}'),
            ]))),
            const SizedBox(height: 12),
            Text(s['today']!, style: Theme.of(context).textTheme.headlineLarge),
            Text('$tasksDone/3 ${s['todaySub']!}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            TaskTile(title: s['taskQuiz']!, done: didQuizToday, onTap: () {
              // Phase 17 (L7): no longer hardcoded to maths. Use the
              // student's last real subject: the most recent saved
              // attempt with a maths/science subject, else the
              // subject they last selected in Practice this session.
              var subject = PracticeSession.selectedSubject;
              for (final a in sum.attempts.reversed) {
                if (a.subject == 'math' || a.subject == 'science') {
                  subject = a.subject;
                  break;
                }
              }
              if (subject != 'math' && subject != 'science') {
                subject = 'math';
              }
              PracticeSession.selectedSubject = subject;
              PracticeSession.quizItems = practiceService.quizFor(subject);
              context.go('/quiz');
            }),
            TaskTile(title: s['taskModel']!, done: didModelToday, onTap: () => context.go('/model-tests')),
            TaskTile(title: s['taskGoal']!, done: sum.goalProgress >= 1, onTap: () => context.go('/practice')),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => context.go('/achievements'), child: Text(s['achievements']!)),
          ]);
        }),
      );
    });
  }
}
