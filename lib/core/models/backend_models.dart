// Plain data models shared by the data services. No network code here.
// GroundedContext lives in grounded_context.dart (moved 2026-11-03
// to keep this file under the 250-line rule); re-exported so
// existing imports keep working unchanged.
export 'grounded_context.dart';

/// One row of the books_public view. The view carries a SINGLE title
/// column: a 'bn' row's title is the Bangla title, an 'en' row's title
/// is the English title. Callers filter by language, so both title
/// fields are filled with that row's title and title(bn) is correct
/// for the UI language in use. Never query the books table directly:
/// it holds the server-only source_link and has no client RLS policy.
class BookInfo {
  final String id, titleBn, titleEn, subject;
  final int schoolClass;
  final bool supplied;
  const BookInfo({
    required this.id,
    required this.titleBn,
    required this.titleEn,
    required this.subject,
    required this.schoolClass,
    required this.supplied,
  });
  String title(bool bangla) => bangla ? titleBn : titleEn;
}

/// One row of the chapters table (client-readable for signed-in
/// users per migration 002). Chapters carry both titles, so one row
/// serves both UI languages.
class ChapterInfo {
  final String id, bookId, bookTitle, titleBn, titleEn;
  final int number;
  const ChapterInfo({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.number,
    required this.titleBn,
    required this.titleEn,
  });
  String title(bool bangla) => bangla ? titleBn : titleEn;
}

/// One row of the subjects table, enriched with the class's books:
/// locked = no supplied book for this subject in this class+language,
/// chapterCount = chapters of that subject's books in that language
/// (0 when unknown / no chapters imported yet).
class SubjectInfo {
  final String id, nameBn, nameEn;
  final bool locked;
  final int chapterCount;

  /// Guide availability (server-checked in subjectsAsync): true
  /// when this class+subject has guide-bank chapters even though
  /// its textbook is not supplied. A guide-available subject is
  /// VISIBLE on Home and reachable in Search via the guide route,
  /// even though textbook lessons stay locked. Defaults false/0
  /// (DEMO fallback, or the guide check failed) — never a guess.
  final bool hasGuide;
  final int guideChapterCount;

  /// Set-based guide content: model-test set count for subjects
  /// whose guide rows are sets + bank rows, not chapters.
  final int guideSetCount;
  const SubjectInfo({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.locked,
    required this.chapterCount,
    this.hasGuide = false,
    this.guideChapterCount = 0,
    this.guideSetCount = 0,
  });
  String name(bool bangla) => bangla ? nameBn : nameEn;

  /// Cache-once round-trip: unknown keys default to false/0,
  /// so older caches without guideSetCount still load.
  Map<String, dynamic> toJson() => {
    'id': id,
    'nameBn': nameBn,
    'nameEn': nameEn,
    'locked': locked,
    'chapterCount': chapterCount,
    'hasGuide': hasGuide,
    'guideChapterCount': guideChapterCount,
    'guideSetCount': guideSetCount,
  };
  factory SubjectInfo.fromJson(Map<String, dynamic> json) => SubjectInfo(
    id: '${json['id'] ?? ''}',
    nameBn: '${json['nameBn'] ?? ''}',
    nameEn: '${json['nameEn'] ?? ''}',
    locked: json['locked'] == true,
    chapterCount: (json['chapterCount'] as num?)?.toInt() ?? 0,
    hasGuide: json['hasGuide'] == true,
    guideChapterCount: (json['guideChapterCount'] as num?)?.toInt() ?? 0,
    guideSetCount: (json['guideSetCount'] as num?)?.toInt() ?? 0,
  );
}

/// How a subjects fetch resolved: server (fresh truth), demo
/// (no backend configured — content by design, not an error),
/// or failed (unreachable — never mistake fallback for "none").
enum SubjectsFetchKind { server, demo, failed }

class SubjectsFetchResult {
  const SubjectsFetchResult({required this.subjects, required this.kind});
  final List<SubjectInfo> subjects;
  final SubjectsFetchKind kind;
}

class LessonResult {
  final String question, answerBn, answerEn;
  final bool found;
  const LessonResult({required this.question, required this.answerBn, required this.answerEn, required this.found});
  static const noMatch = LessonResult(question: '', answerBn: '', answerEn: '', found: false);
}

class PracticeProblem {
  final String id, questionBn, questionEn, answerBn, answerEn;
  const PracticeProblem({required this.id, required this.questionBn, required this.questionEn, required this.answerBn, required this.answerEn});
}

class QuizItem {
  final String id, questionBn, questionEn;
  final List<String> options;
  final int correctIndex;
  // Multi-key (Phase 2 gap plan): accepted indices for JSON-list
  // keys; empty = single-key (correctIndex alone is the set).
  final List<int> correctIndices;
  const QuizItem({
    required this.id,
    required this.questionBn,
    required this.questionEn,
    required this.options,
    required this.correctIndex,
    this.correctIndices = const [],
  });

  /// Multi-key judgment: any accepted index earns full marks;
  /// empty set = single-key, only correctIndex. Accepted texts.
  bool isCorrect(int selected) =>
      correctIndices.isEmpty ? selected == correctIndex : correctIndices.contains(selected);
  List<String> get acceptedOptionTexts {
    final idx = correctIndices.isEmpty ? [correctIndex] : correctIndices;
    return idx.where((i) => i >= 0 && i < options.length).map((i) => options[i]).toList();
  }

  // Phase 2 (2026-10-31): weak-revision persistence. A finished
  // run's wrong items are stored inside Attempt, so a later
  // revision quiz can re-ask GUIDE items too — guide ids are
  // not in any bank, so findQuestion() can never rebuild them.
  Map<String, dynamic> toJson() => {
    'id': id,
    'questionBn': questionBn,
    'questionEn': questionEn,
    'options': options,
    'correctIndex': correctIndex,
    'correctIndices': correctIndices,
  };

  static QuizItem fromJson(Map<String, dynamic> j) {
    final opts = j['options'];
    final acc = j['correctIndices'];
    return QuizItem(
      id: j['id'] as String? ?? '',
      questionBn: j['questionBn'] as String? ?? '',
      questionEn: j['questionEn'] as String? ?? '',
      options: opts is List ? opts.map((e) => e.toString()).toList() : const [],
      correctIndex: (j['correctIndex'] as num?)?.toInt() ?? 0,
      correctIndices: acc is List ? acc.whereType<num>().map((n) => n.toInt()).toList() : const [],
    );
  }
}

class VoiceBudget {
  final int usedMinutes, capMinutes;
  const VoiceBudget({required this.usedMinutes, required this.capMinutes});
  int get remaining => (capMinutes - usedMinutes).clamp(0, capMinutes);
  bool get hasMinutes => remaining > 0;
}
