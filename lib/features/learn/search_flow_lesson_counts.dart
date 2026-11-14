// Lazy per-lesson question counts for the lesson rows of the
// global picker (guide mode). Nothing loads until the user opens
// a chapter's lesson list; then each lesson (and "সব লেসন") asks
// the count service for its own types, so the rows can read
// "সৃজনশীল ১০২ · বহুনির্বাচনি ২৩৭" like a Guide contents page.
// Unknown or zero counts are left out of the line, never guessed.
import 'dart:ui' show VoidCallback;

import '../../core/services/guide_flow_count_service.dart';
import 'search_flow_types.dart';
import 'widgets/digits.dart';

class SearchFlowLessonCounts {
  SearchFlowLessonCounts({required this.onChanged, GuideFlowCountService? service})
      : _svc = service ?? guideFlowCountService;
  final VoidCallback onChanged;
  final GuideFlowCountService _svc;
  final _by = <String, Map<SearchFlowType, int?>>{};
  final _requested = <String>{};

  static String _key(int chapter, String? lesson) => '$chapter|${lesson ?? ''}';

  /// Counts for one lesson (null lesson = "সব লেসন"), or null
  /// while not loaded.
  Map<SearchFlowType, int?>? of(int chapter, String? lesson) =>
      _by[_key(chapter, lesson)];

  /// Loads counts for the "all" row and every lesson of a chapter,
  /// once per chapter per call (repeat opens reuse the result).
  Future<void> load({
    List<SearchFlowType> types = searchFlowBaseTypes,
    required String subject,
    required int schoolClass,
    required int chapter,
    required Iterable<String> lessons,
  }) async {
    final all = <String?>[null, ...lessons];
    await Future.wait([
      for (final lesson in all)
        () async {
          final k = _key(chapter, lesson);
          if (_by.containsKey(k) || !_requested.add(k)) return;
          final out = await _svc.countAll(
            subject: subject,
            schoolClass: schoolClass,
            chapter: chapter,
            lesson: lesson,
            types: types,
          );
          if (out.values.every((v) => v == null)) {
            _requested.remove(k); // nothing known: retry next open
            return;
          }
          _by[k] = out;
          onChanged();
        }(),
    ]);
  }
}

/// "সৃজনশীল ১০২ · বহুনির্বাচনি ২৩৭ · সংক্ষিপ্ত ১৫", or null when
/// no type has a known non-zero count.
String? lessonCountsLine(
  Map<SearchFlowType, int?>? counts,
  Map<String, String> s,
  bool bn,
) {
  if (counts == null) return null;
  const order = [
    SearchFlowType.creative,
    SearchFlowType.mcq,
    SearchFlowType.short,
  ];
  final parts = [
    for (final t in order)
      if ((counts[t] ?? 0) > 0)
        '${searchFlowTypeLabel(t, s)} ${numStr(counts[t]!, bn)}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
