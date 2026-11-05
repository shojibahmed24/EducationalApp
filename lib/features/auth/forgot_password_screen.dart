// Route: /forgot-password
// Design: stitch-reference/_3/code.html (step 1/3, forgot password).
// DEMO: contact is saved and the OTP flow continues locally.
// Real (Supabase) mode: email gets a real reset link via AuthService
// with an app redirectTo (com.yessirai.app://reset-password), so
// tapping the link reopens the app at /reset-password; the user is
// first sent to /login (no fake OTP step). Phone reset is not
// enabled and says so plainly instead of pretending.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/forgot_password_strings.dart';
import '../../theme/app_theme.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_fields.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/fade_slide.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _contact = TextEditingController();

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s = isBangla ? forgotPasswordStringsBn : forgotPasswordStringsEn;
        return AuthScaffold(
          onBack: () => context.go('/login'),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                FadeSlide(
                  delayMs: 240,
                  child: AuthTextField(
                    label: s['contact']!,
                    hint: s['contactHint']!,
                    icon: Icons.contact_mail,
                    controller: _contact,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlide(
                  delayMs: 300,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(s['tip']!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlide(
                  delayMs: 360,
                  child: AuthPrimaryButton(
                    label: s['sendOtp']!,
                    onPressed: () async {
                      final contact = _contact.text.trim();
                      if (contact.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s['emptyError']!)),
                        );
                        return;
                      }
                      await authService.saveResetContact(contact);
                      if (!authService.isDemo && !contact.contains('@')) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s['phoneResetError']!)),
                          );
                        }
                        return;
                      }
                      if (authService.isDemo) {
                        if (context.mounted) {
                          context.go('/otp?from=/forgot-password');
                        }
                        return;
                      }
                      final res = await authService.resetPassword(contact);
                      if (!context.mounted) return;
                      if (res.ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s['sentEmail']!)),
                        );
                        context.go('/login');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                            res.error ?? s['emptyError']!)),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: AuthTextLink(
                    label: s['remembered']!,
                    onPressed: () => context.go('/login'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(s['safe']!,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
