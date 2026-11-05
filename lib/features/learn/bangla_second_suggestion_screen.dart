// Suggestion lesson screen (level 2): the 68 appendix rows
// grouped by suggestionPoricched in first-appearance order.
// The Edge list now serves title, star, chapter and linked ids
// (2026-11-04), so the old gap note is gone. Each row shows
// শিরোনাম + তারকা + question-number list; no filter chips
// (sub_bank is NULL for all 68 rows). "প্রশ্ন দেখুন" opens the
// detail screen, never the MCQ question flow: suggestion rows
// are not answerable questions.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_first_retry_state.dart';
import 'bangla_second_types.dart';
import 'widgets/digits.dart';

class BanglaSecondSuggestionScreen extends StatefulWidget {
  const BanglaSecondSuggestionScreen({super.key});

  @override
  State<BanglaSecondSuggestionScreen> createState() =>
      _BanglaSecondSuggestionScreenState();
}

class _BanglaSecondSuggestionScreenState
    extends State<BanglaSecondSuggestionScreen> {
  late Future<List<GuideBankQuestion>?> _future;
  String? _selection;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<GuideBankQuestion>?> _load() async {
    final rows = await banglaSecondFetch.fetchSectionRows('suggestion');
    if (rows == null) return null;
    return rows..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaSecondStringsBn : banglaSecondStringsEn;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/bangla-second'),
            ),
            title: Text(s['typeSuggestion']!),
          ),
          body: FutureBuilder<List<GuideBankQuestion>?>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final rows = snap.data;
              if (rows == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              GuideBankQuestion? selected;
              for (final q in rows) {
                if (q.id == _selection) selected = q;
              }
              final groups =
                  groupBanglaSecondRows<GuideBankQuestion, String?>(
                      rows, (q) => q.suggestionPoricched);
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(s['suggestionNotQuestions']!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium),
                        const SizedBox(height: 16),
                        Text(
                          '${numStr(rows.length, bn)}${s['suggestionsSuffix']!}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (rows.isEmpty)
                          Center(child: Text(s['empty']!))
                        else
                          for (final entry in groups.entries) ...[
                            if ((entry.key ??
                                        entry.value.first
                                            .suggestionShironam ??
                                        '')
                                    .isNotEmpty) ...[
                              Text(
                                entry.key ??
                                    entry.value.first.suggestionShironam!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              const SizedBox(height: 8),
                            ],
                            for (final q in entry.value)
                              _SuggestionCard(
                                q: q,
                                selected: _selection == q.id,
                                onTap: () => setState(
                                    () => _selection = q.id),
                              ),
                            const SizedBox(height: 12),
                          ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selected == null
                            ? null
                            : () => context.go(
                                '/bangla-second-suggestion-detail?id=${Uri.encodeComponent(selected!.id)}'),
                        child: Text(s['viewQuestions']!),
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

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.q,
    required this.selected,
    required this.onTap,
  });
  final GuideBankQuestion q;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (q.suggestionShironam != null)
                Text(q.suggestionShironam!,
                    style: const TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontWeight: FontWeight.bold)),
              if (q.suggestionStar != null) ...[
                const SizedBox(height: 4),
                Text(q.suggestionStar!,
                    style: const TextStyle(fontFamily: 'HindSiliguri')),
              ],
              const SizedBox(height: 4),
              Text(q.questionText,
                  style: const TextStyle(fontFamily: 'HindSiliguri')),
            ],
          ),
        ),
      ),
    );
  }
}
