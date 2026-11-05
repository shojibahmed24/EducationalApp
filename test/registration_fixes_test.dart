// Regression tests for the 2026-10-30 registration fixes reported
// from the PC-build trial:
//  1. Step 5 medium cards sit side by side (Row), not stacked.
//  2. Toggling the language on a registration step re-renders the
//     step's own strings at once (previously the form stayed English
//     even after switching to Bangla).
//  3. The router knows /email-confirmed (confirmation deep link) and
//     '/' (old error-page Home target) instead of throwing GoException.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/features/registration/steps/step05_medium.dart';
import 'package:yes_sir_ai/features/registration/steps/step06_school.dart';
import 'package:yes_sir_ai/features/registration/widgets/reg_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/router/app_router.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    setLanguage('en');
  });
  tearDown(() {
    setLanguage('bn');
  });

  testWidgets('step 5 medium cards are side by side in a Row',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Step05Medium())),
    );
    await tester.pump();
    expect(find.byType(OptionCard), findsNWidgets(2));
    expect(
      find.ancestor(
        of: find.byType(OptionCard).first,
        matching: find.byType(Row),
      ),
      findsOneWidget,
    );
  });

  testWidgets('language toggle re-renders step 6 in Bangla at once',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Step06School())),
    );
    await tester.pump();
    expect(find.text('Which school do you go to?'), findsOneWidget);
    // Toggle label shows the language to switch TO: 'বাংলা' while EN.
    await tester.tap(find.text('বাংলা'));
    await tester.pump();
    expect(find.text('কোন স্কুলে পড়ো?'), findsOneWidget);
    expect(find.text('স্কুলের নাম'), findsOneWidget);
  });

  test('router knows /email-confirmed and /', () {
    final paths = <String>{};
    void collect(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute) paths.add(r.path);
        collect(r.routes);
      }
    }

    collect(appRouter.configuration.routes);
    expect(paths.contains('/email-confirmed'), isTrue);
    expect(paths.contains('/'), isTrue);
  });
}
