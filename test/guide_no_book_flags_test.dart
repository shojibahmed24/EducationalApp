// No-book flag resolution: the server gates every guide-bank
// action on books, so found:false + reason no-book is a
// definitive empty (not unknown). Without this mapping, the
// 14 book-less class-9 subjects could never resolve complete,
// so home subjects were never cached and refetched on every
// mount — the repeated-loading bug.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/guide_bank_service.dart';
import 'package:yes_sir_ai/core/services/guide_subject_flags.dart';
import 'package:yes_sir_ai/core/services/model_test_set_service.dart';

void main() {
  test('chapters parser: no-book is empty, other found-false is null',
      () {
    expect(parseGuideChaptersResponse(null), isNull);
    expect(
      parseGuideChaptersResponse({'found': false, 'reason': 'no-book'}),
      isEmpty,
    );
    expect(parseGuideChaptersResponse({'found': false}), isNull);
    expect(
      parseGuideChaptersResponse(
          {'found': false, 'reason': 'pilot-columns-missing'}),
      isNull,
    );
    expect(
      parseGuideChaptersResponse({
        'found': true,
        'guideChapters': [
          {'chapter': 8, 'totalCount': 100},
          {'chapter': 9, 'totalCount': 50},
        ],
      }),
      {8: 100, 9: 50},
    );
  });

  test('sets: no-book is empty list, other found-false is null',
      () async {
    final noBook = ModelTestSetService(
      post: (_, {endpoint}) async => {'found': false, 'reason': 'no-book'},
    );
    expect(await noBook.fetchSetsFromServer('science', schoolClass: 9),
        isEmpty);
    final unknown = ModelTestSetService(
      post: (_, {endpoint}) async => {'found': false},
    );
    expect(await unknown.fetchSetsFromServer('science', schoolClass: 9),
        isNull);
    final empty = ModelTestSetService(
      post: (_, {endpoint}) async => {'found': true, 'sets': []},
    );
    expect(await empty.fetchSetsFromServer('science', schoolClass: 9),
        isEmpty);
  });

  test('bank presence: no-book is false, other found-false is null',
      () {
    expect(chapterlessBankPresence(null), isNull);
    expect(
      chapterlessBankPresence({'found': false, 'reason': 'no-book'}),
      isFalse,
    );
    expect(chapterlessBankPresence({'found': false}), isNull);
    expect(chapterlessBankPresence({'found': true, 'total': 0}), isFalse);
    expect(chapterlessBankPresence({'found': true, 'total': 2}), isTrue);
    expect(
      chapterlessBankPresence({'found': true, 'questions': []}),
      isFalse,
    );
    expect(
      chapterlessBankPresence({
        'found': true,
        'questions': [{}],
      }),
      isTrue,
    );
  });

  test('withGuideFlags: all-empty (no-book shape) is complete, no guide',
      () async {
    final result = await withGuideFlags(
      [
        SubjectInfo(
          id: 'science',
          nameBn: 'বিজ্ঞান',
          nameEn: 'Science',
          locked: true,
          chapterCount: 0,
        ),
      ],
      9,
      fetchChapters: (s, {schoolClass = 6}) async => <int, int>{},
      fetchSetCount: (s, {schoolClass = 6}) async => 0,
      probeBank: (s, {schoolClass = 6}) async => false,
    );
    expect(result.complete, isTrue);
    expect(result.subjects.single.hasGuide, isFalse);
  });
}
