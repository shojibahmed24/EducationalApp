// Renders one Mode C page result: an honest empty state (never a
// guessed question) or the verbatim questions on that page. Tapping
// a question hands its PageQuestion back to the screen, which shows
// the verbatim text + AI explanation below.
import 'package:flutter/material.dart';
import '../../../core/services/book_lookup_service.dart';

class BookLookupPageList extends StatelessWidget {
  const BookLookupPageList({
    super.key,
    required this.result,
    required this.s,
    required this.onTap,
  });
  final PageLookup result;
  final Map<String, String> s;
  final ValueChanged<PageQuestion> onTap;

  @override
  Widget build(BuildContext context) {
    if (result.reason == 'edge-missing') {
      return Text(s['edgeMissing']!);
    }
    if (!result.found) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s['noQuestionsYet']!),
          const SizedBox(height: 6),
          Text(s['askExact']!),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s['tapHint']!),
        const SizedBox(height: 8),
        ...result.questions.map((q) => Card(
              child: ListTile(
                title: Text(q.questionText),
                subtitle: Text(
                  '${s['chapterLabel']!} ${q.chapterNumber} · '
                  '${s['pageShort']!} ${q.page} · '
                  '${q.problem != null ? '${s['questionShort']!} ${q.problem}' : s['unnumbered']!}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onTap(q),
              ),
            )),
      ],
    );
  }
}
