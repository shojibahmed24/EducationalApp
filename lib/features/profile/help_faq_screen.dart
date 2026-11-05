// Route: /help
// Every FAQ expands with its real answer (ExpansionTile). The
// contact button does NOT send a message anywhere: it opens a dialog
// with real in-app support info (app + package + where to fix
// language/class), because no support email/channel exists in the
// app data yet and inventing one would be fake.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/help_about_strings.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? helpStringsBn : helpStringsEn;
    final faqs = [
      (s['q1']!, s['a1']!),
      (s['q2']!, s['a2']!),
      (s['q3']!, s['a3']!),
      (s['q4']!, s['a4']!),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: Text(s['title']!),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final f in faqs)
            Card(
                child: ExpansionTile(
                    title: Text(f.$1),
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(f.$2))
                    ])),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s['contactTitle']!),
                content: Text(s['contactBody']!),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(s['close']!),
                  ),
                ],
              ),
            ),
            child: Text(s['contact']!),
          ),
        ],
      ),
    );
  }
}
