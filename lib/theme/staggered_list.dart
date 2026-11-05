// Staggered entrance for short lists (UI plan §6.1/§6.3).
// The first 6 children fade + slide up, each 40ms after the
// previous; later children show directly (never a long cascade).
// Reduced Motion: no animation at all, plain Column.
import 'package:flutter/material.dart';

import 'motion.dart';

class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.gap = MotionTokens.staggerGap,
    this.maxAnimated = MotionTokens.maxStaggerItems,
  });
  final List<Widget> children;
  final Duration gap;
  final int maxAnimated;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion(context)) {
      return Column(children: children);
    }
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          if (i < maxAnimated)
            _StaggeredItem(
              delay: gap * i,
              child: children[i],
            )
          else
            children[i],
      ],
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.entrance,
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      child: widget.child,
    );
  }
}
