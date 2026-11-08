// Route: /model-tests. Stats computed from saved model runs.
// Start buttons open the REAL exam for that test; the locked test's
// button is ENABLED but never opens an exam — tapping it shows a
// dialog naming the book that is needed (audit-fix C1). A short
// locked note also stays visible under the locked card.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/services/model_test_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/model_test_list_strings.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class ModelTestListScreen extends StatelessWidget {
  const ModelTestListScreen({super.key});
  // Audit-fix C1: the locked button must not silently do nothing.
  // It explains which book is needed; it never starts an exam.
  void _lockedInfo(BuildContext context, Map<String, String> s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s['lockedDialogTitle']!),
        content: Text(s['lockedDialogBody']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _start(BuildContext context, ModelTest t) {
    PracticeSession.modelTestId = t.id;
    PracticeSession.modelSubject = t.subject;
    PracticeSession.modelItems = t.items;
    PracticeSession.modelMinutes = t.minutes;
    PracticeSession.modelIsGuide = false;
    PracticeSession.clearModelExam();
    context.go('/model-test-exam');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? modelTestListStringsBn : modelTestListStringsEn;
      final tests = modelTestService.modelTests();
      return ThemedScaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/practice'),
          ),
          title: Text(s['title']!),
        ),
        body: FutureBuilder<ProgressSummary>(future: progressService.summary(), builder: (context, snap) {
          final sum = snap.data ?? ProgressSummary.empty;
          final models = sum.attempts.where((a) => a.kind == 'model').toList();
          final avg = models.isEmpty ? 0 : models.map((a) => a.percent).reduce((a, b) => a + b) ~/ models.length;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(s['subtitle']!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PracticeCard(title: '${s['total']!}: ${tests.length}')),
              const SizedBox(width: 8),
              Expanded(child: PracticeCard(title: '${s['done']!}: ${models.length}')),
              const SizedBox(width: 8),
              Expanded(child: PracticeCard(title: '${s['avg']!}: $avg%')),
            ]),
            const SizedBox(height: 12),
            for (int i = 0; i < tests.length; i++) ...[
              PracticeCard(title: i == 0 ? s['test1']! : (i == 1 ? s['test2']! : s['test3']!),
                  subtitle: i == 0 ? s['test1Sub']! : (i == 1 ? s['test2Sub']! : s['test3Sub']!),
                  icon: tests[i].locked ? Icons.lock : Icons.assignment,
                  trailing: tests[i].locked
                      ? TextButton(onPressed: () => _lockedInfo(context, s), child: Text(s['locked']!))
                      : ElevatedButton(onPressed: () => _start(context, tests[i]), child: Text(s['start']!))),
              if (tests[i].locked) Padding(padding: const EdgeInsets.only(top: 4, bottom: 4), child: Text(s['lockedNote']!, style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(height: 12),
            ],
            OutlinedButton(onPressed: () => context.go('/model-test-results'), child: Text(s['review']!)),
          ]);
        }),
      );
    });
  }
}
