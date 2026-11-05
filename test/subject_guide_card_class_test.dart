// SubjectGuideCard class threading: the card reads the cached
// guide index for the SAVED class (then its explicit class),
// never a silent class-6 index when a class is known. It still
// renders nothing when the resolved class has no cached index.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/features/learn/widgets/subject_guide_card.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';

Widget card({int? schoolClass}) => MaterialApp(
      home: Scaffold(
        body: SubjectGuideCard(
          subjectId: 'math',
          bn: true,
          s: guideBankStringsBn,
          schoolClass: schoolClass,
        ),
      ),
    );

void main() {
  testWidgets('saved class 7 shows class-7 counts, ignores class-6',
      (t) async {
    SharedPreferences.setMockInitialValues({
      'guide_bank_cache_version': 2,
      'demo_profile_json': '{"school_class": 7}',
      'guide_bank_index_7_math': '{"3": 5}',
      'guide_bank_index_6_math': '{"1": 100}',
    });
    await t.pumpWidget(card());
    await t.pumpAndSettle();
    expect(find.text('গাইড প্রশ্ন'), findsOneWidget);
    expect(find.text('৫টি প্রশ্ন · ১টি অধ্যায়'), findsOneWidget);
  });

  testWidgets('saved class with no index renders nothing', (t) async {
    SharedPreferences.setMockInitialValues({
      'guide_bank_cache_version': 2,
      'demo_profile_json': '{"school_class": 7}',
      'guide_bank_index_6_math': '{"1": 100}',
    });
    await t.pumpWidget(card());
    await t.pumpAndSettle();
    expect(find.text('গাইড প্রশ্ন'), findsNothing);
  });

  testWidgets('explicit class is used when nothing is saved',
      (t) async {
    SharedPreferences.setMockInitialValues({
      'guide_bank_cache_version': 2,
      'guide_bank_index_8_math': '{"2": 4, "5": 6}',
    });
    await t.pumpWidget(card(schoolClass: 8));
    await t.pumpAndSettle();
    expect(find.text('গাইড প্রশ্ন'), findsOneWidget);
    expect(find.text('১০টি প্রশ্ন · ২টি অধ্যায়'), findsOneWidget);
  });
}
