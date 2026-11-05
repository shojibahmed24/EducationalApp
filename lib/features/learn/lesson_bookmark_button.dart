// Bookmark button for the lesson app bar, split out to keep
// lesson_screen.dart under the 250-line file limit.
import 'package:flutter/material.dart';

import '../../core/services/local_store.dart';
import 'learn_store.dart';
import 'lesson_selection.dart';

class LessonBookmarkButton extends StatelessWidget {
  const LessonBookmarkButton({
    super.key,
    required this.sel,
    required this.saved,
    required this.s,
    required this.onSavedChanged,
  });
  final LessonSelection sel;
  final bool saved;
  final Map<String, String> s;
  final void Function(bool saved) onSavedChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
      onPressed: () async {
        final nowSaved = await LearnStore.toggleSaved(sel.key);
        if (nowSaved) await LocalStore.saveQuestion(sel.key);
        if (!context.mounted) return;
        onSavedChanged(nowSaved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nowSaved ? s['saved']! : s['unsaved']!),
          ),
        );
      },
    );
  }
}
