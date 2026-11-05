// Route: /register/welcome (Step 1/13)
// UI ONLY - no backend. Next goes to /register/name.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/reg_step01_strings.dart';
import '../../../theme/app_theme.dart';
import '../widgets/reg_scaffold.dart';

class Step01Welcome extends StatelessWidget {
  final VoidCallback? onNext;
  const Step01Welcome({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    // Stateless like the other steps' listener: rebuild on language
    // toggle, otherwise the welcome strings stay frozen in English.
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, _, __) {
        final s = isBangla ? regStep01Bn : regStep01En;
        return RegScaffold(
      step: 1,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: onNext ?? () => context.go('/register/name'),
      child: Column(
        children: [
          const Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.primary,
              child: Text('🤖', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(s['body']!,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}
