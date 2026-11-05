// Book lookup (Mode C client). The app NEVER reads book_questions
// directly (no client policy, by design): this service POSTs to the
// Edge Function, which reads with the service role and returns only
// public fields. No question bank lives here — an empty index comes
// back as 'not-indexed' and the UI says so honestly. The AI
// explanation itself still goes through explanation_service.explain
// (OpenRouter when configured, labelled DEMO otherwise).
// POSTs go through the shared edgePost (30s timeout, client
// closed on all paths) — no private copy here.
import '../models/backend_models.dart';
import 'edge_post.dart';
import 'explanation_service.dart';

/// One verbatim question on a printed page, as returned by Mode C.
/// problem is null for unnumbered items (worked examples); the UI
/// shows no number for those instead of inventing one.
class PageQuestion {
  final String bookId;
  final String bookTitle;
  final int chapterNumber;
  final String chapterTitle;
  final int page;
  final int? problem;
  final String questionText;
  const PageQuestion({
    required this.bookId,
    required this.bookTitle,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.page,
    required this.problem,
    required this.questionText,
  });

  /// Grounding for explanation_service.explain: the row is already
  /// book-verified by the Edge Function, so no Mode A re-resolve
  /// is needed (and an unnumbered item has no Mode A path at all).
  Grounding toGrounding(String subject, int schoolClass) {
    return Grounding(
      context: GroundedContext(
        bookTitle: bookTitle,
        chapterTitle: chapterTitle,
        subject: subject,
        schoolClass: schoolClass,
        chapterNumber: chapterNumber,
        page: page,
        problem: problem ?? 0,
        questionText: questionText,
        source: 'edge',
      ),
      reason: 'found',
    );
  }
}

class PageLookup {
  final List<PageQuestion> questions;
  final String reason; // 'found' | 'not-indexed' | 'no-book' | 'edge-missing'
  const PageLookup({required this.questions, required this.reason});
  bool get found => reason == 'found';
}

class BookLookupService {
  /// Mode C: all indexed questions on [page] of [bookId].
  /// Unreachable / undeployed function => 'edge-missing', never a
  /// fabricated list.
  Future<PageLookup> listByPage({
    required String bookId,
    required int page,
  }) async {
    final res = await edgePost({
      'listByPage': true,
      'bookId': bookId,
      'page': page,
    });
    if (res == null) {
      return const PageLookup(questions: [], reason: 'edge-missing');
    }
    if (res['found'] != true) {
      final reason = res['reason'];
      return PageLookup(
        questions: const [],
        reason: reason is String ? reason : 'not-indexed',
      );
    }
    final raw = res['questions'];
    final title = '${res['bookTitle'] ?? ''}';
    final list = <PageQuestion>[];
    if (raw is List) {
      for (final r in raw.whereType<Map<String, dynamic>>()) {
        final text = r['questionText'];
        if (text is! String || text.isEmpty) continue;
        list.add(PageQuestion(
          bookId: '${res['bookId'] ?? ''}',
          bookTitle: title,
          chapterNumber: (r['chapterNumber'] as num?)?.toInt() ?? 0,
          chapterTitle: '${r['chapterTitle'] ?? ''}',
          page: (r['page'] as num?)?.toInt() ?? page,
          problem: (r['problem'] as num?)?.toInt(),
          questionText: text,
        ));
      }
    }
    if (list.isEmpty) {
      return const PageLookup(questions: [], reason: 'not-indexed');
    }
    return PageLookup(questions: list, reason: 'found');
  }

}

final bookLookupService = BookLookupService();
