// Bangla 1st Paper fetch (shared class 9-10 book, DB class_id 9).
// Bank rows are chapterless (chapter_number NULL); the list scope
// is chapterless + lesson + section. Bulk first, paged fallback —
// same failure semantics as guide_bank_fetch: null = unavailable,
// never partial. Nothing here writes, deploys, or invents rows.
import '../models/guide_bank_model.dart';
import 'app_config.dart';
import 'edge_post.dart';
import 'guide_bank_fetch.dart';
import 'model_test_set_service.dart';
import '../../core/data/bangla_first_lessons.dart';

class BanglaFirstFetch {
  static const schoolClass = 9;
  static const subject = 'bangla';

  GuideFetchPost get _post => (Map<String, dynamic> body,
          {String? endpoint}) =>
      edgePost(body, endpoint: AppConfig.guideBankEndpoint);

  /// All bank rows of one lesson + section ('mcq' | 'creative').
  /// Empty lesson => null without a network call (caller shows
  /// the unavailable state, never a guessed list).
  Future<List<GuideBankQuestion>?> fetchLessonRows({
    required String lesson,
    required String section,
  }) async {
    if (AppConfig.guideBankEndpoint.isEmpty || lesson.isEmpty) {
      return null;
    }
    final base = <String, dynamic>{
      'classId': schoolClass,
      'subject': subject,
      'chapterless': true,
      'lesson': lesson,
      'section': section,
    };
    final bulk =
        await fetchBulkRows(post: _post, baseBody: base, label: 'bangla');
    final fetched = bulk ??
        await fetchAllListRows(post: _post, baseBody: base, label: 'bangla');
    if (fetched == null) return null;
    return fetched.rows.map(GuideBankQuestion.fromServerJson).toList();
  }

  /// Server lesson values (guideLessons action) for the fallback
  /// section: titles the map does not know. Null = unreachable.
  Future<Map<String, int>?> fetchServerLessons() async {
    if (AppConfig.guideBankEndpoint.isEmpty) return null;
    final res = await edgePost({
      'action': 'guideLessons',
      'classId': schoolClass,
      'subject': subject,
    }, endpoint: AppConfig.guideBankEndpoint).catchError((_) => null);
    if (res == null || res['found'] != true) return null;
    final list = res['lessons'];
    if (list is! List) return null;
    final out = <String, int>{};
    for (final e in list.whereType<Map>()) {
      final lesson = e['lesson'];
      final total = e['totalCount'];
      if (lesson is String && lesson.isNotEmpty && total is num) {
        out[lesson] = total.toInt();
      }
    }
    return out;
  }

  /// Model-test sets of one section, by setId prefix
  /// (ban1-<section>-<slug>-<kind>). Null = unreachable; empty =
  /// the section genuinely has no sets (the novel has none).
  Future<List<GuideModelSetInfo>?> fetchSectionSets(String section) async {
    final sets = await modelTestSetService
        .fetchSetsFromServer(subject, schoolClass: schoolClass)
        .catchError((_) => null);
    if (sets == null) return null;
    final prefix = banglaFirstSetPrefix(section);
    return sets.where((s) => s.setId.startsWith(prefix)).toList();
  }
}

final banglaFirstFetch = BanglaFirstFetch();
