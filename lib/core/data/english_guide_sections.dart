// English 1st paper section vocabulary (ENGLISH_REDO_PLAN §3, locked).
// This list is the ONLY section vocabulary the app may offer for the
// English guide search flow. Paper-II values (gapbox, prefix, suffix,
// tag, transform, verbs, connector, preposition, punctuation) are
// DELIBERATELY ABSENT: Paper-II is a separate subject (owner
// correction 2026-11-01), never a filter inside English 1st paper,
// and never separated by a `paper` tag. Adding a value here needs a
// plan-file change agreed with the data track — never invent one.

/// Paper-I sections in plan order (Q1–Q11, then writing-bank items).
/// true-false sits after mcq (owner standing rule 2026-11-01: all
/// true/false always stays true/false, never converted to mcq).
const englishPaperOneSections = [
  'mcq',
  'true-false',
  'short',
  'gapfill',
  'table',
  'summary',
  'matching',
  'rearranging',
  'poem',
  'story',
  'writing-story',
  'writing-dialogue',
  'writing-paragraph',
  'writing-letter',
  'writing-graph',
  'writing-composition',
  'writing-email',
];

/// True when [value] is a locked Paper-I section value.
bool isEnglishPaperOneSection(String? value) =>
    value != null && englishPaperOneSections.contains(value);

/// search_flow_strings key for a section's dropdown label.
String englishSectionStringKey(String value) {
  switch (value) {
    case 'mcq':
      return 'sectionMcq';
    case 'true-false':
      return 'sectionTrueFalse';
    case 'short':
      return 'sectionShort';
    case 'gapfill':
      return 'sectionGapfill';
    case 'table':
      return 'sectionTable';
    case 'summary':
      return 'sectionSummary';
    case 'matching':
      return 'sectionMatching';
    case 'rearranging':
      return 'sectionRearranging';
    case 'poem':
      return 'sectionPoem';
    case 'story':
      return 'sectionStory';
    case 'writing-story':
      return 'sectionWritingStory';
    case 'writing-dialogue':
      return 'sectionWritingDialogue';
    case 'writing-paragraph':
      return 'sectionWritingParagraph';
    case 'writing-letter':
      return 'sectionWritingLetter';
    case 'writing-graph':
      return 'sectionWritingGraph';
    case 'writing-composition':
      return 'sectionWritingComposition';
    case 'writing-email':
      return 'sectionWritingEmail';
    default:
      return 'sectionMcq';
  }
}
