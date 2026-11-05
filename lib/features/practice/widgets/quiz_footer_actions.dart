// Quiz footer actions (split out of quiz_question_screen.dart
// to keep it under the 250-line cap): save toggle, skip, and
// view-saved buttons. Owns its saved-ids state (loaded once
// from LocalStore); the screen no longer tracks saved ids.
// Save semantics unchanged (H3): 'saved' only on a genuinely
// new save, 'removed' only on a real removal.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/local_store.dart';
import '../../../core/services/practice_service.dart';

class QuizFooterActions extends StatefulWidget {
  const QuizFooterActions({
    super.key,
    required this.questionId,
    required this.s,
    required this.onSkip,
  });
  final String questionId;
  final Map<String, String> s;
  final VoidCallback onSkip;

  @override
  State<QuizFooterActions> createState() => _QuizFooterActionsState();
}

class _QuizFooterActionsState extends State<QuizFooterActions> {
  final Set<String> _savedIds = {};

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final ids = await LocalStore.savedQuestions();
    if (mounted) setState(() => _savedIds.addAll(ids));
  }

  Future<void> _toggleSave() async {
    final s = widget.s;
    final id = widget.questionId;
    if (_savedIds.contains(id)) {
      final removed = await LocalStore.unsaveQuestion(id);
      if (!mounted) return;
      setState(() => _savedIds.remove(id));
      if (removed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s['unsavedMsg']!)));
      }
    } else {
      final newlySaved = await practiceService.saveQuestion(id);
      if (!mounted) return;
      setState(() => _savedIds.add(id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              newlySaved ? s['savedMsg']! : s['alreadySavedMsg']!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isSaved = _savedIds.contains(widget.questionId);
    return Column(children: [
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleSave,
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            label: Text(isSaved ? s['savedState']! : s['save']!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton(
            onPressed: widget.onSkip,
            child: Text(s['skip']!),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () => context.go('/saved'),
            icon: const Icon(Icons.bookmark),
            label: Text(s['viewSaved']!),
          ),
        ),
      ]),
    ]);
  }
}
