// Question counts per type for the global picker (guide mode).
// One tiny `list` call per type (limit 1, slim): the exact total
// comes from the server, nothing is estimated. A count is shown
// ONLY when the server echoed the lesson and section filters
// (a real server-side filter); an old server, an error or a
// pre-migration reply gives null = "unknown", never a guess, and
// is not cached so the next open retries. Counts that were read
// are kept in memory for the session.
import '../../features/learn/search_flow_types.dart';
import 'app_config.dart';
import 'edge_post.dart';
import 'guide_flow_models.dart';

class GuideFlowCountService {
  GuideFlowCountService({GuideFlowPost? post})
      : _post = post ?? edgePost,
        _customPost = post != null;
  final GuideFlowPost _post;
  final bool _customPost;
  final _cache = <String, int>{};
  final _inFlight = <String, Future<int?>>{};

  static String keyOf(String subject, int schoolClass, int chapter,
          SearchFlowType type, String? lesson) =>
      '$schoolClass|$subject|$chapter|${type.name}|${lesson ?? ''}';

  /// Exact question count, or null when it cannot be known.
  Future<int?> count({
    required String subject,
    required int schoolClass,
    required int chapter,
    required SearchFlowType type,
    String? lesson,
  }) {
    final key = keyOf(subject, schoolClass, chapter, type, lesson);
    final hit = _cache[key];
    if (hit != null) return Future.value(hit);
    // Block body on purpose: remove() returns this very future,
    // and whenComplete would wait on it forever.
    return _inFlight[key] ??= _fetch(
      key, subject, schoolClass, chapter, type, lesson,
    ).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  /// Counts for every type of one chapter (+ lesson), in parallel.
  Future<Map<SearchFlowType, int?>> countAll({
    required String subject,
    required int schoolClass,
    required int chapter,
    String? lesson,
  }) async {
    final types = SearchFlowType.values;
    final out = await Future.wait([
      for (final t in types)
        count(
          subject: subject,
          schoolClass: schoolClass,
          chapter: chapter,
          type: t,
          lesson: lesson,
        ),
    ]);
    return {for (var i = 0; i < types.length; i++) types[i]: out[i]};
  }

  Future<int?> _fetch(String key, String subject, int schoolClass,
      int chapter, SearchFlowType type, String? lesson) async {
    if (!_customPost && AppConfig.guideBankEndpoint.isEmpty) return null;
    try {
      final res = await _post({
        'action': 'list',
        'classId': schoolClass,
        'subject': subject,
        'chapter': chapter,
        'lesson': lesson,
        'section': searchFlowGuideSection(type),
        'offset': 0,
        'limit': 1,
        'slim': true,
      }, endpoint: AppConfig.guideBankEndpoint);
      if (res == null || res['found'] != true) return null;
      if (!res.containsKey('lesson') || !res.containsKey('section')) {
        return null; // old server ignored the filter: total not trusted
      }
      final total = (res['total'] as num?)?.toInt();
      if (total == null || total < 0) return null;
      _cache[key] = total;
      return total;
    } catch (_) {
      return null;
    }
  }
}

final guideFlowCountService = GuideFlowCountService();
