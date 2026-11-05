// Writing-surface translator tests (no Edge, no model, no live I/O).
// The answer screen shares the reader's translation pieces:
// the service (AI path + memory/persisted cache), the
// translated-field widget, and the same persisted switch
// preference. A fake AI stands in for the Edge Mode GEN path
// ('BN:' + source). Body-level translation runs through the
// shared singleton's PERSISTED cache (pre-seeded here), so no
// test ever calls a real model.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/english_reader_service.dart';
import 'package:yes_sir_ai/core/services/english_set_scan.dart';
import 'package:yes_sir_ai/core/services/english_translation_service.dart';
import 'package:yes_sir_ai/core/services/openrouter_client.dart';
import 'package:yes_sir_ai/features/learn/english_reader_screen.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_answer_body.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_explanation_section.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_math_text.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_translated_math_text.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_translate_switch.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';
import 'package:yes_sir_ai/l10n/pages/lesson_strings.dart';

const _prefix = 'Translate this English text into Bangla:\n\n';

/// Fake AI: 'BN:' + the text after the prompt prefix.
/// [fail] flips it to an empty reply.
class FakeAi {
  FakeAi({this.fail = false});
  bool fail;
  int calls = 0;

  Future<GenResult> call({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    calls++;
    if (fail) return const GenResult();
    return GenResult(text: 'BN:${userPrompt.replaceFirst(_prefix, '')}');
  }
}

EnglishSetScanService fakeScan({
  List<GuideModelSetInfo>? sets,
  Map<String, List<GuideBankQuestion>>? setRows,
}) =>
    EnglishSetScanService(
      fetchSets: (subject, {int schoolClass = 9}) async => sets,
      fetchSetRows: (subject, setId, {int schoolClass = 9}) async =>
          setRows?[setId],
      fetchBankRows: (subject, {int schoolClass = 9}) async => [],
    );

/// English writing row (letter): instruction + model answer,
/// no options, no key — the shape the list screen opens.
GuideAnswerBody writingBody({
  required String subjectId,
  required String question,
  required String verbatim,
}) {
  return GuideAnswerBody(
    q: GuideBankQuestion(
      id: 'w1',
      questionText: question,
      questionType: 'creative',
      section: 'letter',
    ),
    attempt: null,
    keyText: null,
    chips: const ['guide'],
    fontSize: 16,
    onFontSmaller: () {},
    onFontLarger: () {},
    verbatimKind: 'guide',
    verbatimText: verbatim,
    correctionNote: '',
    guideError: false,
    showExplanation: false,
    stepsOnly: false,
    onExplainDetailed: () {},
    onExplainSteps: () {},
    explanation: ExplanationSectionInput(
      requested: false,
      pending: false,
      unavailable: false,
      onRequest: () {},
      onRetry: () {},
    ),
    subjectId: subjectId,
    chapterNumber: 0,
    bn: true,
    s: guideBankStringsBn,
    ls: lessonStringsBn,
  );
}

Future<void> pumpBody(WidgetTester tester, Widget body) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
  await tester.pumpAndSettle();
}

/// Pre-seeds the singleton's persisted cache so the body can
/// translate without any model call.
void seedCache(Map<String, String> texts) {
  // Must match the service's current cache prefix (v2 since
  // 2026-11-03: prompt + script validation changed, v1 entries
  // are orphaned on purpose).
  SharedPreferences.setMockInitialValues({
    for (final e in texts.entries)
      'english_translation_v2_${translationCacheKey(e.key)}': e.value,
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    languageNotifier.value = const Locale('bn');
    englishTranslationService.enabledNotifier.value = false;
  });

  group('answer body translation', () {
    const question = 'Write a letter to your friend about school.';
    const answer = 'Dear Rahim,\n\nI am fine and hope you are fine.';
    const otherQuestion = 'Write a paragraph about your village.';
    const otherAnswer = 'My village is small and beautiful.';

    testWidgets('English body translates question and model answer',
        (tester) async {
      seedCache({question: 'BN:$question', answer: 'BN:$answer'});
      englishTranslationService.enabledNotifier.value = true;
      await pumpBody(
          tester,
          writingBody(
              subjectId: 'english', question: question, verbatim: answer));
      expect(find.text('BN:$question'), findsOneWidget);
      expect(find.text('BN:$answer'), findsOneWidget);
      expect(find.text(question), findsNothing);
      expect(find.text(answer), findsNothing);
      final helpers = tester
          .widgetList<GuideTranslatedMathText>(
              find.byType(GuideTranslatedMathText))
          .toList();
      expect(helpers.length, 2);
      expect(helpers.every((h) => h.translate), isTrue);
    });

    testWidgets('non-English body never translates, switch on or not',
        (tester) async {
      seedCache(
          {otherQuestion: 'BN:$otherQuestion', otherAnswer: 'BN:$otherAnswer'});
      englishTranslationService.enabledNotifier.value = true;
      await pumpBody(
          tester,
          writingBody(
              subjectId: 'math',
              question: otherQuestion,
              verbatim: otherAnswer));
      // Untranslated content renders through GuideMathText
      // (math RichText spans), which find.text cannot match
      // as one string — assert the rendered widget instead.
      expect(find.byType(GuideMathText), findsNWidgets(2));
      expect(find.text('BN:$otherQuestion'), findsNothing);
      final helpers = tester
          .widgetList<GuideTranslatedMathText>(
              find.byType(GuideTranslatedMathText))
          .toList();
      expect(helpers.length, 2);
      expect(helpers.every((h) => !h.translate), isTrue);
    });

    testWidgets('switch off shows the originals', (tester) async {
      await pumpBody(
          tester,
          writingBody(
              subjectId: 'english',
              question: 'Write a letter about the flood.',
              verbatim: 'Dear Sir, I am writing.'));
      expect(find.byType(GuideMathText), findsNWidgets(2));
      final helpers = tester
          .widgetList<GuideTranslatedMathText>(
              find.byType(GuideTranslatedMathText))
          .toList();
      expect(helpers.length, 2);
      expect(helpers.every((h) => h.translate), isTrue);
    });
  });

  group('shared cache across surfaces', () {
    testWidgets('reader and answer body share the persisted cache',
        (tester) async {
      const sharedQ = 'What is the colour of the sky?';
      final fake = FakeAi();
      final translation = EnglishTranslationService(aiCall: fake.call);
      SharedPreferences.setMockInitialValues(
          {EnglishTranslationService.enabledKey: true});
      languageNotifier.value = const Locale('bn');
      await tester.pumpWidget(MaterialApp(
          home: EnglishReaderScreen(
        schoolClass: 9,
        kind: EnglishReaderKind.model,
        title: 'মডেল টেস্ট ১',
        setId: 'main-01',
        readerService: EnglishReaderService(
            scan: fakeScan(
                sets: [
              GuideModelSetInfo(
                  setId: 'main-01', totalCount: 1, keyedCount: 0)
            ],
                setRows: {
              'main-01': [
                GuideBankQuestion(
                  id: 'm1',
                  questionText: sharedQ,
                  questionType: 'mcq',
                  section: 'mcq',
                  stimulusText: 'Passage text.',
                  stimulusRef: 'P',
                  setId: 'main-01',
                  options: ['Opt one', 'Opt two'],
                ),
              ],
            })),
        translationService: translation,
      )));
      await tester.pumpAndSettle();
      expect(find.text('BN:$sharedQ'), findsOneWidget);
      final callsAfterReader = fake.calls;
      expect(callsAfterReader, greaterThan(0));
      // The answer body runs on the shared singleton: the same
      // text must come from the persisted cache, no new call.
      // Its model answer is already Bangla, so it needs no call.
      englishTranslationService.enabledNotifier.value = true;
      await pumpBody(
          tester,
          writingBody(
              subjectId: 'english',
              question: sharedQ,
              verbatim: 'মডেল উত্তর।'));
      expect(find.text('BN:$sharedQ'), findsOneWidget);
      expect(fake.calls, callsAfterReader);
    });
  });

  group('helper and switch widgets', () {
    testWidgets('helper failure keeps original, note, retry works',
        (tester) async {
      final fake = FakeAi(fail: true);
      final service = EnglishTranslationService(aiCall: fake.call);
      service.enabledNotifier.value = true;
      const text = 'Hello world.';
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: GuideTranslatedMathText(
        text: text,
        fontSize: 16,
        translate: true,
        service: service,
      ))));
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
      expect(find.text('অনুবাদ করা যায়নি, মূল ইংরেজি দেখানো হচ্ছে'),
          findsOneWidget);
      expect(find.text('আবার চেষ্টা'), findsOneWidget);
      fake.fail = false;
      await tester.tap(find.text('আবার চেষ্টা'));
      await tester.pumpAndSettle();
      expect(find.text('BN:$text'), findsOneWidget);
    });

    testWidgets('helper off shows original with zero AI calls',
        (tester) async {
      final fake = FakeAi();
      final service = EnglishTranslationService(aiCall: fake.call);
      service.enabledNotifier.value = true;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: GuideTranslatedMathText(
        text: 'Hello world.',
        fontSize: 16,
        translate: false,
        service: service,
      ))));
      await tester.pumpAndSettle();
      // Off renders GuideMathText (math RichText spans), which
      // find.text cannot match as one string — assert the
      // rendered widget instead, plus zero AI calls.
      expect(find.byType(GuideMathText), findsOneWidget);
      expect(fake.calls, 0);
    });

    testWidgets('switch persists the choice and syncs the notifier',
        (tester) async {
      final service = EnglishTranslationService(aiCall: FakeAi().call);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: GuideTranslateSwitch(service: service))));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(service.enabledNotifier.value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(EnglishTranslationService.enabledKey), isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(service.enabledNotifier.value, isFalse);
      expect(prefs.getBool(EnglishTranslationService.enabledKey), isFalse);
    });
  });
}
