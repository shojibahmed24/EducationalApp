// Dashboard redesign: paper-aware display names + empty-state
// action card. Display only — server ids and routes unchanged.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/home/home_design.dart';
import 'package:yes_sir_ai/features/home/widgets/home_empty_state.dart';

void main() {
  test('paperSubjectName: bangla paper follows the profile class', () {
    expect(paperSubjectName('bangla', 'বাংলা', true, 10), 'বাংলা ২য় পত্র');
    expect(paperSubjectName('bangla', 'বাংলা', true, 9), 'বাংলা ১ম পত্র');
    expect(paperSubjectName('bangla', 'Bangla', false, 10), 'Bangla 2nd Paper');
    expect(paperSubjectName('bangla', 'Bangla', false, 9), 'Bangla 1st Paper');
    expect(paperSubjectName('bangla', 'বাংলা', true, null), 'বাংলা');
    expect(paperSubjectName('bangla', 'বাংলা', true, 6), 'বাংলা');
  });

  test('paperSubjectName: english papers, unknown ids fall back', () {
    expect(paperSubjectName('english', 'ইংরেজি', true, 9), 'ইংরেজি ১ম পত্র');
    expect(paperSubjectName('english', 'English', false, 10), 'English 1st Paper');
    expect(paperSubjectName('english', 'ইংরেজি', true, 6), 'ইংরেজি');
    expect(
      paperSubjectName('english-2nd', 'ইংরেজি', true, 9),
      'ইংরেজি ২য় পত্র',
    );
    expect(
      paperSubjectName('english-2nd', 'English', false, null),
      'English 2nd Paper',
    );
    expect(paperSubjectName('math', 'গণিত', true, 9), 'গণিত');
  });

  testWidgets('HomeEmptyState shows message, action, and taps through', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeEmptyState(
            message: 'এখনো কিছু নেই',
            actionLabel: 'প্রশ্ন খুঁজুন',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('এখনো কিছু নেই'), findsOneWidget);
    await tester.tap(find.text('প্রশ্ন খুঁজুন'));
    expect(tapped, isTrue);
  });
}
