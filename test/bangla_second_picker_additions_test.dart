// Tests for the Bangla 2nd picker additions (2026-11-04):
// অনুবাদ as a nirmiti kind, সাজেশন as its own non-question
// flow. Fixtures mirror the verified live id shapes only; no
// guide text is used. Since 2026-11-04 the Edge list serves
// suggestion title/star/chapter/linked ids, so grouping and
// linkage ARE derived here — from live fields only, never
// from the workspace import file.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/bangla_second_chapter_titles.dart';
import 'package:yes_sir_ai/features/learn/bangla_second_potro.dart';
import 'package:yes_sir_ai/features/learn/bangla_second_types.dart';
import 'package:yes_sir_ai/l10n/pages/bangla_second_strings.dart';

void main() {
  test('onubad is a nirmiti kind and parses from its ids', () {
    expect(banglaSecondNirmitiPrefix(BanglaSecondType.onubad), 'onubad');
    expect(banglaSecondNirmitiKinds.contains('onubad'), isTrue);
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-onubad-001'),
        'onubad');
    expect(parseBanglaSecondNirmitiKind('ban2-nirmiti-onubad-039'),
        'onubad');
    expect(nirmitiRowMatchesKind('ban2-nirmiti-onubad-039', 'onubad'),
        isTrue);
    expect(nirmitiRowMatchesKind('ban2-nirmiti-onubad-039', 'onucched'),
        isFalse);
  });

  test('suggestion has its own route, outside nirmiti and MCQ flows',
      () {
    final route = banglaSecondRoute(BanglaSecondType.suggestion);
    expect(route, '/bangla-second-suggestion');
    expect(route, isNot('/bangla-second-mcq'));
    expect(route.startsWith('/bangla-second-mcq-questions'), isFalse);
    expect(route.startsWith('/bangla-second-nirmiti'), isFalse);
    expect(banglaSecondNirmitiKinds.contains('suggestion'), isFalse);
    expect(banglaSecondNirmitiPrefix(BanglaSecondType.suggestion),
        isNull);
  });

  test('suggestion ids carry no chapter, kind or division', () {
    const id = 'ban2-appendix-suggestion-040';
    expect(isBanglaSecondSuggestionId(id), isTrue);
    expect(parseBanglaSecondChapter(id), isNull);
    expect(parseBanglaSecondNirmitiKind(id), isNull);
    expect(parseBanglaSecondPotroNumber(id), isNull);
    expect(nirmitiRowMatchesKind(id, 'onubad'), isFalse);
    expect(isBanglaSecondSuggestionId('ban2-nirmiti-onubad-001'), isFalse);
    expect(isBanglaSecondSuggestionId('ban2-ch05-mcq-bank-002'), isFalse);
  });

  test('new types have non-empty labels in both languages', () {
    for (final s in [banglaSecondStringsBn, banglaSecondStringsEn]) {
      expect(banglaSecondTypeLabel(BanglaSecondType.onubad, s).isNotEmpty,
          isTrue);
      expect(
          banglaSecondTypeLabel(BanglaSecondType.suggestion, s).isNotEmpty,
          isTrue);
      expect(s['translationsSuffix']!.isNotEmpty, isTrue);
      expect(s['suggestionsSuffix']!.isNotEmpty, isTrue);
      expect(s['suggestionNumbers']!.isNotEmpty, isTrue);
      expect(s['suggestionNotQuestions']!.isNotEmpty, isTrue);
      expect(s['suggestionLinkedTitle']!.isNotEmpty, isTrue);
      expect(s['suggestionUnmatchedSuffix']!.isNotEmpty, isTrue);
    }
  });

  test('model test stays last in the eleven-item order', () {
    expect(banglaSecondTypesInOrder.length, 11);
    expect(banglaSecondTypesInOrder.last, BanglaSecondType.modelTest);
    expect(
        banglaSecondTypesInOrder
            .indexOf(BanglaSecondType.suggestion),
        banglaSecondTypesInOrder.indexOf(BanglaSecondType.modelTest) -
            1);
  });

  test('chapter titles cover exactly the bank chapters', () {
    expect(
        banglaSecondChapterTitles.keys.toSet(),
        {
          5, 6, 7, 8, 9, 10, 11, 12, 13,
          18, 19, 20, 21, 22, 23, 24, 25,
          31, 32, 33, 34,
          39, 40, 41, 42, 43,
        });
    for (final title in banglaSecondChapterTitles.values) {
      expect(title.isNotEmpty, isTrue);
    }
  });

  test('server row parses all five suggestion fields', () {
    final q = GuideBankQuestion.fromServerJson({
      'id': 'ban2-appendix-suggestion-040',
      'questionText': '2, 4, 9',
      'questionType': 'suggestion',
      'suggestionKind': 'suggestion-mcq',
      'suggestionStar': '★★',
      'suggestionPoricched': '৫',
      'suggestionShironam': 'পরিচ্ছেদ ৫: ধ্বনি ও বর্ণ',
      'linkedDirectiveIds': [
        'ban2-ch05-mcq-bank-002',
        'ban2-nirmiti-onucched-001',
      ],
    });
    expect(q.suggestionKind, 'suggestion-mcq');
    expect(q.suggestionStar, '★★');
    expect(q.suggestionPoricched, '৫');
    expect(q.suggestionShironam, 'পরিচ্ছেদ ৫: ধ্বনি ও বর্ণ');
    expect(q.linkedDirectiveIds,
        ['ban2-ch05-mcq-bank-002', 'ban2-nirmiti-onucched-001']);
  });

  test('server row without suggestion fields parses empty', () {
    final q = GuideBankQuestion.fromServerJson({
      'id': 'ban2-ch05-mcq-bank-002',
      'questionText': 'x',
      'questionType': 'mcq',
    });
    expect(q.suggestionKind, isNull);
    expect(q.suggestionStar, isNull);
    expect(q.suggestionPoricched, isNull);
    expect(q.suggestionShironam, isNull);
    expect(q.linkedDirectiveIds, isEmpty);
    final roundTripped =
        GuideBankQuestion.fromJson(q.toJson());
    expect(roundTripped.linkedDirectiveIds, isEmpty);
  });

  test('suggestion grouping preserves first-appearance order', () {
    GuideBankQuestion row(String id, String? poricched) =>
        GuideBankQuestion(
            id: id,
            questionText: '',
            questionType: 'suggestion',
            suggestionPoricched: poricched);
    final groups = groupBanglaSecondRows<GuideBankQuestion, String?>(
        [
          row('ban2-appendix-suggestion-050', '৭'),
          row('ban2-appendix-suggestion-040', '৫'),
          row('ban2-appendix-suggestion-051', '৭'),
          row('ban2-appendix-suggestion-041', '৫'),
        ],
        (q) => q.suggestionPoricched);
    expect(groups.keys.toList(), ['৭', '৫']);
    expect(groups['৭']!.length, 2);
    expect(groups['৫']!.length, 2);
    expect(groups['৭']!.first.id, 'ban2-appendix-suggestion-050');
  });

  test('linked resolution keeps order across bank and nirmiti', () {
    final bank = GuideBankQuestion(
        id: 'ban2-ch05-mcq-bank-002',
        questionText: '',
        questionType: 'mcq');
    final nirmiti = GuideBankQuestion(
        id: 'ban2-nirmiti-onucched-001',
        questionText: '',
        questionType: 'written');
    final resolved = resolveBanglaSecondLinked(
        [
          'ban2-nirmiti-onucched-001',
          'ban2-ch05-mcq-bank-999',
          'ban2-ch05-mcq-bank-002',
        ],
        [bank, nirmiti]);
    expect(
        resolved.matched.map((q) => q.id).toList(),
        ['ban2-nirmiti-onucched-001', 'ban2-ch05-mcq-bank-002']);
    expect(resolved.unmatched, 1);
  });
}
