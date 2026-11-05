// Phase 2 model-test sets (fake-post, offline): sets metadata
// parsing and set-row paging (50/page). Cache round-trip uses
// mock SharedPreferences.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/model_test_set_service.dart';

Future<Map<String, dynamic>?> _fakePost(
  Map<String, dynamic> body, {
  String? endpoint,
}) async {
  if (body['action'] == 'sets') {
    return {
      'found': true,
      'sets': [
        {'setId': 'model-test-01', 'totalCount': 69, 'keyedCount': 30},
        {'setId': 'model-test-02', 'totalCount': 69, 'keyedCount': 30},
      ],
    };
  }
  // list with setId: 69 rows, paged 50 + 19.
  final offset = body['offset'] as int;
  final limit = body['limit'] as int;
  const total = 69;
  final rows = <Map<String, dynamic>>[];
  for (var i = offset; i < offset + limit && i < total; i++) {
    final isMcq = i < 30;
    rows.add({
      'id': 'set1-q$i',
      'questionText': 'q$i',
      'questionType': isMcq ? 'mcq' : 'short',
      'options': isMcq ? ['A', 'B', 'C', 'D'] : [],
      'hasKey': isMcq,
      'guideError': false,
      'setId': 'model-test-01',
    });
  }
  return {'found': true, 'total': total, 'questions': rows};
}

void main() {
  test('fetchSetsFromServer parses set counts', () async {
    final svc = ModelTestSetService(post: _fakePost);
    final sets = await svc.fetchSetsFromServer('math', schoolClass: 9);
    expect(sets, isNotNull);
    expect(sets!.length, 2);
    expect(sets.first.setId, 'model-test-01');
    expect(sets.first.totalCount, 69);
    expect(sets.first.keyedCount, 30);
    expect(sets.first.unkeyedCount, 39);
  });

  test('fetchSetRows pages through the whole set', () async {
    final svc = ModelTestSetService(post: _fakePost);
    final rows =
        await svc.fetchSetRows('math', 'model-test-01', schoolClass: 9);
    expect(rows, isNotNull);
    expect(rows!.length, 69);
    expect(rows.first.id, 'set1-q0');
    expect(rows.last.id, 'set1-q68');
    expect(rows.where((q) => q.questionType == 'mcq').length, 30);
    expect(rows.every((q) => q.setId == 'model-test-01'), isTrue);
  });

  test('cacheSets/cachedSets round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = ModelTestSetService(post: _fakePost);
    final rows =
        await svc.fetchSetRows('math', 'model-test-01', schoolClass: 9);
    await svc.cacheSets(
        'math',
        [GuideModelSet(
            setId: 'model-test-01', subjectId: 'math', questions: rows!)],
        schoolClass: 9);
    final cached = await svc.cachedSets('math', schoolClass: 9);
    expect(cached.length, 1);
    expect(cached.first.setId, 'model-test-01');
    expect(cached.first.questions.length, 69);
  });
}
