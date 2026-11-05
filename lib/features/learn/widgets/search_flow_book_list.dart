// Textbook portion of the new type list (Step 5): rows show the
// printed page/problem only — NEVER marks, because NCTB textbook
// questions print no marks and none may be invented. The parent
// owns the filtered list and the 20-at-a-time window.
import 'package:flutter/material.dart';

import '../../../core/services/textbook_chapter_service.dart';
import 'digits.dart';
import 'textbook_filter.dart';

class SearchFlowBookListView extends StatelessWidget {
  const SearchFlowBookListView({
    super.key,
    required this.rows,
    required this.visible,
    required this.bn,
    required this.s,
    required this.cs,
    required this.onOpen,
    required this.onLoadMore,
  });
  final List<TextbookChapterQuestion> rows;
  final int visible;
  final bool bn;

  /// search_flow strings (Bn or En).
  final Map<String, String> s;

  /// chapter_questions strings (Bn or En) for row meta.
  final Map<String, String> cs;
  final void Function(TextbookChapterQuestion q) onOpen;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final shown = rows.take(visible).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(s['showingTotal']!
            .replaceAll('{total}', numStr(rows.length, bn))
            .replaceAll('{shown}', numStr(shown.length, bn))),
        const SizedBox(height: 8),
        for (final q in shown)
          Card(
            child: ListTile(
              title: Text(q.questionText,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(textbookRowMeta(q, cs, bn)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpen(q),
            ),
          ),
        if (rows.length > visible) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onLoadMore,
            child: Text(s['loadMore']!),
          ),
        ],
      ],
    );
  }
}
