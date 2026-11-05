// Q9 punctuation self-check (English Paper-II only): a written
// answer input + check button + diff-based score against the
// Mode G key passage shown above. This is a practice check, not
// quiz scoring: Q9 rows never enter the MCQ quiz (no options),
// and the key card above is untouched. The widget renders only
// when the parent passes a key with at least one mark.
import 'package:flutter/material.dart';

import '../../../core/services/punctuation_score.dart';

class GuidePunctuationCheck extends StatefulWidget {
  const GuidePunctuationCheck({
    super.key,
    required this.keyText,
    required this.maxMarks,
    required this.fontSize,
    required this.ls,
  });

  /// Mode G key passage (the fully-punctuated passage).
  final String keyText;
  final int maxMarks;
  final double fontSize;
  final Map<String, String> ls;

  @override
  State<GuidePunctuationCheck> createState() => _GuidePunctuationCheckState();
}

class _GuidePunctuationCheckState extends State<GuidePunctuationCheck> {
  final _controller = TextEditingController();
  PunctuationScore? _score;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatMarks(double marks) {
    if (marks == marks.truncateToDouble()) return marks.toInt().toString();
    return marks.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fontSize = widget.fontSize;
    final score = _score;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ls['punctuationCheckTitle']!,
              style: TextStyle(
                fontSize: fontSize + 1,
                fontWeight: FontWeight.w600,
                fontFamily: 'HindSiliguri',
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: widget.ls['punctuationCheckHint'],
                border: const OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: fontSize, color: onSurface),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() {
                _score = scorePunctuation(
                  _controller.text,
                  widget.keyText,
                  maxMarks: widget.maxMarks,
                );
              }),
              child: Text(widget.ls['punctuationCheckButton']!),
            ),
            if (score != null) ...[
              const SizedBox(height: 8),
              Text(
                '${widget.ls['punctuationScoreLabel']}: '
                '${_formatMarks(score.marks)} / ${score.maxMarks}',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              Text(
                '${widget.ls['punctuationCorrectLabel']}: '
                '${score.correct} / ${score.total}',
                style: TextStyle(fontSize: fontSize, color: onSurface),
              ),
              if (score.missed.isNotEmpty)
                Text(
                  '${widget.ls['punctuationMissedLabel']}: '
                  '${score.missed.join(' ')}',
                  style: TextStyle(fontSize: fontSize, color: onSurface),
                ),
              if (score.extra.isNotEmpty)
                Text(
                  '${widget.ls['punctuationExtraLabel']}: '
                  '${score.extra.join(' ')}',
                  style: TextStyle(fontSize: fontSize, color: onSurface),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
