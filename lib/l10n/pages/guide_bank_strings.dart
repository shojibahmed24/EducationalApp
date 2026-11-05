// Guide bank strings - page-wise Bangla + English.
const Map<String, String> guideBankStringsBn = {
  'title': 'গাইড ব্যাংক',
  'textbookTab': 'পাঠ্যবই',
  'guideTab': 'গাইড',
  'loading': 'গাইড প্রশ্ন আনা হচ্ছে…',
  'emptyChapter': 'এই অধ্যায়ের গাইড প্রশ্ন এখনো যোগ হয়নি',
  'unavailableTitle': 'গাইড প্রশ্ন এখনো যুক্ত হয়নি',
  'unavailableBody':
      'এই অধ্যায়ের গাইড প্রশ্ন এখনো এই অ্যাপে যোগ হয়নি। যোগ হলে এখানেই দেখা যাবে।',
  'questionsSuffix': 'টি প্রশ্ন',
  'keyedSuffix': 'টি চাবিযুক্ত',
  'chaptersSuffix': 'টি অধ্যায়',
  'filterAll': 'সব',
  'filterMcq': 'MCQ',
  'filterShort': 'সংক্ষিপ্ত',
  'filterCreative': 'সৃজনশীল',
  'filterFillBlank': 'শূন্যস্থান পূরণ',
  'filterOther': 'অন্যান্য',
  'searchHint': 'প্রশ্ন খুঁজুন…',
  'loadMore': 'আরো দেখুন',
  'lockedNote': 'প্রিমিয়ামে দেখুন',
  'keyMissing': 'চাবি নেই',
  'reportTitle': 'প্রশ্নটি রিপোর্ট করুন',
  'reportWrongKey': 'ভুল চাবি',
  'reportWrongChapter': 'ভুল অধ্যায়',
  'reportUnreadable': 'পড়া যায় না',
  'reportSubmit': 'রিপোর্ট জমা দিন',
  'reportSavedLocal':
      'রিপোর্ট ডিভাইসে সংরক্ষিত হয়েছে — সার্ভারে পাঠানো এখনো চালু হয়নি',
  'modelTestsTitle': 'গাইড মডেল টেস্ট',
  'modelTestsEntrySub': 'গাইডের মডেল টেস্ট সেট — টাইমড পরীক্ষা',
  'modelTestsEmpty': 'এই বিষয়ের গাইড মডেল টেস্ট এখনো যোগ হয়নি',
  'modelTestsUnavailable':
      'সার্ভারে পৌঁছানো যায়নি, আর সংরক্ষিত সেটও নেই। আবার চেষ্টা করো।',
  'modelTestNoKeyed': 'এই সেটে চাবিযুক্ত MCQ পাওয়া যায়নি।',
  'modelTestStart': 'শুরু করুন',
  'unkeyedExcludedSuffix': 'টি প্রশ্নের চাবি নেই — স্কোরিং থেকে বাদ',
  'answerUnavailable': 'এই গাইড প্রশ্নের উত্তর এখনো যুক্ত হয়নি',
  'answerFailed': 'ব্যাখ্যা তৈরি করা যায়নি',
  'explanationKeyMismatch':
      'এআই ব্যাখ্যাটি গাইডের উত্তরের সঙ্গে মেলেনি, তাই দেখানো হয়নি। উপরে গাইডের সঠিক উত্তর চিহ্নিত আছে।',
  'retry': 'আবার চেষ্টা করুন',
  'guideQuestions': 'গাইড প্রশ্ন',
  'marksWord': 'নম্বর',
  'back': 'ফিরে যান',
  // Pilot (lesson 2.1, 2026-10-31): level selector, section tabs,
  // practice-work warning, creative group header.
  'practiceWorkNote': 'এটা অনুশীলনের জন্য, পাঠ্যবইয়ের সমাধান নয়',
  'solutionAvailable': 'সমাধান আছে',
  'explanationLoading': 'ব্যাখ্যা তৈরি হচ্ছে…',
  // On-demand (2026-11-03 fix): the explanation button + the
  // honest note for an MCQ whose options never arrived.
  'viewExplanation': 'ব্যাখ্যা দেখুন',
  'explanationUnavailableOptions':
      'এই প্রশ্নের অপশন পাওয়া যায়নি, তাই AI ব্যাখ্যা তৈরি করা যাচ্ছে না। প্রশ্ন আর চাবি থাকলে চ্যাটে জিজ্ঞেস করো।',
  // Server search (whole guide, 2026-10-31): searching note and
  // the honest fallback note when the server search fails and
  // the list falls back to chapter-local filtering.
  // Verbatim-first stage 1 (2026-10-31): guide text as printed,
  // corrected text with its note, or an honest no-verbatim note.
  'verbatimGuideTitle': 'গাইডের উত্তর',
  'verbatimCorrectedTitle': 'সংশোধিত উত্তর',
  'verbatimCorrectedNote': 'গাইডে ছাপা উত্তরে ভুল ছিল',
  // Label fix (2026-11-01): AI-written text is NEVER titled as
  // the guide's answer. No-verbatim cards read exactly this.
  'aiAnswerTitle': 'AI ব্যাখ্যা (গাইডে ছাপা নেই)',
  'aiAnswerNoGuideNote':
      'গাইডে এই প্রশ্নের লেখা সমাধান পাওয়া যায়নি — নিচের উত্তরটি AI লিখেছে, এটি গাইডের লেখা নয়',
  'verbatimErrorNote':
      'গাইডে ছাপা উত্তর ভুল প্রমাণিত, সংশোধন এখনো তৈরি হয়নি — নিচে এআই ব্যাখ্যা দেখুন',
  'explainDetailed': 'বিস্তারিত বলুন',
  'explainSteps': 'ধাপে ধাপে বুঝিয়ে বলুন',
  // Step 6 (creative grouped view + ask-AI restore): stimulus
  // header title + the button that opens grounded chat.
  'stimulusTitle': 'উদ্দীপক',
  'passageSource': 'প্যাসেজের উৎস',
  'askAi': 'AI-কে জিজ্ঞাসা কর',
  // Phase 3: link to the linked bank model row (Q10-12 rows).
  'modelAnswer': 'মডেল উত্তর',
  // MCQ try-first options card (2026-11-01): options render
  // with math; the student picks before the key reveals.
  'optionsTitle': 'অপশন',
  'optionsTryHint': 'একটি অপশন বাছো — তারপর সঠিক উত্তর দেখা যাবে',
  'optionsCorrect': 'ঠিক উত্তর!',
  'optionsWrong': 'ভুল হয়েছে — সঠিক উত্তরটি দেখো',
  'optionsMissing':
      'এই প্রশ্নের অপশন তোলা হয়নি — অপশন ছাড়া উত্তর বাছা যাবে না',
  'chapterWord': 'অধ্যায়',
  'modelTestWord': 'মডেল টেস্ট',
};
const Map<String, String> guideBankStringsEn = {
  'title': 'Guide Bank',
  'textbookTab': 'Textbook',
  'guideTab': 'Guide',
  'loading': 'Loading guide questions…',
  'emptyChapter': 'No guide questions added for this chapter yet',
  'unavailableTitle': 'Guide questions not connected yet',
  'unavailableBody':
      'Guide questions for this chapter have not been added to this app yet. They will appear here once added.',
  'questionsSuffix': ' questions',
  'keyedSuffix': ' keyed',
  'chaptersSuffix': ' chapters',
  'filterAll': 'All',
  'filterMcq': 'MCQ',
  'filterShort': 'Short',
  'filterCreative': 'Creative',
  'filterFillBlank': 'Fill in the blanks',
  'filterOther': 'Other',
  'searchHint': 'Search questions…',
  'loadMore': 'Load more',
  'lockedNote': 'See with Premium',
  'keyMissing': 'No key',
  'reportTitle': 'Report this question',
  'reportWrongKey': 'Wrong key',
  'reportWrongChapter': 'Wrong chapter',
  'reportUnreadable': 'Unreadable',
  'reportSubmit': 'Submit report',
  'reportSavedLocal':
      'Report saved on this device — server submission is not live yet',
  'modelTestsTitle': 'Guide Model Tests',
  'modelTestsEntrySub': 'Guide model-test sets — timed exams',
  'modelTestsEmpty': 'No guide model tests added for this subject yet',
  'modelTestsUnavailable': 'Server unreachable and no cached sets. Try again.',
  'modelTestNoKeyed': 'No keyed MCQs found in this set.',
  'modelTestStart': 'Start',
  'unkeyedExcludedSuffix': ' questions have no key — excluded from scoring',
  'answerUnavailable': 'This guide question is not connected yet',
  'answerFailed': 'Explanation could not be generated',
  'explanationKeyMismatch':
      'The AI explanation did not match the guide answer, so it is withheld. The guide answer is marked above.',
  'retry': 'Try again',
  'guideQuestions': 'Guide questions',
  'marksWord': 'marks',
  'back': 'Go back',
  'practiceWorkNote': 'For practice only, not the textbook solution',
  'solutionAvailable': 'Solution available',
  'explanationLoading': 'Generating explanation…',
  // On-demand (2026-11-03 fix): the explanation button + the
  // honest note for an MCQ whose options never arrived.
  'viewExplanation': 'View explanation',
  'explanationUnavailableOptions':
      'The options for this question could not be found, so an AI explanation cannot be generated. Ask in chat if the question and key are shown.',
  'verbatimGuideTitle': 'Guide answer',
  'verbatimCorrectedTitle': 'Corrected answer',
  'verbatimCorrectedNote': 'The printed guide answer was wrong',
  'aiAnswerTitle': 'AI explanation (not printed in the guide)',
  'aiAnswerNoGuideNote':
      'No written guide solution was found for this question in the guide — the answer below was written by AI and is not the guide\'s text',
  'verbatimErrorNote':
      'The printed guide answer was proven wrong and no correction is ready yet — see the AI explanation below',
  'explainDetailed': 'Explain in detail',
  'explainSteps': 'Explain step by step',
  'stimulusTitle': 'Stimulus',
  'passageSource': 'Passage source',
  'askAi': 'Ask AI',
  'modelAnswer': 'Model answer',
  'optionsTitle': 'Options',
  'optionsTryHint': 'Pick an option — the correct answer reveals after',
  'optionsCorrect': 'Correct!',
  'optionsWrong': 'Not quite — see the correct answer',
  'optionsMissing':
      'This question\'s options were not captured — you cannot pick an answer without them',
  'chapterWord': 'Chapter',
  'modelTestWord': 'Model test',
};
