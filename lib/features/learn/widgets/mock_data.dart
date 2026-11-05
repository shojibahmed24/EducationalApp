// UI ONLY - local mock data for Home + Learn screens.
// TODO backend: replace with Supabase / book index data. No real AI calls.
class MockSubject {
  const MockSubject(this.id, this.bn, this.en, this.chapters, this.done, this.locked);
  final String id;
  final String bn;
  final String en;
  final int chapters;
  final int done;
  final bool locked;
}

class MockChapter {
  const MockChapter(this.bn, this.en, this.pages, this.status);
  final String bn;
  final String en;
  final String pages;
  final String status; // done | inProgress | remaining
}

const mockSubjects = <MockSubject>[
  MockSubject('math', 'গণিত', 'Maths', 14, 9, false),
  MockSubject('science', 'বিজ্ঞান', 'Science', 12, 6, false),
  MockSubject('english', 'English', 'English', 10, 8, false),
  MockSubject('bangla', 'বাংলা', 'Bangla', 16, 9, false),
  MockSubject('bgs', 'বি. ও বিশ্বপরিচয়', 'BGS', 11, 3, false),
  MockSubject('ict', 'আইসিটি', 'ICT', 6, 5, false),
  MockSubject('religion', 'ধর্ম ও নৈতিক শিক্ষা', 'Religion', 8, 0, true),
];

const mockChapters = <MockChapter>[
  MockChapter('০১ প্যাটার্ন', '01 Pattern', '১ – ১৮', 'done'),
  MockChapter('০২ মুনাফা ও সরল সুদ', '02 Profit & simple interest', '১৯ – ৩৬', 'done'),
  MockChapter('০৩ পরিমাপ ও ক্ষেত্রফল', '03 Measurement & area', '৩৭ – ৫৪', 'inProgress'),
  MockChapter('০৪ বীজগণিতীয় সূত্রাবলি', '04 Algebraic formulas', '৫৫ – ৭২', 'remaining'),
  MockChapter('০৫ বীজগণিতীয় ভগ্নাংশ', '05 Algebraic fractions', '৭৩ – ৯০', 'remaining'),
];

const mockRoutineBn = <String>[
  'গণিত অনুশীলনী ৩.১-এর ৫টি প্রশ্ন — সম্পন্ন',
  'পদার্থবিজ্ঞান: গতি অধ্যায়ের সূত্র রিভিশন — ১৫ মিনিট',
  'ইংরেজি ভোকাবুলারি কুইজ ১০টি — ১০ মিনিট',
];
const mockRoutineEn = <String>[
  'Maths exercise 3.1, 5 questions — done',
  'Physics: revise motion formulas — 15 min',
  'English vocabulary quiz, 10 questions — 10 min',
];

/// Display names for every subject id in the DB (migration 002 seeds
/// + book_import.sql extras). Async screens read names from
/// Supabase; this map is only for sync spots that need a name
/// without a load (Home hero, book viewer). Unknown ids fall back
/// to the first mock subject, as before — never an invented name.
String subjectNameFor(String id, bool bn) {
  const names = <String, (String, String)>{
    'math': ('গণিত', 'Mathematics'),
    'science': ('বিজ্ঞান', 'Science'),
    'bangla': ('বাংলা', 'Bangla'),
    'english': ('ইংরেজি', 'English'),
    'bgs': ('বাংলাদেশ ও বিশ্বপরিচয়', 'Bangladesh & Global Studies'),
    'ict': ('তথ্য ও যোগাযোগ প্রযুক্তি', 'ICT'),
    'physical': ('শারীরিক শিক্ষা ও স্বাস্থ্য', 'Physical Education and Health'),
    'worklife': ('কর্ম ও জীবনমুখী শিক্ষা', 'Work and Life-Oriented Education'),
    'agriculture': ('কৃষিশিক্ষা', 'Agriculture Studies'),
    'homescience': ('গার্হস্থ্য বিজ্ঞান', 'Home Science'),
    'arts': ('চারু ও কারুকলা', 'Arts and Crafts'),
    'islam': ('ইসলাম শিক্ষা', 'Islamic Studies'),
    'hindu': ('হিন্দুধর্ম শিক্ষা', 'Hindu Religion Studies'),
    'christian': ('খ্রিষ্টধর্ম শিক্ষা', 'Christian Religion Studies'),
    'buddhist': ('বৌদ্ধধর্ম শিক্ষা', 'Buddhist Religion Studies'),
    'arabic': ('সচিত্র আরবি পাঠ', 'Sochitro Arbi Path'),
    'sanskrit': ('সংস্কৃত', 'Sanskrit'),
    'pali': ('পালি', 'Pali'),
    'music': ('সংগীত', 'Music'),
    'religion': ('ধর্ম ও নৈতিক শিক্ষা', 'Religion'),
  };
  final n = names[id];
  if (n != null) return bn ? n.$1 : n.$2;
  final m = mockSubjects.firstWhere(
    (s) => s.id == id,
    orElse: () => mockSubjects.first,
  );
  return bn ? m.bn : m.en;
}
