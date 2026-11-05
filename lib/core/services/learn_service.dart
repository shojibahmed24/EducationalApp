// Book-grounding gate. A question is answered ONLY if it is in the
// book index. Otherwise LessonResult.noMatch - the UI must show
// the no-match screen and ask for the exact question or a photo.
// This service NEVER guesses, substitutes, or invents an answer.
//
// Two modes:
//   DEMO (no Supabase client): the sync resolve() below answers the
//     2 locally indexed questions (Maths ch.3 p.45 q.7/q.5, old mock
//     chapter numbering) and noMatch for everything else.
//   CONFIGURED: resolveAsync() checks the REAL chapters table via
//     BooksService. A chapter that does not exist in the book is
//     noMatch. A chapter that DOES exist is still noMatch for a
//     specific question: migration 002 gives book_questions NO
//     client read policy on purpose (server / Edge Function only),
//     so the app cannot verify a page/problem from the client, and
//     returning a DEMO answer against real chapter numbers would be
//     wrong (real Maths ch.3 is Integers, not the mock's chapter).
//     Question-level grounding is therefore a C2 Edge Function job;
//     C1 honestly narrows the gate to real DB chapters and never
//     claims a question is found when it cannot be verified.
import '../models/backend_models.dart';
import 'books_service.dart';
import 'supabase_client.dart';

class LearnService {
  // DEMO-only local index. Never used when a Supabase client exists.
  static const _index = {
    'math|3|45|7': 'ratio',
    'math|3|45|5': 'area',
  };

  /// First indexed question on this subject+page, if any. DEMO only:
  /// callers must use keyForPageAsync / resolveAsync when configured.
  LessonResult? resolveForPage(String subject, int page) {
    for (final entry in _index.entries) {
      final parts = entry.key.split('|');
      if (parts[0] == subject && int.tryParse(parts[2]) == page) {
        return resolve(
          subject: subject,
          chapter: int.parse(parts[1]),
          page: page,
          problem: int.parse(parts[3]),
        );
      }
    }
    return null;
  }

  /// Index key for the first indexed question on this page, or
  /// null. DEMO only; see resolveForPage.
  String? keyForPage(String subject, int page) {
    for (final entry in _index.entries) {
      final parts = entry.key.split('|');
      if (parts[0] == subject && int.tryParse(parts[2]) == page) {
        return entry.key;
      }
    }
    return null;
  }

  /// DEMO-only sync resolution (2 indexed questions).
  LessonResult resolve({
    required String subject,
    required int chapter,
    required int page,
    required int problem,
  }) {
    final key = '$subject|$chapter|$page|$problem';
    if (!_index.containsKey(key)) return LessonResult.noMatch;
    if (_index[key] == 'ratio') {
      return const LessonResult(
        question: 'Ratio problem, page 45, question 7',
        answerBn: 'অনুপাত মানে দুটি সংখ্যার তুলনা। ধাপে ধাপে: '
            'প্রথমে মোট ভাগ বের করো, তারপর প্রতিটি ভাগের মান বের করো।',
        answerEn: 'A ratio compares two numbers. Step by step: '
            'first find the total parts, then the value of each part.',
        found: true,
      );
    }
    return const LessonResult(
      question: 'Area problem, page 45, question 5',
      answerBn: 'ক্ষেত্রফল = দৈর্ঘ্য × প্রস্থ। ধাপে ধাপে মান বসিয়ে হিসাব করো।',
      answerEn: 'Area = length x width. Substitute the values step by step.',
      found: true,
    );
  }

  /// Supabase-aware resolution. DEMO (no client): the sync index.
  /// Configured: the chapter must exist in the chapters table for
  /// the subject's Class 6 book in the UI language; otherwise
  /// noMatch. Even when the chapter exists, the specific question
  /// is noMatch — the app cannot read book_questions (server-only
  /// by design), so it must not claim the question is verified.
  Future<LessonResult> resolveAsync({
    required String subject,
    required int chapter,
    required int page,
    required int problem,
    required bool bangla,
  }) async {
    if (supabaseOrNull == null) {
      return resolve(
        subject: subject,
        chapter: chapter,
        page: page,
        problem: problem,
      );
    }
    final chapters =
        await booksService.chaptersForSubjectAsync(6, subject, bangla);
    if (chapters == null) return LessonResult.noMatch;
    if (!chapters.any((c) => c.number == chapter)) {
      return LessonResult.noMatch;
    }
    // Chapter is real, question is unverifiable from the client.
    return LessonResult.noMatch;
  }
}

final learnService = LearnService();
