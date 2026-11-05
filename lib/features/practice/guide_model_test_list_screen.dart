// Route: /guide-model-tests — SERVER-FIRST (Phase 2, plan §2
// step 4): set metadata from the server (sets action, counts
// only); the cache is FALLBACK ONLY for an unreachable server
// (the old cache-only screen could never show a set, since
// nothing ever wrote the cache). Rows load on demand at Start
// (list action, setId filter) and are then cached; keys resolve
// via Mode G, so unkeyed rows are excluded and labelled, never
// scored or guessed. Free while freeGuideLimit < 0; otherwise
// non-premium starts go to the paywall. Minutes default 15.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/app_config.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/guide_quiz_service.dart';
import '../../core/services/model_test_set_service.dart';
import '../../core/services/resolve_school_class.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../learn/widgets/digits.dart';
import '../learn/widgets/mock_data.dart';
import 'practice_store.dart';
import 'widgets/practice_widgets.dart';

class _LoadedSets {
  final List<GuideModelSetInfo>? meta;
  final List<GuideModelSet> cached;
  final int schoolClass;
  const _LoadedSets({required this.meta, required this.cached, required this.schoolClass});
}

class _SetRow {
  final String setId;
  final int total, keyed;
  final GuideModelSet? cached;
  const _SetRow(this.setId, this.total, this.keyed, this.cached);
  int get unkeyed => total - keyed;
}

/// Server metadata wins for counts; cached-only sets (server
/// unreachable) fall back to their cached rows. Cached rows
/// carry hasKey booleans only, so their keyed count uses
/// serverHasKey, not the index-based keyedCount.
List<_SetRow> _mergeRows(
    List<GuideModelSetInfo>? meta, List<GuideModelSet> cached) {
  final byId = {for (final s in cached) s.setId: s};
  final rows = <_SetRow>[];
  if (meta != null) {
    for (final m in meta) {
      rows.add(_SetRow(m.setId, m.totalCount, m.keyedCount, byId[m.setId]));
    }
  }
  for (final s in cached) {
    if (meta == null || !meta.any((m) => m.setId == s.setId)) {
      rows.add(_SetRow(s.setId, s.questions.length,
          s.questions.where((q) => q.serverHasKey).length, s));
    }
  }
  return rows;
}

class GuideModelTestListScreen extends StatefulWidget {
  const GuideModelTestListScreen({super.key});

  @override
  State<GuideModelTestListScreen> createState() =>
      _GuideModelTestListScreenState();
}

class _GuideModelTestListScreenState
    extends State<GuideModelTestListScreen> {
  String? _startingSetId;

  Future<void> _start(
    BuildContext context,
    String subject,
    _SetRow row,
    int schoolClass,
    bool isPremium,
    bool bangla,
    Map<String, String> s,
  ) async {
    // Free-open (freeGuideLimit < 0) bypasses the paywall; the
    // branch stays so one AppConfig value re-locks it later.
    if (!isPremium && AppConfig.freeGuideLimit >= 0) {
      context.go('/premium');
      return;
    }
    setState(() => _startingSetId = row.setId);
    List<GuideBankQuestion>? rows = row.cached?.questions;
    if (rows == null || rows.isEmpty) {
      rows = await modelTestSetService.fetchSetRows(subject, row.setId,
          schoolClass: schoolClass);
      if (rows != null) {
        final cached = await modelTestSetService.cachedSets(subject,
            schoolClass: schoolClass);
        final merged = [
          for (final c in cached) if (c.setId != row.setId) c,
          GuideModelSet(
              setId: row.setId, subjectId: subject, questions: rows),
        ];
        await modelTestSetService.cacheSets(subject, merged,
            schoolClass: schoolClass);
      }
    }
    if (rows == null) {
      if (mounted) {
        setState(() => _startingSetId = null);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s['modelTestsUnavailable']!)));
      }
      return;
    }
    final candidates = rows
        .where((q) =>
            q.questionType == 'mcq' && q.serverHasKey && !q.guideError)
        .map((q) => GuideQuizCandidate(q, 0))
        .toList();
    final items = await guideQuizService.resolveKeys(candidates,
        subject: subject,
        schoolClass: schoolClass,
        bangla: bangla,
        limit: candidates.length);
    if (items.isEmpty || !context.mounted) {
      if (mounted) {
        setState(() => _startingSetId = null);
        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s['modelTestNoKeyed']!)));
        }
      }
      return;
    }
    PracticeSession.modelTestId = 'guide:${row.setId}';
    PracticeSession.modelSubject = subject;
    PracticeSession.modelChapter = '';
    PracticeSession.modelItems = items;
    PracticeSession.modelMinutes = 15;
    PracticeSession.modelIsGuide = true;
    PracticeSession.clearModelExam();
    setState(() => _startingSetId = null);
    context.go('/model-test-exam');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? guideBankStringsBn : guideBankStringsEn;
        final subject = PracticeSession.selectedSubject;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/practice'),
            ),
            title: Text(
              '${s['modelTestsTitle']!} · ${subjectNameFor(subject, bn)}',
            ),
          ),
          body: FutureBuilder<List<dynamic>>(
            // Sets are class-keyed: resolve the saved class first
            // instead of taking the service's documented fallback.
            future: Future.wait([
              resolveSchoolClass().then((c) async => _LoadedSets(
                    meta: await modelTestSetService.fetchSetsFromServer(
                        subject,
                        schoolClass: c),
                    cached: await modelTestSetService.cachedSets(
                      subject,
                      schoolClass: c,
                    ),
                    schoolClass: c,
                  )),
              billingService.isPremium(),
            ]),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final loaded = snap.data![0] as _LoadedSets;
              final isPremium = snap.data![1] as bool;
              final rows = _mergeRows(loaded.meta, loaded.cached);
              if (loaded.meta == null && loaded.cached.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    s['modelTestsUnavailable']!,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                );
              }
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    s['modelTestsEmpty']!,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final row in rows) ...[
                    PracticeCard(
                      title: row.setId,
                      subtitle:
                          '${numStr(row.total, bn)}'
                          '${s['questionsSuffix']!} · '
                          '${numStr(row.keyed, bn)}'
                          '${s['keyedSuffix']!}'
                          '${row.unkeyed > 0 ? ' · '
                              '${numStr(row.unkeyed, bn)}'
                              '${s['unkeyedExcludedSuffix']!}' : ''}',
                      icon: row.keyed == 0
                          ? Icons.lock
                          : Icons.assignment,
                      trailing: _startingSetId == row.setId
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : ElevatedButton(
                              onPressed: row.keyed == 0
                                  ? null
                                  : () => _start(
                                        context,
                                        subject,
                                        row,
                                        loaded.schoolClass,
                                        isPremium,
                                        bn,
                                        s,
                                      ),
                              child: Text(s['modelTestStart']!),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
