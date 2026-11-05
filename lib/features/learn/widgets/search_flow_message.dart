// List-screen message state (unavailable / filter-pending /
// empty), split out of search_flow_list_screen.dart to keep
// that file under the 250-line cap. Back returns to search;
// a failed list is retried by re-entering it (fresh _load).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Widget searchFlowMessage(
  BuildContext context,
  String title,
  String body,
  Map<String, String> s,
  String back,
) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(body),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.go(back),
          child: Text(s['backToSearch']!),
        ),
      ],
    ),
  );
}
