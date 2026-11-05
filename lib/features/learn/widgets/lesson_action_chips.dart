import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lesson action chips. Style chips now CALL BACK into the lesson
/// screen, which really regenerates the answer (DEMO transform or
/// OpenRouter after the grounding check). Chat opens the text chat
/// with this question's context. No voice here, by design.
class LessonActionChips extends StatelessWidget {
  const LessonActionChips({
    super.key,
    required this.shorten,
    required this.simpler,
    required this.stepByStep,
    required this.moreExamples,
    required this.beautiful,
    required this.askInChat,
    required this.onStyle,
  });
  final String shorten;
  final String simpler;
  final String stepByStep;
  final String moreExamples;
  final String beautiful;
  final String askInChat;
  final void Function(String style) onStyle;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, String)>[
      (shorten, 'short'),
      (simpler, 'simple'),
      (stepByStep, 'steps'),
      (moreExamples, 'examples'),
      (beautiful, 'beautiful'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips
              .map((c) => ActionChip(
                    label: Text(c.$1),
                    onPressed: () => onStyle(c.$2),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => context.go('/lesson/chat'),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(askInChat),
        ),
      ],
    );
  }
}
