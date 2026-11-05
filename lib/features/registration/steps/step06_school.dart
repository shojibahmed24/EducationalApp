// Route: /register/school (Step 6/13, optional)
// UI ONLY - saves to local mock registrationDataNotifier.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/reg_step06_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step06School extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  const Step06School({super.key, this.onNext, this.onBack, this.onSkip});

  @override
  State<Step06School> createState() => _Step06SchoolState();
}

class _Step06SchoolState extends State<Step06School> with RegLangMixin {
  late final _school =
      TextEditingController(text: registrationDataNotifier.value.schoolName);
  late final _district =
      TextEditingController(text: registrationDataNotifier.value.district);

  void _saveAndGo() {
    updateRegistration(registrationDataNotifier.value.copyWith(
      schoolName: _school.text.trim(),
      district: _district.text.trim(),
    ));
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/contact');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep06Bn : regStep06En;
    return RegScaffold(
      step: 6,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: _saveAndGo,
      onBack: widget.onBack,
      showSkip: true,
      onSkip: widget.onSkip ?? _saveAndGo,
      skipRoute: '/register/contact',
      child: Column(
        children: [
          RegTextField(
              label: s['school']!,
              hint: s['schoolHint']!,
              controller: _school),
          const SizedBox(height: 16),
          RegTextField(
              label: s['district']!,
              hint: s['districtHint']!,
              controller: _district),
        ],
      ),
    );
  }
}
