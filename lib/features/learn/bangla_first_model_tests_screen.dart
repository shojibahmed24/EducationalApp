// Section model tests by setId prefix. Titles come from the
// slug -> lesson map, never invented; unparsable ids show
// raw. MCQ sets start the timed exam path; creative sets
// open their groups; no sets (the novel) shows empty.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/bangla_first_lessons.dart';
import '../../core/models/guide_bank_model.dart';
import '../../core/services/app_config.dart';
import '../../core/services/bangla_first_fetch.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/guide_quiz_service.dart';
import '../../core/services/model_test_set_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_first_strings.dart';
import '../practice/practice_store.dart';
import 'bangla_first_retry_state.dart';
import 'widgets/digits.dart';

class _Loaded {
  const _Loaded({required this.sets, required this.isPremium});
  final List<GuideModelSetInfo>? sets;
  final bool isPremium;
}

class _SetDisplay {
  const _SetDisplay(
      {required this.info, required this.title, required this.isCreative});
  final GuideModelSetInfo info;
  final String title;
  final bool isCreative;
}

_SetDisplay _displayFor(
    GuideModelSetInfo info, String section, Map<String, String> s) {
  final prefix = banglaFirstSetPrefix(section);
  final id = info.setId;
  if (!id.startsWith(prefix)) {
    return _SetDisplay(info: info, title: id, isCreative: false);
  }
  final rest = id.substring(prefix.length);
  late final bool creative;
  late final String slug;
  if (rest.endsWith('-model-mcq')) {
    creative = false;
    slug = rest.substring(0, rest.length - '-model-mcq'.length);
  } else if (rest.endsWith('-model-creative')) {
    creative = true;
    slug = rest.substring(0, rest.length - '-model-creative'.length);
  } else {
    return _SetDisplay(info: info, title: id, isCreative: false);
  }
  final lesson = banglaFirstLessonBySlug(slug);
  final kind = creative ? s['modelCreativeKind']! : s['modelMcqKind']!;
  return _SetDisplay(
      info: info,
      title: lesson == null ? id : '${lesson.title} · $kind',
      isCreative: creative);
}

class BanglaFirstModelTestsScreen extends StatefulWidget {
  const BanglaFirstModelTestsScreen({super.key, required this.section});
  final String section;

  @override
  State<BanglaFirstModelTestsScreen> createState() =>
      _BanglaFirstModelTestsScreenState();
}

class _BanglaFirstModelTestsScreenState
    extends State<BanglaFirstModelTestsScreen> {
  late Future<_Loaded> _future;
  String? _startingSetId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Loaded> _load() async {
    final results = await Future.wait([
      banglaFirstFetch.fetchSectionSets(widget.section),
      billingService.isPremium().catchError((_) => false),
    ]);
    return _Loaded(
      sets: results[0] as List<GuideModelSetInfo>?,
      isPremium: results[1] as bool,
    );
  }

  Future<void> _startExam(
      BuildContext context, _SetDisplay display, bool isPremium, bool bn,
      Map<String, String> s) async {
    if (!isPremium && AppConfig.freeGuideLimit >= 0) {
      context.go('/premium');
      return;
    }
    setState(() => _startingSetId = display.info.setId);
    final rows = await modelTestSetService.fetchSetRows(
        'bangla', display.info.setId,
        schoolClass: BanglaFirstFetch.schoolClass);
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
        subject: 'bangla',
        schoolClass: BanglaFirstFetch.schoolClass,
        bangla: bn,
        limit: candidates.length);
    if (items.isEmpty || !context.mounted) {
      if (mounted) {
        setState(() => _startingSetId = null);
        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s['noKeyed']!)));
        }
      }
      return;
    }
    PracticeSession.modelTestId = 'guide:${display.info.setId}';
    PracticeSession.modelSubject = 'bangla';
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
        final s = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(
                  '/bangla-first-section?section=${widget.section}'),
            ),
            title: Text(s['modelTestsTitle']!),
          ),
          body: FutureBuilder<_Loaded>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final loaded = snap.data!;
              final sets = loaded.sets;
              if (sets == null) {
                return BanglaFirstRetryState(
                  message: s['modelTestsUnavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              if (sets.isEmpty) {
                return Center(child: Text(s['modelTestsEmpty']!));
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final info in sets)
                    _SetCard(
                      display: _displayFor(info, widget.section, s),
                      s: s,
                      bn: bn,
                      starting:
                          _startingSetId == info.setId,
                      onTap: () {
                        final display =
                            _displayFor(info, widget.section, s);
                        if (display.isCreative) {
                          context.go(
                              '/bangla-first-creative-set?setId=${info.setId}&section=${widget.section}&title=${Uri.encodeComponent(display.title)}');
                        } else {
                          _startExam(context, display, loaded.isPremium,
                              bn, s);
                        }
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard(
      {required this.display,
      required this.s,
      required this.bn,
      required this.starting,
      required this.onTap});
  final _SetDisplay display;
  final Map<String, String> s;
  final bool bn;
  final bool starting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = display.info;
    final unkeyed = info.unkeyedCount;
    return Card(
      child: ListTile(
        title: Text(display.title),
        subtitle: Text(
          '${numStr(info.totalCount, bn)}${s['questionsSuffix']!} · '
          '${numStr(info.keyedCount, bn)}${s['keyedSuffix']!}'
          '${unkeyed > 0 ? ' · $unkeyed' : ''}',
        ),
        trailing: starting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton(
                onPressed: info.keyedCount == 0 && !display.isCreative
                    ? null
                    : onTap,
                child: Text(display.isCreative
                    ? s['viewGroups']!
                    : s['startExam']!),
              ),
      ),
    );
  }
}
