// Question card above the chat messages for guide chats
// (2026-11-03 chat fix): the tutor UI must clearly show WHICH
// question the chat was opened for — question text + verbatim
// options from the selection. It renders only what the
// selection actually carries; nothing is invented. When the
// selection carries neither, only the label shows — itself an
// honest signal that context is absent.
import 'package:flutter/material.dart';

import '../lesson_selection.dart';

const _bnLabels = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];

class ChatQuestionCard extends StatelessWidget {
  const ChatQuestionCard({super.key, required this.sel, required this.s});
  final LessonSelection sel;
  final Map<String, String> s;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s['chatForQuestion']!,
          style: style?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (sel.queryText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(sel.queryText, style: style),
        ],
        for (var i = 0; i < sel.guideOptions.length; i++)
          Text(
            '${i < _bnLabels.length ? _bnLabels[i] : '${i + 1}'}. '
            '${sel.guideOptions[i]}',
            style: style,
          ),
      ],
    );
  }
}
