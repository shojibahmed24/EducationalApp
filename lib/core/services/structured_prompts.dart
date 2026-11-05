// Structured-solution prompts, split out of
// structured_explanation_service.dart to keep it under the
// 250-line limit. Prompt wording only — no parsing, no policy.
import '../models/backend_models.dart';
import 'marks_budget.dart';

String structuredSystemPrompt(bool bangla, MarksBudget budget, bool strict) {
  final lang = bangla ? 'Bangla' : 'English';
  final strictNote = strict
      ? ' STRICT: follow the shape and the marks budget exactly.'
      : '';
  // 2026-11-03 explanation fix: the language and option rules are
  // explicit, not implied. Bangla means EVERYTHING in Bangla, in
  // easy simple words (the old single "Write in Bangla" line still
  // produced an all-English explanation). Options are quoted
  // EXACTLY as given — the old prompt never carried options at
  // all, so the model either answered "cannot determine" or
  // invented option wording ("scream" for a stored option).
  final banglaRule = bangla
      ? ' Write EVERYTHING in Bangla, in easy simple words a '
          'class 9 student understands. Never write any part of '
          'the explanation in English. The Bangla sentences must '
          'be Bangla script and Bangla words only: never use '
          'Chinese, Korean, Japanese, or Arabic characters, and '
          'never use Hindi or Urdu words such as ko, mein, ka, '
          'or ki inside a Bangla sentence.'
      : '';
  return 'You are a school teacher. Reply with JSON ONLY, no '
      'markdown fences, matching this shape: {"summary": "1-2 '
      'line PLAN of what will be done, operations in order", '
      '"steps": [{"n": 1, "title": "short heading", '
      '"text": "step body", "formulaLatex": "LaTeX or empty", '
      '"sectionLabel": "ক/খ/গ/ঘ or empty", "sectionMarks": 0}], '
      '"finalAnswer": "the answer with its unit, plus a one-line '
      'answer sentence", "correctOption": "MCQ only", '
      '"whyCorrect": "MCQ only", "whyOthersWrong": "MCQ only"}. '
      'The summary is a PLAN, never a restatement of the final '
      'answer: name the operations in order and any key '
      'conversion or assumption the solution needs (a unit '
      'change, a value assumed where the question leaves it '
      'open). Summary says WHAT will be done, finalAnswer says '
      'the RESULT — the two must differ. If units differ, '
      'convert them in an early step before computing; an '
      'assumption gets at most one step line, never the whole '
      'solution. '
      'Write in $lang.$banglaRule Formulas in LaTeX wrapped in \$...\$ '
      'delimiters so they render as typeset math, never caret-text. '
      'Never copy hidden grounding verbatim; rewrite its steps '
      'in your own words. Formulas, symbols and notation '
      'must be re-derived, never quoted from OCR text. '
      'OPTIONS RULE: when options are listed in the prompt, quote '
      'every option EXACTLY as written there — exact words, exact '
      'order. Never paraphrase, substitute, or invent option '
      'wording, and identify the correct option by its exact text '
      'and label. When no options are listed for an MCQ, do NOT '
      'invent any: state plainly that the options are missing. '
      'LENGTH RULE: when this prompt includes a guide answer or '
      'worked solution, your explanation must be at least as long '
      'as that guide answer — the same length or a little longer, '
      'never shorter. EXCEPTION: if the student explicitly asks '
      'for a short or brief explanation, write briefly instead; '
      'the student\'s explicit request overrides the length rule. '
      'SCRIPT RULE: every Bengali word must be written in Bengali script. '
      'Never write a Bengali word in Latin letters, never mix scripts '
      'inside one word, and never use Arabic script. English words are '
      'allowed only where the question or guide itself uses English. '
      'whyCorrect and whyOthersWrong must explain the options in the '
      'student\'s language; never put meta-notes such as \'Options '
      'missing\' in any field. '
      'Marks budget: '
      '${budget.guidance} At most ${budget.maxSteps} steps and '
      '${budget.maxLines} lines. Word counts are approximate; '
      'step count and shape are the real control.'
      '$strictNote';
}

/// Hard cap for one grounding block in a TRIMMED retry prompt
/// (2026-11-01 diagnosis: long Bengali prompts + long JSON output
/// never complete on the slow free model, so the retry prompt is
/// deliberately smaller on both input and output). Untrimmed
/// (first-attempt) prompts are untouched — trimming applies only
/// to the retry, never to the quality-first attempt.
String _cap(String s, int n) =>
    s.length <= n ? s : '${s.substring(0, n)}…';

/// Display labels for options, positional: the guide's roman
/// key (i/ii/iii/iv/v) and the screen's Bengali letters (ক/খ/গ/ঘ/ঙ)
/// name the same option by position. Prompts print BOTH so the
/// model can never confuse them.
const _bnOptionLabels = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];
const _romanOptionLabels = ['i', 'ii', 'iii', 'iv', 'v'];

/// Correct-option label, positional ("ক (ii)"). Shared by the
/// structured and plain prompts.
String correctOptionLabel(int idx) {
  final bn = idx < _bnOptionLabels.length ? _bnOptionLabels[idx] : '${idx + 1}';
  final roman =
      idx < _romanOptionLabels.length ? _romanOptionLabels[idx] : '${idx + 1}';
  return '$bn ($roman)';
}

/// Stimulus block, shared by the structured and plain chat
/// prompts: labeled context only, never fused into the question
/// line (the old fuse made a bare-word MCQ read as "only
/// stimulus given, no question"). Empty = the row has none.
String stimulusPromptBlock(GroundedContext ctx) {
  if (ctx.stimulusText.isEmpty) return '';
  final b = StringBuffer()
    ..writeln('উদ্দীপক (stimulus — context only, NOT the question '
        'itself): ${ctx.stimulusText}');
  if (ctx.stimulusRef.isNotEmpty) {
    b.writeln('Stimulus reference: ${ctx.stimulusRef}');
  }
  return b.toString();
}

/// Options block, shared by the structured and plain prompts:
/// verbatim options with both label systems, or the honest none
/// line for an option-less MCQ (never an invitation to invent).
/// Empty = the row is not an MCQ and carries no options.
String optionsPromptBlock(GroundedContext ctx) {
  if (ctx.options.isNotEmpty) {
    final b = StringBuffer()
      ..writeln('Options (verbatim — quote these EXACT texts, never '
          'paraphrase, substitute, or invent wording):');
    for (var i = 0; i < ctx.options.length; i++) {
      b.writeln('${correctOptionLabel(i)}. ${ctx.options[i]}');
    }
    return b.toString();
  }
  if (ctx.questionType == 'mcq') {
    // Backstop only — the UI never calls for an option-less MCQ,
    // but a prompt must never silently invite invented options.
    return 'Options: NONE were provided for this MCQ. Do NOT '
        'invent options and do NOT present a plan as an '
        'explanation; state plainly that the options are missing.\n';
  }
  return '';
}

String structuredUserPrompt(GroundedContext ctx, String style,
    String? followUp, {bool trimmed = false}) {
  final b = StringBuffer();
  // Stimulus FIRST, as its own labeled block — never fused into
  // the question line (the old fuse made a bare-word MCQ read as
  // "only stimulus given, no question"). Context only: the
  // question below is what gets explained.
  b.write(stimulusPromptBlock(ctx));
  b.writeln('Question (verbatim): ${ctx.questionText}');
  // 2026-11-03 fix: options travel WITH the question. The old
  // prompt carried none, so the model either answered "cannot
  // determine" or invented option wording. The correct option is
  // named by exact text + label, never by key letter alone.
  b.write(optionsPromptBlock(ctx));
  if (ctx.answerKey.isNotEmpty) {
    final correct = ctx.correctOptionText;
    final idx = ctx.correctOptionIndex;
    b.writeln('Verified correct answer (the screen shows this '
        'verbatim separately; explain WHY it is correct, and why '
        'the other options are wrong): ${ctx.answerKey}'
        '${correct == null ? '' : " — exact text: '$correct' (option ${correctOptionLabel(idx!)})"}');
  }
  if (ctx.guideUnitText.isNotEmpty) {
    final unit = trimmed ? _cap(ctx.guideUnitText, 1200) : ctx.guideUnitText;
    b.writeln('HIDDEN worked solution for grounding ONLY — never '
        'quote it verbatim; rewrite its steps in your own words: '
        '$unit');
    // 2026-11-03 length rule: the explanation must run at least
    // as long as the guide answer it explains — same length or a
    // little longer, never shorter — unless the student asked
    // for a brief explanation. The count anchors the rule to the
    // text actually sent (capped on trimmed retries).
    final guideWords = unit.trim().split(RegExp(r'\s+')).length;
    b.writeln('Guide answer length: $guideWords words. Your '
        'explanation must be at least $guideWords words long — '
        'the same length or a little longer, never shorter. (If '
        'the student asked for a brief explanation, this length '
        'rule does not apply.)');
  }
  if (ctx.fallbackChunkText.isNotEmpty) {
    final note =
        trimmed ? _cap(ctx.fallbackChunkText, 600) : ctx.fallbackChunkText;
    b.writeln('Guide note (context only): $note');
  }
  // Trimmed retry: the first chapter chunk only, capped — the
  // retry must not re-send the full grounding that just timed out.
  final chunks = trimmed && ctx.chunkTexts.isNotEmpty
      ? [ctx.chunkTexts.first]
      : ctx.chunkTexts;
  for (var i = 0; i < chunks.length; i++) {
    final text = trimmed ? _cap(chunks[i], 800) : chunks[i];
    b.writeln('Book chapter text ${i + 1}: $text');
  }
  final follow = (followUp ?? '').trim();
  if (follow.isNotEmpty) b.writeln('Student follow-up: $follow');
  b.writeln('Style: $style. (short = tighter within the marks '
      'band; simple = simpler words; steps = numbered steps; '
      'examples = add one example step; beautiful = polished '
      'wording, same structure.)');
  return b.toString();
}
