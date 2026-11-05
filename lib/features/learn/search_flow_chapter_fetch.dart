// Chapter tuples for the search flow, factored out of
// SearchFlowController so the controller stays under the
// 250-line cap and the prefetch path can share the exact
// same fetch (same dedupe key, same fallback). Null = the
// source is unreachable, never "no chapters": the caller
// decides the fallback (cached chapters, or the verified
// title list for textbook / empty for guide).
import '../../core/services/books_service.dart';
import '../../core/services/guide_bank_service.dart';
import 'search_flow_types.dart';

Future<List<(int, String)>?> fetchSearchFlowChapterTuples({
  required String source,
  required String subject,
  required int schoolClass,
  required bool bangla,
}) async {
  if (source == 'guide') {
    final map = await guideBankService
        .fetchGuideChapters(subject, schoolClass: schoolClass)
        .catchError((_) => null);
    if (map == null) return null;
    final numbers = (map.keys.toList())..sort();
    return [
      for (final n in numbers)
        (n, verifiedChapterTitle(subject, schoolClass, n) ?? ''),
    ];
  }
  final db = await booksService
      .chaptersForSubjectAsync(schoolClass, subject, bangla)
      .catchError((_) => null);
  if (db == null) return null;
  if (db.isNotEmpty) {
    return [
      for (final c in db) (c.number, c.title(bangla)),
    ];
  }
  return searchFlowChapterFallback(subject, schoolClass);
}

/// What the picker showed before any cache existed: the
/// verified title list for textbook (never invented titles),
/// empty for guide (the Edge list is the only truth there).
List<(int, String)> searchFlowChapterFallback(
    String subject, int schoolClass) {
  return [
    for (var n = 1; n <= 17; n++)
      if (verifiedChapterTitle(subject, schoolClass, n) != null)
        (n, verifiedChapterTitle(subject, schoolClass, n)!),
  ];
}
