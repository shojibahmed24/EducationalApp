// Pinned passage/stimulus block for the single-question answer
// body: the same pattern as the grouped creative view (title +
// text card), but for singles, which previously never showed
// stimulus at all — so English story/poem starters and, after
// the passage backfill, reading passages render above the
// question. Empty text AND empty ref render nothing (the caller
// guards too); nothing here is ever invented. The optional ref
// line names the passage's source once the ref backfill lands.
import 'package:flutter/material.dart';

import 'guide_math_text.dart';

class GuideStimulusBlock extends StatelessWidget {
  const GuideStimulusBlock({
    super.key,
    this.text,
    this.ref,
    required this.fontSize,
    required this.s,
  });
  final String? text;
  final String? ref;
  final double fontSize;
  final Map<String, String> s;

  bool get _hasText => text != null && text!.isNotEmpty;
  bool get _hasRef => ref != null && ref!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasText && !_hasRef) return const SizedBox.shrink();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (_hasText)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['stimulusTitle']!,
                    style: TextStyle(
                      fontSize: fontSize + 1,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'HindSiliguri',
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GuideMathText(
                    text: text!,
                    fontSize: fontSize,
                    color: onSurface,
                  ),
                ],
              ),
            ),
          ),
        if (_hasRef)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${s['passageSource']!}: $ref',
              style: TextStyle(
                fontSize: fontSize - 1,
                fontFamily: 'HindSiliguri',
                color: onVariant,
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
