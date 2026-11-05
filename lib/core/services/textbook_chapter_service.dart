// Textbook chapter lists + by-id resolution, client side of the
// shared Edge contract (Worker B implements the server side):
//   listByChapter {listByChapter: true, subject, classId, chapter,
//     language} -> {found: true, bookId, bookTitle, language,
//     chapterNumber, chapterTitle,
//     questions: [{id, questionText, page, problem, questionType}]}
//     ordered by page, then problem nulls last. NO chunks /
//     solutions / keys / answers ever arrive in this payload, and
//     this model parses nothing else (extra fields are ignored).
//   by-question-id {questionId, language} -> Mode-A-shaped
//     {found: true, bookTitle, chapterTitle, chapterNumber, page,
//     problem, questionText, chunks: [{text, pageStart, pageEnd}]}
//     (max 3 page-overlapping chunks, no neighbours).
// fetchChapter returns null when the Edge is unreachable /
// non-200 / not-found (unavailable), and a list — possibly EMPTY
// — when the chapter was found. Null vs empty is the honest
// distinction: never invent questions for an unavailable chapter.
// [post] is injectable so tests can fake the Edge, never live-call.
import '../models/backend_models.dart';
import 'app_config.dart';
import 'edge_post.dart';
import 'explanation_service.dart';

/// One row of a textbook chapter list. problem / questionType are
/// null when the Edge has no recorded value — the UI must never
/// invent a number or a type for such a row.
class TextbookChapterQuestion {
  final String id;
  final String questionText;
  final int page;
  final int? problem;
  final String? questionType;
  const TextbookChapterQuestion({
    required this.id,
    required this.questionText,
    required this.page,
    this.problem,
    this.questionType,
  });

  /// Parses ONLY the contract fields. Answer / chunk / solution /
  /// key fields in the payload (if any) are deliberately ignored.
  factory TextbookChapterQuestion.fromJson(Map<String, dynamic> json) {
    final problemRaw = json['problem'];
    final typeRaw = json['questionType'];
    return TextbookChapterQuestion(
      id: '${json['id'] ?? ''}',
      questionText: '${json['questionText'] ?? ''}',
      page: parsePageValue(json['page']),
      problem: problemRaw is num
          ? problemRaw.toInt()
          : int.tryParse('$problemRaw'),
      questionType: typeRaw is String && typeRaw.isNotEmpty ? typeRaw : null,
    );
  }
}

int parsePageValue(dynamic raw) =>
    raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;

/// Contract order: page ascending, then problem ascending with
/// unnumbered (null) problems last. Returns a new sorted list.
List<TextbookChapterQuestion> sortChapterQuestions(
  List<TextbookChapterQuestion> rows,
) {
  final out = List<TextbookChapterQuestion>.of(rows);
  out.sort((a, b) {
    if (a.page != b.page) return a.page.compareTo(b.page);
    if (a.problem == null && b.problem == null) return 0;
    if (a.problem == null) return 1;
    if (b.problem == null) return -1;
    return a.problem!.compareTo(b.problem!);
  });
  return out;
}

class TextbookChapterService {
  TextbookChapterService(
      {Future<Map<String, dynamic>?> Function(Map<String, dynamic>)? post})
      : _post = post ?? edgePost,
        _customPost = post != null;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic>) _post;

  /// True only when a test fake was injected. The real edgePost
  /// already returns null for an empty endpoint, so the endpoint
  /// check below is skipped for fakes (otherwise no unit test
  /// could ever reach the fake) and kept for the real path.
  final bool _customPost;

  /// Null = unavailable (no endpoint / unreachable / not found).
  /// Empty list = chapter found, but it holds no questions.
  Future<List<TextbookChapterQuestion>?> fetchChapter(
    String subject,
    int schoolClass,
    int chapter,
    bool bangla,
  ) async {
    if (!_customPost && AppConfig.explainEndpoint.isEmpty) return null;
    final res = await _post({
      'listByChapter': true,
      'subject': subject,
      'classId': schoolClass,
      'chapter': chapter,
      'language': bangla ? 'bn' : 'en',
    });
    if (res == null || res['found'] != true) return null;
    final rows = ((res['questions'] as List?) ?? [])
        .whereType<Map>()
        .map((m) => TextbookChapterQuestion.fromJson(
            Map<String, dynamic>.from(m)))
        .toList();
    return sortChapterQuestions(rows);
  }

  /// By-id resolve, returning a Mode-A Grounding built the same way
  /// explanation_service._contextFrom does (max 3 chunks). Not
  /// found / unreachable -> Grounding.notIndexed, never a guess.
  /// [subject] / [schoolClass] are not in the by-id payload; the
  /// caller (lesson screen) passes its own selection values.
  Future<Grounding> resolveById(
    String questionId,
    bool bangla, {
    String subject = '',
    int schoolClass = 6,
  }) async {
    if (!_customPost && AppConfig.explainEndpoint.isEmpty) {
      return const Grounding(reason: 'edge-missing');
    }
    final res = await _post({
      'questionId': questionId,
      'language': bangla ? 'bn' : 'en',
    });
    if (res == null || res['found'] != true) return Grounding.notIndexed;
    final questionText = res['questionText'];
    if (questionText is! String || questionText.isEmpty) {
      return Grounding.notIndexed;
    }
    final chunks = ((res['chunks'] as List?) ?? [])
        .whereType<Map>()
        .where((c) => c['text'] is String && (c['text'] as String).isNotEmpty)
        .take(3)
        .toList();
    final chunkTexts = chunks.map((c) => c['text'] as String).toList();
    final chunkRanges = chunks.map((c) {
      final s = c['pageStart'], e = c['pageEnd'];
      return s is num && e is num ? '${s.toInt()}–${e.toInt()}' : '';
    }).toList();
    return Grounding(
      context: GroundedContext(
        bookTitle: '${res['bookTitle'] ?? ''}',
        chapterTitle: '${res['chapterTitle'] ?? ''}',
        subject: subject,
        schoolClass: schoolClass,
        chapterNumber: (res['chapterNumber'] as num?)?.toInt() ?? 0,
        page: (res['page'] as num?)?.toInt() ?? 0,
        problem: (res['problem'] as num?)?.toInt() ?? 0,
        questionText: questionText,
        source: 'edge',
        chunkTexts: chunkTexts,
        chunkPageRanges: chunkRanges,
      ),
      reason: 'found',
    );
  }
}

final textbookChapterService = TextbookChapterService();
