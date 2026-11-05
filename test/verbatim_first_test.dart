// Verbatim-first stage-1 rules (2026-10-31): the guide's own
// answer renders ONLY when the server marks it verbatim.
// Hidden grounding text must never leak into display by
// accident: an empty text, kind 'none', or any other kind
// means "no trusted verbatim text", whatever else is set.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/features/learn/widgets/verbatim_answer_card.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';

GroundedContext _ctx({
  String kind = 'none',
  String text = '',
  String note = '',
  bool error = false,
}) =>
    GroundedContext(
      bookTitle: '',
      chapterTitle: '',
      subject: 'math',
      schoolClass: 7,
      chapterNumber: 1,
      page: 0,
      problem: 0,
      questionText: 'q?',
      source: 'guide',
      verbatimKind: kind,
      verbatimText: text,
      correctionNote: note,
      guideError: error,
    );

void main() {
  test('guide kind with text is verbatim', () {
    expect(_ctx(kind: 'guide', text: 'সমাধান').hasVerbatim, isTrue);
  });

  test('corrected kind with text is verbatim', () {
    expect(
      _ctx(kind: 'corrected', text: 'ঘ', note: 'note').hasVerbatim,
      isTrue,
    );
  });

  test('empty text is never verbatim, even for guide kind', () {
    expect(_ctx(kind: 'guide', text: '').hasVerbatim, isFalse);
  });

  test('none kind is never verbatim, even with text set', () {
    expect(_ctx(kind: 'none', text: 'সমাধান').hasVerbatim, isFalse);
  });

  test('unknown kind is never verbatim', () {
    expect(_ctx(kind: 'solution', text: 'x').hasVerbatim, isFalse);
  });

  test('defaults are safe: no verbatim without server marking', () {
    const ctx = GroundedContext(
      bookTitle: '',
      chapterTitle: '',
      subject: 'math',
      schoolClass: 7,
      chapterNumber: 1,
      page: 0,
      problem: 0,
      questionText: 'q?',
      source: 'guide',
      guideUnitText: 'hidden grounding must not show',
    );
    expect(ctx.hasVerbatim, isFalse);
    expect(ctx.verbatimKind, 'none');
  });

  testWidgets('verbatim card shows guide title, text, and buttons',
      (tester) async {
    var detailed = false;
    var steps = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VerbatimAnswerCard(
            kind: 'guide',
            text: 'গাইডের সমাধান',
            correctionNote: '',
            guideError: false,
            fontSize: 16,
            s: guideBankStringsBn,
            explanationShown: false,
            onExplainDetailed: () => detailed = true,
            onExplainSteps: () => steps = true,
          ),
        ),
      ),
    );
    expect(find.text('গাইডের উত্তর'), findsOneWidget);
    expect(find.text('গাইডের সমাধান', findRichText: true), findsOneWidget);
    await tester.tap(find.text('বিস্তারিত বলুন'));
    expect(detailed, isTrue);
    await tester.tap(find.text('ধাপে ধাপে বুঝিয়ে বলুন'));
    expect(steps, isTrue);
  });

  testWidgets('verbatim card for uncorrected error shows error note',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VerbatimAnswerCard(
            kind: 'none',
            text: '',
            correctionNote: '',
            guideError: true,
            fontSize: 16,
            s: guideBankStringsBn,
            explanationShown: true,
            onExplainDetailed: () {},
            onExplainSteps: () {},
          ),
        ),
      ),
    );
    expect(find.text('গাইডের উত্তর'), findsNothing);
    expect(
      find.textContaining('ভুল প্রমাণিত'),
      findsOneWidget,
    );
  });
}
