// Robot teacher avatar, drawn with widgets only (no asset dependency).
// Uses AppTheme colours only. Used by splash + login (Hero) and
// onboarding (plain, no Hero, to avoid duplicate Hero tags).
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class RobotAvatar extends StatelessWidget {
  final double size;
  final bool useHero;
  const RobotAvatar({super.key, this.size = 96, this.useHero = false});

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.card,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Graduation cap (simple, symbolic).
          Positioned(
            top: size * 0.08,
            child: Container(
              width: size * 0.62,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: size * 0.26,
            child: Container(
              width: size * 0.56,
              height: size * 0.42,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(size * 0.18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _eye(size),
                  _eye(size),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.14,
            child: Container(
              width: size * 0.22,
              height: size * 0.07,
              decoration: BoxDecoration(
                color: AppTheme.amber,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
    if (useHero) return Hero(tag: 'yes-sir-robot', child: avatar);
    return avatar;
  }

  Widget _eye(double size) {
    return Container(
      width: size * 0.11,
      height: size * 0.13,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
