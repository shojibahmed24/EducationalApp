// Search page strings - page-wise Bangla + English.
const Map<String, String> searchStringsBn = {
  'title': 'পাঠ্যবই সমাধান খুঁজুন',
  'subtitle': 'সহজ ৪ ধাপে তোমার বইয়ের যেকোনো অনুশীলনী সমাধান করো',
  'stepSubject': '১. বিষয়',
  'stepChapter': '২. অধ্যায়',
  'stepPage': '৩. পৃষ্ঠা নম্বর',
  'stepProblem': '৪. প্রশ্ন নম্বর',
  'subject': 'গণিত',
  'chapter': 'অধ্যায় ৩: বীজগাণিতিক রাশি',
  'pageLabel': 'পৃষ্ঠা নম্বর (ঐচ্ছিক)',
  'problemLabel': 'প্রশ্ন নম্বর (ঐচ্ছিক)',
  'showSolution': 'সমাধান দেখো',
  'bookLookup': 'পৃষ্ঠা ধরে প্রশ্ন খুঁজুন',
  'chapterListButton': 'অধ্যায়ের সব প্রশ্ন দেখুন',
  'classLabel': 'শ্রেণি',
  'textbookOnlyNote':
      'এই তালিকায় শুধু NCTB পাঠ্যবইয়ের প্রশ্ন আছে। গাইড বইয়ের প্রশ্ন গাইড ব্যাংকে পাবে।',
  'guideBankLink': 'গাইড ব্যাংক দেখুন',
  'guideChaptersButton': 'গাইডের অধ্যায় দেখুন',
  'recent': 'সম্প্রতি খোঁজা',
  'clearRecent': 'মুছুন',
  'recentCleared': 'সম্প্রতি খোঁজা মুছে ফেলা হয়েছে',
  // Ready / not-indexed templates: {subject} {chapter} {page}
  // {problem} are filled from the CURRENT selection — never a
  // hardcoded page/question (the old 'ready' string said p.45 q.7
  // no matter what the selector showed).
  'readyTemplate':
      '{subject} · অধ্যায় {chapter}, পৃষ্ঠা {page}-এর প্রশ্ন {problem}-এর সমাধান প্রস্তুত আছে',
  'notIndexedTemplate':
      '{subject} · অধ্যায় {chapter}, পৃষ্ঠা {page}-এর প্রশ্ন {problem} বইয়ের সূচিতে পাওয়া যায়নি',
  'chaptersLoadFailed':
      'অধ্যায়ের তালিকা লোড করা যায়নি — সমাধান দেখো চাপলে সরাসরি যাচাই হবে',
  'notFoundHint': 'খুঁজে না পেলে এখানে যাও',
  'lockedSubject': 'এই বিষয়ের বই এখনো দেওয়া হয়নি, তাই লেসন খোলা যাবে না',
  'noRecentSearch': 'এখনো কিছু খোঁজা হয়নি',
  'loadingChapters': 'অধ্যায় লোড হচ্ছে…',
  'chapterInBook': 'এই অধ্যায়টি বইয়ে আছে, কিন্তু নির্দিষ্ট প্রশ্নটি যাচাই করা যায়নি',
  'chapterNotInBook': 'এই অধ্যায়টি বইয়ে পাওয়া যায়নি',
  'checking': 'যাচাই করা হচ্ছে…',
  // Phase 16 (M1): text typed on Home, shown here, not discarded.
  'homeSearch': 'হোম থেকে খোঁজা:',
  'homeSearchSub': 'এই লেখাটি সরাসরি মেলানো যায় না — নিচের ৪ ধাপে বিষয়, অধ্যায়, পৃষ্ঠা ও প্রশ্ন বেছে সমাধান দেখো।',
};
const Map<String, String> searchStringsEn = {
  'title': 'Find a textbook solution',
  'subtitle': 'Solve any exercise from your book in 4 easy steps',
  'stepSubject': '1. Subject',
  'stepChapter': '2. Chapter',
  'stepPage': '3. Page number',
  'stepProblem': '4. Question number',
  'subject': 'Maths',
  'chapter': 'Chapter 3: Algebraic expressions',
  'pageLabel': 'Page number (optional)',
  'problemLabel': 'Question number (optional)',
  'showSolution': 'Show solution',
  'bookLookup': 'Find questions by page',
  'chapterListButton': 'See all questions in this chapter',
  'classLabel': 'Class',
  'textbookOnlyNote':
      'This list holds NCTB textbook questions only. Guide-book questions live in the Guide Bank.',
  'guideBankLink': 'See Guide Bank',
  'guideChaptersButton': 'See guide chapters',
  'recent': 'Recently searched',
  'clearRecent': 'Clear',
  'recentCleared': 'Recent searches cleared',
  'readyTemplate':
      '{subject} · Chapter {chapter}, page {page}, question {problem} solution is ready',
  'notIndexedTemplate':
      '{subject} · Chapter {chapter}, page {page}, question {problem} was not found in the book index',
  'chaptersLoadFailed':
      'Chapter list could not be loaded — Show solution will verify directly',
  'notFoundHint': 'If not found, go here',
  'lockedSubject': "This subject's book is not supplied yet, so no lesson can be opened",
  'noRecentSearch': 'Nothing searched yet',
  'loadingChapters': 'Loading chapters…',
  'chapterInBook': 'This chapter is in the book, but the specific question could not be verified',
  'chapterNotInBook': 'This chapter was not found in the book',
  'checking': 'Checking…',
  'homeSearch': 'Searched from Home:',
  'homeSearchSub': 'This text cannot be matched directly — use the 4 steps below (subject, chapter, page, question) to see the solution.',
};
