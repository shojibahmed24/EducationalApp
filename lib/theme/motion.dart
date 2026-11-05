// Shared motion tokens (UI plan §6.1). Durations are capped:
// micro 150ms, standard 250ms, entrance 300ms, celebration
// 600ms. Curves are Flutter's easeOutCubic (entrance) and
// easeInOut (tabs/toggles). Reduced Motion: when the platform
// reports animations disabled, widgets skip motion entirely.
import 'package:flutter/material.dart';

class MotionTokens {
  static const micro = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 250);
  static const entrance = Duration(milliseconds: 300);
  static const celebration = Duration(milliseconds: 600);
  static const staggerGap = Duration(milliseconds: 40);
  static const maxStaggerItems = 6;
  static const tapScale = 0.97;
  static const progress = Duration(milliseconds: 500);
}

/// True when the user asked the platform to reduce motion
/// (MediaQuery.disableAnimations). Callers show content
/// directly instead of animating it.
bool reducedMotion(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;
