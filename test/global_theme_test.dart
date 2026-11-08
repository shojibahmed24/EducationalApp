// Global theme tests (2026-11-05): one font, one button/card/input
// language for both modes, warm dark palette, quiz header.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/practice/widgets/quiz_question_header.dart';
import 'package:yes_sir_ai/theme/app_text_theme.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';
import 'package:yes_sir_ai/theme/app_tokens.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _ratio(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final dark in [false, true]) {
    final name = dark ? 'dark' : 'light';
    final theme = dark ? AppTheme.dark() : AppTheme.light();

    test('$name: Hind Siliguri is the app-wide font', () {
      expect(theme.textTheme.bodyMedium!.fontFamily, kAppFont);
      expect(theme.textTheme.headlineMedium!.fontFamily, kAppFont);
      expect(theme.textTheme.labelLarge!.fontFamily, kAppFont);
      expect(theme.textTheme.titleMedium!.fontFamily, kAppFont);
    });

    test('$name: tuned Bangla sizes and line heights are unchanged', () {
      expect(theme.textTheme.bodyLarge!.fontSize, 17);
      expect(theme.textTheme.bodyLarge!.height, 1.75);
      expect(theme.textTheme.bodyMedium!.fontSize, 15);
      expect(theme.textTheme.bodySmall!.fontSize, 13);
      expect(theme.textTheme.headlineMedium!.fontSize, 20);
    });

    test('$name: buttons share height and pill shape', () {
      final elevated = theme.elevatedButtonTheme.style!;
      final outlined = theme.outlinedButtonTheme.style!;
      expect(elevated.minimumSize!.resolve({})!.height, 56);
      expect(outlined.minimumSize!.resolve({})!.height, 56);
      // a finite width floor, so a Row without Expanded cannot break
      expect(outlined.minimumSize!.resolve({})!.width, isNot(double.infinity));
    });

    test('$name: card radius stays 24 (matches ripples and HomeDesign)', () {
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(24));
    });

    test('$name: input border has at least 3:1 against its fill', () {
      final border =
          theme.inputDecorationTheme.border as OutlineInputBorder;
      final fill = theme.inputDecorationTheme.fillColor!;
      expect(_ratio(border.borderSide.color, fill), greaterThanOrEqualTo(3));
    });

    test('$name: button text clears 4.5:1', () {
      final style = theme.elevatedButtonTheme.style!;
      final fg = style.foregroundColor!.resolve({})!;
      final bg = style.backgroundColor!.resolve({})!;
      expect(_ratio(fg, bg), greaterThanOrEqualTo(4.5));
    });

    test('$name: body and muted text clear 4.5:1 on the scaffold', () {
      final bg = theme.scaffoldBackgroundColor;
      expect(_ratio(theme.textTheme.bodyMedium!.color!, bg),
          greaterThanOrEqualTo(4.5));
      expect(_ratio(theme.textTheme.bodySmall!.color!, bg),
          greaterThanOrEqualTo(4.5));
    });

    test('$name: app bar colour matches the top of the page gradient', () {
      expect(
        theme.appBarTheme.backgroundColor,
        dark ? DarkPalette.backgroundTop : LightPalette.backgroundTop,
      );
    });
  }

  test('dark mode is warm, not the old cool slate', () {
    final dark = AppTheme.dark();
    expect(dark.scaffoldBackgroundColor, DarkPalette.background);
    expect(dark.scaffoldBackgroundColor, isNot(const Color(0xFF1E293B)));
    expect(dark.cardTheme.color, DarkPalette.surface);
    expect(_ratio(DarkPalette.onSurface, DarkPalette.surface),
        greaterThanOrEqualTo(7));
  });

  test('light cards and links keep their audited colours', () {
    final light = AppTheme.light();
    expect(light.cardTheme.color, AppTheme.card);
    expect(light.scaffoldBackgroundColor, AppTheme.paper);
    expect(light.textButtonTheme.style?.foregroundColor?.resolve({}),
        AppTheme.primaryDark);
  });

  testWidgets('QuizQuestionHeader shows label, clock, chapter, progress',
      (tester) async {
    final elapsed = ValueNotifier<int>(65);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: QuizQuestionHeader(
          label: 'প্রশ্ন ৩/২০',
          progress: 3 / 20,
          elapsed: elapsed,
          chapter: 'অধ্যায় ১',
        ),
      ),
    ));
    expect(find.text('প্রশ্ন ৩/২০'), findsOneWidget);
    expect(find.text('অধ্যায় ১'), findsOneWidget);
    expect(find.text('01:05'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(0.15, 1e-9));

    elapsed.value = 70;
    await tester.pump();
    expect(find.text('01:10'), findsOneWidget);
    expect(find.text('01:05'), findsNothing);
  });

  test('QuizQuestionHeader clock pads minutes and seconds', () {
    expect(QuizQuestionHeader.clock(0), '00:00');
    expect(QuizQuestionHeader.clock(9), '00:09');
    expect(QuizQuestionHeader.clock(600), '10:00');
  });
}
