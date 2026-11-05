// One quiz card: printed question + its guide answer below.
// Quiz rows print no options, so this is never a tap-option
// MCQ. The answer arrives per card (see the screen's loader):
// loading spinner, verbatim answer, or an honest missing note
// with retry. The card never hides the question, whatever the
// loader returns. Tests inject a fake loader with this shape.
import 'package:flutter/material.dart';

import '../../core/models/guide_bank_model.dart';

/// One quiz row's loaded answer. Null text = no verbatim
/// answer came back (missing print, or a failed load) — the
/// card shows the missing note + retry, never a made-up text.
class QuizAnswer {
  const QuizAnswer({required this.text});
  final String? text;
}

/// Loads one quiz row's answer. Tests inject a fake; the
/// screen's default uses Mode G verbatim (no AI section here).
typedef QuizAnswerLoader = Future<QuizAnswer> Function(
  GuideBankQuestion q,
  bool bn,
);

class BanglaFirstQuizCard extends StatefulWidget {
  const BanglaFirstQuizCard({
    super.key,
    required this.q,
    required this.loader,
    required this.bn,
    required this.s,
  });
  final GuideBankQuestion q;
  final QuizAnswerLoader loader;
  final bool bn;
  final Map<String, String> s;

  @override
  State<BanglaFirstQuizCard> createState() => _BanglaFirstQuizCardState();
}

class _BanglaFirstQuizCardState extends State<BanglaFirstQuizCard> {
  late Future<QuizAnswer> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader(widget.q, widget.bn);
  }

  void _retry() => setState(() {
        _future = widget.loader(widget.q, widget.bn);
      });

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(fontFamily: 'HindSiliguri');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.q.questionText, style: body),
            const SizedBox(height: 8),
            FutureBuilder<QuizAnswer>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final text = snap.hasError ? null : snap.data?.text;
                if (text == null || text.isEmpty) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(widget.s['quizNoAnswer']!,
                            style: body),
                      ),
                      TextButton(
                        onPressed: _retry,
                        child: Text(widget.s['retry']!),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.s['quizAnswer']!,
                        style: body.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(text, style: body),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
