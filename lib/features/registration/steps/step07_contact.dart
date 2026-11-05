// Route: /register/contact (Step 7/13)
// UI ONLY - saves to local mock registrationDataNotifier.
// Phone OTP is sent via Supabase Auth (see auth_phone_service);
// the old "TODO backend" note was stale and is removed.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/pages/reg_step07_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

// Audit-fix G1: proper email check, kept top-level so it is
// unit-testable. Empty stays valid (email is optional here).
// Rejects a@b@c (exactly one '@' required), addresses with no
// domain dot (user@mail), and malformed local/domain parts.
// Phone / name / password rules live elsewhere and are untouched.
bool isValidContactEmail(String raw) {
  if (raw.isEmpty) return true;
  final email = raw.trim();
  if (email.isEmpty || email.contains(' ')) return false;
  if ('@'.allMatches(email).length != 1) return false;
  final parts = email.split('@');
  final local = parts[0];
  final domain = parts[1];
  if (local.isEmpty || domain.isEmpty) return false;
  if (!domain.contains('.') ||
      domain.startsWith('.') ||
      domain.endsWith('.') ||
      domain.contains('..')) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
      .hasMatch(email);
}

class Step07Contact extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const Step07Contact({super.key, this.onNext, this.onBack});

  @override
  State<Step07Contact> createState() => _Step07ContactState();
}

class _Step07ContactState extends State<Step07Contact> with RegLangMixin {
  late final _phone =
      TextEditingController(text: registrationDataNotifier.value.phone);
  late final _email =
      TextEditingController(text: registrationDataNotifier.value.email);
  String? _error;

  // Phase 17 (L6): basic format checks only — no SMS/email is
  // actually sent from this step. Phone: 11 digits starting 01, or
  // +880 followed by a 1… number (digits only, spaces/dashes ignored).
  // Email: optional, but if written it must pass isValidContactEmail.
  bool _phoneOk(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11) return digits.startsWith('01');
    if (digits.length == 13) return digits.startsWith('8801');
    return false;
  }

  bool _emailOk(String raw) => isValidContactEmail(raw);

  void _next() {
    final s = isBangla ? regStep07Bn : regStep07En;
    if (_phone.text.trim().isEmpty) {
      setState(() => _error = s['error']);
      return;
    }
    if (!_phoneOk(_phone.text.trim())) {
      setState(() => _error = s['phoneError']);
      return;
    }
    if (!_emailOk(_email.text.trim())) {
      setState(() => _error = s['emailError']);
      return;
    }
    updateRegistration(registrationDataNotifier.value.copyWith(
      phone: _phone.text.trim(),
      email: _email.text.trim(),
    ));
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep07Bn : regStep07En;
    return RegScaffold(
      step: 7,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: _next,
      onBack: widget.onBack,
      child: Column(
        children: [
          RegTextField(
              label: s['phone']!,
              hint: s['phoneHint']!,
              controller: _phone,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          RegTextField(
              label: s['email']!,
              hint: s['emailHint']!,
              controller: _email,
              keyboardType: TextInputType.emailAddress),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
          ],
        ],
      ),
    );
  }
}
