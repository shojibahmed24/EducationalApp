// Question generation: selection + the book-question fetch path.
//
// Two halves, kept deliberately separate:
//
//  1. SELECTION (pure, tested): selectQuestions() takes ANY scorable
//     pool (QuizItem list) and returns a fixed-count set with chapter
//     coverage: it shuffles deterministically from a seed key, then
//     deals round-robin across chapters, so the first round covers
//     every chapter before any chapter repeats. Ids are deduped, so
//     a set never repeats a question. The seed key carries the day
//     (daily quiz) or the test id (model test): same key = same set,
//     a new day = a new set, and no day repeats within itself.
//  2. BOOK POOL (Edge Function Mode D): fetchBookQuestions() asks
//     the server — never the app — for the indexed book_questions
//     rows of one class + subject + language. The app must NEVER
//     query book_questions directly (migration 002: no client
//     policy, by design). Book rows carry question_text ONLY: no
//     options, no verified answer. They therefore CANNOT become
//     scored QuizItems, and this file never converts them into
//     ones — inventing options/answers would fake a score. Until
//     a verified-options source exists (see QUESTION_GENERATION.md),
//     the labelled practice bank was the only scorable pool.
//     Guide MCQs are now a second scorable pool (guide sets say
//     source == guide); the bank stays the fallback.
import 'dart:convert';
import 'dart:io';

import '../models/backend_models.dart';
import 'app_config.dart';
import 'supabase_client.dart';

/// One indexed book question, as returned by Edge Function Mode D.
/// Public fields only; source_link is never selected or returned.
class BookQuestion {
  final String id, bookId, bookTitle, chapterTitle, questionText;
  final int chapterNumber, page;
  final int? problem;
  const BookQuestion({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.chapterTitle,
    required this.questionText,
    required this.chapterNumber,
    required this.page,
    this.problem,
  });

  /// Grouping key for chapter-coverage selection.
  String get chapterKey => '$bookId-ch$chapterNumber';
}

/// Where a generated set's questions came from. `book` is only ever
/// used when the pool itself is book-verified AND scorable; today
/// that pool does not exist, so generation returns bankFallback.
enum QuestionSource { book, guide, bankFallback }

/// One generated set. `bookQuestionsIndexed` is the Mode D row count
/// (0 when the function is undeployed, unconfigured, or the index
/// is empty): informational only — it never changes the items,
/// because book rows are not scorable (see the header).
class GeneratedSet {
  final List<QuizItem> items;
  final QuestionSource source;
  final String seedKey;
  final int bookQuestionsIndexed;

  /// Phase 2 (plan §2 step 2): how many of the 20 guide
  /// questions are missing (0 = full set, or a bank set where
  /// the field is meaningless). The caller NEVER fills this
  /// silently from the bank — it shows the shortfall with an
  /// explicit bank button, and 20 here (empty guide set) means
  /// "ask the user" instead of starting anything.
  final int guideShortfall;
  const GeneratedSet({
    required this.items,
    required this.source,
    required this.seedKey,
    this.bookQuestionsIndexed = 0,
    this.guideShortfall = 0,
  });
}

class QuestionGenerationService {
  /// Daily seed: class + subject + local day, so one day has one
  /// set and the next day gets a new one.
  String dailySeedKey(int schoolClass, String subject, String day) =>
      'daily-$schoolClass-$subject-$day';

  /// Model-test seed: fixed per test, so the same test is the same
  /// questions on every run (fixed-count exam, not a daily draw).
  String modelSeedKey(String testId) => 'model-$testId';

  /// Deterministic selection with chapter coverage (see header).
  /// `chapterOf` supplies the grouping key: for the bank it is the
  /// coarse chapterOf() label (one per subject today); for a real
  /// book pool it is BookQuestion.chapterKey (one per chapter).
  List<QuizItem> selectQuestions({
    required List<QuizItem> pool,
    required int count,
    required String seedKey,
    required String Function(QuizItem) chapterOf,
  }) {
    if (pool.isEmpty || count <= 0) return [];
    final seen = <String>{};
    final unique = <QuizItem>[];
    for (final q in pool) {
      if (seen.add(q.id)) unique.add(q);
    }
    final byChapter = <String, List<QuizItem>>{};
    for (final q in unique) {
      (byChapter[chapterOf(q)] ??= []).add(q);
    }
    final chapters = byChapter.keys.toList()..sort();
    final base = _seed(seedKey);
    for (var i = 0; i < chapters.length; i++) {
      _shuffle(byChapter[chapters[i]]!, base + i * 97);
    }
    final out = <QuizItem>[];
    var round = 0;
    var progressed = true;
    while (out.length < count && progressed) {
      progressed = false;
      for (final c in chapters) {
        if (out.length >= count) break;
        final list = byChapter[c]!;
        if (round < list.length) {
          out.add(list[round]);
          progressed = true;
        }
      }
      round++;
    }
    return out;
  }

  /// Edge Function Mode D: all indexed questions of one class +
  /// subject + language, ordered by chapter/page/problem. Null =
  /// unconfigured, unreachable, undeployed, no supplied book, or
  /// no rows indexed yet — every one of those means "not available",
  /// never a fabricated list. The caller must NOT turn the result
  /// into QuizItems (no options/answers exist for these rows).
  Future<List<BookQuestion>?> fetchBookQuestions({
    required String subject,
    required int schoolClass,
    required bool bangla,
  }) async {
    if (supabaseOrNull == null || AppConfig.explainEndpoint.isEmpty) {
      return null;
    }
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      try {
        final req =
            await client.postUrl(Uri.parse(AppConfig.explainEndpoint));
        req.headers.set('Authorization', 'Bearer ${AppConfig.supabaseAnonKey}');
        req.headers.set('apikey', AppConfig.supabaseAnonKey);
        req.headers.set('Content-Type', 'application/json');
        req.add(utf8.encode(jsonEncode({
          'generateQuiz': true,
          'subject': subject,
          'classId': schoolClass,
          'language': bangla ? 'bn' : 'en',
        })));
        final res = await req.close();
        final text = await res.transform(utf8.decoder).join();
        if (res.statusCode != 200) return null;
        final data = jsonDecode(text);
        if (data is! Map<String, dynamic> || data['found'] != true) {
          return null;
        }
        final raw = data['questions'];
        if (raw is! List) return null;
        final bookId = '${data['bookId'] ?? ''}';
        final bookTitle = '${data['bookTitle'] ?? ''}';
        final list = <BookQuestion>[];
        for (final r in raw.whereType<Map<String, dynamic>>()) {
          final qText = r['questionText'];
          if (qText is! String || qText.isEmpty) continue;
          list.add(BookQuestion(
            id: '${r['bookId'] ?? bookId}-ch${r['chapterNumber'] ?? 0}'
                '-p${r['page'] ?? 0}-q${r['problem'] ?? ''}',
            bookId: bookId,
            bookTitle: bookTitle,
            chapterTitle: '${r['chapterTitle'] ?? ''}',
            questionText: qText,
            chapterNumber: (r['chapterNumber'] as num?)?.toInt() ?? 0,
            page: (r['page'] as num?)?.toInt() ?? 0,
            problem: (r['problem'] as num?)?.toInt(),
          ));
        }
        return list.isEmpty ? null : list;
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }

  /// djb2 string hash: stable across runs (Dart's hashCode is not).
  int _seed(String key) {
    var h = 5381;
    for (final c in key.codeUnits) {
      h = ((h << 5) + h + c) & 0x7fffffff;
    }
    return h;
  }

  /// Fisher-Yates with a small LCG, seeded — same seed, same order.
  void _shuffle(List<QuizItem> list, int seed) {
    var state = seed == 0 ? 1 : seed;
    for (var i = list.length - 1; i > 0; i--) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      final j = state % (i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}

final questionGeneration = QuestionGenerationService();
