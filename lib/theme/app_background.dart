// Layered app background (UI plan §5.2). Warm cream base +
// a very light 2-tone gradient (light blueish-cream at the top
// fading to cream) + two large, very faint colour blobs at
// 8% opacity. Text contrast stays high: ink on the top tint
// is far above WCAG AA. [calm] (lesson/chat reading areas)
// keeps the gradient only, no blobs, so reading stays calm.
// Use as the first child of a Stack; it fills its parent.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_tokens.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.calm = false});
  final bool calm;

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? const [DarkPalette.backgroundTop, DarkPalette.background]
                    : const [LightPalette.backgroundTop, AppTheme.paper],
              ),
            ),
          ),
        ),
        if (!calm) ...[
          Positioned(
            top: -90,
            right: -70,
            child: _blob(AppTheme.primary, 260),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _blob(AppTheme.secondary, 240),
          ),
        ],
      ],
    );
  }
}
