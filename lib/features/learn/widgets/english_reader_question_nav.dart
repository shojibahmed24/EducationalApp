// Prev/next row under the English reader's question card.
// The parent owns navigation state; this row only renders.
import 'package:flutter/material.dart';

class EnglishReaderQuestionNav extends StatelessWidget {
  const EnglishReaderQuestionNav({
    super.key,
    required this.canPrev,
    required this.s,
    required this.onPrev,
    required this.onNext,
  });
  final bool canPrev;
  final Map<String, String> s;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: canPrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left),
          label: Text(s['readerPrevQuestion']!),
        ),
        TextButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          label: Text(s['readerNextQuestion']!),
        ),
      ],
    );
  }
}
