// Route: /register/password (Step 8/13)
// UI ONLY - password kept in local mock state only, never sent anywhere.
// TODO backend: Supabase Auth sign-up on Step 12 confirm.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/pages/reg_step08_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step08Password extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const Step08Password({super.key, this.onNext, this.onBack});

  @override
  State<Step08Password> createState() => _Step08PasswordState();
}

class _Step08PasswordState extends State<Step08Password> with RegLangMixin {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  void _next() {
    final s = isBangla ? regStep08Bn : regStep08En;
    if (_pw.text != _confirm.text) {
      setState(() => _error = s['mismatch']);
      return;
    }
    if (_pw.text.length < 8) {
      setState(() => _error = s['hint']);
      return;
    }
    updateRegistration(
        registrationDataNotifier.value.copyWith(password: _pw.text));
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep08Bn : regStep08En;
    return RegScaffold(
      step: 8,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: _next,
      onBack: widget.onBack,
      child: Column(
        children: [
          RegTextField(
              label: s['password']!,
              hint: s['passwordHint']!,
              controller: _pw,
              obscure: true,
              showObscureToggle: true),
          const SizedBox(height: 16),
          RegTextField(
              label: s['confirm']!,
              hint: s['confirmHint']!,
              controller: _confirm,
              obscure: true,
              showObscureToggle: true),
          const SizedBox(height: 12),
          Text(s['hint']!,
              style: Theme.of(context).textTheme.bodySmall),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
          ],
        ],
      ),
    );
  }
}
