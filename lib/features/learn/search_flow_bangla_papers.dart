// Bangla paper split for the search picker (2026-11-04): the
// subjects table has one 'bangla' row, but the picker shows
// two papers — Bangla 1st Paper and Bangla 2nd Paper — while
// every other subject stays as-is. The controller keeps the
// paper id as its subjectId and translates to the real subject
// ('bangla') + the paper's class for every Edge call and for
// the list route: 1st Paper resolves through the picked class
// (its book is class 9), 2nd Paper always through class 10
// (its book is class10-bangla-2nd-bn-guide) — otherwise a class-9
// query would silently return 1st-Paper content for the 2nd
// paper. Section picking (goddo/poddo/uponnas) is 1st-Paper
// only; the 2nd paper keeps the generic guide pickers.
import '../../core/models/backend_models.dart';

/// Picker-level subject ids for the two Bangla papers.
const banglaFirstPaperId = 'bangla-1st';
const banglaSecondPaperId = 'bangla-2nd';

/// True when a picker subject id is one of the Bangla papers.
bool isBanglaPaperId(String id) =>
    id == banglaFirstPaperId || id == banglaSecondPaperId;

/// 1st-Paper guide mode: the chapter picker becomes the section
/// picker (goddo/poddo/uponnas), and the lesson picker filters
/// by that section.
bool isBanglaFirstMode(String subjectId, String source) =>
    source == 'guide' && subjectId == banglaFirstPaperId;

/// 2nd-Paper guide mode: generic guide pickers, resolved
/// through the class-10 book.
bool isBanglaSecondMode(String subjectId, String source) =>
    source == 'guide' && subjectId == banglaSecondPaperId;

/// Real subject id for Edge calls and the list route.
String banglaPaperSubject(String subjectId) =>
    isBanglaPaperId(subjectId) ? 'bangla' : subjectId;

/// Class for Edge calls and the list route: the 2nd paper's
/// book is class 10, always; every other subject (including
/// the 1st paper) uses the picked class.
int banglaPaperClass(String subjectId, String source, int schoolClass) =>
    source == 'guide' && subjectId == banglaSecondPaperId
        ? 10
        : schoolClass;

/// Picker subjects: the single 'bangla' entry becomes the two
/// papers (same locked/guide flags, same position). Other
/// entries pass through untouched, and the input list is never
/// mutated (subjectsAsync caches it for other screens).
List<SubjectInfo> splitBanglaSubjects(List<SubjectInfo> list) {
  final out = <SubjectInfo>[];
  for (final s in list) {
    if (s.id != 'bangla') {
      out.add(s);
      continue;
    }
    out.add(SubjectInfo(
      id: banglaFirstPaperId,
      nameBn: 'বাংলা ১ম পত্র',
      nameEn: 'Bangla 1st Paper',
      locked: s.locked,
      chapterCount: s.chapterCount,
      hasGuide: s.hasGuide,
      guideChapterCount: s.guideChapterCount,
      guideSetCount: s.guideSetCount,
    ));
    out.add(SubjectInfo(
      id: banglaSecondPaperId,
      nameBn: 'বাংলা ২য় পত্র',
      nameEn: 'Bangla 2nd Paper',
      locked: s.locked,
      chapterCount: s.chapterCount,
      hasGuide: s.hasGuide,
      guideChapterCount: s.guideChapterCount,
      guideSetCount: s.guideSetCount,
    ));
  }
  return out;
}

/// Legacy picker id: the old single 'bangla' entry always meant
/// 1st-Paper content (its book is class 9), so old links and
/// saved subjects land on the 1st paper.
String normalizeBanglaSubject(String subjectId) =>
    subjectId == 'bangla' ? banglaFirstPaperId : subjectId;
