// One LaTeX formula in a distinct box. Long formulas scroll
// horizontally — they are never cut off. A formula the math
// renderer cannot parse falls back to plain styled text (never
// a crash, never caret-text presented as rendered math).
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class SolutionFormulaBox extends StatelessWidget {
  const SolutionFormulaBox({
    super.key,
    required this.latex,
    required this.fontSize,
  });
  final String latex;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          latex,
          textStyle: TextStyle(fontSize: fontSize + 1),
          onErrorFallback: (err) => Text(
            latex,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: 'HindSiliguri',
              height: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}
