// Guide bank data models (UI-agnostic row shapes). One bank
// row: verbatim text plus printed-only metadata; absent marks
// or importance must never be invented (no badge/star).
import 'creative_marks_parts.dart';

List<String> _stringList(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

class GuideBankQuestion {
  final String id;
  final String questionText;
  final String questionType; // lowercase canonical type
  final List<String> options; // MCQ options verbatim; empty otherwise
  final int? correctOptionIndex; // null = no printed key IN THIS ROW.
  // List rows never carry a key (only hasKey); correctOptionIndex
  // stays null even when a key exists — use keyExists for labels.
  final bool serverHasKey;
  // Printed short-answer text (short questions only). Empty means
  // the guide prints no key text for this row — never synthesized.
  final String answerKeyText;
  final int? marks; // null = not printed
  final bool important; // true only when the guide prints it
  final String? setId; // null = chapter bank; model-test-<n> = set
  // Pilot tags (2026-10-31, all OPTIONAL): lesson, section,
  // stimulusId, stimulusText, stimulusRef (passage source).
  final String? lesson;
  final String? section;
  // Phase B (Bangla 1st Paper): writer|lesson; null = untagged.
  final String? mcqGroup;
  final String? stimulusId;
  final String? stimulusText;
  final String? stimulusRef;
  // Pilot (013): flag_note — print note, verbatim; null = none.
  final String? flagNote;
  // Pilot (2026-10-31): hasSolution = Q+solution chunked as ONE pair; null = unknown.
  final bool? hasSolution;
  // Guide-native chapter number (migration 011); null = server did not say.
  final int? chapterNumber;
  final String? modelQuestionId; // Phase 3: linked bank model row id.
  // Creative part marks (ক,খ,গ,ঘ order), normalised; null = unknown.
  final List<int>? marksParts;
  // Bangla 2nd suggestion rows (Edge list, 2026-11-04): kind,
  // star, chapter text, title, linked bank/nirmiti row ids.
  // Null = server did not say; linked list empty when absent.
  final String? suggestionKind;
  final String? suggestionStar;
  final String? suggestionPoricched;
  final String? suggestionShironam;
  final List<String> linkedDirectiveIds;
  // Phase 2 (2026-10-31): guide_error = printed key/solution
  // proven wrong (never scored); false also covers pre-migration.
  final bool guideError;
  // Quick-load Phase 3: slim list row (no options/stimulus);
  // the full row arrives on open via action 'get'. False also
  // covers genuinely option-less rows (short/creative), which
  // are never slim-flagged — only the server sets slim: true.
  final bool slim;
  const GuideBankQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    this.options = const [],
    this.correctOptionIndex,
    this.serverHasKey = false,
    this.answerKeyText = '',
    this.marks,
    this.important = false,
    this.setId,
    this.guideError = false,
    this.slim = false,
    this.lesson,
    this.section,
    this.mcqGroup,
    this.stimulusId,
    this.stimulusText,
    this.stimulusRef, this.flagNote,
    this.hasSolution,
    this.chapterNumber,
    this.modelQuestionId,
    this.marksParts,
    this.suggestionKind,
    this.suggestionStar,
    this.suggestionPoricched,
    this.suggestionShironam,
    this.linkedDirectiveIds = const [],
  });

  /// A key counts only when it points at a real option.
  bool get hasKey =>
      correctOptionIndex != null &&
      correctOptionIndex! >= 0 &&
      correctOptionIndex! < options.length;

  /// "A stored key exists" (label use only): index-based key OR
  /// server hasKey. Never use where the key VALUE is needed.
  bool get keyExists => hasKey || serverHasKey;

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionText': questionText,
    'questionType': questionType,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    // Round-trip key status so cached rows keep the label.
    'hasKey': keyExists,
    'answerKeyText': answerKeyText,
    'marks': marks,
    'important': important,
    'setId': setId,
    'guideError': guideError,
    'lesson': lesson,
    'section': section,
    'mcqGroup': mcqGroup,
    'stimulusId': stimulusId,
    'stimulusText': stimulusText,
    'stimulusRef': stimulusRef,
    'flagNote': flagNote,
    'hasSolution': hasSolution,
    'chapterNumber': chapterNumber,
    'modelQuestionId': modelQuestionId,
    'marksParts': marksParts,
    'suggestionKind': suggestionKind,
    'suggestionStar': suggestionStar,
    'suggestionPoricched': suggestionPoricched,
    'suggestionShironam': suggestionShironam,
    'linkedDirectiveIds': linkedDirectiveIds,
    'slim': slim,
  };

  static GuideBankQuestion fromJson(Map<String, dynamic> j) {
    final opts = j['options'];
    return GuideBankQuestion(
      id: j['id'] as String? ?? '',
      questionText: j['questionText'] as String? ?? '',
      questionType: j['questionType'] as String? ?? '',
      options: opts is List ? opts.map((e) => e.toString()).toList() : const [],
      correctOptionIndex: (j['correctOptionIndex'] as num?)?.toInt(),
      serverHasKey: j['hasKey'] == true,
      answerKeyText: j['answerKeyText'] as String? ?? '',
      marks: (j['marks'] as num?)?.toInt(),
      important: j['important'] == true,
      setId: j['setId'] as String?,
      guideError: j['guideError'] == true,
      lesson: j['lesson'] as String?,
      section: j['section'] as String?,
      mcqGroup: j['mcqGroup'] as String?,
      stimulusId: j['stimulusId'] as String?,
      stimulusText: j['stimulusText'] as String?,
      stimulusRef: j['stimulusRef'] as String?,
      flagNote: j['flagNote'] as String?,
      hasSolution: j['hasSolution'] is bool ? j['hasSolution'] as bool : null,
      chapterNumber: (j['chapterNumber'] as num?)?.toInt(),
      modelQuestionId: j['modelQuestionId'] as String?,
      marksParts: normalizeMarksParts(j['marksParts']),
      suggestionKind: j['suggestionKind'] as String?,
      suggestionStar: j['suggestionStar'] as String?,
      suggestionPoricched: j['suggestionPoricched'] as String?,
      suggestionShironam: j['suggestionShironam'] as String?,
      linkedDirectiveIds: _stringList(j['linkedDirectiveIds']),
      slim: j['slim'] == true,
    );
  }

  /// A list-endpoint row: options + hasKey boolean, NEVER a key
  /// index or key text (those stay with Mode G).
  static GuideBankQuestion fromServerJson(Map<String, dynamic> j) {
    final opts = j['options'];
    return GuideBankQuestion(
      id: j['id'] as String? ?? '',
      questionText: j['questionText'] as String? ?? '',
      questionType: j['questionType'] as String? ?? '',
      options: opts is List ? opts.map((e) => e.toString()).toList() : const [],
      serverHasKey: j['hasKey'] == true,
      marks: (j['marks'] as num?)?.toInt(),
      important: j['important'] == true,
      setId: j['setId'] as String?,
      guideError: j['guideError'] == true,
      lesson: j['lesson'] as String?,
      section: j['section'] as String?,
      mcqGroup: j['mcq_group'] as String?,
      stimulusId: j['stimulusId'] as String?,
      stimulusText: j['stimulusText'] as String?,
      stimulusRef: j['stimulusRef'] as String?,
      flagNote: j['flagNote'] as String?,
      hasSolution: j['hasSolution'] is bool ? j['hasSolution'] as bool : null,
      chapterNumber: (j['chapterNumber'] as num?)?.toInt(),
      modelQuestionId: j['modelQuestionId'] as String?,
      marksParts: normalizeMarksParts(j['marksParts']),
      suggestionKind: j['suggestionKind'] as String?,
      suggestionStar: j['suggestionStar'] as String?,
      suggestionPoricched: j['suggestionPoricched'] as String?,
      suggestionShironam: j['suggestionShironam'] as String?,
      linkedDirectiveIds: _stringList(j['linkedDirectiveIds']),
      slim: j['slim'] == true,
    );
  }
}

/// One guide model-test set's server metadata (sets action),
/// counts only; rows come from the list action (setId filter).
class GuideModelSetInfo {
  final String setId;
  final int totalCount;
  final int keyedCount;
  final Map<String, List<int>>? gradeBands; // Phase 3: printed bands, null = none.
  const GuideModelSetInfo({
    required this.setId,
    required this.totalCount,
    required this.keyedCount,
    this.gradeBands,
  });

  int get unkeyedCount => totalCount - keyedCount;

  Map<String, dynamic> toJson() => {
    'setId': setId,
    'totalCount': totalCount,
    'keyedCount': keyedCount,
    'gradeBands': gradeBands,
  };

  static GuideModelSetInfo fromJson(Map<String, dynamic> j) =>
      GuideModelSetInfo(
        setId: j['setId'] as String? ?? '',
        totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
        keyedCount: (j['keyedCount'] as num?)?.toInt() ?? 0,
        gradeBands: (j['gradeBands'] as Map?)?.map((k, v) => MapEntry(
            k.toString(),
            (v as List).map((e) => (e as num).toInt()).toList())),
      );
}

/// One guide model-test set: only the set id, subject and its rows.
// No title is stored: set titles are never invented.
class GuideModelSet {
  final String setId;
  final String subjectId;
  final List<GuideBankQuestion> questions;
  const GuideModelSet({
    required this.setId,
    required this.subjectId,
    required this.questions,
  });

  int get keyedCount => questions.where((q) => q.hasKey).length;
  int get unkeyedCount => questions.length - keyedCount;

  Map<String, dynamic> toJson() => {
    'setId': setId,
    'subjectId': subjectId,
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  static GuideModelSet fromJson(Map<String, dynamic> j) {
    final qs = j['questions'];
    return GuideModelSet(
      setId: j['setId'] as String? ?? '',
      subjectId: j['subjectId'] as String? ?? '',
      questions: qs is List
          ? qs
                .whereType<Map>()
                .map(
                  (e) => GuideBankQuestion.fromJson(
                    e.map((k, v) => MapEntry(k.toString(), v)),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

/// A per-question report, captured locally only (see
/// GuideBankService.submitReportLocal); nothing is ever sent.
class GuideReport {
  final String questionId;
  final String subjectId;
  final int chapterNumber;
  final String reason; // wrong-key | wrong-chapter | unreadable
  final String createdAt; // ISO-8601 string
  const GuideReport({
    required this.questionId,
    required this.subjectId,
    required this.chapterNumber,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'subjectId': subjectId,
    'chapterNumber': chapterNumber,
    'reason': reason,
    'createdAt': createdAt,
  };

  static GuideReport fromJson(Map<String, dynamic> j) => GuideReport(
    questionId: j['questionId'] as String? ?? '',
    subjectId: j['subjectId'] as String? ?? '',
    chapterNumber: (j['chapterNumber'] as num?)?.toInt() ?? 0,
    reason: j['reason'] as String? ?? '',
    createdAt: j['createdAt'] as String? ?? '',
  );
}
