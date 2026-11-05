// Marks-calibrated answer length (locked 2026-10-29; detailed
// shape spec added 2026-10-31 from MARKS_ANSWER_TRAINING_PLAN
// §4). The AI answer must match the PRINTED marks: never so
// short that marks are lost, never so long it cannot be written
// in an exam. Word counts are approximate by design — LLMs do
// not count words exactly — so step count and shape are the
// real control, enforced as a prompt budget plus one retry when
// the step count is far off-band. Marks are printed-only:
// unprinted marks fall back to a TYPE default for the budget
// computation only, and the UI must never display that default
// as if it were printed. This guidance shapes AI EXPLANATIONS
// only (lesson, chat, guide stage 2) — never the verbatim
// stage-1 display, which keeps the guide's own length
// (verbatim-first, 2026-10-31, superseding the plan's old
// never-verbatim line). The Edge marksBudget function must
// carry the identical texts; a test pins the caps, and the
// mirror is verified by diff at change time.

/// Step/line budget for one answer.
class MarksBudget {
  final int marks;
  final int maxSteps;
  final int maxLines;
  final String guidance;
  const MarksBudget({
    required this.marks,
    required this.maxSteps,
    required this.maxLines,
    required this.guidance,
  });
}

int _defaultMarks(String questionType, String? sectionLabel) {
  switch (questionType) {
    case 'mcq':
      return 1;
    case 'short':
      return 2;
    case 'creative':
    case 'problem':
      // Creative sub-parts carry their own printed marks when
      // present; without them, ক→ঘ order is the only honest
      // default (budget only, never displayed as printed).
      switch (sectionLabel) {
        case 'ক':
          return 1;
        case 'খ':
          return 2;
        case 'গ':
          return 3;
        case 'ঘ':
          return 4;
        default:
          return 3;
      }
    default:
      // Unknown type (including textbook Mode A rows, which
      // carry no question type): neutral middle band. A short
      // default here would squeeze long language-subject
      // answers; a long default would pad short ones. Budget
      // only, never displayed as printed marks.
      return 3;
  }
}

/// MCQ shape rule, appended to the band guidance whenever the
/// question is an MCQ (any band): correct option + short why,
/// never a long wrong-option discussion, never "memorize this".
const _mcqGuidance = ' MCQ: correct option + 1-2 lines why it '
    'is correct; at most one line on why the rest are not; '
    'never present the key as something to memorize.';

/// Budget for one answer. [marks] is the PRINTED mark count, or
/// null when the guide prints none (type default is then used).
/// Caps are unchanged from the locked bands; only the guidance
/// grew from one line to the full §4 shape spec. The Edge
/// marksBudget texts must match these exactly.
MarksBudget marksBudgetFor({
  int? marks,
  required String questionType,
  String? sectionLabel,
}) {
  final m = (marks ?? _defaultMarks(questionType, sectionLabel))
      .clamp(1, 10);
  final String base;
  final int maxSteps;
  final int maxLines;
  switch (m) {
    case 1:
      maxSteps = 2;
      maxLines = 4;
      base = '1 mark: direct answer first (value, name, or one '
          'line), then 1-2 lines why — one formula or reason in '
          'one line. At most 2 steps, 4 lines, about 20-40 '
          'words. No preamble, no conclusion, no detailed '
          'explanation, no alternative method.';
    case 2:
      maxSteps = 4;
      maxLines = 10;
      base = '2 marks: 2-4 steps or points, each step = work + '
          'one short reason; the result in one line at the end. '
          'At most 4 steps, 10 lines, about 40-80 words. No '
          'long preamble, no conclusion paragraph, never split '
          'one step\'s work into three steps to pad.';
    case 3:
      maxSteps = 7;
      maxLines = 18;
      base = '3 marks: state the formula or rule, substitute '
          'the values, then step-by-step calculation with a '
          'brief reason for each step, then the result. '
          'Language subjects: points, each with a one-line '
          'reason or example. At most 7 steps, 18 lines, about '
          '80-150 words. No irrelevant background, never repeat '
          'the same reason twice.';
    case 4:
      maxSteps = 10;
      maxLines = 28;
      base = '4 marks: full steps with reasoning, each step '
          'with its reason, plus a final VERIFICATION line as '
          'the closing check (plug the value back, or check '
          'the units) — never end abruptly without it. '
          'Creative parts ক/খ/গ/ঘ are written separately, each '
          'at its own marks length, never mixed across parts. '
          'At most 10 steps, 28 lines, about 150-250 words. '
          'No long intro paragraph.';
    default:
      maxSteps = 14;
      maxLines = 45;
      base = '$m marks: full structure — a 3-4 line intro (what '
          'the question asks), full steps with reasons, '
          'a 3-4 line conclusion. Length grows only through '
          'reasoning and verification, never padding. At most '
          '14 steps, 45 lines, about 250-400 words. Never add '
          'unnecessary parts.';
  }
  return MarksBudget(
    marks: m,
    maxSteps: maxSteps,
    maxLines: maxLines,
    guidance: questionType == 'mcq' ? base + _mcqGuidance : base,
  );
}

/// True when [stepCount] is far enough off-band to justify the
/// one retry: clearly too long, or (for 3+ marks) clearly too
/// short to earn the marks. Small deviations are accepted —
/// bands are approximate, not word counts.
bool stepsFarOffBudget(int stepCount, MarksBudget budget) {
  if (stepCount > budget.maxSteps + 2) return true;
  if (budget.marks >= 3 && stepCount < budget.maxSteps ~/ 2) return true;
  return false;
}
