// Verified book data for Bangla 1st Paper (Panjeree SSC 2026,
// shared class 9-10 book, DB class_id 9, book_id
// 'class9-bangla-1st-bn-guide'). Lesson order = BOOK order
// (goddo 1-9, poddo 1-8, uponnas 1), never alphabetical.
// Titles, authors and sections come from the books' own TOCs
// (see BANGLA1ST_PLAN.md); nothing here is estimated.
// The DB import dropped the book-part column, so this map is
// what restores the section split in the app. If the server
// later returns a lesson title absent here, screens show it
// under the fallback section instead of hiding it.
class BanglaFirstLesson {
  const BanglaFirstLesson({
    required this.title,
    required this.section,
    required this.author,
    required this.slug,
  });
  final String title;
  // Book part: 'goddo' | 'poddo' | 'uponnas' (collection values).
  final String section;
  final String author;
  final String slug;
}

/// Book-part values in display order.
const banglaFirstSections = ['goddo', 'poddo', 'uponnas'];

/// Model-test setId prefix for a section: ban1-<section>-<slug>
/// -<kind> (verified from the lesson files; the novel has none).
String banglaFirstSetPrefix(String section) => 'ban1-$section-';

const banglaFirstLessons = <BanglaFirstLesson>[
  BanglaFirstLesson(
      title: 'প্রত্যুপকার',
      section: 'goddo',
      author: 'ঈশ্বরচন্দ্র বিদ্যাসাগর',
      slug: 'prottupokar'),
  BanglaFirstLesson(
      title: 'সুভা',
      section: 'goddo',
      author: 'রবীন্দ্রনাথ ঠাকুর',
      slug: 'subha'),
  BanglaFirstLesson(
      title: 'বই পড়া',
      section: 'goddo',
      author: 'প্রমথ চৌধুরী',
      slug: 'boi-pora'),
  BanglaFirstLesson(
      title: 'আম-আঁটির ভেঁপু',
      section: 'goddo',
      author: 'বিভূতিভূষণ বন্দ্যোপাধ্যায়',
      slug: 'am-antir-bhepu'),
  BanglaFirstLesson(
      title: 'মানুষ মুহম্মদ (স.)',
      section: 'goddo',
      author: 'মোহাম্মদ ওয়াজেদ আলী',
      slug: 'manush-muhammad'),
  BanglaFirstLesson(
      title: 'নিমগাছ', section: 'goddo', author: 'বনফুল', slug: 'nimgach'),
  BanglaFirstLesson(
      title: 'শিক্ষা ও মনুষ্যত্ব',
      section: 'goddo',
      author: 'মোতাহের হোসেন চৌধুরী',
      slug: 'shikkha-o-manushotto'),
  BanglaFirstLesson(
      title: 'প্রবাস বন্ধু',
      section: 'goddo',
      author: 'সৈয়দ মুজতবা আলী',
      slug: 'probas-bondhu'),
  BanglaFirstLesson(
      title: 'একুশের গল্প',
      section: 'goddo',
      author: 'জহির রায়হান',
      slug: 'ekusher-golpo'),
  BanglaFirstLesson(
      title: 'কপোতাক্ষ নদ',
      section: 'poddo',
      author: 'মাইকেল মধুসূদন দত্ত',
      slug: 'kopotakkho-nod'),
  BanglaFirstLesson(
      title: 'জীবন বিনিময়',
      section: 'poddo',
      author: 'গোলাম মোস্তফা',
      slug: 'jibon-binimoy'),
  BanglaFirstLesson(
      title: 'উমর ফারুক',
      section: 'poddo',
      author: 'কাজী নজরুল ইসলাম',
      slug: 'umor-faruk'),
  BanglaFirstLesson(
      title: 'সেইদিন এই মাঠ',
      section: 'poddo',
      author: 'জীবনানন্দ দাশ',
      slug: 'seidin-ei-math'),
  BanglaFirstLesson(
      title: 'বৃষ্টি', section: 'poddo', author: 'ফররুখ আহমদ', slug: 'brishti'),
  BanglaFirstLesson(
      title: 'আমি কোনো আগন্তুক নই',
      section: 'poddo',
      author: 'আহসান হাবীব',
      slug: 'ami-kono-agontuk-noi'),
  BanglaFirstLesson(
      title: 'তোমাকে পাওয়ার জন্যে, হে স্বাধীনতা',
      section: 'poddo',
      author: 'শামসুর রাহমান',
      slug: 'tomake-pawar-jonne-he-sadhinota'),
  BanglaFirstLesson(
      title: 'বোশেখ', section: 'poddo', author: 'আল মাহমুদ', slug: 'boshekh'),
  BanglaFirstLesson(
      title: '১৯৭১',
      section: 'uponnas',
      author: 'হুমায়ূন আহমেদ',
      slug: '1971'),
];

/// Lessons of one section, in book order.
List<BanglaFirstLesson> banglaFirstLessonsFor(String section) =>
    banglaFirstLessons.where((l) => l.section == section).toList();

/// Exact title match (lesson values are verbatim server strings).
BanglaFirstLesson? banglaFirstLessonByTitle(String title) {
  for (final l in banglaFirstLessons) {
    if (l.title == title) return l;
  }
  return null;
}

/// Server lesson titles with no map entry: shown under the
/// fallback section, never hidden and never misfiled.
List<String> banglaFirstUnmappedLessons(Iterable<String> serverTitles) =>
    serverTitles.where((t) => banglaFirstLessonByTitle(t) == null).toList();

/// Lesson by file slug (model-test setIds carry the slug).
BanglaFirstLesson? banglaFirstLessonBySlug(String slug) {
  for (final l in banglaFirstLessons) {
    if (l.slug == slug) return l;
  }
  return null;
}

/// Display name for a section value, from the page strings.
/// Unknown values fall back to the "other lessons" label.
String banglaFirstSectionName(String section, Map<String, String> s) {
  switch (section) {
    case 'goddo':
      return s['sectionProse']!;
    case 'poddo':
      return s['sectionPoetry']!;
    case 'uponnas':
      return s['sectionNovel']!;
    default:
      return s['otherLessons']!;
  }
}
