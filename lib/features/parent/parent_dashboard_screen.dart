// Route: /parent-dashboard
// READ-ONLY: no edit buttons, no actions that change data. Every
// number comes from saved storage (profile JSON in LocalStore +
// progressService.summary() + saved questions + voice budget).
// If nothing is saved, cards show an honest empty state instead
// of invented numbers. Per-subject percentages are NOT shown:
// no per-subject source exists, so inventing them would be fake.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ai_voice_service.dart';
import '../../core/services/app_config.dart';
import '../../core/services/local_store.dart';
import '../../core/services/progress_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/parent_strings.dart';
import '../../theme/app_theme.dart';
import 'widgets/parent_stat_card.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});
  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  bool _loading = true;
  String _name = '';
  String _schoolClass = '';
  int _goalMinutes = 0;
  int _streak = 0, _chapters = 0, _avg = 0, _saved = 0;
  int _voiceUsed = 0, _voiceCap = 30;
  // Phase 16 (M7): weak chapters from progressService.summary(),
  // not a permanent empty card.
  List<WeakChapter> _weak = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profileJson = await LocalStore.readProfile();
    var name = '', schoolClass = '';
    var goal = 0;
    if (profileJson != null) {
      try {
        final m = jsonDecode(profileJson) as Map<String, dynamic>;
        name = (m['full_name'] ?? '').toString();
        schoolClass = (m['school_class'] ?? '').toString();
        goal = (m['daily_goal_minutes'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    final summary = await progressService.summary();
    final saved = await progressService.savedQuestions();
    final budget = await aiVoiceService.budget();
    if (!mounted) return;
    setState(() {
      _name = name;
      _schoolClass = schoolClass;
      _goalMinutes = goal;
      _streak = summary.streakDays;
      _chapters = summary.chaptersDone;
      _avg = summary.averageScore;
      _saved = saved.length;
      _voiceUsed = budget.usedMinutes;
      _voiceCap = budget.capMinutes;
      _weak = summary.weakChapters;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? parentStringsBn : parentStringsEn;
    if (_loading) {
      return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/profile'),
            ),
            title: Text(s['dashTitle']!),
          ),
          body: const Center(child: CircularProgressIndicator()));
    }
    final hasData = _streak > 0 || _chapters > 0 || _avg > 0 || _saved > 0;
    final heading = _name.isEmpty
        ? s['student']!
        : (_schoolClass.isEmpty ? _name : '$_name • $_schoolClass');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        title: Text(s['dashTitle']!),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.visibility),
              const SizedBox(width: 8),
              Expanded(child: Text(s['readOnly']!))
            ]),
          ),
          if (AppConfig.demoMode) ...[
            const SizedBox(height: 12),
            Text(s['demoNote']!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          Text(heading, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          if (!hasData)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s['emptyProgress']!))),
          Row(children: [
            Expanded(
                child: ParentStatCard(
                    icon: Icons.local_fire_department,
                    label: s['streak']!,
                    value: '$_streak ${s['days']!}')),
            const SizedBox(width: 12),
            Expanded(
                child: ParentStatCard(
                    icon: Icons.check_circle,
                    label: s['chaptersDone']!,
                    value: '$_chapters')),
          ]),
          const SizedBox(height: 12),
          ParentStatCard(
              icon: Icons.quiz, label: s['avgScore']!, value: '$_avg%'),
          const SizedBox(height: 12),
          ParentStatCard(
              icon: Icons.bookmark, label: s['savedLabel']!, value: '$_saved'),
          const SizedBox(height: 12),
          ParentStatCard(
              icon: Icons.mic,
              label: s['voiceUsedLabel']!,
              value: '$_voiceUsed / $_voiceCap ${s['minutes']!}'),
          const SizedBox(height: 12),
          Text(
              _goalMinutes > 0
                  ? "${s['goalLabel']!}: $_goalMinutes ${s['minutes']!}"
                  : s['noGoal']!,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['weakTitle']!,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        if (_weak.isEmpty)
                          Text(s['weakEmpty']!)
                        else
                          for (final w in _weak)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(w.label(
                                  Localizations.localeOf(context)
                                          .languageCode ==
                                      'bn')),
                              subtitle: Text(
                                  '${w.wrong}/${w.total} ${s['wrong']!}'),
                            ),
                      ]))),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text(s['backHome']!)),
        ],
      ),
    );
  }
}
