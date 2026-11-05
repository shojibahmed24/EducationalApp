// Lesson Quiz screen: every quiz row of one lesson as a flat
// question + answer list. Quiz rows print no options, so cards
// are never tap-option MCQs — each card loads its guide answer
// below the question via Mode G verbatim (list rows never carry
// answer text, so there is no bulk path). Model MCQ never
// appears here; it lives on the section Model test entry. A null
// fetch shows the retry state, an empty list the honest empty
// note; rows are never hidden, whatever the server sends.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_first_fetch.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_first_strings.dart';
import 'bangla_first_quiz_card.dart';
import 'bangla_first_retry_state.dart';
import 'widgets/guide_creative_part_loader.dart';

/// Mode G verbatim only (no AI explanation section on quiz
/// cards): a printable answer becomes text, anything else null.
Future<QuizAnswer> defaultQuizAnswerLoader(
  GuideBankQuestion q,
  bool bn,
) async {
  final load = await defaultCreativePartLoader(
    part: q,
    subjectId: 'bangla',
    schoolClass: BanglaFirstFetch.schoolClass,
    bn: bn,
    onStage1: (_) {},
  );
  return QuizAnswer(text: load.hasVerbatim ? load.verbatimText : null);
}

class BanglaFirstQuizScreen extends StatefulWidget {
  const BanglaFirstQuizScreen({
    super.key,
    required this.section,
    required this.lessonTitle,
  });
  final String section;
  final String lessonTitle;

  @override
  State<BanglaFirstQuizScreen> createState() => _BanglaFirstQuizScreenState();
}

class _BanglaFirstQuizScreenState extends State<BanglaFirstQuizScreen> {
  late Future<List<GuideBankQuestion>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<GuideBankQuestion>?> _load() =>
      banglaFirstFetch.fetchLessonRows(
          lesson: widget.lessonTitle, section: 'quiz');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(
                  '/bangla-first-lesson?section=${widget.section}&lesson=${Uri.encodeComponent(widget.lessonTitle)}'),
            ),
            title: Text(s['lessonQuiz']!),
          ),
          body: FutureBuilder<List<GuideBankQuestion>?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(child: Text(s['loading']!));
              }
              final rows = snap.data;
              if (rows == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              if (rows.isEmpty) {
                return Center(child: Text(s['quizEmpty']!));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, i) => BanglaFirstQuizCard(
                  q: rows[i],
                  loader: defaultQuizAnswerLoader,
                  bn: bn,
                  s: s,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
