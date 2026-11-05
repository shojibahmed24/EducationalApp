// MCQ try-first options card (2026-11-01): the answer screen
// used to show only the question + key, never the options, so
// a student could not attempt the question first. This card
// shows the ক/খ/গ/ঘ options (math-rendered); the first tap
// locks the pick, colours correct/wrong, and tells the parent
// (onAttempted) to reveal the key + explanation below. The
// parent keys this widget by question id, so a new question
// always starts unpicked. Quiz behaviour is untouched.
import 'package:flutter/material.dart';

import 'guide_math_text.dart';

/// Printed option letters, in server order (optionsToArray:
/// ক,খ,গ,ঘ,ঙ). Bangla letters always — they are the printed
/// labels, whatever the UI language is.
const mcqOptionLetters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];

class GuideMcqOptionsCard extends StatefulWidget {
  const GuideMcqOptionsCard({
    super.key,
    required this.options,
    required this.correctOptionIndex,
    required this.fontSize,
    required this.s,
    required this.onAttempted,
  });
  final List<String> options;

  /// Null = display-only (unkeyed MCQ): options show, no pick,
  /// no feedback. Non-null = try-first interactive mode.
  final int? correctOptionIndex;
  final double fontSize;

  /// Guide-bank strings (title / hint / feedback lines).
  final Map<String, String> s;
  final VoidCallback onAttempted;

  @override
  State<GuideMcqOptionsCard> createState() => _GuideMcqOptionsCardState();
}

class _GuideMcqOptionsCardState extends State<GuideMcqOptionsCard> {
  int? _selected;

  bool get _interactive => widget.correctOptionIndex != null;

  Color _rowColor(int i, ColorScheme scheme, bool dark) {
    if (!_interactive || _selected == null) {
      return scheme.surfaceContainerHighest;
    }
    if (i == widget.correctOptionIndex) {
      return dark ? Colors.green.shade900 : Colors.green.shade100;
    }
    if (i == _selected) return scheme.errorContainer;
    return scheme.surfaceContainerHighest;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = scheme.onSurface;
    final picked = _interactive && _selected != null;
    final correct = picked && _selected == widget.correctOptionIndex;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.s['optionsTitle']!,
              style: TextStyle(
                fontSize: widget.fontSize + 1,
                fontWeight: FontWeight.w600,
                fontFamily: 'HindSiliguri',
                color: onSurface,
              ),
            ),
            if (_interactive) ...[
              const SizedBox(height: 4),
              Text(
                picked
                    ? (correct
                        ? widget.s['optionsCorrect']!
                        : widget.s['optionsWrong']!)
                    : widget.s['optionsTryHint']!,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontFamily: 'HindSiliguri',
                  height: 1.7,
                  color: onSurface,
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (var i = 0; i < widget.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: !_interactive || _selected != null
                      ? null
                      : () {
                          setState(() => _selected = i);
                          widget.onAttempted();
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _rowColor(i, scheme, dark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            i < mcqOptionLetters.length
                                ? mcqOptionLetters[i]
                                : '${i + 1}',
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'HindSiliguri',
                              color: onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: GuideMathText(
                            text: widget.options[i],
                            fontSize: widget.fontSize,
                            color: onSurface,
                          ),
                        ),
                        if (picked && i == widget.correctOptionIndex)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                        if (picked &&
                            i == _selected &&
                            i != widget.correctOptionIndex)
                          const Icon(Icons.cancel,
                              color: Colors.red, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
