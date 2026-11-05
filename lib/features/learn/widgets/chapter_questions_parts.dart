// Pieces of ChapterQuestionsScreen, split out to keep it under
// the 250-line file cap: the class selector, the centred message
// state (unavailable / empty chapter), and the grouped rows
// (page section headers + question rows, meta only, no answers).
import 'package:flutter/material.dart';
import '../../../core/services/textbook_chapter_service.dart';
import 'digits.dart';
import 'textbook_filter.dart';

List<Widget> buildChapterQuestionRows({
  required BuildContext context,
  required List<TextbookChapterQuestion> shown,
  required Map<String, String> s,
  required bool bn,
  required void Function(TextbookChapterQuestion) onTap,
}) {
  final rows = <Widget>[];
  int? lastPage;
  for (final q in shown) {
    if (q.page != lastPage) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text("${s['pageWord']!} ${numStr(q.page, bn)}",
            style: Theme.of(context).textTheme.titleMedium),
      ));
      lastPage = q.page;
    }
    rows.add(Card(
      child: ListTile(
        title: Text(q.questionText),
        subtitle: Text(textbookRowMeta(q, s, bn)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onTap(q),
      ),
    ));
  }
  return rows;
}

class ChapterClassSelector extends StatelessWidget {
  const ChapterClassSelector({
    super.key,
    required this.schoolClass,
    required this.label,
    required this.onChanged,
  });
  final int schoolClass;
  final String label;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final items = {6, 7, schoolClass}.toList()..sort();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            DropdownButton<int>(
              value: schoolClass,
              items: items
                  .map((c) => DropdownMenuItem(value: c, child: Text('$c')))
                  .toList(),
              onChanged: (v) {
                if (v == null || v == schoolClass) return;
                onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChapterMessage extends StatelessWidget {
  const ChapterMessage({super.key, required this.title, this.body = ''});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(body),
              ],
            ],
          ),
        ),
      );
}
