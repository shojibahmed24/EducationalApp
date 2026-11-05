// End card for the English reader: shown after the last
// question, with the seen-group count and a way back.
import 'package:flutter/material.dart';

class EnglishReaderEndCard extends StatelessWidget {
  const EnglishReaderEndCard({
    super.key,
    required this.seenCount,
    required this.groupCount,
    required this.s,
    required this.onBack,
  });
  final int seenCount;
  final int groupCount;
  final Map<String, String> s;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s['readerEndTitle']!),
          const SizedBox(height: 8),
          Text('${s['readerEndSeen']!} $seenCount/$groupCount'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onBack,
            child: Text(s['readerBackToList']!),
          ),
        ],
      ),
    );
  }
}
