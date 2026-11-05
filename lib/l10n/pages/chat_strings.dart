// Text Chat (AI Doubt Solver) strings - page-wise Bangla + English.
// Text only: no voice in this screen, by design.
const Map<String, String> chatStringsBn = {
  'title': 'চ্যাট টিউটর',
  'context': 'প্রশ্ন ৫ · পৃষ্ঠা ৪৫ | গণিত · পরিমাপ ও ক্ষেত্রফল',
  'viewQuestion': 'মূল প্রশ্ন দেখুন',
  'tip': 'টিপস: প্রথমে সম্পূর্ণ ক্ষেত্রফল বের করে ভেতরের বাগানের ক্ষেত্রফল বাদ দাও।',
  // Greeting templates: {name} is replaced at runtime with the
  // saved profile's first name; greetingPlain is used when no
  // name exists, so no name is ever invented. greetingPrompt
  // names only generic parts (step / formula / calculation).
  'greetingNamed': 'নমস্কার {name}!',
  'greetingPlain': 'নমস্কার!',
  'greetingPrompt': 'এই প্রশ্নের কোন অংশে আটকে গেছো — ধাপ, সূত্র, নাকি হিসাব? আমাকে বলো, আমি ভেঙে বুঝিয়ে দিচ্ছি।',
  'userQ': 'স্যার, ক্ষেত্রফল বের করার সময় বর্গমিটার কেন হয় আর পরিসীমায় শুধু মিটার কেন থাকে?',
  'aiAnswer': 'চমৎকার প্রশ্ন! পরিসীমা হলো চারপাশের সীমানার মোট দৈর্ঘ্য, তাই একক শুধু মিটার। আর ক্ষেত্রফল হলো ভেতরের জায়গা, দৈর্ঘ্য × প্রস্থ = মিটার × মিটার, তাই বর্গমিটার।',
  'hint': 'প্রশ্ন লেখো…',
  'send': 'পাঠাও',
  'textOnly': 'এটি লেখা চ্যাট। ভয়েস টিউটর আলাদা প্রিমিয়াম স্ক্রিনে।',
  'savedQ': 'প্রশ্ন সেভ হয়েছে',
  'unsavedQ': 'সেভ বাতিল হয়েছে',
  'saveQ': 'সেভ করো',
  'outsideLesson': 'এই প্রশ্নটি এই লেসনের বইয়ের পাতার বাইরে। এই লেসন নিয়ে জিজ্ঞেস করো, অথবা সার্চে ঠিক প্রশ্নটি লেখো।',
  'notIndexedDetail': 'বইয়ের ইনডেক্সে এই প্রশ্নটি যাচাই করা যায়নি। সার্চে হুবহু প্রশ্নটি লেখো অথবা বইয়ের ছবি দাও — আন্দাজে উত্তর দেওয়া হবে না।',
  'aiFailed': 'লাইভ উত্তর আনা যায়নি। বইয়ের যাচাইকৃত লেখা থাকলে সেটাই দেখানো হচ্ছে।',
  'guideNotFound':
      'এই গাইড প্রশ্নটি খুঁজে পাওয়া যায়নি। গাইড-উত্তর স্ক্রিন থেকে আবার চেষ্টা করো — আন্দাজে উত্তর দেওয়া হবে না।',
  // Honest guide-chat states (2026-11-03 chat fix): shown
  // INSTEAD of a model call, never built from a wrong passage.
  'guideChatNoContext':
      'এই প্রশ্নের লেখা পাওয়া যায়নি, তাই চ্যাটে ব্যাখ্যা দেওয়া যাচ্ছে না। গাইড-উত্তর স্ক্রিন থেকে আবার চেষ্টা করো — আন্দাজে উত্তর দেওয়া হবে না।',
  'guideChatNoOptions':
      'এই MCQ-এর অপশন পাওয়া যায়নি, তাই চ্যাটে ব্যাখ্যা দেওয়া যাচ্ছে না — অপশন ছাড়া উত্তর বানানো হবে না। গাইড-উত্তর স্ক্রিনে অপশনগুলো দেখে আবার চেষ্টা করো।',
  'chatForQuestion': 'এই প্রশ্নের জন্য চ্যাট',
  'aiServerKeyMissing': 'AI সার্ভারে চালু হয়নি — সার্ভারের চাবি এখনো বসানো হয়নি।',
  'demoReply': 'ডেমো উত্তর — লাইভ AI নয়',
  'aiThinking': 'ভাবছি…',
};
const Map<String, String> chatStringsEn = {
  'title': 'Chat Tutor',
  'context': 'Question 5 · Page 45 | Maths · Measurement and area',
  'viewQuestion': 'View the original question',
  'tip': 'Tip: first find the full area, then subtract the inner garden area.',
  // See the Bangla map: named/plain greeting + generic prompt.
  'greetingNamed': 'Hello {name}!',
  'greetingPlain': 'Hello!',
  'greetingPrompt': 'Which part of this question are you stuck on — a step, the formula, or the calculation? Tell me and I will break it down for you.',
  'userQ': 'Sir, why is area in square metres, while perimeter is just in metres?',
  'aiAnswer': 'Great question! Perimeter is the total length around the edge, so its unit is just metres. Area is the space inside, length × width = metre × metre, so square metres.',
  'hint': 'Write your question…',
  'send': 'Send',
  'textOnly': 'This is a text chat. The voice tutor is a separate premium screen.',
  'savedQ': 'Question saved',
  'unsavedQ': 'Question unsaved',
  'saveQ': 'Save',
  'outsideLesson': "This question is outside this lesson's book page. Ask about this lesson, or type the exact question in Search.",
  'notIndexedDetail': 'This question could not be verified against the book index. Type the exact question in Search or share a photo of the book page — no answer will be guessed.',
  'aiFailed': 'The live answer could not be fetched. Showing the verified book text if one exists.',
  'guideNotFound':
      'This guide question could not be found. Try again from the guide answer screen — no answer will be guessed.',
  // Honest guide-chat states (2026-11-03 chat fix): shown
  // INSTEAD of a model call, never built from a wrong passage.
  'guideChatNoContext':
      'The text of this question could not be found, so no chat explanation can be given. Try again from the guide answer screen — no answer will be guessed.',
  'guideChatNoOptions':
      'The options for this MCQ could not be found, so no chat explanation can be given — no answer will be built without options. Check the options on the guide answer screen and try again.',
  'chatForQuestion': 'Chat for this question',
  'aiServerKeyMissing':
      'AI is not enabled on the server yet — the server key has not been set.',
  'demoReply': 'Demo reply — not live AI',
  'aiThinking': 'Thinking…',
};
