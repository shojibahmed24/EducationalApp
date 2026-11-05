// Route: /achievements. Every badge is earned/locked from REAL
// saved milestones; locked badges show the real requirement and the
// user's real progress toward it (e.g. 3/5 quizzes).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/achievements_strings.dart';

class _Badge {
  final String titleKey, subKey, progress;
  final bool earned;
  final IconData icon;
  const _Badge(this.titleKey, this.subKey, this.earned, this.progress, this.icon);
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _filter = 'all';
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? achievementsStringsBn : achievementsStringsEn;
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/progress'),
          ),
          title: Text(s['title']!),
        ),
        body: FutureBuilder<ProgressSummary>(future: progressService.summary(), builder: (context, snap) {
          final sum = snap.data ?? ProgressSummary.empty;
          final quizCount = sum.attempts.where((a) => a.kind == 'quiz').length;
          final modelCount = sum.attempts.where((a) => a.kind == 'model').length;
          final perfect = sum.attempts.any((a) => a.total > 0 && a.correct == a.total);
          final genius = sum.totalAnswered >= 5 && sum.averageScore >= 90;
          final badges = [
            _Badge('badgeFirst', 'badgeFirstSub', quizCount >= 1, '$quizCount/1', Icons.play_arrow),
            _Badge('badgeQuiz5', 'badgeQuiz5Sub', quizCount >= 5, '$quizCount/5', Icons.bolt),
            _Badge('badgeStreak3', 'badgeStreak3Sub', sum.streakDays >= 3, '${sum.streakDays}/3', Icons.local_fire_department),
            _Badge('badgeStreak7', 'badgeStreak7Sub', sum.streakDays >= 7, '${sum.streakDays}/7', Icons.local_fire_department),
            _Badge('badgeGenius', 'badgeGeniusSub', genius, '${sum.averageScore}%', Icons.calculate),
            _Badge('badgePerfect', 'badgePerfectSub', perfect, perfect ? '1/1' : '0/1', Icons.star),
            _Badge('badgeModel', 'badgeModelSub', modelCount >= 1, '$modelCount/1', Icons.assignment),
          ];
          final earnedCount = badges.where((b) => b.earned).length;
          final shown = badges.where((b) =>
              _filter == 'all' || (_filter == 'earned' && b.earned) || (_filter == 'locked' && !b.earned)).toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${s['level']!} ${sum.level} · ${sum.xp} XP", style: Theme.of(context).textTheme.headlineMedium),
              Text('$earnedCount/${badges.length} ${s['unlocked']!}'),
              const SizedBox(height: 8),
              Text("${s['nextLevel']!} ${sum.level + 1} — ${100 - sum.xp % 100} XP"),
            ]))),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: ['all', 'earned', 'locked'].map((f) => ChoiceChip(
                label: Text(f == 'all' ? s['filterAll']! : (f == 'earned' ? s['filterEarned']! : s['filterLocked']!)),
                selected: _filter == f, onSelected: (_) => setState(() => _filter = f))).toList()),
            const SizedBox(height: 12),
            for (final b in shown) ...[
              PracticeCard(title: '${s[b.titleKey]!} ${b.earned ? '' : '(${s['locked']!})'}',
                  subtitle: '${s[b.subKey]!} · ${b.progress}', icon: b.icon,
                  trailing: Chip(label: Text(b.earned ? s['earned']! : s['locked']!))),
              const SizedBox(height: 12),
            ],
            ProgressBar(value: badges.isEmpty ? 0 : earnedCount / badges.length),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => context.go('/quiz'), child: Text(s['badgeQuiz5']!)),
          ]);
        }),
      );
    });
  }
}
