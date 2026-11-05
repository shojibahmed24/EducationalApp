// Guide content text that follows the English translator
// switch on the shared guide answer screen (2026-11-03).
// Same pieces as the reader switch: the existing translation
// service (AI path + memory/persisted cache, never-word-by-
// word prompt) and the translated-field widget (original
// while translating, original + note + retry on failure,
// never blank). [translate] is false outside the English
// flow: other subjects always render the original
// GuideMathText, whatever the switch says. The switch state
// itself is NOT threaded here — it comes from the service's
// enabledNotifier, so the shared answer body needs no switch
// state and the screen only adds the switch widget.
import 'package:flutter/material.dart';

import '../../../core/services/english_translation_service.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/english_search_flow_strings.dart';
import 'english_translated_text.dart';
import 'guide_math_text.dart';

class GuideTranslatedMathText extends StatelessWidget {
  const GuideTranslatedMathText({
    super.key,
    required this.text,
    required this.fontSize,
    this.color,
    this.fontWeight,
    required this.translate,
    this.service,
  });
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight? fontWeight;

  /// False outside the English flow (subjectId != 'english').
  final bool translate;

  /// Injectable in tests; defaults to the shared singleton,
  /// so the answer screen shares the persisted cache with
  /// the reader (same texts are never translated twice).
  final EnglishTranslationService? service;

  @override
  Widget build(BuildContext context) {
    final svc = service ?? englishTranslationService;
    return ValueListenableBuilder<bool>(
      valueListenable: svc.enabledNotifier,
      builder: (context, enabled, _) {
        if (!translate || !enabled) {
          return GuideMathText(
            text: text,
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
          );
        }
        final bn = languageNotifier.value.languageCode == 'bn';
        final es =
            bn ? englishSearchFlowStringsBn : englishSearchFlowStringsEn;
        return EnglishTranslatedText(
          text: text,
          translate: true,
          service: svc,
          failedNote: es['readerTranslateFailed']!,
          retryLabel: es['readerTranslateRetry']!,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: 'HindSiliguri',
            height: 1.7,
            color: color,
          ),
        );
      },
    );
  }
}
