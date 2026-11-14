// Question types of the search flow and which ones a subject
// offers. The first five are the original dropdown options, the
// same everywhere. The other five exist only where the guide keeps
// a kind of question under its own section name (class 9 chemistry
// and civics): they are asked for by a server-side group name
// (grp_*), so no database row is renamed. Every group is an exact
// list of raw section names on the server (list.ts SECTION_GROUPS);
// nothing is matched by guesswork. There is deliberately NO "all
// questions" option: a list always loads one type, 20 at a time.
enum SearchFlowType {
  mcq,
  short,
  creative,
  practiceWork,
  textbookExercise,
  oneWord,
  knowledge,
  comprehension,
  mathProblem,
  otherPractice,
  exercise,
  activity,
  exerciseMcq,
}

/// The five original options (textbook mode and every subject
/// without extra guide sections).
const searchFlowBaseTypes = [
  SearchFlowType.mcq,
  SearchFlowType.short,
  SearchFlowType.creative,
  SearchFlowType.practiceWork,
  SearchFlowType.textbookExercise,
];

/// Extra guide types per class 9 subject, in exam order: the
/// 1-mark one-word answers first, then knowledge (জ্ঞানমূলক) and
/// comprehension (অনুধাবনমূলক), then the numeric problems.
const _extraGuideTypes = <String, List<SearchFlowType>>{
  'chemistry': [
    SearchFlowType.oneWord,
    SearchFlowType.knowledge,
    SearchFlowType.comprehension,
    SearchFlowType.mathProblem,
    SearchFlowType.otherPractice,
  ],
  'civics': [SearchFlowType.knowledge, SearchFlowType.comprehension],
};

/// Class 9 Higher Math keeps its textbook exercise, activity and
/// exercise MCQs under their own section names (exercise, activity,
/// exercise-mcq), none under textbook_exercise / practice_work, so
/// it lists its own three instead of those two base types.
const _higherMathTypes = [
  SearchFlowType.mcq,
  SearchFlowType.short,
  SearchFlowType.creative,
  SearchFlowType.exercise,
  SearchFlowType.activity,
  SearchFlowType.exerciseMcq,
];

/// Types a dropdown / picker offers. Extras only in guide mode.
List<SearchFlowType> searchFlowTypesFor({
  required bool guide,
  required String subject,
  required int schoolClass,
}) {
  if (guide && schoolClass == 9 && subject == 'higher-math') {
    return _higherMathTypes;
  }
  return [
    ...searchFlowBaseTypes,
    if (guide && schoolClass == 9) ...?_extraGuideTypes[subject],
  ];
}

/// String-map key of each type's label. Looked up lazily: only the
/// asked type's key must exist in the strings map.
const _labelKeys = {
  SearchFlowType.mcq: 'typeMcq',
  SearchFlowType.short: 'typeShort',
  SearchFlowType.creative: 'typeCreative',
  SearchFlowType.practiceWork: 'typePracticeWork',
  SearchFlowType.textbookExercise: 'typeTextbookExercise',
  SearchFlowType.oneWord: 'typeOneWord',
  SearchFlowType.knowledge: 'typeKnowledge',
  SearchFlowType.comprehension: 'typeComprehension',
  SearchFlowType.mathProblem: 'typeMathProblem',
  SearchFlowType.otherPractice: 'typeOtherPractice',
  SearchFlowType.exercise: 'typeTextbookExercise',
  SearchFlowType.activity: 'typeActivity',
  SearchFlowType.exerciseMcq: 'typeExerciseMcq',
};

/// Dropdown label for a search-flow type.
String searchFlowTypeLabel(SearchFlowType t, Map<String, String> s) =>
    s[_labelKeys[t]!]!;

/// Guide-bank `section` value for a dropdown option (guide mode).
/// The grp_* names are server-side groups of raw section names.
String searchFlowGuideSection(SearchFlowType type) => {
  SearchFlowType.mcq: 'mcq_bank',
  SearchFlowType.short: 'short',
  SearchFlowType.creative: 'creative',
  SearchFlowType.practiceWork: 'practice_work',
  SearchFlowType.textbookExercise: 'textbook_exercise',
  SearchFlowType.oneWord: 'grp_one_word',
  SearchFlowType.knowledge: 'grp_knowledge',
  SearchFlowType.comprehension: 'grp_comprehension',
  SearchFlowType.mathProblem: 'grp_math_problem',
  SearchFlowType.otherPractice: 'grp_other_practice',
  SearchFlowType.exercise: 'grp_exercise',
  SearchFlowType.activity: 'grp_activity',
  SearchFlowType.exerciseMcq: 'grp_exercise_mcq',
}[type]!;

/// Types with a server-side questionType filter on the OLD guide
/// server (v7 rows carry question_type but no section/lesson):
/// only MCQ / short / creative can be filtered client-side there.
/// Every other type needs the new server's section filter — on the
/// old server it is honestly unavailable, never faked.
String? searchFlowLegacyQuestionType(SearchFlowType type) => {
  SearchFlowType.mcq: 'mcq',
  SearchFlowType.short: 'short',
  SearchFlowType.creative: 'creative',
}[type];
