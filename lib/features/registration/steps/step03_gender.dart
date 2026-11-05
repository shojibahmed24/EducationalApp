// Route: /register/gender (Step 3/13)
// Gender appears ONLY here, nowhere else in the app.
// UI ONLY - saves to local mock registrationDataNotifier.
// Phase 17 (L6): Next vs Skip are genuinely different paths —
// Next saves the tapped gender (or skips empty), Skip discards any
// selection and moves on; the scaffold renders Skip as a distinct
// outlined icon button, not a second Next.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/reg_step03_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step03Gender extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  const Step03Gender({super.key, this.onNext, this.onBack, this.onSkip});

  @override
  State<Step03Gender> createState() => _Step03GenderState();
}

class _Step03GenderState extends State<Step03Gender> with RegLangMixin {
  String _gender = registrationDataNotifier.value.gender;

  void _go(String? gender) {
    if (gender != null) {
      updateRegistration(
          registrationDataNotifier.value.copyWith(gender: gender));
    }
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/class');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep03Bn : regStep03En;
    return RegScaffold(
      step: 3,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: () => _go(_gender.isEmpty ? null : _gender),
      onBack: widget.onBack,
      showSkip: true,
      onSkip: widget.onSkip ?? () => _go(null),
      skipRoute: '/register/class',
      child: Row(
        children: [
          Expanded(
            child: OptionCard(
              emoji: '👦',
              title: s['boy']!,
              subtitle: '',
              selected: _gender == 'boy',
              onTap: () => setState(() => _gender = 'boy'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OptionCard(
              emoji: '👧',
              title: s['girl']!,
              subtitle: '',
              selected: _gender == 'girl',
              onTap: () => setState(() => _gender = 'girl'),
            ),
          ),
        ],
      ),
    );
  }
}
