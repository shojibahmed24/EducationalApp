// Home page strings - page-wise Bangla + English, written with the screen.
const Map<String, String> homeStringsBn = {
  'greeting': 'হ্যালো',
  'classChip': 'ক্লাস',
  'todayGoal': 'আজ কী পড়বে? চলো লক্ষ্য পূরণ করি।',
  'searchHint': 'পেজ / প্রশ্ন খুঁজো…',
  'continueLearning': 'আগের পড়া চালিয়ে যাও',
  'continueSubject': 'গণিত · অধ্যায় ৩ · পৃষ্ঠা ৪৫',
  'continueTopic': 'পরিমাপ ও ক্ষেত্রফল নির্ণয়',
  'progressDone': '৬০% সম্পন্ন',
  'continue': 'চালিয়ে যাও',
  'streak': 'দিনের স্ট্রিক',
  'chaptersDone': 'অধ্যায় শেষ',
  'avgScore': 'গড় স্কোর',
  'todaysRoutine': 'আজকের রুটিন',
  'routineDone': '৩টির মধ্যে ১টি সম্পন্ন',
  'subjects': 'বিষয়সমূহ',
  'seeAll': 'সব দেখুন',
  'weakChapters': 'দুর্বল অধ্যায়',
  'practiceAgain': 'আবার পড়ো',
  'recommendations': 'তোমার জন্য পরামর্শ',
  'recentBooks': 'সম্প্রতি খোলা বই',
  'home': 'হোম',
  'search': 'সার্চ',
  'practice': 'প্র্যাকটিস',
  'progress': 'প্রোগ্রেস',
  'profile': 'প্রোফাইল',
  'noDataYet': 'এখনো কোনো রেকর্ড নেই — প্রথম লেসন শুরু করো।',
  'noLessonYet': 'এখনো কোনো লেসন খোলা হয়নি',
  'startFromSearch': 'সার্চ থেকে শুরু করো',
  'lessonsOpened': 'লেসন খোলা হয়েছে',
  'savedCount': 'সেভ করা প্রশ্ন',
  'booksOpened': 'বই খোলা হয়েছে',
  'lessonsToday': 'আজকের লেসন',
  // Batch 2, item 3: the middle stat is chapters OPENED
  // (LearnStore distinct chapter keys), not finished — no
  // completion event exists, so the old 'অধ্যায় শেষ' label
  // claimed something the number never measured.
  'chaptersOpened': 'অধ্যায় খোলা',
  // Home stat detail screens: titles + honest empty states.
  'todayLessonsTitle': 'আজকের লেসন',
  'todayLessonsEmpty': 'আজ এখনো কোনো লেসন খোলা হয়নি',
  'openedChaptersTitle': 'খোলা অধ্যায়',
  'openedChaptersEmpty': 'এখনো কোনো অধ্যায় খোলা হয়নি',
  // Batch 2, item 3: shown instead of the subject grid when no
  // class has been chosen yet, so Home never pretends Class 6.
  'chooseClassTitle': 'ক্লাস বাছা হয়নি',
  'chooseClassBody':
      'সেটিংসে গিয়ে তোমার ক্লাস বাছো — তাহলে তোমার ক্লাসের বিষয়গুলো এখানে দেখাবে।',
  'chooseClassAction': 'সেটিংসে যাও',
  'noWeakYet': 'এখনো দুর্বল অধ্যায় চিহ্নিত হয়নি',
  'findQuestions': 'প্রশ্ন খুঁজুন',
  'noRecentBook': 'এখনো কোনো বই খোলা হয়নি',
  'loadingSubjects': 'বিষয় লোড হচ্ছে…',
  'noSubjects': 'কোনো বিষয় পাওয়া যায়নি',
  // Cache-once home grid: shown ONLY when no saved list exists
  // and the fetch fails — never for a load failure that still
  // has a list on screen, and never as "no subjects".
  'subjectsLoadFailed': 'বিষয় লোড করা যায়নি — আবার চেষ্টা করো।',
  'subjectsRetry': 'আবার চেষ্টা করুন',
  // Set-based guide tile (class-9 English): number + suffix.
  'guideSets': 'টি সেট',
  // Bank-only guide subject (sets and chapters both zero).
  'guideAvailable': 'গাইড আছে',
  'refreshSubjects': 'বিষয় রিফ্রেশ করো',
  // Phase 6 (H1): home is the tab root, so system back asks twice
  // instead of silently exiting the app.
  'pressBackAgain': 'আবার ব্যাক চাপলে অ্যাপ বন্ধ হবে',
};
const Map<String, String> homeStringsEn = {
  'greeting': 'Hello',
  'classChip': 'Class',
  'todayGoal': 'What will you study today? Let\'s meet your goal.',
  'searchHint': 'Search page / question…',
  'continueLearning': 'Continue your last lesson',
  'continueSubject': 'Maths · Chapter 3 · Page 45',
  'continueTopic': 'Measurement and area',
  'progressDone': '60% done',
  'continue': 'Continue',
  'streak': 'day streak',
  'chaptersDone': 'chapters done',
  'avgScore': 'average score',
  'todaysRoutine': 'Today\'s routine',
  'routineDone': '1 of 3 done',
  'subjects': 'Subjects',
  'seeAll': 'See all',
  'weakChapters': 'Weak chapters',
  'practiceAgain': 'Study again',
  'recommendations': 'Recommended for you',
  'recentBooks': 'Recently opened books',
  'home': 'Home',
  'search': 'Search',
  'practice': 'Practice',
  'progress': 'Progress',
  'profile': 'Profile',
  'noDataYet': 'No record yet — start your first lesson.',
  'noLessonYet': 'No lesson opened yet',
  'startFromSearch': 'Start from Search',
  'lessonsOpened': 'lessons opened',
  'savedCount': 'saved questions',
  'booksOpened': 'books opened',
  'lessonsToday': "today's lessons",
  // Batch 2, item 3: see the Bangla note above — opened, not done.
  'chaptersOpened': 'chapters opened',
  // Home stat detail screens: titles + honest empty states.
  'todayLessonsTitle': "Today's lessons",
  'todayLessonsEmpty': 'No lessons opened today yet',
  'openedChaptersTitle': 'Opened chapters',
  'openedChaptersEmpty': 'No chapters opened yet',
  // Batch 2, item 3: shown instead of the subject grid when no
  // class has been chosen yet, so Home never pretends Class 6.
  'chooseClassTitle': 'No class chosen yet',
  'chooseClassBody':
      'Choose your class in Settings to see your class subjects here.',
  'chooseClassAction': 'Go to Settings',
  'noWeakYet': 'No weak chapter marked yet',
  'findQuestions': 'Find questions',
  'noRecentBook': 'No book opened yet',
  'loadingSubjects': 'Loading subjects…',
  'noSubjects': 'No subjects found',
  'subjectsLoadFailed': 'Subjects could not be loaded — try again.',
  'subjectsRetry': 'Try again',
  'guideSets': 'sets',
  'guideAvailable': 'Guide available',
  'refreshSubjects': 'Refresh subjects',
  'pressBackAgain': 'Press back again to exit the app',
};
