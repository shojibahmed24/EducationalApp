// Guide availability flags for subject lists, split out to keep
// books_service.dart under the 250-line cap. Used by
// BooksService.subjectsAsync: locked subjects (no supplied
// textbook) get hasGuide from the server, so Home and Search can
// source subjects from the guide as well as from textbooks.
// Fallback chain per locked subject (each step capped at 8s):
// guide chapters -> model-test sets -> chapter-less bank rows.
// A set-only subject (class-9 English: sets + bank rows, no
// chapters) is therefore visible with a set count, never a
// synthetic chapter entry. Null at any needed step means
// "unknown" (never a guessed true/false), and the result is
// incomplete: callers must NOT cache it as server truth.
import '../models/backend_models.dart';
import 'app_config.dart';
import 'edge_post.dart';
import 'guide_bank_service.dart';
import 'model_test_set_service.dart';

/// Null = unreachable (unknown, not empty).
typedef GuideChaptersFetch =
    Future<Map<int, int>?> Function(String subject, {int schoolClass});

/// Null = unreachable (unknown, not zero sets).
typedef GuideSetCountFetch =
    Future<int?> Function(String subject, {int schoolClass});

/// Null = unreachable (unknown, not "no bank rows").
typedef GuideBankPresenceFetch =
    Future<bool?> Function(String subject, {int schoolClass});

class GuideFlagsResult {
  const GuideFlagsResult({required this.subjects, required this.complete});
  final List<SubjectInfo> subjects;
  final bool complete;
}

/// One subject's resolved guide state. [known] is false when a
/// needed check failed, so hasGuide cannot be trusted for it.
class _ResolvedGuide {
  const _ResolvedGuide({
    required this.subject,
    this.chapters,
    this.setCount,
    this.bankPresent,
  });
  final SubjectInfo subject;
  final Map<int, int>? chapters;
  final int? setCount;
  final bool? bankPresent;

  bool get hasChapters => chapters != null && chapters!.isNotEmpty;
  bool get hasSets => setCount != null && setCount! > 0;
  bool get hasGuide => hasChapters || hasSets || bankPresent == true;
  bool get known =>
      hasChapters ||
      hasSets ||
      bankPresent == true ||
      (chapters != null && setCount != null && bankPresent != null);
}

/// Maps a chapterless bank list response to presence.
/// Null = unreachable or unknown. found:false with reason
/// no-book is definitively no rows (bank rows are book-scoped
/// server-side), so false — not null.
bool? chapterlessBankPresence(Map<String, dynamic>? res) {
  if (res == null) return null;
  if (res['found'] != true) {
    return res['reason'] == 'no-book' ? false : null;
  }
  final total = (res['total'] as num?)?.toInt();
  if (total != null) return total > 0;
  final rows = res['questions'];
  if (rows is List) return rows.isNotEmpty;
  return null;
}

Future<GuideFlagsResult> withGuideFlags(
  List<SubjectInfo> list,
  int schoolClass, {
  GuideChaptersFetch? fetchChapters,
  GuideSetCountFetch? fetchSetCount,
  GuideBankPresenceFetch? probeBank,
}) async {
  final locked = list.where((s) => s.locked).toList();
  if (locked.isEmpty) return GuideFlagsResult(subjects: list, complete: true);
  final chaptersOf =
      fetchChapters ??
      ((String s, {int schoolClass = 6}) =>
          guideBankService.fetchGuideChapters(s, schoolClass: schoolClass));
  final setsOf =
      fetchSetCount ??
      ((String s, {int schoolClass = 6}) async {
        final sets = await ModelTestSetService().fetchSetsFromServer(
          s,
          schoolClass: schoolClass,
        );
        return sets?.length;
      });
  final bankOf =
      probeBank ??
      ((String s, {int schoolClass = 6}) async {
        if (AppConfig.guideBankEndpoint.isEmpty) return null;
        final res = await edgePost({
          'action': 'list',
          'classId': schoolClass,
          'subject': s,
          'chapterless': true,
          'limit': 1,
          'offset': 0,
        }, endpoint: AppConfig.guideBankEndpoint);
        return chapterlessBankPresence(res);
      });
  // No onTimeout callback here on purpose: `onTimeout: () => null`
  // mis-resolves when T is inferred from a non-nullable closure
  // return (the timeout then yields null for a real value). A
  // plain timeout throws TimeoutException instead, which the
  // catch below maps to null — same 8s cap, no inference trap.
  Future<T?> _capped<T>(Future<T?> Function() f) async {
    try {
      return await f().timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  try {
    final resolved = await Future.wait(
      locked.map((s) async {
        final chapters = await _capped(
          () => chaptersOf(s.id, schoolClass: schoolClass),
        );
        int? setCount;
        bool? bankPresent;
        if (chapters == null || chapters.isEmpty) {
          setCount = await _capped(
            () => setsOf(s.id, schoolClass: schoolClass),
          );
        }
        if ((chapters == null || chapters.isEmpty) &&
            (setCount == null || setCount == 0)) {
          bankPresent = await _capped(
            () => bankOf(s.id, schoolClass: schoolClass),
          );
        }
        return _ResolvedGuide(
          subject: s,
          chapters: chapters,
          setCount: setCount,
          bankPresent: bankPresent,
        );
      }),
    );
    final complete = resolved.every((r) => r.known);
    final byId = {for (final r in resolved) r.subject.id: r};
    return GuideFlagsResult(
      subjects: list.map((s) {
        final r = byId[s.id];
        if (r == null || !r.hasGuide) return s;
        return SubjectInfo(
          id: s.id,
          nameBn: s.nameBn,
          nameEn: s.nameEn,
          locked: s.locked,
          chapterCount: s.chapterCount,
          hasGuide: true,
          guideChapterCount: r.chapters?.length ?? 0,
          guideSetCount: r.setCount ?? 0,
        );
      }).toList(),
      complete: complete,
    );
  } catch (_) {
    return GuideFlagsResult(subjects: list, complete: false);
  }
}
