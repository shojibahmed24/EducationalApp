// Step 6 tests: creative part ordering + grouped view behavior.
// Fixtures are clearly fake (নকল = fake) — never real guide
// content. The grouped view runs on an injected fake loader so
// no Edge call happens in tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_answer_body.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_explanation_section.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_answer_view.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_part_loader.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_parts.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';
import 'package:yes_sir_ai/l10n/pages/lesson_strings.dart';

GuideBankQuestion fakePart(String id, String text, int marks) =>
    GuideBankQuestion(
      id: id,
      questionText: text,
      questionType: 'creative',
      marks: marks,
      stimulusText: 'নকল উদ্দীপক লেখা',
    );

void main() {
  group('orderedCreativeParts', () {
    test('orders ক→খ→গ→ঘ from shuffled input', () {
      final parts = orderedCreativeParts([
        fakePart('g', 'গ) নকল গ অংশ', 4),
        fakePart('k', 'ক) নকল ক অংশ', 2),
        fakePart('kh', 'খ) নকল খ অংশ', 4),
      ]);
      expect(parts.map((p) => p.id).toList(), ['k', 'kh', 'g']);
    });

    test('tolerates a missing part without inventing one', () {
      final parts = orderedCreativeParts([
        fakePart('g', 'গ) নকল গ অংশ', 4),
        fakePart('k', 'ক) নকল ক অংশ', 2),
      ]);
      expect(parts.map((p) => p.id).toList(), ['k', 'g']);
    });

    test('unlettered rows keep input order after lettered ones', () {
      final parts = orderedCreativeParts([
        fakePart('u', 'নকল অংশ (অক্ষর ছাড়া)', 2),
        fakePart('k', 'ক) নকল ক অংশ', 2),
      ]);
      expect(parts.map((p) => p.id).toList(), ['k', 'u']);
      expect(creativePartLabel(1), 'খ');
    });

    test('marks order fixes misleading first letters', () {
      final parts = orderedCreativeParts([
        fakePart('kha', 'আ দিয়ে শুরু নকল প্রশ্ন', 2),
        fakePart('ka', 'খ দিয়ে শুরু নকল প্রশ্ন', 1),
      ]);
      expect(parts.map((p) => p.id).toList(), ['ka', 'kha']);
      expect(creativePartLabel(0), 'ক');
      expect(creativePartLabel(1), 'খ');
    });
  });

  group('GuideCreativeAnswerView', () {
    final answers = {
      'k': 'ক-এর নকল গাইড উত্তর',
      'kh': 'খ-এর নকল গাইড উত্তর',
      'g': 'গ-এর নকল গাইড উত্তর',
    };
    Future<CreativePartLoad> fakeLoader(
      GuideBankQuestion p,
      bool bn,
      CreativePartStage1 onStage1,
    ) async =>
        CreativePartLoad(
          verbatimKind: 'guide',
          verbatimText: answers[p.id]!,
          correctionNote: '',
          guideError: false,
        );

    Widget buildView({void Function(GuideBankQuestion)? onAskAi}) {
      return MaterialApp(
        home: Scaffold(
          body: GuideCreativeAnswerView(
            parts: [
              fakePart('g', 'গ) নকল গ অংশ', 4),
              fakePart('k', 'ক) নকল ক অংশ', 2),
              fakePart('kh', 'খ) নকল খ অংশ', 4),
            ],
            stimulusText: 'নকল উদ্দীপক লেখা',
            subjectId: 'math',
            chapterNumber: 2,
            schoolClass: 9,
            bn: true,
            s: guideBankStringsBn,
            ls: lessonStringsBn,
            onAskAi: onAskAi ?? (_) {},
            loader: fakeLoader,
          ),
        ),
      );
    }

    testWidgets('shows stimulus + ক first, not খ', (tester) async {
      await tester.pumpWidget(buildView());
      await tester.pump();
      expect(find.text('নকল উদ্দীপক লেখা', findRichText: true), findsOneWidget);
      expect(find.text('ক) নকল ক অংশ', findRichText: true), findsOneWidget);
      expect(find.text('ক-এর নকল গাইড উত্তর', findRichText: true), findsOneWidget);
      expect(find.text('খ-এর নকল গাইড উত্তর', findRichText: true), findsNothing);
    });

    testWidgets('part chips show each part\'s marks', (tester) async {
      await tester.pumpWidget(buildView());
      await tester.pump();
      expect(find.text('ক · ২'), findsOneWidget);
      expect(find.text('খ · ৪'), findsOneWidget);
      expect(find.text('গ · ৪'), findsOneWidget);
    });

    testWidgets('switching to খ shows খ answer, stimulus stays',
        (tester) async {
      await tester.pumpWidget(buildView());
      await tester.pump();
      await tester.tap(find.text('খ · ৪'));
      await tester.pump();
      expect(find.text('নকল উদ্দীপক লেখা', findRichText: true), findsOneWidget);
      expect(find.text('খ) নকল খ অংশ', findRichText: true), findsOneWidget);
      expect(find.text('খ-এর নকল গাইড উত্তর', findRichText: true), findsOneWidget);
      expect(find.text('ক-এর নকল গাইড উত্তর', findRichText: true), findsNothing);
    });

    testWidgets('per-part explanation buttons + ask-AI exist',
        (tester) async {
      GuideBankQuestion? asked;
      await tester.pumpWidget(buildView(onAskAi: (p) => asked = p));
      await tester.pump();
      expect(find.text(guideBankStringsBn['explainDetailed']!),
          findsOneWidget);
      expect(
          find.text(guideBankStringsBn['explainSteps']!), findsOneWidget);
      expect(find.text(guideBankStringsBn['askAi']!), findsOneWidget);
      await tester.tap(find.text('গ · ৪'));
      await tester.pump();
      expect(find.text(guideBankStringsBn['explainDetailed']!),
          findsOneWidget);
      expect(find.text(guideBankStringsBn['askAi']!), findsOneWidget);
      await tester.tap(find.text(guideBankStringsBn['askAi']!));
      expect(asked?.id, 'g');
    });
  });

  group('GuideAnswerBody ask-AI (single mode)', () {
    Widget buildBody({void Function()? onAskAi}) => MaterialApp(
          home: Scaffold(
            body: GuideAnswerBody(
              q: const GuideBankQuestion(
                id: 't1',
                questionText: 'নকল একক প্রশ্ন?',
                questionType: 'problem',
              ),
              attempt: null,
              keyText: null,
              chips: const ['guide'],
              fontSize: 16,
              onFontSmaller: () {},
              onFontLarger: () {},
              verbatimKind: 'none',
              verbatimText: '',
              correctionNote: '',
              guideError: false,
              showExplanation: true,
              stepsOnly: false,
              onExplainDetailed: () {},
              onExplainSteps: () {},
              explanation: ExplanationSectionInput(
      requested: true,
      pending: false,
      unavailable: false,
      onRequest: () {},
      onRetry: () {},
    ),
              onAskAi: onAskAi,
              subjectId: 'math',
              chapterNumber: 1,
              bn: true,
              s: guideBankStringsBn,
              ls: lessonStringsBn,
            ),
          ),
        );

    testWidgets('ask-AI button present when callback given',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildBody(onAskAi: () => tapped = true));
      await tester.tap(find.text(guideBankStringsBn['askAi']!));
      expect(tapped, isTrue);
    });

    testWidgets('no ask-AI button when callback is null',
        (tester) async {
      await tester.pumpWidget(buildBody());
      expect(find.text(guideBankStringsBn['askAi']!), findsNothing);
    });
  });
}
