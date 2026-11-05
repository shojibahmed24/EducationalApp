// English redesign lesson items (2026-11-03): the lesson
// picker is STRICTLY filtered by section, so each builder
// below derives items for exactly one section from the data
// already loaded (set metadata, bank rows, constants).
import '../models/guide_bank_model.dart';
import 'english_redesign.dart';

/// One lesson-field item, strictly scoped to its section.
class EnglishRedesignLesson {
  const EnglishRedesignLesson({
    required this.kind,
    required this.index,
    this.setId,
    this.lesson,
    this.stimulusRef,
    this.workName,
  });
  final String kind; // practice | model | special | poem | story | bucket
  final int index; // 1-based serial; 0 for poem/story/bucket names
  final String? setId;
  final String? lesson;
  final String? stimulusRef; // null = passage-less serial
  final String? workName; // poem/story title

  // Value equality: the screen rebuilds item lists per build,
  // so the dropdown must match the selection by value.
  @override
  bool operator ==(Object other) =>
      other is EnglishRedesignLesson &&
      kind == other.kind &&
      index == other.index &&
      setId == other.setId &&
      lesson == other.lesson &&
      stimulusRef == other.stimulusRef &&
      workName == other.workName;

  @override
  int get hashCode =>
      Object.hash(kind, index, setId, lesson, stimulusRef, workName);
}

/// Sort key for a lesson string ('Unit-02; Lesson-01',
/// 'Unit-3 Lesson-2(B)'): (unit, lesson) numbers, else large.
(int, int) lessonSortKey(String? lesson) {
  final nums = RegExp(r'\d+')
      .allMatches(lesson ?? '')
      .map((m) => int.parse(m.group(0)!))
      .toList();
  if (nums.isEmpty) return (999, 999);
  return (nums[0], nums.length > 1 ? nums[1] : 0);
}

int _compareLessonKeys(
        (int, int) a, (int, int) b, String? refA, String? refB) {
  if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
  if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
  if (refA == null && refB != null) return 1;
  if (refA != null && refB == null) return -1;
  return (refA ?? '').compareTo(refB ?? '');
}

/// Practice serials from bank rows: one serial per (lesson,
/// stimulusRef) pair, in lesson order; a lesson's passage-less
/// rows form one trailing serial (passage shows the honest
/// note, questions stay reachable). Lesson-free rows never
/// become serials (no passage, no lesson to order by).
List<EnglishRedesignLesson> practiceSerials(
    List<GuideBankQuestion> bankRows) {
  final keys = <String, EnglishRedesignLesson>{};
  for (final r in bankRows) {
    final lesson = r.lesson;
    if (lesson == null || lesson.isEmpty) continue;
    final key = '$lesson\u0000${r.stimulusRef ?? ''}';
    keys.putIfAbsent(
        key,
        () => EnglishRedesignLesson(
            kind: 'practice',
            index: 0,
            lesson: lesson,
            stimulusRef: r.stimulusRef));
  }
  final sorted = keys.values.toList()
    ..sort((a, b) => _compareLessonKeys(lessonSortKey(a.lesson),
        lessonSortKey(b.lesson), a.stimulusRef, b.stimulusRef));
  return [
    for (var i = 0; i < sorted.length; i++)
      EnglishRedesignLesson(
          kind: 'practice',
          index: i + 1,
          lesson: sorted[i].lesson,
          stimulusRef: sorted[i].stimulusRef),
  ];
}

/// Model-test lesson items from set metadata: setIds 'main-NN'
/// only, sorted by number, numbered from 1.
List<EnglishRedesignLesson> modelLessonItems(
    List<GuideModelSetInfo> sets) {
  final mains = <(int, String)>[];
  for (final s in sets) {
    final m = RegExp(r'^main-(\d+)$').firstMatch(s.setId);
    if (m != null) mains.add((int.parse(m.group(1)!), s.setId));
  }
  mains.sort((a, b) => a.$1.compareTo(b.$1));
  return [
    for (var i = 0; i < mains.length; i++)
      EnglishRedesignLesson(
          kind: 'model', index: i + 1, setId: mains[i].$2),
  ];
}

/// Special-test lesson items: setIds 'special…-NN', sorted by
/// the trailing number, numbered from 1 (44 → 1, …, 57 → 14).
List<EnglishRedesignLesson> specialLessonItems(
    List<GuideModelSetInfo> sets) {
  final specials = <(int, String)>[];
  for (final s in sets) {
    final m = RegExp(r'^special\d*-(\d+)$').firstMatch(s.setId);
    if (m != null) specials.add((int.parse(m.group(1)!), s.setId));
  }
  specials.sort((a, b) => a.$1.compareTo(b.$1));
  return [
    for (var i = 0; i < specials.length; i++)
      EnglishRedesignLesson(
          kind: 'special', index: i + 1, setId: specials[i].$2),
  ];
}

/// Sort rank for a bucket test item: main tests first (by
/// number), then special tests (by trailing number), then
/// any other setId (by string, last).
(int, int, String) _bucketTestRank(String setId) {
  final main = RegExp(r'^main-(\d+)$').firstMatch(setId);
  if (main != null) return (0, int.parse(main.group(1)!), '');
  final special = RegExp(r'^special\d*-(\d+)$').firstMatch(setId);
  if (special != null) return (1, int.parse(special.group(1)!), '');
  return (2, 0, setId);
}

/// Bucket (গল্প ও কবিতা) lesson items from all rows: one item
/// per source test with bucket rows (tests in order), then
/// one item per lesson for test-less bucket rows (lesson
/// order), then a single fallback item for the remainder.
/// No title is ever guessed: items carry test numbers and
/// lesson names only.
List<EnglishRedesignLesson> bucketLessonItemsFromRows(
    List<GuideBankQuestion> allRows) {
  final bucket = allRows
      .where((r) => isBucketPoemStoryRow(r.section, r.stimulusRef))
      .toList();
  final testIds = <String>{};
  final lessons = <String>{};
  var hasFallback = false;
  for (final r in bucket) {
    if (r.setId != null && r.setId!.isNotEmpty) {
      testIds.add(r.setId!);
    } else if (r.lesson != null && r.lesson!.isNotEmpty) {
      lessons.add(r.lesson!);
    } else {
      hasFallback = true;
    }
  }
  final sortedTests = testIds.toList()
    ..sort((a, b) {
      final ra = _bucketTestRank(a);
      final rb = _bucketTestRank(b);
      if (ra.$1 != rb.$1) return ra.$1.compareTo(rb.$1);
      if (ra.$2 != rb.$2) return ra.$2.compareTo(rb.$2);
      return ra.$3.compareTo(rb.$3);
    });
  final sortedLessons = lessons.toList()
    ..sort((a, b) {
      final ka = lessonSortKey(a);
      final kb = lessonSortKey(b);
      if (ka.$1 != kb.$1) return ka.$1.compareTo(kb.$1);
      if (ka.$2 != kb.$2) return ka.$2.compareTo(kb.$2);
      return a.compareTo(b);
    });
  return [
    for (final t in sortedTests)
      EnglishRedesignLesson(kind: 'bucket', index: 0, setId: t),
    for (final l in sortedLessons)
      EnglishRedesignLesson(kind: 'bucket', index: 0, lesson: l),
    if (hasFallback)
      const EnglishRedesignLesson(kind: 'bucket', index: 0),
  ];
}

/// Display label for one bucket item: test items carry the
/// test number (specials as their 1-based serial, 44 → 1),
/// lesson items carry the lesson name, the fallback carries
/// just the section name. Never a guessed work title.
String bucketLessonLabel(EnglishRedesignLesson item, bool bn) {
  final suffix = bn ? 'গল্প ও কবিতা' : 'Poem & Story';
  final setId = item.setId;
  if (setId != null) {
    final main = RegExp(r'^main-(\d+)$').firstMatch(setId);
    if (main != null) {
      final n = int.parse(main.group(1)!);
      return bn
          ? 'মডেল টেস্ট ${bnDigits(n)} · $suffix'
          : 'Model Test $n · $suffix';
    }
    final special = RegExp(r'^special\d*-(\d+)$').firstMatch(setId);
    if (special != null) {
      final n = int.parse(special.group(1)!) - 43;
      return bn
          ? 'বিশেষ মডেল টেস্ট ${bnDigits(n)} · $suffix'
          : 'Special Model Test $n · $suffix';
    }
    return '$setId · $suffix';
  }
  if (item.lesson != null) return '${item.lesson} · $suffix';
  return suffix;
}

/// Display label for any lesson item: bucket items use their
/// test/lesson label, everything else uses the serial label.
String redesignLessonDisplayLabel(EnglishRedesignLesson item, bool bn) {
  if (item.kind == 'bucket') return bucketLessonLabel(item, bn);
  return redesignLessonLabel(item.kind, item.index, item.workName, bn);
}
