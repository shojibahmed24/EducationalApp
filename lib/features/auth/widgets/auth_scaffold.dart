// Shared auth scaffold: Warm Paper background, soft blobs, top bar
// with back button + bn/en language toggle. Uses AppTheme colours only.
import 'package:flutter/material.dart';
import '../../../l10n/language_provider.dart';
import '../../../theme/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Phase 6 (H1): when a screen supplies an explicit onBack, system
    // back must follow it too. go() leaves a single-entry stack, so
    // the default maybePop() did nothing and system back exited the
    // app. Screens with no onBack (splash, login) keep default
    // behaviour: they are roots with no parent to return to.
    final scaffold = Scaffold(
      backgroundColor: AppTheme.paper,
      body: Stack(
        children: [
          // Soft background blobs (Warm Paper Scholar frosted look).
          Positioned(
            top: -80,
            left: -60,
            child: _blob(AppTheme.secondary.withValues(alpha: 0.12), 240),
          ),
          Positioned(
            top: 240,
            right: -80,
            child: _blob(AppTheme.amber.withValues(alpha: 0.16), 220),
          ),
          Positioned(
            bottom: -70,
            left: 40,
            child: _blob(AppTheme.primary.withValues(alpha: 0.10), 280),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(context),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
    if (onBack == null) return scaffold;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack!();
      },
      child: scaffold,
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: AppTheme.ink),
            )
          else
            const SizedBox(width: 48),
          // Language toggle: works via language_provider.dart.
          ValueListenableBuilder<Locale>(
            valueListenable: languageNotifier,
            builder: (context, locale, _) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _langChip('বাংলা', 'bn', locale.languageCode == 'bn'),
                    _langChip('English', 'en', locale.languageCode == 'en'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _langChip(String label, String code, bool active) {
    return GestureDetector(
      onTap: () => setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppTheme.inkSecondary,
          ),
        ),
      ),
    );
  }
}
