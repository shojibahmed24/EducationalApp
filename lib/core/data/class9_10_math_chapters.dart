// Static, verified chapter/lesson titles for class 9-10 mathematics.
//
// SOURCE (chapters): the NCTB textbook's own table of contents
// ("সূচিপত্র"), PDF page 5 of
// `Secondary-2026-Class-9-10-Math.pdf` (362 pages, image-only PDF —
// read visually from a 200 dpi render; the PDF has no text layer).
// Printed page ranges below are the ranges printed in that TOC.
// This is an INTERIM source: the app database has no class 9-10
// textbook chapter rows yet, so the new search UI reads titles here
// until the DB is populated. When the DB lands, it replaces this map.
//
// SOURCE (chapter-2 lessons): the guide pilot page_maps
// (`talimit/math/_work/pilot-2.1/page_map.md` and
// `pilot-2.2/page_map.md`) — guide banners, not invented titles.
// 2.1 = "সেট" (banner "অনুশীলনী ২.১ সেট");
// 2.2 = "অন্বয় ও ফাংশন এবং ডোমেন ও রেঞ্জ"
// (banner "অনুশীলনী ২.২ — অন্বয় ও ফাংশন এবং ডোমেন ও রেঞ্জ").
// The guide's chapter 2 has NO 2.3 lesson (pilot-2.2 page_map:
// after 2.2 come chapter-level sections, then chapter 3).
//
// English titles are DELIBERATELY omitted: the TOC prints Bangla
// titles only. Chapter-opening pages do carry English subtitles
// (e.g. ch. 2 "Set and Function"), but English was not verified for
// all 17 chapters, so no translation is guessed here.
//
// Guide cross-check (2026-11-01): the guide-covered chapters
// 2, 3, 7, 8, 9, 11, 16, 17 match the textbook TOC in number AND
// name — NO mismatch found. Chapters 1, 4, 5, 6, 10, 12, 13, 14, 15
// are textbook-only (the guide has no chapter 10 at all:
// after ch. 9 comes ch. 11).

/// Class 9-10 math chapter number -> Bangla title (NCTB TOC).
const Map<int, String> class9_10MathChapterTitles = {
  1: 'বাস্তব সংখ্যা', // printed pp. 1-20
  2: 'সেট ও ফাংশন', // printed pp. 21-42
  3: 'বীজগাণিতিক রাশি', // printed pp. 43-74
  4: 'সূচক ও লগারিদম', // printed pp. 75-92
  5: 'এক চলকবিশিষ্ট সমীকরণ', // printed pp. 93-110
  6: 'রেখা, কোণ ও ত্রিভুজ', // printed pp. 111-135
  7: 'ব্যবহারিক জ্যামিতি', // printed pp. 136-151
  8: 'বৃত্ত', // printed pp. 152-173
  9: 'ত্রিকোণমিতিক অনুপাত', // printed pp. 174-196
  10: 'দূরত্ব ও উচ্চতা', // printed pp. 197-204
  11: 'বীজগাণিতিক অনুপাত ও সমানুপাত', // printed pp. 205-223
  12: 'দুই চলকবিশিষ্ট সরল সহসমীকরণ', // printed pp. 224-248
  13: 'সসীম ধারা', // printed pp. 249-265
  14: 'অনুপাত, সদৃশতা ও প্রতিসমতা', // printed pp. 266-284
  15: 'ক্ষেত্রফল সম্পর্কিত উপপাদ্য ও সম্পাদ্য', // printed pp. 285-293
  16: 'পরিমিতি', // printed pp. 294-315
  17: 'পরিসংখ্যান', // printed pp. 316-344
};

/// Chapter-2 lesson titles. DB-backed scope: these are the lessons
/// the guide database actually covers for chapter 2. Keep separate
/// from [guideLessonTitles]: ch2 titles come from the pilot-2.1/
/// 2.2 page_maps, the other map from the pilot-3/7/8/9/11/16
/// page_maps. Both maps are DB-backed since the 2026-11-01 math
/// import; they stay separate by chapter for readability.
const Map<String, String> chapter2LessonTitles = {
  '2.1': 'সেট',
  '2.2': 'অন্বয় ও ফাংশন এবং ডোমেন ও রেঞ্জ',
};

/// Guide lesson titles, lesson-code -> banner title.
///
/// Read from the guide pilot page_maps' "লেসন-শিরোনাম" sections
/// (guide banners verified at 500 dpi / scout renders):
/// pilot-3, pilot-7, pilot-8, pilot-9, pilot-11 (11.1 banner on PDF
/// 604, 11.2 banner on PDF 636), pilot-16 (title table with banner
/// references for 16.1–16.4).
/// DB-backed scope: every key matches a live DB lesson value
/// verbatim (math import 2026-11-01 landed ch 3/7/8/9/11/16 lessons
/// in the DB). Formerly named pilotOnlyLessonTitles, when these
/// lessons existed in pilot files only; that name is retired now
/// that the DB covers them — nothing here is pilot-only any more.
/// Chapter 3's guide also has an unnumbered "পরিশিষ্ট" (appendix)
/// section — it is not a numbered lesson, so it is intentionally
/// absent from this map (its rows stay reachable via 'সব লেসন').
const Map<String, String> guideLessonTitles = {
  // Chapter 3 — বীজগাণিতিক রাশি (pilot-3/page_map.md).
  '3.1': 'বর্গ সংবলিত সূত্রাবলি ও প্রয়োগ',
  '3.2': 'ঘন সংবলিত সূত্রাবলি ও প্রয়োগ',
  '3.3': 'উৎপাদকে বিশ্লেষণ',
  '3.4': 'ভাগশেষ উপপাদ্য',
  '3.5': 'বাস্তব সমস্যা সমাধানে বীজগাণিতিক সূত্র গঠন ও প্রয়োগ',
  // Chapter 7 — ব্যবহারিক জ্যামিতি (pilot-7/page_map.md).
  '7.1': 'ত্রিভুজ অঙ্কন',
  '7.2': 'চতুর্ভুজ অঙ্কন',
  // Chapter 8 — বৃত্ত (pilot-8/page_map.md).
  '8.1': 'বৃত্তের জ্যা ও ব্যাস সংক্রান্ত উপপাদ্য',
  '8.2': 'বৃত্তচাপ, বৃত্তস্থ ও কেন্দ্রস্থ কোণ সংক্রান্ত উপপাদ্য',
  '8.3': 'বৃত্তস্থ চতুর্ভুজ ও বৃত্ত সংক্রান্ত উপপাদ্য',
  '8.4': 'বৃত্তের ছেদক ও স্পর্শক',
  '8.5': 'বৃত্ত সম্পর্কীয় সম্পাদ্য ও বৃত্তের স্পর্শক অঙ্কন',
  // Chapter 9 — ত্রিকোণমিতিক অনুপাত (pilot-9/page_map.md).
  '9.1': 'ত্রিকোণমিতিক অনুপাত ও অনুপাতের সম্পর্ক',
  '9.2': 'বিভিন্ন কোণের ত্রিকোণমিতিক অনুপাত',
  // Chapter 11 — বীজগাণিতিক অনুপাত ও সমানুপাত (pilot-11/page_map.md).
  '11.1': 'বীজগাণিতিক অনুপাত ও সমানুপাত',
  '11.2': 'ধারাবাহিক অনুপাত ও সমানুপাতিক ভাগ',
  // Chapter 16 — পরিমিতি (pilot-16/page_map.md title table).
  '16.1': 'ত্রিভুজক্ষেত্রের ক্ষেত্রফল',
  '16.2': 'চতুর্ভুজক্ষেত্রের ক্ষেত্রফল',
  '16.3': 'বৃত্ত সংক্রান্ত পরিমাপ',
  '16.4': 'আয়তাকার ঘনবস্তু',
};
