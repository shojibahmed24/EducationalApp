// Audit-fix Worker C tests (plan §1.5, C1, F1/F2, G1):
// - G1 email validation (isValidContactEmail, step07_contact)
// - B2 quiz explanation rendering: no raw **, | or ``` fences
//   in visible text (QuizExplanationBody + SolutionBlocks)
// - C1 locked-model-test strings name the needed book
// - F1 paywall coming-soon strings exist in both languages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/practice/quiz_explanation_body.dart';
import 'package:yes_sir_ai/features/registration/steps/step07_contact.dart';
import 'package:yes_sir_ai/l10n/pages/model_test_list_strings.dart';
import 'package:yes_sir_ai/l10n/pages/premium_strings.dart';
import 'package:yes_sir_ai/l10n/pages/quiz_question_strings.dart';

String visibleText(WidgetTester tester) {
  final buf = StringBuffer();
  for (final e in tester.elementList(find.byType(RichText))) {
    buf.write((e.widget as RichText).text.toPlainText());
    buf.write('\n');
  }
  for (final e in tester.elementList(find.byType(Text))) {
    final d = (e.widget as Text).data;
    if (d != null) buf.write(d);
    buf.write('\n');
  }
  return buf.toString();
}

Future<void> pumpBody(
  WidgetTester tester, {
  required bool loading,
  required String? kind,
  required String? text,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuizExplanationBody(
          loading: loading,
          kind: kind,
          text: text,
          s: quizQuestionStringsBn,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('G1 email validation', () {
    test('accepts ordinary addresses, empty stays valid (optional)', () {
      expect(isValidContactEmail(''), isTrue);
      expect(isValidContactEmail('shojib@example.com'), isTrue);
      expect(isValidContactEmail('user.name+tag@mail.co.uk'), isTrue);
    });

    test('rejects a@b@c (two @ signs)', () {
      expect(isValidContactEmail('a@b@c'), isFalse);
      expect(isValidContactEmail('a@b@c.com'), isFalse);
    });

    test('rejects addresses without a domain dot', () {
      expect(isValidContactEmail('user@mail'), isFalse);
      expect(isValidContactEmail('user@localhost'), isFalse);
    });

    test('rejects malformed local/domain parts', () {
      expect(isValidContactEmail('@mail.com'), isFalse);
      expect(isValidContactEmail('user@'), isFalse);
      expect(isValidContactEmail('user@.com'), isFalse);
      expect(isValidContactEmail('user@mail.'), isFalse);
      expect(isValidContactEmail('user@mail..com'), isFalse);
      expect(isValidContactEmail('user name@mail.com'), isFalse);
    });
  });

  test('stripCodeFences drops fence lines only', () {
    const fenced = '```dart\nকোড লাইন\n```\nআসল ব্যাখ্যা';
    final stripped = stripCodeFences(fenced);
    expect(stripped, isNot(contains('```')));
    expect(stripped, contains('আসল ব্যাখ্যা'));
    expect(stripped, contains('কোড লাইন'));
  });

  testWidgets('B2 quiz explanation shows no raw **, | or ``` fences',
      (tester) async {
    const explanation = '```\n**গুরুত্বপূর্ণ** সূত্রটি দেখো।\n\n'
        '| ধাপ | কাজ |\n| --- | --- |\n| ১ | যোগ করো |\n';
    await pumpBody(tester,
        loading: false, kind: 'live', text: explanation);
    final visible = visibleText(tester);
    expect(visible, contains('গুরুত্বপূর্ণ'));
    expect(visible, contains('যোগ করো'));
    expect(visible, isNot(contains('**')));
    expect(visible, isNot(contains('```')));
    expect(visible, isNot(contains('|')));
  });

  testWidgets('quiz explanation loading and missing states still render',
      (tester) async {
    await pumpBody(tester, loading: true, kind: null, text: null);
    expect(find.text(quizQuestionStringsBn['aiLoading']!), findsOneWidget);

    await pumpBody(tester, loading: false, kind: 'missing', text: null);
    expect(find.textContaining(quizQuestionStringsBn['notIndexed']!),
        findsOneWidget);
  });

  test('C1 locked dialog strings name the Class 6 English book', () {
    expect(modelTestListStringsBn['lockedDialogBody']!,
        contains('ইংরেজি পাঠ্যবই'));
    expect(modelTestListStringsEn['lockedDialogBody']!,
        contains('Class 6 English textbook'));
    expect(modelTestListStringsBn['lockedDialogTitle']!.isNotEmpty, isTrue);
    expect(modelTestListStringsEn['lockedDialogTitle']!.isNotEmpty, isTrue);
  });

  test('F1 paywall coming-soon strings exist in both languages', () {
    expect(premiumStringsBn['comingSoon'], 'শীঘ্রই আসছে');
    expect(premiumStringsEn['comingSoon'], 'Coming soon');
    expect(premiumStringsBn['comingSoonNote']!.isNotEmpty, isTrue);
    expect(premiumStringsEn['comingSoonNote']!.isNotEmpty, isTrue);
  });
}
