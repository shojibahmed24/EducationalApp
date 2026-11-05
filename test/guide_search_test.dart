// Unit tests for whole-guide server search: request building
// (blank query must make NO call), response mapping (failure
// shapes -> null, never fake rows), the searchGuide service
// with a fake post function, the server-vs-local resolve rule,
// and the debounced search state.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/guide_search_service.dart';
import 'package:yes_sir_ai/features/learn/guide_search_state.dart';

GuideBankQuestion row(String id, String text,
        {String type = 'short',
        int? marks,
        int? chapter,
        String? section}) =>
    GuideBankQuestion(
        id: id,
        questionText: text,
        questionType: type,
        marks: marks,
        chapterNumber: chapter,
        section: section);

void main() {
  group('buildGuideSearchRequest', () {
    test('blank and whitespace queries build nothing (no call)', () {
      expect(
          buildGuideSearchRequest(
              subject: 'math', schoolClass: 9, query: ''),
          isNull);
      expect(
          buildGuideSearchRequest(
              subject: 'math', schoolClass: 9, query: '   '),
          isNull);
    });

    test('normal query builds the search action, trimmed', () {
      final req = buildGuideSearchRequest(
          subject: 'math', schoolClass: 9, query: '  সেট  ');
      expect(req!['action'], 'search');
      expect(req['classId'], 9);
      expect(req['subject'], 'math');
      expect(req['query'], 'সেট');
      expect(req['limit'], 50);
    });

    test('limit clamps to 1..50', () {
      expect(
          buildGuideSearchRequest(
              subject: 'math', schoolClass: 9, query: 'x', limit: 500)!['limit'],
          50);
      expect(
          buildGuideSearchRequest(
              subject: 'math', schoolClass: 9, query: 'x', limit: 0)!['limit'],
          1);
    });
  });

  group('parseGuideSearchResponse', () {
    test('failure shapes map to null', () {
      expect(parseGuideSearchResponse(null), isNull);
      expect(parseGuideSearchResponse({'found': false}), isNull);
      expect(
          parseGuideSearchResponse(
              {'found': true, 'questions': 'nope'}),
          isNull);
    });

    test('rows map with chapter, key flag, error flag, options', () {
      final rows = parseGuideSearchResponse({
        'found': true,
        'questions': [
          {
            'id': 'q1',
            'questionText': 'সেট কাকে বলে?',
            'questionType': 'short',
            'options': [],
            'marks': 2,
            'chapterNumber': 8,
            'hasKey': true,
            'guideError': false,
          },
        ],
      })!;
      expect(rows.length, 1);
      expect(rows.first.chapterNumber, 8);
      expect(rows.first.serverHasKey, true);
      expect(rows.first.guideError, false);
      expect(rows.first.marks, 2);
    });

    test('a key in the payload never becomes a key index', () {
      final rows = parseGuideSearchResponse({
        'found': true,
        'questions': [
          {
            'id': 'q9',
            'questionText': 'MCQ?',
            'questionType': 'mcq',
            'options': ['এক', 'দুই'],
            'marks': 1,
            'chapterNumber': 2,
            'hasKey': true,
            'answer_key': 'ক',
            'guide_solution': 'SECRET',
          },
        ],
      })!;
      expect(rows.first.correctOptionIndex, isNull);
      expect(rows.first.serverHasKey, true);
      expect(rows.first.options, ['এক', 'দুই']);
    });
  });

  group('searchGuide with fake post', () {
    test('blank query makes zero calls', () async {
      var calls = 0;
      Future<Map<String, dynamic>?> fake(Map<String, dynamic> b,
          {String? endpoint}) async {
        calls++;
        return null;
      }

      final rows = await searchGuide(
          subject: 'math', schoolClass: 9, query: '  ', endpoint: 'https://example.test/guide-bank', post: fake);
      expect(rows, isNull);
      expect(calls, 0);
    });

    test('null and found-false responses map to null', () async {
      Future<Map<String, dynamic>?> nullPost(Map<String, dynamic> b,
              {String? endpoint}) async =>
          null;
      expect(
          await searchGuide(
              subject: 'math',
              schoolClass: 9,
              query: 'সেট',
              endpoint: 'https://example.test/guide-bank',
              post: nullPost),
          isNull);
      Future<Map<String, dynamic>?> falsePost(Map<String, dynamic> b,
              {String? endpoint}) async =>
          {'found': false};
      expect(
          await searchGuide(
              subject: 'math',
              schoolClass: 9,
              query: 'সেট',
              endpoint: 'https://example.test/guide-bank',
              post: falsePost),
          isNull);
    });

    test('good response maps to rows', () async {
      Future<Map<String, dynamic>?> goodPost(Map<String, dynamic> b,
          {String? endpoint}) async {
        expect(b['action'], 'search');
        return {
          'found': true,
          'questions': [
            {
              'id': 'q1',
              'questionText': 'সেট কাকে বলে?',
              'questionType': 'short',
              'options': [],
              'marks': 2,
              'chapterNumber': 2,
              'hasKey': false,
              'guideError': false,
            },
          ],
        };
      }

      final rows = await searchGuide(
          subject: 'math', schoolClass: 9, query: 'সেট', endpoint: 'https://example.test/guide-bank', post: goodPost);
      expect(rows!.length, 1);
      expect(rows.first.questionText, 'সেট কাকে বলে?');
    });
  });

  group('GuideSearchState', () {
    test('blank query clears synchronously, no search', () {
      var calls = 0;
      final state = GuideSearchState(
        search: ({required subject, required schoolClass, required query}) async {
          calls++;
          return [];
        },
      );
      state.serverRows = [row('x', 'y')];
      state.queryChanged('   ', subject: 'math', schoolClass: 9);
      expect(state.serverRows, isNull);
      expect(state.serverFailed, false);
      expect(state.serverSearching, false);
      expect(calls, 0);
      state.dispose();
    });

    test('typed query lands rows, failure sets the flag', () async {
      final ok = GuideSearchState(
        search: ({required subject, required schoolClass, required query}) async =>
            [row('s1', 'ফল')],
        debounce: Duration.zero,
      );
      ok.queryChanged('সেট', subject: 'math', schoolClass: 9);
      expect(ok.serverSearching, true);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(ok.serverSearching, false);
      expect(ok.serverRows!.map((q) => q.id), ['s1']);
      expect(ok.serverFailed, false);
      ok.dispose();

      final bad = GuideSearchState(
        search: ({required subject, required schoolClass, required query}) async =>
            null,
        debounce: Duration.zero,
      );
      bad.queryChanged('সেট', subject: 'math', schoolClass: 9);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bad.serverRows, isNull);
      expect(bad.serverFailed, true);
      bad.dispose();
    });

    test('superseded search results are dropped', () async {
      final state = GuideSearchState(
        search: ({required subject, required schoolClass, required query}) async {
          if (query == 'প্রথম') {
            await Future.delayed(const Duration(milliseconds: 100));
            return [row('old', 'পুরনো')];
          }
          return [row('new', 'নতুন')];
        },
        debounce: const Duration(milliseconds: 10),
      );
      state.queryChanged('প্রথম', subject: 'math', schoolClass: 9);
      await Future.delayed(const Duration(milliseconds: 30));
      state.queryChanged('দ্বিতীয়', subject: 'math', schoolClass: 9);
      await Future.delayed(const Duration(milliseconds: 200));
      expect(state.serverRows!.map((q) => q.id), ['new']);
      state.dispose();
    });
  });
}
