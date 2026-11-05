// Route: /register/medium (Step 5/13)
// UI ONLY - saves to local mock registrationDataNotifier.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/reg_step05_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step05Medium extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const Step05Medium({super.key, this.onNext, this.onBack});

  @override
  State<Step05Medium> createState() => _Step05MediumState();
}

class _Step05MediumState extends State<Step05Medium> with RegLangMixin {
  String _medium = registrationDataNotifier.value.medium;

  void _next() {
    if (_medium.isNotEmpty) {
      updateRegistration(
          registrationDataNotifier.value.copyWith(medium: _medium));
    }
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/school');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep05Bn : regStep05En;
    return RegScaffold(
      step: 5,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      nextEnabled: _medium.isNotEmpty,
      onNext: _next,
      onBack: widget.onBack,
      // Side by side (not stacked): the two medium cards share the
      // row equally and stretch to the same height. IntrinsicHeight
      // is required: the scaffold body scrolls (unbounded height),
      // and a stretching Row under unbounded height crashes layout
      // ("BoxConstraints forces an infinite height").
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: OptionCard(
                emoji: '🇧🇩',
                title: s['bangla']!,
                subtitle: s['banglaSub']!,
                selected: _medium == 'bn',
                onTap: () => setState(() => _medium = 'bn'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OptionCard(
                emoji: '🇬🇧',
                title: s['english']!,
                subtitle: s['englishSub']!,
                selected: _medium == 'en',
                onTap: () => setState(() => _medium = 'en'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
