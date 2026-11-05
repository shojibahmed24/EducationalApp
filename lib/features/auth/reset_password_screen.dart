// Route: /reset-password
// Design: stitch-reference/_2/code.html (step 3/3, reset password).
// Flow: /otp -> /reset-password -> /login, and (real mode) email
// recovery link -> /reset-password via the recoveryPending router
// gate. Validates empty / mismatch / <8 chars first. DEMO accepts
// locally (labelled by the banner); real mode calls Supabase
// updateUser and only shows the done state when that call succeeds.
// A recovery session is what makes updateUser work here; without
// any session in real mode the screen says so and sends the user
// back to /login instead of showing a generic failure.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_recovery_listener.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/demo_banner.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/reset_password_strings.dart';
import '../../theme/app_theme.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_fields.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/fade_slide.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s =
            isBangla ? resetPasswordStringsBn : resetPasswordStringsEn;
        return AuthScaffold(
          onBack: () {
            // Leaving the reset screen ends the recovery gate, so a
            // later navigation is not forced back here.
            clearRecoveryPending();
            context.go('/login');
          },
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
                const SizedBox(height: 24),
                if (!_done) ...[
                  FadeSlide(
                    delayMs: 240,
                    child: PasswordField(
                      label: s['newPassword']!,
                      hint: s['newPassword']!,
                      controller: _new,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlide(
                    delayMs: 300,
                    child: PasswordField(
                      label: s['confirmPassword']!,
                      hint: s['confirmPassword']!,
                      controller: _confirm,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _rule(context, s['rule1']!),
                  _rule(context, s['rule2']!),
                  _rule(context, s['rule3']!),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: s['change']!,
                    onPressed: () async {
                      if (_new.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s['emptyError']!)),
                        );
                        return;
                      }
                      if (_new.text != _confirm.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s['mismatch']!)),
                        );
                        return;
                      }
                      if (_new.text.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s['tooShort']!)),
                        );
                        return;
                      }
                      // Real mode without any session (opened directly,
                      // expired link): updateUser would fail generically,
                      // so say plainly what is missing instead.
                      if (!authService.isDemo &&
                          authService.currentUserId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s['noSession']!)),
                        );
                        if (context.mounted) context.go('/login');
                        return;
                      }
                      final res =
                          await authService.updatePassword(_new.text);
                      if (!context.mounted) return;
                      if (res.ok) {
                        setState(() => _done = true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                            res.error ?? s['updateFailed']!)),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(s['tip']!, style: Theme.of(context).textTheme.bodySmall),
                ] else ...[
                  const Icon(Icons.check_circle,
                      size: 64, color: AppTheme.success),
                  const SizedBox(height: 16),
                  Text(s['done']!,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(s['doneDetail']!,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: s['goLogin']!,
                    onPressed: () {
                      // Password set: end the recovery gate, then the
                      // user signs in with the new password.
                      clearRecoveryPending();
                      context.go('/login');
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rule(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppTheme.success),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
