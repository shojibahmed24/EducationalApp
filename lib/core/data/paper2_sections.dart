// English 2nd paper section vocabulary (Phase 1, gap plan).
// This list is the ONLY section vocabulary the app may offer for
// the English-2nd guide search flow, and it shows ONLY when the
// subject is 'english-2nd'. These values are DELIBERATELY ABSENT
// from english_guide_sections.dart (Paper-I) and from the generic
// Paper-I section field: Paper-II is a separate subject (owner
// correction 2026-11-01), never a filter inside English 1st paper.
//
// Order is the exam Q1–Q12 order: the ten grammar sections first
// (Q1–Q10 in list order), then the five writing options, which
// are alternatives inside the writing questions and therefore
// carry no per-value question number in their labels.

/// Paper-II sections in exam order. Every value is an exact
/// LIST_SECTION_VALUES member on the server (list.ts), so the
/// chapterless list filter accepts it verbatim.
const paperTwoSections = [
  'gapbox',
  'table',
  'verbs',
  'transform',
  'tag',
  'suffix',
  'prefix',
  'preposition',
  'connector',
  'punctuation',
  'writing-paragraph',
  'writing-email',
  'writing-letter',
  'writing-application',
  'writing-composition',
];

/// True when [value] is a locked Paper-II section value.
bool isPaperTwoSection(String? value) =>
    value != null && paperTwoSections.contains(value);

/// search_flow_strings key for a section's dropdown label.
String paperTwoSectionStringKey(String value) {
  switch (value) {
    case 'gapbox':
      return 'paper2SectionGapbox';
    case 'table':
      return 'paper2SectionTable';
    case 'verbs':
      return 'paper2SectionVerbs';
    case 'transform':
      return 'paper2SectionTransform';
    case 'tag':
      return 'paper2SectionTag';
    case 'suffix':
      return 'paper2SectionSuffix';
    case 'prefix':
      return 'paper2SectionPrefix';
    case 'preposition':
      return 'paper2SectionPreposition';
    case 'connector':
      return 'paper2SectionConnector';
    case 'punctuation':
      return 'paper2SectionPunctuation';
    case 'writing-paragraph':
      return 'paper2SectionWritingParagraph';
    case 'writing-email':
      return 'paper2SectionWritingEmail';
    case 'writing-letter':
      return 'paper2SectionWritingLetter';
    case 'writing-application':
      return 'paper2SectionWritingApplication';
    case 'writing-composition':
      return 'paper2SectionWritingComposition';
    default:
      return 'paper2SectionGapbox';
  }
}
