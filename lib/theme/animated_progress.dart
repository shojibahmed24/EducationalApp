// Animated progress (UI plan §6.2): a bar (or ring) that
// fills from 0 to [value] over 500ms, with an optional
// count-up label. Reduced Motion: the final value shows
// immediately, no animation. [value] is clamped to 0..1.
import 'package:flutter/material.dart';

import 'motion.dart';

class AnimatedProgress extends StatelessWidget {
  const AnimatedProgress({
    super.key,
    required this.value,
    this.color,
    this.countLabel,
    this.ring = false,
    this.size = 48,
  });
  final double value;
  final Color? color;
  final String? countLabel;
  final bool ring;
  final double size;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 1).toDouble();
    final barColor =
        color ?? Theme.of(context).colorScheme.primary;
    final trackColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    if (reducedMotion(context)) {
      return ring
          ? _ring(context, v, barColor, trackColor)
          : _bar(context, v, barColor, trackColor);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: v),
      duration: MotionTokens.progress,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => ring
          ? _ring(context, t, barColor, trackColor)
          : _bar(context, t, barColor, trackColor),
    );
  }

  Widget _bar(
      BuildContext context, double t, Color barColor, Color trackColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(color: trackColor),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: t,
                child: Container(color: barColor),
              ),
            ),
          ),
        ),
        if (countLabel != null) ...[
          const SizedBox(height: 4),
          Text(countLabel!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _ring(
      BuildContext context, double t, Color barColor, Color trackColor) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: t,
              color: barColor,
              backgroundColor: trackColor,
              strokeWidth: 6,
            ),
          ),
          if (countLabel != null)
            Text(countLabel!,
                style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
