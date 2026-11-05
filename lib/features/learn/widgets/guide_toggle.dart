// Chapter-screen source toggle: textbook (default) | guide.
// Route-driven tabs: the parent navigates on change; this widget
// holds no navigation logic and no data of its own.
import 'package:flutter/material.dart';

class GuideToggle extends StatelessWidget {
  const GuideToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.s,
  });
  final String value; // 'textbook' | 'guide'
  final ValueChanged<String> onChanged;
  final Map<String, String> s;

  @override
  Widget build(BuildContext context) {
    // UI palette (গ): selected segment gets a primary tint so the
    // textbook | guide choice reads at a glance in both modes.
    return SegmentedButton<String>(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
      ),
      segments: [
        ButtonSegment(
          value: 'textbook',
          label: Text(s['textbookTab']!),
          icon: const Icon(Icons.menu_book),
        ),
        ButtonSegment(
          value: 'guide',
          label: Text(s['guideTab']!),
          icon: const Icon(Icons.assignment),
        ),
      ],
      selected: {value},
      onSelectionChanged: (sel) {
        if (sel.isNotEmpty) onChanged(sel.first);
      },
    );
  }
}
