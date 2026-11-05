// Math-aware text for the guide path (2026-11-01): plain
// guide text (Unicode powers, set symbols, inline fractions)
// is normalized to $...$ LaTeX segments, then rendered by the
// existing SolutionRichText (flutter_math_fork). Unparseable
// input stays raw text — the normalizer never drops content
// and never touches Bangla words. Selectability is traded for
// typeset math (RichText math spans cannot select).
import 'package:flutter/material.dart';

import '../../../core/services/math_normalizer.dart';
import 'solution_rich_text.dart';

class GuideMathText extends StatelessWidget {
  const GuideMathText({
    super.key,
    required this.text,
    required this.fontSize,
    this.color,
    this.fontWeight,
  });
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return SolutionRichText(
      text: normalizeMathText(text),
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
