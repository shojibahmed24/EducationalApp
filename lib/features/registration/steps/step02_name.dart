// Route: /register/name (Step 2/13)
// UI ONLY - saves to local mock registrationDataNotifier.
// TODO backend: validate + persist on confirm (Step 12).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/pages/reg_step02_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step02Name extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const Step02Name({super.key, this.onNext, this.onBack});

  @override
  State<Step02Name> createState() => _Step02NameState();
}

class _Step02NameState extends State<Step02Name> with RegLangMixin {
  late final _name =
      TextEditingController(text: registrationDataNotifier.value.fullName);
  late final _nick =
      TextEditingController(text: registrationDataNotifier.value.nickname);
  String? _error;

  void _next() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error =
          (isBangla ? regStep02Bn : regStep02En)['error']);
      return;
    }
    updateRegistration(registrationDataNotifier.value.copyWith(
      fullName: _name.text.trim(),
      nickname: _nick.text.trim(),
    ));
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/gender');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep02Bn : regStep02En;
    return RegScaffold(
      step: 2,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: _next,
      onBack: widget.onBack,
      child: Column(
        children: [
          RegTextField(
              label: s['fullName']!,
              hint: s['fullNameHint']!,
              controller: _name),
          const SizedBox(height: 16),
          RegTextField(
              label: s['nickname']!,
              hint: s['nicknameHint']!,
              controller: _nick),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppTheme.error)),
          ],
        ],
      ),
    );
  }
}
