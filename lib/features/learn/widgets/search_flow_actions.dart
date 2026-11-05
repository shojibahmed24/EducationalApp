// Bottom actions for the search screen, extracted verbatim
// 2026-11-01 to keep search_flow_screen.dart under the
// 250-line cap. Pure rendering: the parent owns canSubmit /
// jumping state and the list / jump callbacks. No behavior
// change: same hint, same buttons, same enable conditions.
import 'package:flutter/material.dart';

class SearchFlowActions extends StatelessWidget {
  const SearchFlowActions({
    super.key,
    required this.canSubmit,
    required this.jumping,
    required this.actionHint,
    required this.s,
    required this.onShowList,
    required this.onJump,
  });
  final bool canSubmit;
  final bool jumping;
  final String? actionHint;
  final Map<String, String> s;
  final VoidCallback onShowList;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    // Local capture: fields do not promote, so the null check
    // below needs this local for Text(hint) to type-check.
    final hint = actionHint;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(hint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ElevatedButton(
                onPressed: canSubmit ? onShowList : null,
                child: Text(s['showList']!)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: canSubmit && !jumping ? onJump : null,
              child: Text(jumping ? s['jumpChecking']! : s['jumpButton']!),
            ),
          ],
        ),
      ),
    );
  }
}
