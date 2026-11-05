// Route: /register/goal (Step 10/13)
// UI ONLY - saves to local mock registrationDataNotifier.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/reg_step10_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step10Goal extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const Step10Goal({super.key, this.onNext, this.onBack});

  @override
  State<Step10Goal> createState() => _Step10GoalState();
}

class _Step10GoalState extends State<Step10Goal> with RegLangMixin {
  int _goal = registrationDataNotifier.value.dailyGoalMinutes;

  void _next() {
    updateRegistration(
        registrationDataNotifier.value.copyWith(dailyGoalMinutes: _goal));
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/guardian');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep10Bn : regStep10En;
    final options = [
      (15, s['min15']!, s['min15Sub']!),
      (30, s['min30']!, s['min30Sub']!),
      (60, s['min60']!, s['min60Sub']!),
    ];
    return RegScaffold(
      step: 10,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: _next,
      onBack: widget.onBack,
      child: Column(
        children: [
          for (final o in options) ...[
            OptionCard(
              emoji: '⏱️',
              title: o.$2,
              subtitle: o.$3,
              selected: _goal == o.$1,
              onTap: () => setState(() => _goal = o.$1),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
