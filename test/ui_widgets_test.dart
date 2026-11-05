// UI palette (গ) shared widgets (2026-10-31): tokens, the 5
// shared widgets, and ThemedScaffold. Behaviour pinned here:
// subject mapping, motion tokens, tap handling, stagger
// rendering, shimmer presence, progress bar/ring, and Reduced
// Motion (content still shows when animations are disabled).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/theme/animated_card.dart';
import 'package:yes_sir_ai/theme/animated_progress.dart';
import 'package:yes_sir_ai/theme/app_background.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';
import 'package:yes_sir_ai/theme/motion.dart';
import 'package:yes_sir_ai/theme/shimmer_card.dart';
import 'package:yes_sir_ai/theme/staggered_list.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  test('motion tokens match the plan caps', () {
    expect(MotionTokens.micro, const Duration(milliseconds: 150));
    expect(MotionTokens.standard, const Duration(milliseconds: 250));
    expect(MotionTokens.entrance, const Duration(milliseconds: 300));
    expect(MotionTokens.celebration, const Duration(milliseconds: 600));
    expect(MotionTokens.staggerGap, const Duration(milliseconds: 40));
    expect(MotionTokens.maxStaggerItems, 6);
    expect(MotionTokens.tapScale, 0.97);
  });

  test('subject colours follow the plan mapping', () {
    expect(AppTheme.subjectColorFor('math'), AppTheme.primary);
    expect(AppTheme.subjectColorFor('science'), AppTheme.success);
    expect(AppTheme.subjectColorFor('english'), AppTheme.secondary);
    expect(AppTheme.subjectColorFor('bangla'), const Color(0xFFE86A2C));
    expect(AppTheme.subjectColorFor('bgs'), const Color(0xFF0E8A8A));
    expect(AppTheme.subjectColorFor('ict'), const Color(0xFF0891B2));
    expect(AppTheme.subjectColorFor('religion'), const Color(0xFFB45309));
    // Unknown ids fall back to neutral slate, never a guessed
    // subject colour, and dark pairs differ from light ones.
    expect(AppTheme.subjectColorFor('unknown'),
        const Color(0xFF64748B));
    expect(AppTheme.subjectColorFor('math', dark: true),
        isNot(AppTheme.subjectColorFor('math')));
    expect(AppTheme.statGradients.length, 3);
    expect(AppTheme.statGradientsDark.length, 3);
  });

  testWidgets('AnimatedCard renders child and fires onTap',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      AnimatedCard(
        onTap: () => tapped = true,
        child: const Text('hello card'),
      ),
    ));
    expect(find.text('hello card'), findsOneWidget);
    // Entrance is 300ms at opacity 0 → 1; a tap during the
    // entrance cannot hit-test, so let it finish first.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('hello card'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('AnimatedCard shows content with Reduced Motion',
      (tester) async {
    await tester.pumpWidget(_wrap(
      AnimatedCard(child: const Text('calm card')),
      disableAnimations: true,
    ));
    expect(find.text('calm card'), findsOneWidget);
  });

  testWidgets('StaggeredList renders every child', (tester) async {
    await tester.pumpWidget(_wrap(
      const StaggeredList(
        children: [Text('one'), Text('two'), Text('three')],
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(find.text('three'), findsOneWidget);
  });

  testWidgets('StaggeredList with Reduced Motion renders at once',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const StaggeredList(children: [Text('a'), Text('b')]),
      disableAnimations: true,
    ));
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
  });

  testWidgets('AppBackground renders calm and full variants',
      (tester) async {
    await tester.pumpWidget(_wrap(const AppBackground()));
    expect(find.byType(AppBackground), findsOneWidget);
    await tester.pumpWidget(_wrap(const AppBackground(calm: true)));
    expect(find.byType(AppBackground), findsOneWidget);
  });

  testWidgets('ShimmerCard renders a skeleton', (tester) async {
    // No pumpAndSettle: the shimmer repeats forever.
    await tester.pumpWidget(_wrap(const ShimmerCard()));
    expect(find.byType(ShimmerCard), findsOneWidget);
  });

  testWidgets('AnimatedProgress bar and ring render with labels',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        children: [
          AnimatedProgress(value: 0.5, countLabel: 'half'),
          AnimatedProgress(value: 0.75, ring: true, countLabel: '3/4'),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('half'), findsOneWidget);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AnimatedProgress clamps out-of-range values',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const AnimatedProgress(value: 2, countLabel: 'full'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('full'), findsOneWidget);
  });

  testWidgets('ThemedScaffold renders background + body',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ThemedScaffold(body: Text('scaffold body')),
      ),
    );
    expect(find.text('scaffold body'), findsOneWidget);
    expect(find.byType(AppBackground), findsOneWidget);
  });
}
