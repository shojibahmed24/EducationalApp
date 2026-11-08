// Model-test lesson screen (level 2): মডেল সেট cards from
// the appendix-model-test section + বোর্ড প্রশ্ন cards from
// the board sections, grouped by set_id. Model sets are
// single-kind in the file (model-1..20 MCQ, model-21..40
// written); board sets carry both parts. Selecting a card
// enables the pinned button: MCQ model sets start the timed
// exam (printed 30 minutes for the MCQ paper); written model
// sets and board sets open their rows screen.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_first_retry_state.dart';
import 'bangla_second_model_exam.dart';
import 'bangla_second_types.dart';
import 'widgets/digits.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class _ModelLoaded {
  const _ModelLoaded(
      {required this.model,
      required this.board,
      required this.isPremium});
  final List<GuideBankQuestion>? model;
  final List<GuideBankQuestion>? board;
  final bool isPremium;
}

class BanglaSecondModelTestsScreen extends StatefulWidget {
  const BanglaSecondModelTestsScreen({super.key});

  @override
  State<BanglaSecondModelTestsScreen> createState() =>
      _BanglaSecondModelTestsScreenState();
}

class _BanglaSecondModelTestsScreenState
    extends State<BanglaSecondModelTestsScreen> {
  late Future<_ModelLoaded> _future;
  String? _selection;
  String? _starting;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ModelLoaded> _load() async {
    final results = await Future.wait([
      banglaSecondFetch.fetchSectionRows('appendix-model-test'),
      banglaSecondFetch.fetchSectionRows('board-mcq'),
      banglaSecondFetch.fetchSectionRows('board-written'),
      billingService.isPremium().catchError((_) => false),
    ]);
    final boardMcq = results[1] as List<GuideBankQuestion>?;
    final boardWritten = results[2] as List<GuideBankQuestion>?;
    return _ModelLoaded(
      model: results[0] as List<GuideBankQuestion>?,
      board: boardMcq == null || boardWritten == null
          ? null
          : [...boardMcq, ...boardWritten],
      isPremium: results[3] as bool,
    );
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
              onPressed: () => context.go('/bangla-second'),
            ),
            title: Text(s['modelTestsTitle']!),
          ),
          body: FutureBuilder<_ModelLoaded>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final loaded = snap.data!;
              final model = loaded.model;
              final board = loaded.board;
              if (model == null || board == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              final modelSets =
                  groupBanglaSecondRows<GuideBankQuestion, String?>(
                      model, (q) => q.setId);
              final modelIds = modelSets.keys.whereType<String>().toList()
                ..sort((a, b) =>
                    (parseBanglaSecondModelSetNumber(a) ?? 0)
                        .compareTo(parseBanglaSecondModelSetNumber(b) ?? 0));
              final boardSets =
                  groupBanglaSecondRows<GuideBankQuestion, String?>(
                      board, (q) => q.setId);
              final boardIds = boardSets.keys.whereType<String>().toList()
                ..sort((a, b) {
                  final ya = parseBanglaSecondBoardYear(a) ?? 0;
                  final yb = parseBanglaSecondBoardYear(b) ?? 0;
                  if (ya != yb) return yb.compareTo(ya);
                  return a.compareTo(b);
                });
              Widget card({
                required String key,
                required String title,
                required String subtitle,
              }) {
                final selected = _selection == key;
                return Card(
                  color: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(subtitle),
                    trailing: _starting == key
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : selected
                            ? const Icon(Icons.check_circle)
                            : const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _selection = key),
                  ),
                );
              }

              String? buttonLabel;
              VoidCallback? buttonAction;
              if (_selection != null) {
                if (_selection!.startsWith('model:')) {
                  final setId = _selection!.substring(6);
                  final rows = modelSets[setId]!;
                  final isMcq =
                      rows.any((q) => q.questionType == 'mcq');
                  if (isMcq) {
                    buttonLabel = s['startExam']!;
                    buttonAction = () => startBanglaSecondModelExam(
                          context,
                          rows: rows,
                          setId: setId,
                          isPremium: loaded.isPremium,
                          bn: bn,
                          noKeyedLabel: s['noKeyed']!,
                          onStart: () =>
                              setState(() => _starting = 'model:$setId'),
                          onDone: () => setState(() => _starting = null),
                        );
                  } else {
                    buttonLabel = s['viewQuestions']!;
                    buttonAction = () => context.go(
                        '/bangla-second-set-rows?group=model&setId=$setId');
                  }
                } else if (_selection!.startsWith('board:')) {
                  final setId = _selection!.substring(6);
                  buttonLabel = s['viewQuestions']!;
                  buttonAction = () => context.go(
                      '/bangla-second-set-rows?group=board&setId=${Uri.encodeComponent(setId)}');
                }
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(s['modelTestsTitle']!,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final setId in modelIds)
                          Builder(builder: (_) {
                            final rows = modelSets[setId]!;
                            final mcq = rows
                                .where((q) => q.questionType == 'mcq')
                                .length;
                            final n =
                                parseBanglaSecondModelSetNumber(setId) ?? 0;
                            return card(
                              key: 'model:$setId',
                              title:
                                  '${s['modelTestsTitle']!} ${numStr(n, bn)}',
                              subtitle:
                                  '${numStr(rows.length, bn)}${s['questionsSuffix']!}'
                                  '${mcq > 0 ? ' · MCQ ${numStr(mcq, bn)}' : ''}',
                            );
                          }),
                        const SizedBox(height: 16),
                        Text(s['boardTitle']!,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final setId in boardIds)
                          Builder(builder: (_) {
                            final rows = boardSets[setId]!;
                            final mcq = rows
                                .where((q) => q.section == 'board-mcq')
                                .length;
                            final written = rows.length - mcq;
                            return card(
                              key: 'board:$setId',
                              title: setId,
                              subtitle:
                                  'MCQ ${numStr(mcq, bn)} · ${numStr(written, bn)}${s['questionsSuffix']!}',
                            );
                          }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: buttonAction,
                        child: Text(buttonLabel ?? s['viewQuestions']!),
                      ),
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
