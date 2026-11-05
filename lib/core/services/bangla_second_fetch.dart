// Bangla 2nd Paper fetch (class-10 book, DB class_id 10).
// Bank rows are chapterless (chapter_number NULL); scopes are
// chapterless + section, like Bangla 1st. Bulk first, paged
// fallback — null = unavailable, never partial. Nothing here
// writes, deploys, or invents rows.
import '../models/guide_bank_model.dart';
import 'app_config.dart';
import 'edge_post.dart';
import 'guide_bank_fetch.dart';

class BanglaSecondFetch {
  static const schoolClass = 10;
  static const subject = 'bangla';

  GuideFetchPost get _post => (Map<String, dynamic> body,
          {String? endpoint}) =>
      edgePost(body, endpoint: AppConfig.guideBankEndpoint);

  /// All rows of one Edge section (bank, nirmiti, assessment,
  /// model-test, board-*), chapterless scope.
  Future<List<GuideBankQuestion>?> fetchSectionRows(
      String section) async {
    if (AppConfig.guideBankEndpoint.isEmpty) return null;
    final base = <String, dynamic>{
      'classId': schoolClass,
      'subject': subject,
      'chapterless': true,
      'section': section,
    };
    final bulk =
        await fetchBulkRows(post: _post, baseBody: base, label: 'bangla2');
    final fetched = bulk ??
        await fetchAllListRows(post: _post, baseBody: base, label: 'bangla2');
    if (fetched == null) return null;
    return fetched.rows.map(GuideBankQuestion.fromServerJson).toList();
  }
}

final banglaSecondFetch = BanglaSecondFetch();
