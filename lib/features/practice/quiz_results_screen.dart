// Route: /quiz-results. Shows the REAL numbers of the last quiz run
// (session first, else the last saved quiz attempt). Honest empty
// state when no quiz has ever finished. Retake restarts a fresh quiz.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/quiz_results_strings.dart';

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key});

  Future<(Attempt?, List<QuizItem>)> _load() async {
    final session = PracticeSession.lastAttempt;
    if (session != null && session.kind == 'quiz') {
      return (session, PracticeSession.lastItems);
    }
    final attempts = await PracticeStore.loadAttempts();
    final quiz = attempts.where((a) => a.kind == 'quiz').toList();
    if (quiz.isEmpty) return (null, <QuizItem>[]);
    final last = quiz.last;
    return (last, practiceService.quizFor(last.subject));
  }

  String _fmt(int sec) => '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? quizResultsStringsBn : quizResultsStringsEn;
      final bangla = locale.languageCode == 'bn';
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/practice'),
          ),
          title: Text(s['title']!),
        ),
        body: FutureBuilder<(Attempt?, List<QuizItem>)>(future: _load(), builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final attempt = snap.data!.$1;
          final items = snap.data!.$2;
          if (attempt == null) {
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(s['noResult']!, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8), Text(s['noResultSub']!),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/quiz'), child: Text(s['startQuiz']!)),
            ]);
          }
          final skipped = attempt.total - attempt.answers.length;
          final wrong = attempt.answers.length - attempt.correct;
          final wrongItems = items.where((q) {
            final a = attempt.answers[q.id];
            return a != null && !q.isCorrect(a);
          }).toList();
          final weakChapters = wrongItems.map((q) => practiceService.chapterOf(q.id, bangla)).toSet().toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            ScoreHeader(score: '${attempt.correct} / ${attempt.total}', total: '${attempt.percent}% • +${attempt.xp} XP', message: s['message']!),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PracticeCard(title: '${s['correct']!}: ${attempt.correct}', icon: Icons.check_circle)),
              const SizedBox(width: 8),
              Expanded(child: PracticeCard(title: '${s['wrong']!}: $wrong', icon: Icons.cancel)),
            ]),
            const SizedBox(height: 12),
            Text("${s['accuracy']!}: ${attempt.percent}% · ${s['skipped']!}: $skipped · ${s['time']!}: ${_fmt(attempt.seconds)}", style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(s['weak']!, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            if (weakChapters.isEmpty) Text(s['allCorrect']!)
            else for (final w in weakChapters) Padding(padding: const EdgeInsets.only(bottom: 8),
                child: PracticeCard(title: w, icon: Icons.lightbulb, onTap: () => context.go('/books/viewer'))),
            if (wrongItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(s['wrongListTitle']!, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              for (final q in wrongItems) Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: PracticeCard(title: bangla ? q.questionBn : q.questionEn,
                      subtitle: q.acceptedOptionTexts.join(' / '), icon: Icons.cancel)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {
              PracticeSession.quizItems = practiceService.quizFor(attempt.subject);
              PracticeSession.selectedSubject = attempt.subject;
              context.go('/quiz');
            }, child: Text(s['retry']!)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.go('/home'), child: Text(s['home']!)),
          ]);
        }),
      );
    });
  }
}
