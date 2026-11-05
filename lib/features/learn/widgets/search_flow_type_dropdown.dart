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
  });
  final String label;

  /// String-keyed labels: typeMcq, typeShort, typeCreative,
  /// typePracticeWork, typeTextbookExercise.
  final Map<String, String> labels;
  final SearchFlowType? value;
  final void Function(SearchFlowType?) onChanged;

  String _label(SearchFlowType t) {
    switch (t) {
      case SearchFlowType.mcq:
        return labels['typeMcq']!;
      case SearchFlowType.short:
        return labels['typeShort']!;
      case SearchFlowType.creative:
        return labels['typeCreative']!;
      case SearchFlowType.practiceWork:
        return labels['typePracticeWork']!;
      case SearchFlowType.textbookExercise:
        return labels['typeTextbookExercise']!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SearchFlowType>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: [
        for (final t in SearchFlowType.values)
          DropdownMenuItem<SearchFlowType>(
            value: t,
            child: Text(_label(t)),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
