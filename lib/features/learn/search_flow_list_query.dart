// List-route query string + subject lookup for the search
// flow controller, split out so the controller stays under
// the 250-line cap. The screen imports this file for
// listQuery(); the controller imports it for subject.
import '../../core/models/backend_models.dart';
import 'search_flow_controller.dart';

extension SearchFlowListQuery on SearchFlowController {
  SubjectInfo? get subject {
    for (final s in subjects) {
      if (s.id == subjectId) return s;
    }
    return null;
  }

  /// Query string for the list route (no navigation here).
  /// Section / set / Paper-II-section / chapterless modes omit
  /// `type` (a stale type pick must never leak in — the type->
  /// section mapping is Math's and would return wrong lists).
  /// `type` is null-guarded and the lesson is URI-encoded.
  String listQuery({int? questionNumber, String? setId, String? paper2Section, bool chapterless = false}) {
    final q = <String, String>{
      'subject': effectiveSubjectId,
      'class': '$effectiveClass',
      'source': source,
      'chapter': '${chapter ?? 0}',
      if (englishGuideSectionMode && section != null) 'section': section!,
      if (paper2Section != null) 'section': paper2Section,
      if (setId != null) 'setId': setId,
      if (chapterless) 'chapterless': 'true',
      if (type != null && paper2Section == null && setId == null && !chapterless) 'type': type!.name,
      if (lesson != null) 'lesson': Uri.encodeComponent(lesson!),
      if (questionNumber != null) 'questionNumber': '$questionNumber',
    };
    return q.entries.map((e) => '${e.key}=${e.value}').join('&');
  }
}
