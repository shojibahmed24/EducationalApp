// Small attribution line under an AI explanation.
//
// It shows ONLY what the Edge response itself reported
// (see GenResult): 'AI: Gemini • gemini-3.8-flash',
// 'AI: OpenRouter • nvidia/...', or — when the Edge deploy
// predates attribution and reported neither field — the
// caller-supplied localized unknown text, never a guess from
// the provider the user merely selected in Settings. The
// provider/model names are language-neutral; only the unknown
// sentence is localized, and it comes from the page's own
// strings map (page-wise rule), never hardcoded here.
import 'package:flutter/material.dart';

class AiAttributionLabel extends StatelessWidget {
  const AiAttributionLabel({
    super.key,
    required this.provider,
    required this.model,
    required this.unknownText,
  });

  /// 'openrouter' | 'gemini' | 'unknown'.
  final String provider;
  final String? model;

  /// Localized honest text for the unknown case, e.g.
  /// 'AI: জানা যায়নি — সার্ভার আপডেট হয়নি, OpenRouter
  /// চলতে পারে' (from the page's strings).
  final String unknownText;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    if (provider != 'openrouter' && provider != 'gemini') {
      return Text(unknownText, style: style);
    }
    final name = provider == 'gemini' ? 'Gemini' : 'OpenRouter';
    final label = model != null && model!.isNotEmpty
        ? 'AI: $name • $model'
        : 'AI: $name';
    return Text(label, style: style);
  }
}
