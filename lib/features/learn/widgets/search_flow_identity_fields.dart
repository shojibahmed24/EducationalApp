// Identity fields for the search screen: class, subject, source
// dropdowns. Split out so the screen stays under the 250-line
// cap. The widget only renders; the screen owns refreshes and
// the English host update behind the callbacks.
import 'package:flutter/material.dart';

import '../search_flow_controller.dart';
import 'search_flow_field.dart';

class SearchFlowIdentityFields extends StatelessWidget {
  const SearchFlowIdentityFields({
    super.key,
    required this.controller,
    required this.s,
    required this.bn,
    required this.onClass,
    required this.onSubject,
    required this.onSource,
  });
  final SearchFlowController controller;
  final Map<String, String> s;
  final bool bn;
  final void Function(int value) onClass;
  final void Function(String value) onSubject;
  final void Function(String value) onSource;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    final classItems = {6, 7, controller.schoolClass}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchFlowDropdownField<int>(
          label: s['classLabel']!, icon: Icons.school,
          value: controller.schoolClass,
          items: classItems.map((c) => SearchFlowDropdownItem(value: c, label: '$c')).toList(),
          onChanged: (v) {
            if (v != null) onClass(v);
          },
        ),
        gap,
        SearchFlowDropdownField<String>(
          label: s['subjectLabel']!, icon: Icons.book,
          value: controller.subjects.any((x) => x.id == controller.subjectId) ? controller.subjectId : null,
          hint: s['subjectLabel']!,
          items: controller.subjects.map((x) => SearchFlowDropdownItem(value: x.id, label: x.name(bn))).toList(),
          onChanged: (v) {
            if (v != null) onSubject(v);
          },
        ),
        gap,
        SearchFlowDropdownField<String>(
          label: s['sourceLabel']!, icon: Icons.source,
          value: controller.source,
          items: [
            SearchFlowDropdownItem(value: 'textbook', label: s['sourceTextbook']!),
            SearchFlowDropdownItem(value: 'guide', label: s['sourceGuide']!),
          ],
          onChanged: (v) {
            if (v != null) onSource(v);
          },
        ),
      ],
    );
  }
}
