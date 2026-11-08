// Lesson MCQ screen: bank MCQ only (model MCQ lives on the
// section Model test entry). Rows group by mcq_group once the
// Phase B backfill lands (writer | lesson); until then the
// whole list shows flat — never a crash, never a hidden MCQ.
// A mixed tagging state shows untagged rows under their own
// "other" header instead of misfiling them. Tapping a row
// opens the existing single-question answer flow.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/bangla_first_lessons.dart';
import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_first_fetch.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_first_strings.dart';
import 'bangla_first_retry_state.dart';
import 'bangla_mcq_grouping.dart';
import 'search_flow_answer_nav.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

const _optionLetters = ['ক', 'খ', 'গ', 'ঘ'];

class _McqLoaded {
  const _McqLoaded({required this.rows, required this.isPremium});
  final List<GuideBankQuestion>? rows;
  final bool isPremium;
}

class BanglaFirstMcqScreen extends StatefulWidget {
  const BanglaFirstMcqScreen({
    super.key,
    required this.section,
    required this.lessonTitle,
  });
  final String section;
  final String lessonTitle;

  @override
  State<BanglaFirstMcqScreen> createState() => _BanglaFirstMcqScreenState();
}

class _BanglaFirstMcqScreenState extends State<BanglaFirstMcqScreen> {
  late Future<_McqLoaded> _future;

  String get _selfUrl =>
      '/bangla-first-mcq?section=${widget.section}&lesson=${Uri.encodeComponent(widget.lessonTitle)}';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_McqLoaded> _load() async {
    final results = await Future.wait([
      banglaFirstFetch.fetchLessonRows(
          lesson: widget.lessonTitle, section: 'mcq'),
      billingService.isPremium().catchError((_) => false),
    ]);
    return _McqLoaded(
      rows: results[0] as List<GuideBankQuestion>?,
      isPremium: results[1] as bool,
    );
  }

  void _open(BuildContext context, _McqLoaded loaded, int index,
      GuideBankQuestion q) {
    openSearchFlowGuideAnswer(
      context,
      isPremium: loaded.isPremium,
      index: index,
      q: q,
      subjectId: 'bangla',
      chapterNumber: 0,
      schoolClass: BanglaFirstFetch.schoolClass,
      returnTo: _selfUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(
                  '/bangla-first-lesson?section=${widget.section}&lesson=${Uri.encodeComponent(widget.lessonTitle)}'),
            ),
            title: Text(s['lessonMcq']!),
          ),
          body: FutureBuilder<_McqLoaded>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final loaded = snap.data!;
              final rows = loaded.rows;
              if (rows == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              if (rows.isEmpty) {
                return Center(child: Text(s['mcqEmpty']!));
              }
              final groups = groupBanglaMcqs(rows);
              var index = 0;
              Widget tile(GuideBankQuestion q) {
                final i = index++;
                return _McqTile(
                  q: q,
                  onTap: () => _open(context, loaded, i, q),
                );
              }

              final children = <Widget>[];
              if (!groups.hasTags) {
                for (final q in groups.untagged) {
                  children.add(tile(q));
                }
              } else {
                if (groups.writer.isNotEmpty) {
                  children.add(_GroupHeader(
                      '${s['mcqWriterGroup']!} (${groups.writer.length})'));
                  for (final q in groups.writer) {
                    children.add(tile(q));
                  }
                }
                if (groups.lesson.isNotEmpty) {
                  final sectionName =
                      banglaFirstSectionName(widget.section, s);
                  children.add(_GroupHeader(
                      '$sectionName${s['mcqLessonSuffix']!} (${groups.lesson.length})'));
                  for (final q in groups.lesson) {
                    children.add(tile(q));
                  }
                }
                if (groups.hasUntagged) {
                  children.add(_GroupHeader(
                      '${s['mcqOtherGroup']!} (${groups.untagged.length})'));
                  for (final q in groups.untagged) {
                    children.add(tile(q));
                  }
                }
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: children,
              );
            },
          ),
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _McqTile extends StatelessWidget {
  const _McqTile({required this.q, required this.onTap});
  final GuideBankQuestion q;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.questionText,
                  style: const TextStyle(fontFamily: 'HindSiliguri')),
              if (q.options.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (var i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${i < _optionLetters.length ? _optionLetters[i] : '${i + 1}'}. ${q.options[i]}',
                      style: const TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

