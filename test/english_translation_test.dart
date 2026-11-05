// English reader translator tests (no Edge, no model, no I/O).
// A fake AI call stands in for the Edge Mode GEN path: it
// returns 'BN:' + the source text, so assertions can tell
// translated fields apart from originals without a model.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/english_reader_service.dart';
import 'package:yes_sir_ai/core/services/english_set_scan.dart';
import 'package:yes_sir_ai/core/services/english_translation_service.dart';
import 'package:yes_sir_ai/core/services/openrouter_client.dart';
import 'package:yes_sir_ai/features/learn/english_reader_screen.dart';
import 'package:yes_sir_ai/features/learn/widgets/english_translated_text.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';

const _prefix = 'Translate this English text into Bangla:\n\n';

/// Fake AI: 'BN:' + the text after the prompt prefix, so line
/// breaks survive. [fail] flips it to an empty reply.
class FakeAi {
  FakeAi({this.fail = false});
  bool fail;
  int calls = 0;
  String? lastSystemPrompt;

  Future<GenResult> call({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    calls++;
    lastSystemPrompt = systemPrompt;
    if (fail) return const GenResult();
    return GenResult(
        text: 'BN:${userPrompt.replaceFirst(_prefix, '')}');
  }
}

EnglishSetScanService fakeScan({
  List<GuideModelSetInfo>? sets,
  Map<String, List<GuideBankQuestion>>? setRows,
  List<GuideBankQuestion>? bankRows,
}) =>
    EnglishSetScanService(
      fetchSets: (subject, {int schoolClass = 9}) async => sets,
      fetchSetRows: (subject, setId, {int schoolClass = 9}) async =>
          setRows?[setId],
      fetchBankRows: (subject, {int schoolClass = 9}) async => bankRows,
    );

Future<void> pumpReader(WidgetTester tester, Widget screen) async {
  languageNotifier.value = const Locale('bn');
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('translation service', () {
    test('translates via the AI call with a no-word-by-word prompt',
        () async {
      final fake = FakeAi();
      final service = EnglishTranslationService(aiCall: fake.call);
      final out = await service.translate('Good morning.');
      expect(out, 'BN:Good morning.');
      expect(fake.calls, 1);
      expect(fake.lastSystemPrompt, contains('never word-by-word'));
    });

    test('memory cache serves a repeat without a second AI call',
        () async {
      final fake = FakeAi();
      final service = EnglishTranslationService(aiCall: fake.call);
      await service.translate('Same text.');
      await service.translate('Same text.');
      expect(fake.calls, 1);
    });

    test('persisted cache serves a fresh service instance', () async {
      final fake1 = FakeAi();
      final first = EnglishTranslationService(aiCall: fake1.call);
      final out1 = await first.translate('Persisted text.');
      final fake2 = FakeAi();
      final second = EnglishTranslationService(aiCall: fake2.call);
      final out2 = await second.translate('Persisted text.');
      expect(out2, out1);
      expect(fake2.calls, 0);
    });

    test('failed AI call returns null (caller shows the original)',
        () async {
      final fake = FakeAi(fail: true);
      final service = EnglishTranslationService(aiCall: fake.call);
      expect(await service.translate('Anything.'), isNull);
    });

    test('prompt demands simple Bangla and Bangla script only',
        () async {
      final fake = FakeAi();
      final service = EnglishTranslationService(aiCall: fake.call);
      await service.translate('Anything.');
      expect(fake.lastSystemPrompt, contains('simple, easy Bangla'));
      expect(fake.lastSystemPrompt, contains('ONLY in Bangla script'));
    });

    test('foreign-script output returns null and is never cached',
        () async {
      var calls = 0;
      Future<GenResult> leaking({
        required String systemPrompt,
        required String userPrompt,
      }) async {
        calls++;
        return const GenResult(text: 'কিন্তু 그날 মেঘ জমেছিল।');
      }

      final service = EnglishTranslationService(aiCall: leaking);
      expect(await service.translate('But that day clouds came.'),
          isNull);
      // Not cached: a retry really re-calls the model.
      expect(await service.translate('But that day clouds came.'),
          isNull);
      expect(calls, 2);
      final prefs = await SharedPreferences.getInstance();
      expect(
          prefs
              .getKeys()
              .where((k) => k.startsWith('english_translation_')),
          isEmpty);
    });

    test('empty, Bangla-only and digits-only text needs no AI call',
        () async {
      final fake = FakeAi();
      final service = EnglishTranslationService(aiCall: fake.call);
      expect(await service.translate(''), '');
      expect(await service.translate('আমি ভালো আছি।'), 'আমি ভালো আছি।');
      expect(await service.translate('১২৩৪'), '১২৩৪');
      expect(fake.calls, 0);
    });

    test('switch choice persists across service instances', () async {
      final service = EnglishTranslationService(aiCall: FakeAi().call);
      expect(await service.loadEnabled(), isFalse);
      await service.setEnabled(true);
      final fresh = EnglishTranslationService(aiCall: FakeAi().call);
      expect(await fresh.loadEnabled(), isTrue);
    });

    test('cache keys are stable and distinct per text', () {
      expect(translationCacheKey('abc'), translationCacheKey('abc'));
      expect(translationCacheKey('abc'),
          isNot(translationCacheKey('abd')));
    });
  });

  group('reader switch', () {
    const passage = 'Para one.\n\nPara two.';
    final modelRows = [
      GuideBankQuestion(
        id: 'm1',
        questionText: 'What is the colour?',
        questionType: 'mcq',
        section: 'mcq',
        stimulusText: passage,
        stimulusRef: 'P',
        setId: 'main-01',
        options: ['Red apple', 'Green mango'],
      ),
    ];

    Widget modelScreen(EnglishTranslationService translation) =>
        EnglishReaderScreen(
          schoolClass: 9,
          kind: EnglishReaderKind.model,
          title: 'মডেল টেস্ট ১',
          setId: 'main-01',
          readerService: EnglishReaderService(
              scan: fakeScan(
                  sets: [GuideModelSetInfo(
                      setId: 'main-01', totalCount: 1, keyedCount: 0)],
                  setRows: {'main-01': modelRows})),
          translationService: translation,
        );

    testWidgets('switch translates passage, question and options',
        (tester) async {
      final fake = FakeAi();
      final translation = EnglishTranslationService(aiCall: fake.call);
      await pumpReader(tester, modelScreen(translation));
      expect(find.text(passage), findsOneWidget);
      expect(find.text('What is the colour?'), findsOneWidget);
      expect(find.text('Red apple'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('BN:$passage'), findsOneWidget);
      expect(find.text('BN:What is the colour?'), findsOneWidget);
      expect(find.text('BN:Red apple'), findsOneWidget);
      expect(find.text('BN:Green mango'), findsOneWidget);
      expect(find.text(passage), findsNothing);
    });

    testWidgets('toggling off and on reuses the cache, no new AI call',
        (tester) async {
      final fake = FakeAi();
      final translation = EnglishTranslationService(aiCall: fake.call);
      await pumpReader(tester, modelScreen(translation));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      final afterFirstOn = fake.calls;
      expect(afterFirstOn, greaterThan(0));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(fake.calls, afterFirstOn);
      expect(find.text('BN:$passage'), findsOneWidget);
    });

    testWidgets('failure keeps the original, shows note, retry works',
        (tester) async {
      final fake = FakeAi(fail: true);
      final translation = EnglishTranslationService(aiCall: fake.call);
      await pumpReader(tester, modelScreen(translation));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text(passage), findsWidgets);
      expect(
          find.text('অনুবাদ করা যায়নি, মূল ইংরেজি দেখানো হচ্ছে'),
          findsWidgets);
      expect(find.text('আবার চেষ্টা'), findsWidgets);
      fake.fail = false;
      await tester.tap(find.text('আবার চেষ্টা').first);
      await tester.pumpAndSettle();
      expect(find.text('BN:$passage'), findsOneWidget);
    });

    testWidgets('poem passage translates through the same switch',
        (tester) async {
      final fake = FakeAi();
      final translation = EnglishTranslationService(aiCall: fake.call);
      const poem = 'The woods are lovely, dark and deep.';
      await pumpReader(
          tester,
          EnglishReaderScreen(
            schoolClass: 9,
            kind: EnglishReaderKind.poem,
            title: 'কবিতা',
            workName: 'Stopping by Woods on a Snowy Evening',
            readerService: EnglishReaderService(
                scan: fakeScan(sets: [], bankRows: [
              GuideBankQuestion(
                id: 'p1',
                questionText: 'What does the poet see?',
                questionType: 'short',
                section: 'poem',
                stimulusText: poem,
                stimulusRef: 'Stopping by Woods on a Snowy Evening',
              ),
            ])),
            translationService: translation,
          ));
      expect(find.text(poem), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('BN:$poem'), findsOneWidget);
    });
  });

  group('translated field widget', () {
    testWidgets('letter body translates with line breaks kept',
        (tester) async {
      const letter = 'Dear Sir,\n\nI am writing to inform you.\n\n'
          'Yours faithfully,\nRahim';
      final service = EnglishTranslationService(aiCall: FakeAi().call);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: EnglishTranslatedText(
        text: letter,
        translate: true,
        service: service,
        failedNote: 'FAILED',
        retryLabel: 'RETRY',
      ))));
      await tester.pumpAndSettle();
      expect(find.text('BN:$letter'), findsOneWidget);
    });

    testWidgets('switch off shows the original untouched',
        (tester) async {
      final fake = FakeAi();
      final service = EnglishTranslationService(aiCall: fake.call);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: EnglishTranslatedText(
        text: 'Hello world.',
        translate: false,
        service: service,
        failedNote: 'FAILED',
        retryLabel: 'RETRY',
      ))));
      await tester.pumpAndSettle();
      expect(find.text('Hello world.'), findsOneWidget);
      expect(fake.calls, 0);
    });
  });
}
