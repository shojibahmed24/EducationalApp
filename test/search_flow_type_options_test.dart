// Per-subject question types: chemistry / civics get the extra guide
// types (class 9, guide mode only); every other case keeps the five
// original options. Group names match the server's grp_* values.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

void main() {
  List<SearchFlowType> types(String subject,
          {bool guide = true, int cls = 9}) =>
      searchFlowTypesFor(guide: guide, subject: subject, schoolClass: cls);

  test('chemistry class 9 guide offers the five extras after the base five',
      () {
    final t = types('chemistry');
    expect(t.sublist(0, 5), searchFlowBaseTypes);
    expect(t.sublist(5), [
      SearchFlowType.oneWord,
      SearchFlowType.knowledge,
      SearchFlowType.comprehension,
      SearchFlowType.mathProblem,
      SearchFlowType.otherPractice,
    ]);
  });

  test('civics gets knowledge and comprehension only', () {
    expect(types('civics').sublist(5),
        [SearchFlowType.knowledge, SearchFlowType.comprehension]);
  });

  test('math, textbook mode and other classes keep the base five', () {
    expect(types('math'), searchFlowBaseTypes);
    expect(types('chemistry', guide: false), searchFlowBaseTypes);
    expect(types('chemistry', cls: 8), searchFlowBaseTypes);
  });

  test('server section names of the extra types', () {
    expect({
      for (final t in SearchFlowType.values) t: searchFlowGuideSection(t),
    }.entries.where((e) => e.key.index >= 5).map((e) => e.value).toList(), [
      'grp_one_word',
      'grp_knowledge',
      'grp_comprehension',
      'grp_math_problem',
      'grp_other_practice',
    ]);
    expect(searchFlowGuideSection(SearchFlowType.mcq), 'mcq_bank');
  });

  test('extra types have no old-server question-type filter', () {
    expect(searchFlowLegacyQuestionType(SearchFlowType.oneWord), isNull);
    expect(searchFlowLegacyQuestionType(SearchFlowType.creative), 'creative');
  });
}
