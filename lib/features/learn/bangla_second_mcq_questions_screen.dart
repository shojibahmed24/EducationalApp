// MCQ questions screen (level 3): rows for exactly one lesson
// selection — a পরিচ্ছেদ, the extra bucket, or one assessment
// set. The sub chip (from the lesson screen) filters bank rows
// by live mcq_group; assessment rows carry none, so the chip
// never hides them. Tapping a row opens the answer flow.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_first_retry_state.dart';
import 'bangla_second_row_tile.dart';
import 'bangla_second_types.dart';
import 'search_flow_answer_nav.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class _QuestionsLoaded {
  const _QuestionsLoaded({required this.rows, required this.isPremium});
  final List<GuideBankQuestion>? rows;
  final bool isPremium;
}

class BanglaSecondMcqQuestionsScreen extends StatefulWidget {
  const BanglaSecondMcqQuestionsScreen({
    super.key,
    required this.group,
    required this.sub,
  });
  final String group;
  final String sub;

  @override
  State<BanglaSecondMcqQuestionsScreen> createState() =>
      _BanglaSecondMcqQuestionsScreenState();
}

class _BanglaSecondMcqQuestionsScreenState
    extends State<BanglaSecondMcqQuestionsScreen> {
  late Future<_QuestionsLoaded> _future;

  String get _selfUrl =>
      '/bangla-second-mcq-questions?group=${widget.group}&sub=${widget.sub}';

  bool get _isAssessment => widget.group.startsWith('set:');

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_QuestionsLoaded> _load() async {
    final section = _isAssessment ? 'byakoron-assessment' : 'bank';
    final results = await Future.wait([
      banglaSecondFetch.fetchSectionRows(section),
      billingService.isPremium().catchError((_) => false),
    ]);
    final rows = results[0] as List<GuideBankQuestion>?;
    final filtered = rows == null
        ? null
        : (rows.where((q) {
            if (_isAssessment) {
              return q.setId == widget.group.substring(4);
            }
            if (widget.group == 'extra') {
              if (parseBanglaSecondChapter(q.id) != null) return false;
            } else {
              final n = int.tryParse(widget.group.substring(2));
              if (parseBanglaSecondChapter(q.id) != n) return false;
            }
            return widget.sub == 'all' || q.mcqGroup == widget.sub;
          }).toList()
          ..sort((a, b) => a.id.compareTo(b.id)));
    return _QuestionsLoaded(
        rows: filtered, isPremium: results[1] as bool);
  }

  String _title(Map<String, String> s) {
    if (_isAssessment) return '${s['assessmentGroup']!} ${widget.group.substring(4)}';
    if (widget.group == 'extra') return s['extraGroup']!;
    return '${s['chapterPrefix']!} ${widget.group.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaSecondStringsBn : banglaSecondStringsEn;
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/bangla-second-mcq'),
            ),
            title: Text(_title(s)),
          ),
          body: FutureBuilder<_QuestionsLoaded>(
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
                return Center(child: Text(s['empty']!));
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (var i = 0; i < rows.length; i++)
                    BanglaSecondRowTile(
                      q: rows[i],
                      onTap: () => openSearchFlowGuideAnswer(
                        context,
                        isPremium: loaded.isPremium,
                        index: i,
                        q: rows[i],
                        subjectId: 'bangla',
                        chapterNumber: 0,
                        schoolClass: BanglaSecondFetch.schoolClass,
                        returnTo: _selfUrl,
                      ),
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
