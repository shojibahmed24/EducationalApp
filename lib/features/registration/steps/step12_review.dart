// Route: /register/review (Step 12/13)
// On confirm: create the auth user (if an email was given) and
// persist the profile via profile_service (local JSON copy +
// Supabase upsert attempt when configured). Step 13 is shown ONLY
// after that save attempt completes: a local save counts as a save,
// and a failed Supabase upsert does NOT block success - Step 13
// labels it honestly as online-sync pending. Only a failed LOCAL
// save stays on Review with an error. On success the session is
// persisted so splash routes the new user straight to /home next
// launch — EXCEPT when email confirmation is pending (see below):
// then no session is saved and the user stays here until the email
// is confirmed, so splash can never route an unconfirmed user home.
// The confirmation link returns to the app (emailRedirectTo); a
// signedIn event while this pending state shows finishes
// registration (scoped listener, cancelled in dispose).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/auth_signin_listener.dart';
import '../../../core/services/profile_service.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/reg_step12_strings.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step12Review extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const Step12Review({super.key, this.onNext, this.onBack});

  @override
  State<Step12Review> createState() => _Step12ReviewState();
}

class _Step12ReviewState extends State<Step12Review> with RegLangMixin {
  bool _busy = false;
  String? _pendingEmail;
  void Function()? _cancelAuthListener;

  @override
  void dispose() {
    _cancelAuthListener?.call();
    super.dispose();
  }

  Future<void> _confirm(BuildContext context) async {
    if (_busy) return;
    final data = registrationDataNotifier.value;
    final s = isBangla ? regStep12Bn : regStep12En;
    setState(() => _busy = true);
    String? signUpUserId;
    var confirmationPending = false;
    if (data.email.isNotEmpty && data.password.isNotEmpty) {
      final signUp = await authService.signUpEmail(data.email, data.password);
      if (!signUp.ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(signUp.error ?? s['signupFailed']!)),
          );
        }
        if (mounted) setState(() => _busy = false);
        return;
      }
      signUpUserId = signUp.userId;
      confirmationPending = signUp.confirmationPending;
    }
    final result = await profileService.createProfile(
      data,
      userId: signUpUserId,
    );
    if (!result.saved) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s['error']!)),
        );
      }
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (confirmationPending) {
      // Account exists but no session: email confirmation is
      // pending. Show the pending state instead of success, and
      // never save a session or route home for this user.
      if (mounted) {
        setState(() {
          _pendingEmail = data.email;
          _busy = false;
        });
        // Confirmation link tapped while this pending state shows:
        // the account is confirmed, so finish registration instead
        // of leaving the user on the pending screen. Scoped here
        // only; dispose cancels it.
        _cancelAuthListener = listenForFreshSignIn((user) {
          if (user.email == _pendingEmail) {
            authService.saveSession(user.id);
            context.go('/register/success');
          }
        });
      }
      return;
    }
    if (signUpUserId != null) {
      await authService.saveSession(signUpUserId);
    } else {
      await authService.saveSession('demo-user');
    }
    if (context.mounted) context.go('/register/success');
  }

  Future<void> _resendConfirmation() async {
    final email = _pendingEmail;
    if (email == null || _busy) return;
    final s = isBangla ? regStep12Bn : regStep12En;
    setState(() => _busy = true);
    final res = await authService.resendConfirmationEmail(email);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.ok
            ? s['confirmationResent']!
            : (res.error ?? s['error']!)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep12Bn : regStep12En;
    return ValueListenableBuilder<RegistrationData>(
      valueListenable: registrationDataNotifier,
      builder: (context, d, _) {
        if (_pendingEmail != null) {
          return RegScaffold(
            step: 12,
            title: s['confirmationPendingTitle']!,
            subtitle: s['confirmationPendingDetail']!,
            nextLabel: s['goLogin']!,
            nextEnabled: !_busy,
            onNext: () => context.go('/login'),
            onBack: widget.onBack,
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    title: Text(s['email']!),
                    subtitle: Text(_pendingEmail!),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _resendConfirmation,
                  child: Text(s['resend']!),
                ),
              ],
            ),
          );
        }
        final gender = d.gender == 'boy'
            ? s['boy']!
            : d.gender == 'girl'
                ? s['girl']!
                : '-';
        final medium = d.medium == 'bn'
            ? s['bangla']!
            : d.medium == 'en'
                ? s['english']!
                : '-';
        // OTP honesty (see step09_otp.dart): Step 9 never calls a real
        // verification API. In DEMO any 4 digits complete locally, and
        // in live mode real SMS is not enabled — so a stored code is
        // never labelled "verified". Reachable states: not verified
        // (no code), DEMO check (code + DEMO mode), or code entered
        // but real SMS verification still pending (code + live mode).
        final otpStatus = d.otp.isEmpty
            ? s['otpNotVerified']!
            : authService.isDemo
                ? s['otpDemo']!
                : s['otpEntered']!;
        final notGiven = s['notGiven']!;
        final rows = [
          (s['name']!, d.fullName, '/register/name'),
          (s['gender']!, gender, '/register/gender'),
          (s['class']!,
              d.schoolClass == null ? '-' : '${d.schoolClass}',
              '/register/class'),
          (s['medium']!, medium, '/register/medium'),
          (s['goal']!,
              '${d.dailyGoalMinutes} ${s['minutes']!}',
              '/register/goal'),
          (s['school']!,
              d.schoolName.isEmpty ? notGiven : d.schoolName,
              '/register/school'),
          if (d.district.isNotEmpty)
            (s['district']!, d.district, '/register/school'),
          (s['phone']!,
              d.phone.isEmpty ? notGiven : d.phone, '/register/contact'),
          (s['email']!,
              d.email.isEmpty ? notGiven : d.email, '/register/contact'),
          (s['otp']!, otpStatus, '/register/otp'),
          (s['guardianName']!,
              d.guardianName.isEmpty ? notGiven : d.guardianName,
              '/register/guardian'),
          (s['guardianPhone']!,
              d.guardianPhone.isEmpty ? notGiven : d.guardianPhone,
              '/register/guardian'),
        ];
        return RegScaffold(
          step: 12,
          title: s['title']!,
          subtitle: s['subtitle']!,
          nextLabel: s['next']!,
          nextEnabled: !_busy,
          onNext: widget.onNext ?? () => _confirm(context),
          onBack: widget.onBack,
          child: Column(
            children: [
              for (final r in rows)
                Card(
                  child: ListTile(
                    title: Text(r.$1),
                    subtitle: Text(r.$2),
                    trailing: TextButton(
                      onPressed: () => context.go(r.$3),
                      child: Text(s['edit']!),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
