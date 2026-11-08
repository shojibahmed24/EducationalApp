// Board sub-section screen (Board revision 2026-11-02).
// Reached only from the Board tile, which renders only when
// flagged board rows exist — so the normal path always has
// at least one non-zero sub-section. The screen itself
// never invents counts: it re-fetches the Board entry and
// hides any zero sub-section; a fully empty or unreachable
// entry shows an honest message, never blank cards. Each
// sub-section navigates to the list route with board=true
// plus its section, so MCQ and Creative lists never mix.
// Pre-recollection behaviour: this screen is unreachable
// (the tile hides when no flagged rows exist in the DB),
// and a direct route entry with no rows shows the empty
// message below — never empty question cards.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/guide_bank_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/search_flow_strings.dart';
import 'search_flow_types.dart';
import 'widgets/digits.dart';
import 'widgets/search_flow_message.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class SearchFlowBoardSectionsScreen extends StatelessWidget {
  const SearchFlowBoardSectionsScreen({
    super.key,
    required this.subjectId,
    required this.schoolClass,
  });
  final String subjectId;
  final int schoolClass;

  String _listUrl(String section, String type) =>
      '/search-flow-list?subject=$subjectId&class=$schoolClass'
      '&source=guide&board=true&section=$section&type=$type';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? searchFlowStringsBn : searchFlowStringsEn;
        final back = '/search-flow?subject=$subjectId';
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(back),
            ),
            title: Text(s['boardQuestions']!),
          ),
          body: FutureBuilder<({int total, int mcq, int creative})?>(
            future: guideBankService.fetchGuideBoard(subjectId,
                schoolClass: schoolClass),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(child: Text(s['loading']!));
              }
              final board = snap.data;
              if (board == null) {
                return searchFlowMessage(context, s['unavailableTitle']!,
                    s['unavailableBody']!, s, back);
              }
              if (board.total <= 0 ||
                  (board.mcq <= 0 && board.creative <= 0)) {
                return searchFlowMessage(
                    context, s['emptyList']!, '', s, back);
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (board.mcq > 0)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_box_outlined),
                          title: Text(
                              '${searchFlowTypeLabel(SearchFlowType.mcq, s)} · ${numStr(board.mcq, bn)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go(
                              _listUrl('board-mcq', 'mcq')),
                        ),
                      ),
                    if (board.creative > 0)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.edit_note),
                          title: Text(
                              '${searchFlowTypeLabel(SearchFlowType.creative, s)} · ${numStr(board.creative, bn)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go(
                              _listUrl('board-creative', 'creative')),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
