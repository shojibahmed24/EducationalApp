// English guide section picker (ENGLISH_REDO_PLAN §2 step 6, §3).
// Renders the shared SearchFlowDropdownField with the locked
// Paper-I vocabulary; Paper-II values are deliberately absent
// (separate subject, owner correction 2026-11-01). Theme-aware
// via the shared field; no content is invented here.
import 'package:flutter/material.dart';

import '../../../core/data/english_guide_sections.dart';
import '../../../core/data/english_redesign.dart';
import 'search_flow_field.dart';

class SearchFlowSectionField extends StatelessWidget {
  const SearchFlowSectionField({
    super.key,
    required this.value,
    required this.s,
    required this.onChanged,
    this.values,
  });
  final String? value;
  final Map<String, String> s;
  final void Function(String?) onChanged;

  /// Picker vocabulary. Defaults to the locked Paper-I list
  /// (old flow); the English redesign passes its 12 entries.
  final List<String>? values;

  @override
  Widget build(BuildContext context) {
    return SearchFlowDropdownField<String>(
      label: s['sectionLabel']!,
      icon: Icons.list_alt,
      value: value,
      hint: s['sectionLabel']!,
      items: [
        for (final v in values ?? englishPaperOneSections)
          SearchFlowDropdownItem(
              value: v, label: s[englishRedesignSectionStringKey(v)]!),
      ],
      onChanged: onChanged,
    );
  }
}
