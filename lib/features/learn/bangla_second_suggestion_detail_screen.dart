// Suggestion detail screen (level 3): the selected row's
// শিরোনাম, তারকা and question-number list, then its linked
// questions IN LINKED-ID ORDER. Linked rows resolve client-side
// from the bank + nirmiti sections (file audit: 448 bank, 180
// nirmiti links); rachana suggestions link nirmiti topics.
// Tapping a linked row opens the existing answer flow (nirmiti
// rows via the nirmiti opener, bank rows via the single flow).
// A linked id with no match shows only an unmatched count —
// never an invented question. Dropped directives are not in
// linkedDirectiveIds at all, so they never appear here.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_first_retry_state.dart';
import 'bangla_second_answer_open.dart';
import 'bangla_second_row_tile.dart';
import 'bangla_second_types.dart';
import 'search_flow_answer_nav.dart';
import 'widgets/digits.dart';

class _DetailLoaded {
  const _DetailLoaded({
    required this.suggestions,
    required this.bank,
    required this.nirmiti,
    required this.isPremium,
  });
  final List<GuideBankQuestion>? suggestions;
  final List<GuideBankQuestion>? bank;
  final List<GuideBankQuestion>? nirmiti;
  final bool isPremium;
}

class BanglaSecondSuggestionDetailScreen extends StatefulWidget {
  const BanglaSecondSuggestionDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<BanglaSecondSuggestionDetailScreen> createState() =>
      _BanglaSecondSuggestionDetailScreenState();
}

class _BanglaSecondSuggestionDetailScreenState
    extends State<BanglaSecondSuggestionDetailScreen> {
  late Future<_DetailLoaded> _future;

  String get _selfUrl =>
      '/bangla-second-suggestion-detail?id=${Uri.encodeComponent(widget.id)}';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailLoaded> _load() async {
    final results = await Future.wait([
      banglaSecondFetch.fetchSectionRows('suggestion'),
      banglaSecondFetch.fetchSectionRows('bank'),
      banglaSecondFetch.fetchSectionRows('nirmiti'),
      billingService.isPremium().catchError((_) => false),
    ]);
    return _DetailLoaded(
      suggestions: results[0] as List<GuideBankQuestion>?,
      bank: results[1] as List<GuideBankQuestion>?,
      nirmiti: results[2] as List<GuideBankQuestion>?,
      isPremium: results[3] as bool,
    );
  }

  Future<void> _open(
      BuildContext context, int index, GuideBankQuestion q,
      bool isPremium) async {
    final kind = parseBanglaSecondNirmitiKind(q.id);
    if (kind != null) {
      await openBanglaSecondNirmitiAnswer(
        context,
        kind: kind,
        isPremium: isPremium,
        index: index,
        q: q,
        returnTo: _selfUrl,
      );
      return;
    }
    await openSearchFlowGuideAnswer(
      context,
      isPremium: isPremium,
      index: index,
      q: q,
      subjectId: 'bangla',
      chapterNumber: 0,
      schoolClass: BanglaSecondFetch.schoolClass,
      returnTo: _selfUrl,
    );
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
              onPressed: () => context.go('/bangla-second-suggestion'),
            ),
            title: Text(s['typeSuggestion']!),
          ),
          body: FutureBuilder<_DetailLoaded>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final loaded = snap.data!;
              if (loaded.suggestions == null ||
                  loaded.bank == null ||
                  loaded.nirmiti == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              GuideBankQuestion? row;
              for (final q in loaded.suggestions!) {
                if (q.id == widget.id) row = q;
              }
              if (row == null) {
                return Center(child: Text(s['empty']!));
              }
              final resolved = resolveBanglaSecondLinked(
                  row.linkedDirectiveIds,
                  [...loaded.bank!, ...loaded.nirmiti!]);
              final linked = resolved.matched;
              final unmatched = resolved.unmatched;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (row.suggestionShironam != null)
                    Text(row.suggestionShironam!,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium),
                  if (row.suggestionStar != null) ...[
                    const SizedBox(height: 4),
                    Text(row.suggestionStar!,
                        style: const TextStyle(
                            fontFamily: 'HindSiliguri')),
                  ],
                  const SizedBox(height: 16),
                  Text(s['suggestionNumbers']!,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(row.questionText,
                      style: const TextStyle(fontFamily: 'HindSiliguri')),
                  const SizedBox(height: 16),
                  Text(s['suggestionLinkedTitle']!,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (linked.isEmpty)
                    Text(s['empty']!)
                  else
                    for (var i = 0; i < linked.length; i++)
                      BanglaSecondRowTile(
                        q: linked[i],
                        onTap: () => _open(
                            context, i, linked[i], loaded.isPremium),
                      ),
                  if (unmatched > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${numStr(unmatched, bn)}${s['suggestionUnmatchedSuffix']!}',
                    ),
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
