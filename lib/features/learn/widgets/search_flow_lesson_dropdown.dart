// Lesson dropdown for the new search flow (guide mode only).
// Rendered ONLY when [lessons] is non-empty: when the selected
// chapter has no lesson-tagged rows, the search screen skips this
// step entirely (plan §1) instead of showing an empty dropdown.
// The first entry is "all lessons" (null): lesson is a filter the
// student may leave open, never a forced choice.
import 'package:flutter/material.dart';

class SearchFlowLessonDropdown extends StatelessWidget {
  const SearchFlowLessonDropdown({
    super.key,
    required this.label,
    required this.allLabel,
    required this.lessons,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String allLabel;

  /// Lesson code -> verified title, in display order.
  final Map<String, String> lessons;
  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: [
        DropdownMenuItem<String>(value: null, child: Text(allLabel)),
        for (final e in lessons.entries)
          DropdownMenuItem<String>(
            value: e.key,
            child: Text('${e.key} · ${e.value}'),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
