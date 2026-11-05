// Pure MCQ grouping for the Bangla 1st Paper lesson screen.
// Rows carry mcqGroup = 'writer' | 'lesson' once the Phase B
// backfill lands; null = the server predates the tag. Any other
// value is treated as untagged: grouping never crashes and never
// hides a row, whatever the server sends.
import '../../core/models/guide_bank_model.dart';

class BanglaMcqGroups {
  const BanglaMcqGroups({
    required this.writer,
    required this.lesson,
    required this.untagged,
  });
  final List<GuideBankQuestion> writer;
  final List<GuideBankQuestion> lesson;
  final List<GuideBankQuestion> untagged;

  /// True once at least one row carries a tag: the screen shows
  /// groups. False (all untagged) => the flat full list.
  bool get hasTags => writer.isNotEmpty || lesson.isNotEmpty;
  bool get hasUntagged => untagged.isNotEmpty;
  int get total => writer.length + lesson.length + untagged.length;
}

BanglaMcqGroups groupBanglaMcqs(List<GuideBankQuestion> rows) {
  final writer = <GuideBankQuestion>[];
  final lesson = <GuideBankQuestion>[];
  final untagged = <GuideBankQuestion>[];
  for (final q in rows) {
    switch (q.mcqGroup) {
      case 'writer':
        writer.add(q);
      case 'lesson':
        lesson.add(q);
      default:
        untagged.add(q);
    }
  }
  return BanglaMcqGroups(
      writer: writer, lesson: lesson, untagged: untagged);
}
