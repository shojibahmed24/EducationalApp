// Type dropdown for the new search flow: EXACTLY the 5 approved
// options, the same in textbook and guide mode. There is NO
// "all questions" option: a list always loads one type, 20 rows
// at a time (plan §1). Labels come from the strings map, never
// hardcoded here.
import 'package:flutter/material.dart';

import '../search_flow_types.dart';

class SearchFlowTypeDropdown extends StatelessWidget {
  const SearchFlowTypeDropdown({
    super.key,
    required this.label,
    required this.labels,
    required this.value,
    required this.onChanged,
    this.types = searchFlowBaseTypes,
  });
  final String label;

  /// String-keyed labels: typeMcq, typeShort, typeCreative,
  /// typePracticeWork, typeTextbookExercise.
  final Map<String, String> labels;
  final SearchFlowType? value;
  final void Function(SearchFlowType?) onChanged;
  final List<SearchFlowType> types;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SearchFlowType>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: [
        for (final t in types)
          DropdownMenuItem<SearchFlowType>(
            value: t,
            child: Text(searchFlowTypeLabel(t, labels)),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
