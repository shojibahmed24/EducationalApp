// Batch-2 regression tests (items 4/5): pumps the real exam +
// results screens through a real GoRouter. Test 1 reproduces the
// reported submit bug (fresh prefs, no activity-dates key yet).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/features/practice/model_test_exam_screen.dart';
import 'package:yes_sir_ai/features/practice/model_test_results_screen.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/model-test-exam',
      routes: [
        GoRoute(
            path: '/model-test-exam',
            builder: (c, s) => const ModelTestExamScreen()),
        GoRoute(
            path: '/model-test-results',
            builder: (c, s) => const ModelTestResultsScreen()),
        GoRoute(
            path: '/model-tests',
            builder: (c, s) => const Scaffold(body: Text('LIST'))),
        GoRoute(
            path: '/practice',
            builder: (c, s) => const Scaffold(body: Text('PRACTICE'))),
        GoRoute(
            path: '/home', builder: (c, s) => const Scaffold(body: Text('HOME'))),
      ],
    );

Future<void> _pumpExam(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  PracticeSession.modelTestId = 'mt-science';
  PracticeSession.modelSubject = 'science';
  PracticeSession.modelItems = practiceService.modelScience();
  PracticeSession.modelMinutes = 15;
  PracticeSession.lastAttempt = null;
  PracticeSession.lastItems = [];
  languageNotifier.value = const Locale('bn');
  await t.pumpWidget(MaterialApp.router(routerConfig: _router()));
  await t.pump();
}

Future<void> _answerCurrent(WidgetTester t) async {
  await t.tap(find.byType(OptionTile).first);
  await t.pump();
}

Future<void> _tapVisible(WidgetTester t, String text) async {
  await t.scrollUntilVisible(find.text(text), 200);
  await t.pump();
  await t.tap(find.text(text));
  await t.pump();
}

Future<void> _expectVisible(WidgetTester t, String text,
    {double delta = 200}) async {
  await t.scrollUntilVisible(find.text(text), delta);
  await t.pump();
  expect(find.text(text), findsOneWidget);
}

void main() {
  testWidgets('submit from last question (8/8) reaches results',
      (WidgetTester t) async {
    await _pumpExam(t);
    expect(find.text('মডেল টেস্ট পরীক্ষা'), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      await _answerCurrent(t);
      if (i < 7) {
        await _tapVisible(t, 'পরবর্তী');
      }
    }
    await _tapVisible(t, 'জমা দাও');
    expect(find.text('পরীক্ষা জমা দেবে?'), findsOneWidget);
    expect(find.textContaining('8/8'), findsOneWidget);
    await t.tap(find.text('হ্যাঁ, জমা দাও'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    expect(find.text('মডেল টেস্ট রেজাল্ট'), findsOneWidget);
    expect(find.textContaining('/ 8'), findsOneWidget);
    final attempts = await PracticeStore.loadAttempts();
    expect(attempts.where((a) => a.kind == 'model'), isNotEmpty);
  });

  testWidgets('submit from question 4/8 mid-test reaches results',
      (WidgetTester t) async {
    await _pumpExam(t);
    for (var i = 0; i < 4; i++) {
      await _answerCurrent(t);
      if (i < 3) {
        await _tapVisible(t, 'পরবর্তী');
      }
    }
    // (Header text is scrolled out of the lazy ListView's viewport
    // after the Next taps, so it is not asserted here; the dialog's
    // 4/8 count below proves the mid-test position instead.)
    await _tapVisible(t, 'জমা দাও');
    expect(find.textContaining('4/8'), findsWidgets);
    await t.tap(find.text('হ্যাঁ, জমা দাও'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    expect(find.text('মডেল টেস্ট রেজাল্ট'), findsOneWidget);
  });

  testWidgets('review flag survives next, jumps, shows on results',
      (WidgetTester t) async {
    await _pumpExam(t);
    // Go to Q2 and flag it, then move to Q3: the flag must survive.
    await _tapVisible(t, 'পরবর্তী');
    await _tapVisible(t, 'রিভিউ চিহ্নিত করো');
    await _expectVisible(t, 'রিভিউ চিহ্নিত ✓');
    await _expectVisible(t, 'রিভিউ চিহ্নিত প্রশ্ন', delta: -200);
    await _tapVisible(t, 'পরবর্তী');
    // Jump back via the flagged list's chip and confirm Q2 is flagged.
    await _tapVisible(t, 'প্রশ্ন 2');
    await _expectVisible(t, 'রিভিউ চিহ্নিত ✓');
    // Answer Q2, submit, and confirm the results mark Q2 flagged.
    await t.scrollUntilVisible(find.byType(OptionTile).first, -200);
    await t.pump();
    await _answerCurrent(t);
    await _tapVisible(t, 'জমা দাও');
    await t.pump();
    expect(find.textContaining('রিভিউ চিহ্নিত: 2'), findsOneWidget);
    await t.tap(find.text('হ্যাঁ, জমা দাও'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    expect(find.text('মডেল টেস্ট রেজাল্ট'), findsOneWidget);
    expect(find.textContaining('রিভিউ চিহ্নিত প্রশ্ন: 2'), findsOneWidget);
    // Per-question cards are lazily built: scroll to the flagged one.
    await t.scrollUntilVisible(
        find.textContaining('⚑ রিভিউ চিহ্নিত'), 200);
    await t.pump();
    expect(find.textContaining('⚑ রিভিউ চিহ্নিত'), findsOneWidget);
    final attempts = await PracticeStore.loadAttempts();
    final model = attempts.where((a) => a.kind == 'model').last;
    expect(model.flagged, contains('sq2'));
  });
}
