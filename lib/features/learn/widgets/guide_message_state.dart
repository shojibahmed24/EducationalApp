// Shared empty/unavailable/failed state: title, optional body,
// one button. Used by the bank, answer and tab screens so none of
// them duplicates the same layout (and stays under 250 lines).
import 'package:flutter/material.dart';

class GuideMessageState extends StatelessWidget {
  const GuideMessageState({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
    this.body = '',
  });
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(body),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
