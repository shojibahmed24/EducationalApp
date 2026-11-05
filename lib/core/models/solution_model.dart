// Structured AI solution model — the output contract for the
// answer screen (locked 2026-10-29). The AI returns JSON, never a
// wall of text: summary, numbered steps, final answer. MCQ adds
// the correct option + why; creative adds marks-split sections.
// Formulas arrive as LaTeX (formulaLatex), never caret-text.
// Tables arrive as data (headers + rows), never comma-paragraphs.
// Parsing is strict: any missing/wrong-typed required field makes
// the whole payload invalid (caller falls back to plain markdown).
// No guide or textbook text lives here — only the shape.

/// One comparison table inside a step.
class SolutionTable {
  final List<String> headers;
  final List<List<String>> rows;
  const SolutionTable({required this.headers, required this.rows});
}

/// One numbered step of a solution.
class SolutionStep {
  final int n;
  final String title;
  final String text;

  /// LaTeX formula for this step, if any (e.g. r'\frac{60}{40}').
  final String? formulaLatex;
  final SolutionTable? table;

  /// Creative sub-part label ('ক' | 'খ' | 'গ' | 'ঘ'), if any.
  final String? sectionLabel;

  /// Printed marks of this section, if any. Null = unprinted:
  /// the UI must show NO marks badge for it, never an invented one.
  final int? sectionMarks;
  const SolutionStep({
    required this.n,
    required this.title,
    required this.text,
    this.formulaLatex,
    this.table,
    this.sectionLabel,
    this.sectionMarks,
  });
}

/// A full structured solution, ready for the card renderer.
class StructuredSolution {
  final String summary;
  final List<SolutionStep> steps;
  final String finalAnswer;

  /// MCQ only: the option the AI claims is correct.
  final String? correctOption;
  final String? whyCorrect;
  final String? whyOthersWrong;
  const StructuredSolution({
    required this.summary,
    required this.steps,
    required this.finalAnswer,
    this.correctOption,
    this.whyCorrect,
    this.whyOthersWrong,
  });
}

String _asString(dynamic v) => v is String ? v : '';
int? _asInt(dynamic v) => v is num ? v.toInt() : null;

SolutionTable? _parseTable(dynamic v) {
  if (v is! Map) return null;
  final headers = (v['headers'] as List?)
      ?.whereType<String>()
      .where((s) => s.isNotEmpty)
      .toList();
  final rows = (v['rows'] as List?)
      ?.whereType<List>()
      .map((r) => r.whereType<String>().toList())
      .where((r) => r.isNotEmpty)
      .toList();
  if (headers == null || headers.isEmpty || rows == null || rows.isEmpty) {
    return null;
  }
  return SolutionTable(headers: headers, rows: rows);
}

/// Strict parse: returns null unless the payload matches the
/// contract exactly (required fields present and correctly typed).
StructuredSolution? parseStructuredSolution(dynamic data) {
  if (data is! Map) return null;
  final summary = _asString(data['summary']);
  final finalAnswer = _asString(data['finalAnswer']);
  final rawSteps = data['steps'];
  if (summary.isEmpty || finalAnswer.isEmpty || rawSteps is! List) {
    return null;
  }
  final steps = <SolutionStep>[];
  for (final raw in rawSteps) {
    if (raw is! Map) return null;
    final n = _asInt(raw['n']);
    final text = _asString(raw['text']);
    if (n == null || text.isEmpty) return null;
    final formula = _asString(raw['formulaLatex']);
    steps.add(SolutionStep(
      n: n,
      title: _asString(raw['title']),
      text: text,
      formulaLatex: formula.isEmpty ? null : formula,
      table: _parseTable(raw['table']),
      sectionLabel: _asString(raw['sectionLabel']).isEmpty
          ? null
          : _asString(raw['sectionLabel']),
      sectionMarks: _asInt(raw['sectionMarks']),
    ));
  }
  if (steps.isEmpty) return null;
  final correctOption = _asString(data['correctOption']);
  final whyCorrect = _asString(data['whyCorrect']);
  final whyOthersWrong = _asString(data['whyOthersWrong']);
  return StructuredSolution(
    summary: summary,
    steps: steps,
    finalAnswer: finalAnswer,
    correctOption: correctOption.isEmpty ? null : correctOption,
    whyCorrect: whyCorrect.isEmpty ? null : whyCorrect,
    whyOthersWrong: whyOthersWrong.isEmpty ? null : whyOthersWrong,
  );
}

/// Key-check gate (2026-11-03, option-level): the AI draft's
/// claimed correct option must name the SAME OPTION as the
/// stored printed key — by label or by option text, never by
/// exact string. The old gate compared raw strings, so a right
/// answer in the other label system (screen Bengali খ, stored
/// roman ii) or as option text ('Photography') was thrown away
/// as a mismatch even though the model agreed with the guide.
/// Labels map positionally: Bengali ক/খ/গ/ঘ/ঙ, roman
/// i/ii/iii/iv/v, Latin A–E, and bare numbers. A claim may be a
/// bare label, a label-led phrase ('খ. Photography',
/// 'খ (ii)'), the exact option text, a sentence containing the
/// option text, or a parenthesised roman ('(ii)'). When
/// correctOption is empty or unresolvable, finalAnswer is tried
/// the same way. With no options (non-MCQ rows) the old exact
/// string gate stays — those rows carry no option to map.
/// Unresolvable on either side is a mismatch.
bool solutionMatchesKey(
    StructuredSolution solution, String storedKey, List<String> options) {
  if (options.isEmpty) {
    final claimed = solution.correctOption;
    if (claimed == null) return false;
    return claimed.trim().toLowerCase() ==
        storedKey.trim().toLowerCase();
  }
  final stored = _claimOptionIndex(storedKey, options);
  if (stored == null) return false;
  var claimed = _claimOptionIndex(solution.correctOption ?? '', options);
  claimed ??= _claimOptionIndex(solution.finalAnswer, options);
  if (claimed == null) return false;
  return claimed == stored;
}

const _bnLabels = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];
const _romanLabels = ['i', 'ii', 'iii', 'iv', 'v'];
const _latinLabels = ['a', 'b', 'c', 'd', 'e'];

/// Index of a bare label token ('খ', 'ii', 'B', '2'), or null.
/// Strips wrapping punctuation: '(ii)', 'খ.', 'B)'.
int? _bareLabelIndex(String token) {
  var t = token.trim().toLowerCase();
  while (t.startsWith('(') || t.startsWith('[')) {
    t = t.substring(1);
  }
  while (t.endsWith('.') ||
      t.endsWith(')') ||
      t.endsWith(']') ||
      t.endsWith(':') ||
      t.endsWith('।') ||
      t.endsWith(',') ||
      t.endsWith('!') ||
      t.endsWith('?')) {
    t = t.substring(0, t.length - 1);
  }
  t = t.trim();
  var i = _bnLabels.indexOf(t);
  if (i >= 0) return i;
  i = _romanLabels.indexOf(t);
  if (i >= 0) return i;
  i = _latinLabels.indexOf(t);
  if (i >= 0) return i;
  final n = int.tryParse(t);
  if (n != null && n >= 1) return n - 1;
  return null;
}

/// Index of a label-led claim ('খ. Photography', 'খ (ii)',
/// 'Option ii'), or null. Only the leading label counts — a
/// roman 'i' buried in a sentence is an English word, not a
/// label, so mid-sentence labels are never scanned.
int? _leadingLabelIndex(String claim) {
  var t = claim.trim();
  t = t.replaceFirst(
      RegExp(r'^option\s+', caseSensitive: false), '');
  final m = RegExp(
          r'^[\(\[]?\s*([ক-ঙ]|iv|v|iii|ii|i|[a-e]|[1-9])\s*(?:[.\)\:\-–—]|\()',
          caseSensitive: false)
      .firstMatch(t);
  if (m == null) return null;
  return _bareLabelIndex(m.group(1)!);
}

/// Index of the option a claim names, or null. Order: bare
/// label, label-led phrase, parenthesised roman ('(ii)'),
/// exact option text, contained option text (longest first),
/// trailing Bengali label ('উত্তরটি হলো খ').
int? _claimOptionIndex(String claim, List<String> options) {
  final text = claim.trim();
  if (text.isEmpty) return null;
  final lower = text.toLowerCase();
  var idx = _bareLabelIndex(text);
  if (idx != null && idx < options.length) return idx;
  // 'Option ii' — strip the word, then the remainder is a label.
  final unprefixed =
      text.replaceFirst(RegExp(r'^option\s+', caseSensitive: false), '');
  if (unprefixed != text) {
    idx = _bareLabelIndex(unprefixed);
    if (idx != null && idx < options.length) return idx;
  }
  idx = _leadingLabelIndex(text);
  if (idx != null && idx < options.length) return idx;
  final paren = RegExp(r'\(\s*(iv|v|iii|ii|i)\s*\)', caseSensitive: false)
      .firstMatch(lower);
  if (paren != null) {
    idx = _bareLabelIndex(paren.group(1)!);
    if (idx != null && idx < options.length) return idx;
  }
  for (var i = 0; i < options.length; i++) {
    if (options[i].trim().toLowerCase() == lower) return i;
  }
  final order = List<int>.generate(options.length, (i) => i)
    ..sort((a, b) => options[b].length.compareTo(options[a].length));
  for (final i in order) {
    final opt = options[i].trim().toLowerCase();
    if (opt.isNotEmpty && lower.contains(opt)) return i;
  }
  final tail = text.split(RegExp(r'\s+')).last;
  idx = _bareLabelIndex(tail);
  if (idx != null && idx < options.length) {
    // Trailing-token rule is Bengali-only: a trailing roman
    // 'i' is an English word, never a label.
    var stripped = tail.trim().toLowerCase();
    while (stripped.startsWith('(') || stripped.startsWith('[')) {
      stripped = stripped.substring(1);
    }
    while (stripped.endsWith('.') ||
        stripped.endsWith(')') ||
        stripped.endsWith(']') ||
        stripped.endsWith(':') ||
        stripped.endsWith('।') ||
        stripped.endsWith(',') ||
        stripped.endsWith('!') ||
        stripped.endsWith('?')) {
      stripped = stripped.substring(0, stripped.length - 1);
    }
    if (_bnLabels.contains(stripped.trim())) return idx;
  }
  return null;
}

/// Outcome of one structured attempt (moved here from
/// structured_explanation_service.dart 2026-11-03 — it is a model,
/// not service logic). ok = parsed solution; keyMismatch = draft
/// discarded, caller shows the stored key; failed = no usable
/// reply (rawText may still hold prose fallback).
enum StructuredStatus { ok, keyMismatch, failed }

class StructuredAttempt {
  final StructuredStatus status;
  final StructuredSolution? solution;
  final String rawText;
  final String storedKey;

  /// Attribution from the Edge response (see GenResult):
  /// 'openrouter' | 'gemini' | 'unknown'. Set whenever the
  /// attempt carries AI text (ok solution or prose fallback);
  /// attempts with no AI text stay 'unknown' and show no label.
  final String aiProvider;
  final String? aiModel;
  const StructuredAttempt({
    required this.status,
    this.solution,
    this.rawText = '',
    this.storedKey = '',
    this.aiProvider = 'unknown',
    this.aiModel,
  });
}
