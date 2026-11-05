// Textbook chapter-list filter. Deliberately NOT BankFilterBar:
// the textbook list has no marks / important chips. Pure logic
// (taxonomy + AND filtering) is tested without widgets; the bar
// below only renders chips for types actually present in the
// loaded chapter, each with its count.
// Taxonomy: mcq, fill_blank, creative, short, problem, task are
// their own chips; anything else AND null -> 'other', whose label
// (in chapter_questions_strings) states it includes questions
// with no recorded type. Filters combine with AND: type + text
// search over question wording + optional numeric page filter
// (empty = no page filter).
import 'package:flutter/material.dart';
import '../../../core/services/textbook_chapter_service.dart';
import 'digits.dart';

/// Known type keys, in chip order. 'other' is always last.
const List<String> textbookTypeOrder = [
  'mcq',
  'fill_blank',
  'creative',
  'short',
  'problem',
  'task',
  'other',
];

String textbookTypeKey(String? raw) {
  switch (raw) {
    case 'mcq':
    case 'fill_blank':
    case 'creative':
    case 'short':
    case 'problem':
    case 'task':
      return raw!;
    default:
      return 'other';
  }
}

String textbookTypeLabel(String key, Map<String, String> s) {
  switch (key) {
    case 'mcq':
      return s['typeMcq']!;
    case 'fill_blank':
      return s['typeFillBlank']!;
    case 'creative':
      return s['typeCreative']!;
    case 'short':
      return s['typeShort']!;
    case 'problem':
      return s['typeProblem']!;
    case 'task':
      return s['typeTask']!;
    default:
      return s['typeOther']!;
  }
}

/// Types present in [all], in textbookTypeOrder, with counts.
List<(String, int)> textbookPresentTypes(
  List<TextbookChapterQuestion> all,
) {
  final counts = <String, int>{};
  for (final q in all) {
    final k = textbookTypeKey(q.questionType);
    counts[k] = (counts[k] ?? 0) + 1;
  }
  return [
    for (final k in textbookTypeOrder)
      if (counts.containsKey(k)) (k, counts[k]!),
  ];
}

List<TextbookChapterQuestion> filterTextbookQuestions({
  required List<TextbookChapterQuestion> all,
  required String type, // 'all' or a textbookTypeKey
  required String query,
  required int? page,
}) {
  final q = query.trim().toLowerCase();
  return all.where((item) {
    if (type != 'all' && textbookTypeKey(item.questionType) != type) {
      return false;
    }
    if (page != null && item.page != page) return false;
    if (q.isNotEmpty && !item.questionText.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }).toList();
}

/// Row meta: ONLY question text's location. Null problem -> page
/// only, never an invented number.
String textbookRowMeta(
  TextbookChapterQuestion q,
  Map<String, String> s,
  bool bn,
) {
  final pagePart = "${s['pageWord']!} ${numStr(q.page, bn)}";
  if (q.problem == null) return pagePart;
  return "$pagePart · ${s['questionWord']!} ${numStr(q.problem!, bn)}";
}

class TextbookFilterBar extends StatelessWidget {
  const TextbookFilterBar({
    super.key,
    required this.s,
    required this.presentTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onQueryChanged,
    required this.onPageChanged,
  });
  final Map<String, String> s;
  final List<(String, int)> presentTypes;
  final String selectedType;
  final void Function(String) onTypeChanged;
  final void Function(String) onQueryChanged;
  final void Function(String) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: s['searchHint'],
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: s['pageHint'],
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: onPageChanged,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: Text(s['allTypes']!),
              selected: selectedType == 'all',
              onSelected: (_) => onTypeChanged('all'),
            ),
            for (final entry in presentTypes)
              FilterChip(
                label: Text(
                  '${textbookTypeLabel(entry.$1, s)} (${entry.$2})',
                ),
                selected: selectedType == entry.$1,
                onSelected: (_) => onTypeChanged(entry.$1),
              ),
          ],
        ),
      ],
    );
  }
}
