// Route: /register/success (Step 13/13)
// Shown ONLY from Step 12 after its save attempt completes: either
// the full save (local + Supabase) succeeded, or the local save
// succeeded while the Supabase upsert failed. The second case is
// labelled honestly below via profileSupabasePendingNotifier - the
// profile is on this phone, but not online yet. Home button goes to
// the existing /home route, where the saved profile is shown.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/profile_service.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/reg_step13_strings.dart';
import '../../../theme/app_theme.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';

class Step13Success extends StatelessWidget {
  final VoidCallback? onNext;
  const Step13Success({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    // Same language-listener pattern as Step 1: without it the
    // success strings stay frozen after a language toggle.
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, _, __) {
        final s = isBangla ? regStep13Bn : regStep13En;
        final name = registrationDataNotifier.value.fullName;
        return RegScaffold(
      step: 13,
      title: '${s['title']!}${name.isNotEmpty ? ', $name!' : ''}',
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: onNext ?? () => context.go('/home'),
      child: Column(
        children: [
          const Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.success,
              child: Icon(Icons.check, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(s['body']!),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: profileSupabasePendingNotifier,
            builder: (context, pending, _) {
              if (!pending) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(s['pending']!),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
        );
      },
    );
  }
}
