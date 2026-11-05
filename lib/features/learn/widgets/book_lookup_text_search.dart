// Question-text search box (Edge Function Mode B, via
// explanation_service.resolveByText on the screen). The button stays
// disabled until at least 3 characters are typed, matching Mode B's
// minimum. No match is reported honestly — never a substitute.
import 'package:flutter/material.dart';

class BookLookupTextSearch extends StatelessWidget {
  const BookLookupTextSearch({
    super.key,
    required this.controller,
    required this.s,
    required this.busy,
    required this.state,
    required this.enabled,
    required this.onSearch,
    required this.onChanged,
  });
  final TextEditingController controller;
  final Map<String, String> s;
  final bool busy;
  final String state; // '' | 'edge-missing' | 'not-found'
  final bool enabled;
  final VoidCallback onSearch;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s['textSearchLabel']!,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: s['textSearchHint']!),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: enabled && !busy ? onSearch : null,
          child: Text(busy ? s['searching']! : s['textSearchButton']!),
        ),
        if (state == 'edge-missing') ...[
          const SizedBox(height: 12),
          Text(s['edgeMissing']!),
        ] else if (state == 'not-found') ...[
          const SizedBox(height: 12),
          Text(s['noTextMatch']!),
          const SizedBox(height: 6),
          Text(s['askExact']!),
        ],
      ],
    );
  }
}
