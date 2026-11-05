// Fixed-count model tests (practice bank pools), split out of
// practice_service.dart to keep it under the 250-line cap.
// Bank pools only: guide model-test sets live in
// model_test_set_service.dart and the guide list screen.
import '../models/backend_models.dart';
import 'practice_service.dart';
import 'question_generation.dart';

class ModelTest {
  final String id, subject, chapter;
  final int minutes;
  final bool locked; // true = no supplied book, must not start
  final List<QuizItem> items;
  const ModelTest({required this.id, required this.subject, required this.chapter, required this.minutes, required this.locked, required this.items});
}

class ModelTestService {
  /// Model-test items: fixed count (maths 10, science 8), fixed seed.
  List<QuizItem> modelItemsFor(String subject) {
    final pool = subject == 'science'
        ? practiceService.modelScience()
        : practiceService.modelMath();
    final count = subject == 'science' ? 8 : 10;
    return questionGeneration.selectQuestions(
        pool: pool, count: count,
        seedKey: questionGeneration.modelSeedKey('mt-$subject'),
        chapterOf: (q) => practiceService.chapterOf(q.id, true));
  }

  List<ModelTest> modelTests() => [
    ModelTest(id: 'mt-math', subject: 'math', chapter: 'ch-math', minutes: 15, locked: false, items: modelItemsFor('math')),
    ModelTest(id: 'mt-science', subject: 'science', chapter: 'ch-science', minutes: 12, locked: false, items: modelItemsFor('science')),
    // English: no supplied Class 6 book yet, so locked, never opens.
    const ModelTest(id: 'mt-english', subject: 'english', chapter: 'ch-en', minutes: 10, locked: true, items: []),
  ];

  /// Model tests (practice bank): fixed count, fixed seed, bank pool.
  Future<GeneratedSet> generateModelTest({
    required String subject,
    required int schoolClass,
    required bool bangla,
  }) async {
    final book = await questionGeneration.fetchBookQuestions(
        subject: subject, schoolClass: schoolClass, bangla: bangla);
    return GeneratedSet(
        items: modelItemsFor(subject),
        source: QuestionSource.bankFallback,
        seedKey: questionGeneration.modelSeedKey('mt-$subject'),
        bookQuestionsIndexed: book?.length ?? 0);
  }
}

final modelTestService = ModelTestService();
