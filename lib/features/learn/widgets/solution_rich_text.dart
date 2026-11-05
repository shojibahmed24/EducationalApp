// Body text with inline LaTeX ($...$), **bold** and *italic*
// segments. Bangla runs in Hind Siliguri (OFL, registered in
// pubspec). Math segments render as real math; an unparseable
// segment falls back to its raw text instead of breaking the
// paragraph. Colour is theme-aware when not passed explicitly:
// null resolves at render time to colorScheme.onSurface, so a
// direct caller in dark mode never gets forced light ink (an
// earlier build defaulted to AppTheme.ink and rendered
// unreadably dark text on dark cards). Callers that pass an
// explicit colour (e.g. SolutionBlocks, which already resolved
// the theme colour) are unaffected.
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class SolutionRichText extends StatelessWidget {
  const SolutionRichText({
    super.key,
    required this.text,
    required this.fontSize,
    this.color,
    this.fontWeight,
  });
  final String text;
  final double fontSize;

  /// Null = resolve from the theme at render time (onSurface).
  final Color? color;

  /// Null = normal weight (callers that need emphasis, like the
  /// guide question card, pass w600 explicitly).
  final FontWeight? fontWeight;

  TextStyle _base(Color c) => TextStyle(
        fontSize: fontSize,
        fontFamily: 'HindSiliguri',
        fontWeight: fontWeight,
        height: 1.7,
        color: c,
      );

  // Matches are consumed by start/end offsets, never by
  // indexOf on the remaining string: repeated bold text used
  // to misplace every span after the first occurrence.
  List<InlineSpan> _inlineSpans(String chunk) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    var cursor = 0;
    for (final m in re.allMatches(chunk)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: chunk.substring(cursor, m.start)));
      }
      final bold = m.group(1);
      final italic = m.group(2);
      if (bold != null) {
        spans.add(TextSpan(
          text: bold,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
      } else if (italic != null) {
        spans.add(TextSpan(
          text: italic,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      cursor = m.end;
    }
    if (cursor < chunk.length) {
      spans.add(TextSpan(text: chunk.substring(cursor)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    final spans = <InlineSpan>[];
    final mathRe = RegExp(r'\$(.+?)\$');
    var cursor = 0;
    for (final m in mathRe.allMatches(text)) {
      if (m.start > cursor) {
        spans.addAll(_inlineSpans(text.substring(cursor, m.start)));
      }
      final latex = m.group(1)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          latex,
          textStyle: TextStyle(
              fontSize: fontSize, color: c, fontWeight: fontWeight),
          onErrorFallback: (_) => Text(latex, style: _base(c)),
        ),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.addAll(_inlineSpans(text.substring(cursor)));
    }
    return RichText(
      text: TextSpan(style: _base(c), children: spans),
    );
  }
}
