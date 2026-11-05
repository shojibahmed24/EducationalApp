// Passage/stimulus block (2026-11-01): the pinned block above
// the question must show passage text when the row carries it,
// show the passage source ref when present, and render nothing
// (no fake passage, no placeholder) when the row carries neither.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_stimulus_block.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('stimulus text renders with the stimulus title', (tester) async {
    await tester.pumpWidget(
      wrap(
        GuideStimulusBlock(
          text: 'There lived a woodcutter in a village.',
          fontSize: 16,
          s: guideBankStringsBn,
        ),
      ),
    );
    expect(find.text(guideBankStringsBn['stimulusTitle']!), findsOneWidget);
    expect(
      find.text('There lived a woodcutter in a village.', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('passage source ref renders as a source line', (tester) async {
    await tester.pumpWidget(
      wrap(
        GuideStimulusBlock(
          ref: 'Unit-01 Lesson-01 seen passage (Mr. Moti)',
          fontSize: 16,
          s: guideBankStringsBn,
        ),
      ),
    );
    expect(
      find.text(
        '${guideBankStringsBn['passageSource']!}: Unit-01 Lesson-01 seen passage (Mr. Moti)',
      ),
      findsOneWidget,
    );
    expect(find.text(guideBankStringsBn['stimulusTitle']!), findsNothing);
  });

  testWidgets('text and ref render together', (tester) async {
    await tester.pumpWidget(
      wrap(
        GuideStimulusBlock(
          text: 'There lived a woodcutter in a village.',
          ref: 'Unit-11 story',
          fontSize: 16,
          s: guideBankStringsBn,
        ),
      ),
    );
    expect(find.text(guideBankStringsBn['stimulusTitle']!), findsOneWidget);
    expect(
      find.text('There lived a woodcutter in a village.', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('${guideBankStringsBn['passageSource']!}: Unit-11 story'),
      findsOneWidget,
    );
  });

  testWidgets('no text and no ref renders nothing', (tester) async {
    await tester.pumpWidget(
      wrap(const GuideStimulusBlock(fontSize: 16, s: guideBankStringsBn)),
    );
    expect(find.text(guideBankStringsBn['stimulusTitle']!), findsNothing);
    expect(find.text(guideBankStringsBn['passageSource']!), findsNothing);
  });

  test('server payload parses stimulusRef when present', () {
    final q = GuideBankQuestion.fromServerJson({
      'id': 'e1',
      'questionText': 'Why?',
      'questionType': 'short',
      'stimulusText': 'Once upon a time.',
      'stimulusRef': 'Unit-01 Lesson-01 seen passage',
    });
    expect(q.stimulusText, 'Once upon a time.');
    expect(q.stimulusRef, 'Unit-01 Lesson-01 seen passage');
  });

  test('server payload without stimulus fields parses as null', () {
    final q = GuideBankQuestion.fromServerJson({
      'id': 'e2',
      'questionText': 'Why?',
      'questionType': 'short',
    });
    expect(q.stimulusText, isNull);
    expect(q.stimulusRef, isNull);
  });
}
