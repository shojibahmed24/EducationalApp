// Route: /otp
// Design: stitch-reference/_1/code.html (step 2/3, 6-digit OTP).
// Flow: /forgot-password -> /otp -> /reset-password, OR /login ->
// /otp -> /home (login OTP). Phase 6 (H1): [returnTo] records where
// the user came from (query ?from=, default /forgot-password, the
// old behaviour for direct /otp links); back and "change number"
// return there, never to a page the user never visited.
// Real OTP: in real mode resend sends a real SMS code via Supabase
// (AuthPhoneService) and verify checks it against Supabase. A
// Supabase Phone Auth provider is still required in the dashboard
// (see BACKEND_DETAILS_LIST.md); without one, Supabase returns an
// error which is shown honestly, never faked. In DEMO mode any
// 6 digits complete locally and the DEMO banner says so.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_phone_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/demo_banner.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/otp_strings.dart';
import '../../theme/app_theme.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_fields.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/fade_slide.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.returnTo = '/forgot-password'});
  final String returnTo;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _code = '';
  String? _contact;
  final _phoneController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    authService.readResetContact().then((c) {
      if (mounted) setState(() => _contact = c);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Phone for the real OTP calls: the saved reset contact when the
  /// user came from forgot-password, otherwise the number typed on
  /// this screen. Returns null (with a snackbar) when unusable.
  String? _resolvePhone(Map<String, String> s) {
    final typed = _phoneController.text.trim();
    final phone = _contact ?? (typed.isEmpty ? null : typed);
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s['phoneRequired']!)),
      );
      return null;
    }
    if (!isValidE164Phone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s['phoneFormatError']!)),
      );
      return null;
    }
    return phone;
  }

  Future<void> _resend() async {
    final s = isBangla ? otpStringsBn : otpStringsEn;
    if (authService.isDemo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s['demoResend']!)),
      );
      return;
    }
    if (_busy) return;
    final phone = _resolvePhone(s);
    if (phone == null) return;
    setState(() => _busy = true);
    final res = await authPhoneService.sendPhoneOtp(phone);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(res.ok ? s['codeSent']! : (res.error ?? s['verifyFailed']!)),
      ),
    );
  }

  Future<void> _verify() async {
    final s = isBangla ? otpStringsBn : otpStringsEn;
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s['incomplete']!)),
      );
      return;
    }
    if (authService.isDemo) {
      // Login OTP verifies a sign-in, so it lands on /home; only
      // the forgot-password OTP continues to password reset.
      context.go(
        widget.returnTo == '/login' ? '/home' : '/reset-password',
      );
      return;
    }
    if (_busy) return;
    final phone = _resolvePhone(s);
    if (phone == null) return;
    setState(() => _busy = true);
    final res = await authPhoneService.verifyPhoneOtp(phone, _code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      // Supabase session is established by verifyOTP; the local
      // copy keeps splash routing consistent with email sign-in.
      if (res.userId != null) await authService.saveSession(res.userId!);
      if (mounted) {
        context.go(
          widget.returnTo == '/login' ? '/home' : '/reset-password',
        );
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.error ?? s['verifyFailed']!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s = isBangla ? otpStringsBn : otpStringsEn;
        return AuthScaffold(
          onBack: () => context.go(widget.returnTo),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DemoBanner(),
                const SizedBox(height: 8),
                FadeSlide(
                  child: Text(s['step']!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.primary,
                          )),
                ),
                const SizedBox(height: 8),
                FadeSlide(
                  delayMs: 80,
                  child: Text(s['title']!,
                      style: Theme.of(context).textTheme.displayLarge),
                ),
                const SizedBox(height: 8),
                FadeSlide(
                  delayMs: 160,
                  child: Text(s['subtitle']!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                if (_contact != null) ...[
                  const SizedBox(height: 8),
                  Text('${s['sentTo']!} $_contact',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                if (_contact == null) ...[
                  const SizedBox(height: 8),
                  FadeSlide(
                    delayMs: 200,
                    child: AuthTextField(
                      label: s['phoneLabel']!,
                      hint: s['phoneHint']!,
                      icon: Icons.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FadeSlide(
                  delayMs: 240,
                  child: OtpBoxes(
                    onChanged: (v) => setState(() => _code = v),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AuthTextLink(
                      label: s['changeNumber']!,
                      onPressed: () => context.go(widget.returnTo),
                    ),
                    AuthTextLink(label: s['resend']!, onPressed: _resend),
                  ],
                ),
                const SizedBox(height: 8),
                AuthPrimaryButton(label: s['verify']!, onPressed: _verify),
                const SizedBox(height: 16),
                Text(s['noCode']!,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(s['safe']!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}
