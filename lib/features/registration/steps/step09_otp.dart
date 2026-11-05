// Route: /register/otp (Step 9/13)
// Honest DEMO OTP: real SMS OTP is not configured (Supabase Phone
// Auth provider pending), so the screen says so in DEMO mode and any
// 4 digits complete locally. In real mode resend says plainly that
// SMS is not enabled; the code is still recorded and Step 12 is the
// real save gate, never a fake verification claim.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../l10n/language_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/pages/reg_step09_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step09Otp extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const Step09Otp({super.key, this.onNext, this.onBack});

  @override
  State<Step09Otp> createState() => _Step09OtpState();
}

class _Step09OtpState extends State<Step09Otp> with RegLangMixin {
  final _boxes = List.generate(4, (_) => TextEditingController());
  String? _error;
  // Phase 17 (L6): resend cooldown — the old button showed only a
  // snackbar and could be tapped endlessly. 30 s between resends;
  // the button shows the countdown and is disabled while it runs.
  // (No real SMS is sent in either mode — see the notes above.)
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _resend(Map<String, String> s) {
    if (_cooldown > 0) return;
    setState(() => _cooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authService.isDemo
          ? s['demoResend']!
          : s['phoneNotConfigured']!)),
    );
  }

  void _next() {
    final code = _boxes.map((c) => c.text).join();
    if (code.length != 4) {
      setState(() => _error =
          (isBangla ? regStep09Bn : regStep09En)['error']);
      return;
    }
    updateRegistration(
        registrationDataNotifier.value.copyWith(otp: code));
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/goal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep09Bn : regStep09En;
    return RegScaffold(
      step: 9,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: _next,
      onBack: widget.onBack,
      child: Column(
        children: [
          Text(
              authService.isDemo
                  ? s['demoNote']!
                  : s['phoneNotConfigured']!,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          OtpField(controllers: _boxes),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _cooldown > 0 ? null : () => _resend(s),
              child: Text(_cooldown > 0
                  ? s['resendWait']!.replaceFirst('{n}', '$_cooldown')
                  : s['resend']!),
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ],
      ),
    );
  }
}
