// Loading skeleton (UI plan §6.2): a card-shaped shimmer for
// lists that are still loading, instead of a bare spinner. The
// shimmer is an opacity pulse only (GPU-friendly, no layout
// animation). Reduced Motion: a static skeleton, no pulse.
import 'package:flutter/material.dart';

import 'motion.dart';

class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key, this.lines = 2, this.height = 96});
  final int lines;
  final double height;

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(BuildContext context, double widthFactor, double height) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skeleton = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: widget.height - 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(context, 0.6, 16),
              const SizedBox(height: 10),
              for (var i = 0; i < widget.lines; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _bar(context, i == widget.lines - 1 ? 0.4 : 0.9, 12),
              ],
            ],
          ),
        ),
      ),
    );
    if (reducedMotion(context)) return skeleton;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: 0.55 + 0.45 * _controller.value,
        child: child,
      ),
      child: skeleton,
    );
  }
}
