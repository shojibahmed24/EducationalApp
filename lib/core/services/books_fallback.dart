// DEMO fallback data for BooksService: the old hardcoded Class 6
// lists. Used only when Supabase is unconfigured or a query fails.
// Chapter counts here are the old UI mock counts, not DB counts —
// subjectsAsync replaces them with real counts when configured.
// The dropped minority-language book is not listed anywhere.
import '../models/backend_models.dart';

/// Canonical subject order: the 6 core subjects first, in the order
/// the Home grid has always shown them; other subjects sort after.
const coreSubjectOrder = ['math', 'science', 'english', 'bangla', 'bgs', 'ict'];

const _suppliedSubjects = {
  'math',
  'science',
  'bangla',
  'english',
  'bgs',
  'ict',
};

List<BookInfo> fallbackClassBooks(int schoolClass, bool bangla) {
  if (schoolClass != 6) {
    // Other classes launch only when their books are supplied.
    return _class6(bangla).map(_locked).toList();
  }
  return _class6(bangla);
}

BookInfo _locked(BookInfo b) => BookInfo(
  id: b.id,
  titleBn: b.titleBn,
  titleEn: b.titleEn,
  subject: b.subject,
  schoolClass: b.schoolClass,
  supplied: false,
);

List<BookInfo> _class6(bool bangla) {
  const subjects = [
    ('math', 'গণিত', 'Mathematics'),
    ('science', 'বিজ্ঞান', 'Science'),
    ('bangla', 'বাংলা', 'Bangla'),
    ('english', 'ইংরেজি', 'English'),
    ('bgs', 'বাংলাদেশ ও বিশ্বপরিচয়', 'Bangladesh & Global Studies'),
    ('ict', 'তথ্য ও যোগাযোগ প্রযুক্তি', 'ICT'),
  ];
  return subjects.map((s) {
    return BookInfo(
      id: 'class6-${s.$1}-${bangla ? 'bn' : 'en'}',
      titleBn: s.$2,
      titleEn: s.$3,
      subject: s.$1,
      schoolClass: 6,
      supplied: _suppliedSubjects.contains(s.$1),
    );
  }).toList();
}

/// DEMO fallback locked card (Religion: book not supplied).
List<BookInfo> fallbackLockedBooks(bool bangla) {
  return const [
    BookInfo(
      id: 'class6-religion-bn',
      titleBn: 'ধর্ম ও নৈতিক শিক্ষা',
      titleEn: 'Religion & Moral Studies',
      subject: 'religion',
      schoolClass: 6,
      supplied: false,
    ),
  ];
}

/// DEMO fallback chapter titles (old UI mock).
List<String> fallbackChapters() {
  return const [
    'Chapter 1',
    'Chapter 2',
    'Chapter 3',
    'Chapter 4',
    'Chapter 5',
  ];
}

/// DEMO fallback subjects: 6 core + Religion locked.
/// Kept for the search screen's old call site (unchanged).
List<SubjectInfo> fallbackSubjects() => fallbackSubjectsForClass(6);

/// Batch 2, item 3: class-aware DEMO fallback. Only Class 6 has
/// supplied books in this fallback (mirroring fallbackClassBooks,
/// which locks every book for other classes), so for any other
/// class every subject is locked — the grid must not show Class 6
/// subjects as unlocked to a Class 7 student. A class with no
/// supplied book does not launch (book-grounding rule).
List<SubjectInfo> fallbackSubjectsForClass(int schoolClass) {
  const list = [
    ('math', 'গণিত', 'Mathematics', 14, false),
    ('science', 'বিজ্ঞান', 'Science', 12, false),
    ('english', 'ইংরেজি', 'English', 10, false),
    ('bangla', 'বাংলা', 'Bangla', 16, false),
    ('bgs', 'বাংলাদেশ ও বিশ্বপরিচয়', 'Bangladesh & Global Studies', 11, false),
    ('ict', 'তথ্য ও যোগাযোগ প্রযুক্তি', 'ICT', 6, false),
    ('religion', 'ধর্ম ও নৈতিক শিক্ষা', 'Religion', 8, true),
  ];
  final otherClass = schoolClass != 6;
  return list
      .map(
        (s) => SubjectInfo(
          id: s.$1,
          nameBn: s.$2,
          nameEn: s.$3,
          chapterCount: s.$4,
          locked: otherClass || s.$5,
        ),
      )
      .toList();
}
