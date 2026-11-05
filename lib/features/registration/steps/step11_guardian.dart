// Route: /register/guardian (Step 11/13, optional, for Parent Mode)
// UI ONLY - saves to local mock registrationDataNotifier.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/pages/reg_step11_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step11Guardian extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  const Step11Guardian({super.key, this.onNext, this.onBack, this.onSkip});

  @override
  State<Step11Guardian> createState() => _Step11GuardianState();
}

class _Step11GuardianState extends State<Step11Guardian> with RegLangMixin {
  late final _name =
      TextEditingController(text: registrationDataNotifier.value.guardianName);
  late final _phone = TextEditingController(
      text: registrationDataNotifier.value.guardianPhone);
  String? _error;

  void _saveAndGo() {
    // Phase 17 (L6): optional guardian phone, if written, gets the
    // same basic 01… check as Step 7; empty stays allowed (optional).
    final phone = _phone.text.trim();
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneOk = phone.isEmpty ||
        (digits.length == 11 && digits.startsWith('01')) ||
        (digits.length == 13 && digits.startsWith('8801'));
    if (!phoneOk) {
      setState(() => _error =
          (isBangla ? regStep11Bn : regStep11En)['phoneError']);
      return;
    }
    updateRegistration(registrationDataNotifier.value.copyWith(
      guardianName: _name.text.trim(),
      guardianPhone: _phone.text.trim(),
    ));
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/review');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep11Bn : regStep11En;
    return RegScaffold(
      step: 11,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: _saveAndGo,
      onBack: widget.onBack,
      showSkip: true,
      // Phase 17 (L6): Skip must NOT save — the old route-mode
      // fallback called _saveAndGo, so Skip and Next did the same
      // thing. Wizard mode already passes a bare _next (no save);
      // route mode now navigates without writing anything.
      onSkip: widget.onSkip ?? () => context.go('/register/review'),
      skipRoute: '/register/review',
      child: Column(
        children: [
          RegTextField(
              label: s['name']!,
              hint: s['nameHint']!,
              controller: _name),
          const SizedBox(height: 16),
          RegTextField(
              label: s['phone']!,
              hint: s['phoneHint']!,
              controller: _phone,
              keyboardType: TextInputType.phone),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
          ],
        ],
      ),
    );
  }
}
