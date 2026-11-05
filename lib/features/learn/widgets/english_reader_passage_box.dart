// Sticky passage box for the English reader (redesign 2026-11-03).
// Fixed height, never full-screen: one group of up to three
// paragraphs at a time, prev/next inside the box, only the part
// text changes. The parent keeps this box pinned while the
// question area scrolls.
import 'package:flutter/material.dart';

import '../../../core/data/english_redesign.dart';
import '../../../core/services/english_translation_service.dart';
import 'english_translated_text.dart';

class EnglishReaderPassageBox extends StatelessWidget {
  const EnglishReaderPassageBox({
    super.key,
    required this.title,
    required this.parts,
    required this.partIndex,
    required this.bn,
    required this.s,
    required this.onPrevPart,
    required this.onNextPart,
    this.translate = false,
    this.translationService,
    this.failedNote = '',
    this.retryLabel = '',
  });
  final String title;
  final List<String> parts;
  final int partIndex;
  final bool bn;
  final Map<String, String> s;
  final VoidCallback onPrevPart;
  final VoidCallback onNextPart;
  // Translator switch (2026-11-03): when on, the part text goes
  // through the Bangla translation; the box layout is untouched.
  final bool translate;
  final EnglishTranslationService? translationService;
  final String failedNote;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = parts.length;
    final label = total == 0
        ? ''
        : bn
            ? 'অংশ ${bnDigits(partIndex + 1)}/${bnDigits(total)}'
            : 'Part ${partIndex + 1}/$total';
    return Card(
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontFamily: 'HindSiliguri')),
                ),
                if (label.isNotEmpty) Text(label),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: total == 0
                  ? Text(s['readerPassageUnavailable']!)
                  : SingleChildScrollView(
                      child: translationService == null
                          ? Text(parts[partIndex],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontFamily: 'HindSiliguri'))
                          : EnglishTranslatedText(
                              text: parts[partIndex],
                              translate: translate,
                              service: translationService!,
                              failedNote: failedNote,
                              retryLabel: retryLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontFamily: 'HindSiliguri'),
                            ),
                    ),
            ),
            if (total > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: partIndex > 0 ? onPrevPart : null,
                    icon: const Icon(Icons.chevron_left),
                    label: Text(s['readerPartPrev']!),
                  ),
                  TextButton.icon(
                    onPressed:
                        partIndex < total - 1 ? onNextPart : null,
                    icon: const Icon(Icons.chevron_right),
                    label: Text(s['readerPartNext']!),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
