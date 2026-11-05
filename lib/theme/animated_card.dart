// Shared tap + entrance card (UI plan §6.3). Tap: scale 0.97
// + ripple, back on release. Entrance: fade + slide up over
// 300ms (optional [delay] for stagger use). Reduced Motion:
// no scale, no entrance — the child shows directly. The card
// uses the ONE soft card style (AppTheme.softCardDecoration)
// with an optional accent colour for the tint border.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

class AnimatedCard extends StatefulWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.radius = 20,
    this.entrance = true,
    this.delay = Duration.zero,
  });
  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  final double radius;
  final bool entrance;
  final Duration delay;

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.entrance,
    );
    if (widget.entrance) {
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(widget.radius),
      child: Ink(
        decoration: AppTheme.softCardDecoration(
          accent: widget.accent,
          dark: dark,
          radius: widget.radius,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: widget.onTap,
          onTapDown: (_) {
            if (!reducedMotion(context)) setState(() => _pressed = true);
          },
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: widget.child,
        ),
      ),
    );
    if (reducedMotion(context) || !widget.entrance) {
      return AnimatedScale(
        scale: _pressed ? MotionTokens.tapScale : 1,
        duration: MotionTokens.micro,
        curve: Curves.easeOutCubic,
        child: card,
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? MotionTokens.tapScale : 1,
        duration: MotionTokens.micro,
        curve: Curves.easeOutCubic,
        child: card,
      ),
    );
  }
}
