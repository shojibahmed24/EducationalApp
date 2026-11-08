// Route: /about
// Version + package are real app data: version 1.0.0+1 from
// pubspec.yaml, package com.yessirai.app. The terms button does NOT
// fake a full legal text: it opens a dialog stating plainly that
// the full terms/privacy text is not in the app yet, plus the real
// rules that do apply (voice premium-only, Play Billing only).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/help_about_strings.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? aboutStringsBn : aboutStringsEn;
    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(s['title']!),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
              radius: 40, child: Text('🤖', style: TextStyle(fontSize: 36))),
          const SizedBox(height: 16),
          Text(s['body']!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Text(s['features']!,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(s['version']!,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(s['package']!,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(s['termsTitle']!),
                      content: Text(s['termsBody']!),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(s['close']!),
                        ),
                      ],
                    ),
                  ),
              child: Text(s['terms']!)),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text(s['home']!)),
        ],
      ),
    );
  }
}
