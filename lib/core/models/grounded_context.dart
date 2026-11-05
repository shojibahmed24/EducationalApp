// Grounded context for ONE question (moved out of backend_models.dart
// 2026-11-03 to keep that file under the 250-line rule).
// Book-verified context, returned only by the server-side path
// (Edge Function) or the local DEMO index. questionText is the
// book's own wording, verbatim — the AI is sent this text, never
// just a question title. localAnswer is non-empty ONLY for the
// local DEMO index; edge-grounded rows carry no stored answer
// (book_questions holds question text only), so a no-key DEMO
// fallback shows the question itself. sourceLink is deliberately
// absent: it is server-only and must never reach the app.
class GroundedContext {
  final String bookTitle, chapterTitle, subject;
  final int schoolClass, chapterNumber, page, problem;
  final String questionText, localAnswer, source; // edge | local-index | guide
  /// Book chapter text chunks (OCR) for this question's page, max 3,
  /// in reading order. Empty = no chunk grounding; the prompt must
  /// then say plainly the explanation is question-only grounded.
  /// chunkPageRanges runs parallel to chunkTexts ('12–14' style).
  final List<String> chunkTexts, chunkPageRanges;

  /// Guide Mode G fields (empty for textbook Mode A rows).
  /// questionType: 'mcq' | 'short' | 'creative' | 'problem' | ''.
  /// marks is the PRINTED mark count, or null when unprinted.
  /// answerKey is the printed key for MCQ/short, else ''.
  /// guideUnitText is HIDDEN grounding (the guide's worked
  /// solution for creative/long/Math) — it goes into the AI
  /// prompt. It is rendered to the student ONLY when the server
  /// marks it verbatim (verbatimKind 'guide'/'corrected'); in
  /// every other case it stays hidden grounding, exactly as
  /// before. fallbackChunkText is the single prose fallback
  /// chunk, or ''.
  final String guideQuestionId, questionType, answerKey;
  final String guideUnitText, guideUnitKind, fallbackChunkText;
  final String verbatimKind, verbatimText, correctionNote;
  /// Printed per-question explanation (migration 017); '' = the
  /// guide prints none for this row. Rendered verbatim, never
  /// mixed into the AI explanation.
  final String guideExplanation;
  final bool guideError;
  final int? marks;
  /// Exact stored option texts for an MCQ (2026-11-03 fix), in
  /// display order — the prompt quotes these VERBATIM, never
  /// paraphrased. Empty for non-MCQ rows, and empty when the
  /// row genuinely carries no options (then the UI shows the
  /// honest not-available state and never calls the model).
  final List<String> options;
  /// The question's own stimulus (উদ্দীপক) text + reference,
  /// when the row carries one. Rendered in prompts as a LABELED
  /// context block, never fused into questionText (the old fuse
  /// made a bare-word MCQ read as "only stimulus given").
  final String stimulusText, stimulusRef;
  const GroundedContext({
    required this.bookTitle,
    required this.chapterTitle,
    required this.subject,
    required this.schoolClass,
    required this.chapterNumber,
    required this.page,
    required this.problem,
    required this.questionText,
    this.localAnswer = '',
    required this.source,
    this.chunkTexts = const [],
    this.chunkPageRanges = const [],
    this.guideQuestionId = '',
    this.questionType = '',
    this.answerKey = '',
    this.guideUnitText = '',
    this.guideUnitKind = '',
    this.fallbackChunkText = '',
    this.verbatimKind = 'none',
    this.verbatimText = '',
    this.correctionNote = '',
    this.guideExplanation = '',
    this.guideError = false,
    this.marks,
    this.options = const [],
    this.stimulusText = '',
    this.stimulusRef = '',
  });

  /// True when the server explicitly allows stage-1 verbatim
  /// display for this row (guide text or curated correction).
  bool get hasVerbatim =>
      (verbatimKind == 'guide' || verbatimKind == 'corrected') &&
      verbatimText.isNotEmpty;

  /// True when this row carries printed marks (a badge may show).
  bool get marksPrinted => marks != null;

  /// True for an MCQ whose options genuinely never arrived:
  /// no explanation call may run for it (the model would either
  /// answer "cannot determine" or invent option wording).
  bool get mcqOptionsMissing => questionType == 'mcq' && options.isEmpty;

  /// The verified key mapped to an option index, or null when
  /// the key is absent, unrecognised, or out of range. Keys come
  /// in two positional systems — Bengali display letters
  /// (ক/খ/গ/ঘ/ঙ) and roman numerals (i/ii/iii/iv/v) — both map
  /// by position, never by guessing.
  int? get correctOptionIndex {
    if (answerKey.isEmpty || options.isEmpty) return null;
    const bn = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];
    const roman = ['i', 'ii', 'iii', 'iv', 'v'];
    var i = bn.indexOf(answerKey);
    if (i < 0) i = roman.indexOf(answerKey.toLowerCase());
    if (i < 0 || i >= options.length) return null;
    return i;
  }

  /// Exact text of the verified-correct option, or null when the
  /// key cannot be mapped (then prompts name the key only and
  /// never invent option wording).
  String? get correctOptionText {
    final i = correctOptionIndex;
    return i == null ? null : options[i];
  }
}
