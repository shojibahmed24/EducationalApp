// Whole-guide server search for the guide bank. The chapter
// list search is local (chapter rows only); this service asks
// the guide-bank Edge Function's `search` action so a query can
// find questions in chapters the user has not opened. Null =
// unreachable / failed / no server (never demo data, never a
// silent empty list from the caller: a failed search must fall
// back to local filtering in the UI).
import '../models/guide_bank_model.dart';
import 'app_config.dart';
import 'edge_post.dart';

/// A post function matching edgePost, injectable in tests so a
/// test can count calls (a blank query must make NO call).
typedef GuideSearchPost = Future<Map<String, dynamic>?> Function(
  Map<String, dynamic> body, {
  String? endpoint,
});

/// The search request, or null when the query is blank. Null
/// means "do not call the server at all" — a blank query must
/// never fetch (and never return) the whole guide.
Map<String, dynamic>? buildGuideSearchRequest({
  required String subject,
  required int schoolClass,
  required String query,
  int limit = 50,
}) {
  final q = query.trim();
  if (q.isEmpty) return null;
  final clamped = limit < 1 ? 1 : (limit > 50 ? 50 : limit);
  return {
    'action': 'search',
    'classId': schoolClass,
    'subject': subject,
    'query': q,
    'limit': clamped,
  };
}

/// Maps a search response to rows, or null on any failure shape:
/// null response, found != true, or a non-list questions field.
/// A row maps through fromServerJson, so a key or solution sent
/// by mistake could never become a key index or key text here —
/// list payloads carry a hasKey boolean only.
List<GuideBankQuestion>? parseGuideSearchResponse(
    Map<String, dynamic>? res) {
  if (res == null || res['found'] != true) return null;
  final rows = res['questions'];
  if (rows is! List) return null;
  return rows
      .whereType<Map>()
      .map((r) => GuideBankQuestion.fromServerJson(
          r.map((k, v) => MapEntry(k.toString(), v))))
      .toList();
}

/// Server search across the whole guide for one subject+class.
/// Null on: no endpoint configured, blank query (no call is
/// made), any network failure, or any failure-shaped response.
/// [endpoint] defaults to the configured guide-bank endpoint;
/// tests pass a dummy value so the mapping is testable without
/// a live backend (the real app always uses the default).
Future<List<GuideBankQuestion>?> searchGuide({
  required String subject,
  required int schoolClass,
  required String query,
  int limit = 50,
  String? endpoint,
  GuideSearchPost post = edgePost,
}) async {
  final url = endpoint ?? AppConfig.guideBankEndpoint;
  if (url.isEmpty) return null;
  final req = buildGuideSearchRequest(
      subject: subject, schoolClass: schoolClass, query: query, limit: limit);
  if (req == null) return null;
  final res = await post(req, endpoint: url);
  return parseGuideSearchResponse(res);
}
