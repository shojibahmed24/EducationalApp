# Yes Sir AI — সম্পূর্ণ সমস্যার তালিকা (2026-10-28)

> অডিট পদ্ধতি: ৫টি আলাদা এজেন্ট, প্রতিটি আলাদা এরিয়া, কোড পড়ে যাচাই করে।
> কোনো কোড বদলানো হয়নি। Severity: CRITICAL = ব্যবহার আটকায় / ভুল তথ্য দেয়,
> HIGH = চোখে পড়ে ও ব্যবহারে বাধা দেয়, MEDIUM = অর্ধেক কাজ করে / বিভ্রান্ত করে,
> LOW = ছোটখাটো / কসমেটিক।
> “ঠিক আছে” বলে যাচাই করা জিনিসগুলো শেষে আছে, যাতে সেগুলোর পেছনে সময় নষ্ট না হয়।

## ব্যবহারকারীর প্রশ্নের উত্তর

### ১. ডেমো মোড লেখাটা ওইখানে কি থাকবে?
কিছুই থাকবে না। `lib/core/widgets/demo_banner.dart` — Supabase চাবি
(`--dart-define=SUPABASE_URL` + `SUPABASE_ANON_KEY`) দিলে ব্যানার
`SizedBox.shrink()` হয়ে যায়, জায়গাটা ভাঁজ হয়ে কন্টেন্ট উপরে উঠে আসে।
কোনো “কানেক্টেড” ব্যাজ, অ্যাকাউন্ট লেবেল বা স্ট্যাটাস লাইন আসে না।
সতর্কতা: ব্যানার শুধু Supabase চাবি দেখে। OpenRouter/Gemini চাবি না
থাকলেও ব্যানার উঠে যাবে, অথচ লেসন/AI তখনো ডেমো চলবে — ব্যবহারকারী
ভুল করে ভাববে “ফুল ইমপ্লিমেন্টেশন লাইভ”।

### ২. “সঠিক উত্তর, স্যারের সহজ ব্যাখ্যা” — এটা কে দেবে? AI দেবে, তাই না?
হ্যাঁ, দেওয়ার কথা AI-এর, বইয়ের ভিত্তিতে। কিন্তু এখন এটা AI নয়।
`lib/core/services/practice_service.dart:122-140` `explanation()` — হার্ডকোড
করা bn/en ম্যাপ, শুধু ১০টি প্রশ্নের জন্য (mq1–mq5, sq1–sq5)।
OpenRouter key দিলেও কুইজের ব্যাখ্যা AI হবে না, কারণ ওই ফাংশনে AI-এর
কোনো শাখাই নেই। মডেল টেস্টের ৮টি প্রশ্নের (mm6–mm10, sm6–sm8) ব্যাখ্যা
ম্যাপেই নেই — শুধু ফলব্যাক “সঠিক উত্তরটি মিলিয়ে দেখো” দেখাবে।
লেসনের ব্যাখ্যাও আলাদা সমস্যা (নিচে #12 দেখুন)।

---

## CRITICAL

### C1. বই ডাটাবেজে আছে, অ্যাপ তা পড়ে না — সবচেয়ে বড় গ্যাপ
- Supabase-এ ৪৪টি বই + ৪৬২টি চ্যাপ্টার ঢোকানো হয়েছে (যাচাই করা)।
- কিন্তু `book_library_screen.dart:34-35`, `books_service.dart:33-53`,
  `chapters_screen.dart:39-48`, `book_page_viewer_screen.dart`,
  `search_screen.dart` — কোথাও `books` / `books_public` /
  `book_questions` টেবিলের কোনো `from()` কল নেই।
- বই লিস্ট হার্ডকোড ৬টি বিষয়, চ্যাপ্টার লিস্ট গণিতে মক ৫টি, বাকিদের
  জেনেরিক “অধ্যায় ১–৫”, ভিউয়ারে সব বই ২৪০ পৃষ্ঠা, আসল PDF দেখায় না।
- ফল: DB ইমপোর্ট শেষ হওয়া মানেই অ্যাপে বই আসা নয়। `books_service` /
  `learn_service` / `chapters_screen` / `book_page_viewer`-কে Supabase
  রিডে বদলাতে হবে।

### C2. লেসন/সার্চ ইনডেক্সে মাত্র ২টি প্রশ্ন
- `learn_service.dart:8-15`: লোকাল ইনডেক্সে শুধু `math|3|45|7` (অনুপাত)
  আর `math|3|45|5` (ক্ষেত্রফল)। এর বাইরে যেকোনো বিষয়/অধ্যায়/পৃষ্ঠা/
  প্রশ্ন → `noMatch`।
- গণিতের ৪৫ পৃষ্ঠা ছাড়া সব পৃষ্ঠা থেকে ব্যাখ্যা পাওয়া যায় না।
- প্রোডাকশনেও AI-কে বইয়ের টেক্সট পাঠানো হয় না, শুধু প্রশ্নের
  শিরোনাম (`grounded.question`) পাঠানো হয়, মডেল `openrouter/auto`।
  তাই “AI ব্যাখ্যা” থাকলেও তা বই-গ্রাউন্ডেড নয়।
- চ্যাটেও একই গেট: ইনডেক্সে না মিললে `outsideLesson`, মিললে DEMO-তে
  হার্ডকোড উত্তর; ব্যবহারকারীর টাইপ করা প্রশ্নের টেক্সট AI-কে যায় না।

### C3. প্রোফাইলে বানানো স্ট্যাট আসল ডাটা হিসেবে দেখায়
- `profile_screen.dart:67-92` + `profile_strings.dart:6-10`: “৭ দিন টানা”,
  “৮টি মেডেল”, “১২টি সংরক্ষিত প্রশ্ন”, “১৪ ঘণ্টা” — সব হার্ডকোড লেখা।
- নতুন ইনস্টলেও একই দেখাবে, যদিও আসল ডাটা (progress_service,
  LocalStore.savedQuestions) অন্যত্র আছে এবং ব্যবহার করা হয় না।
- নাম/ক্লাস/স্কুল আসল, তাই বানানো স্ট্যাট ধরা আরো কঠিন।
- PHASE 4 FIX (2026-10-28, C3 leftover): প্রোফাইলের বানানো আইডি
  লাইন ('আইডি: YS-2024-8902' / 'ID: YS-2024-8902') সরানো হয়েছে।
  এখন শুধু সেভ করা প্রোফাইলের আসল 'id' দেখায় (Supabase userId,
  DEMO-তে 'demo-user'); প্রোফাইল/আইডি না থাকলে আইডি লাইন একদম
  লুকানো থাকে, কোনো বানানো নম্বর নয়। নাম/ক্লাস/স্কুল লজিক অপরিবর্তিত।

### C4. Hind Siliguri ফন্ট ঘোষণা করা, কিন্তু বান্ডল করা হয়নি
- `app_theme.dart:22,58`: `fontFamily: 'Hind Siliguri'`।
- `pubspec.yaml`-এ কোনো `fonts:` সেকশন নেই, প্রজেক্টে কোনো `.ttf` নেই।
- ফলে ফোনের সিস্টেম ফন্টে fallback হয়; TECNO-সহ যেসব ফোনে ভালো
  বাংলা ফন্ট নেই, সেখানে যুক্তাক্ষর ভেঙে যেতে পারে।
- PHASE 4 FIX (2026-10-28): মিথ্যা দাবি সরানো হয়েছে, ফন্ট বান্ডল
  করা হয়নি — কারণ ওয়ার্কস্পেসে কোথাও Hind Siliguri / Noto Sans
  Bengali / অন্য কোনো বাংলা ফন্ট ফাইল নেই (লোগো প্যাকে কোনো ফন্ট
  নেই, শুধু SVG/PNG; Stitch DESIGN.md Plus Jakarta Sans-এর নাম দেয়
  কিন্তু ফাইল দেয় না; পাওয়া একমাত্র .ttf MaterialIcons, বিল্ড
  আর্টিফ্যাক্ট)। অযাচাই করা সোর্স থেকে ফন্ট ডাউনলোড করা হয়নি।
  `app_theme.dart` থেকে দুটি `fontFamily: 'Hind Siliguri'` লাইন
  তোলা হয়েছে; থিম এখন Flutter-এর সিস্টেম-সেফ ডিফল্ট ব্যবহার করে
  (Roboto + ডিভাইসের নিজস্ব বাংলা fallback)। সীমা: ভালো বাংলা
  ফন্ট নেই এমন ফোনে যুক্তাক্ষরের ঝুঁকি আগের মতোই থাকে, তবে এখন
  তা সৎভাবে ডকুমেন্ট করা (app_theme.dart কমেন্ট + pubspec.yaml
  নোট)। সঠিক সমাধানের পথ: OFL-লাইসেন্সযুক্ত Hind Siliguri/Noto
  Sans Bengali .ttf এনে assets/fonts/-এ রেখে pubspec.yaml-এ
  রেজিস্টার করলেই fontFamily ফেরানো যাবে।

### C5. রেজিস্ট্রেশন সাকসেস দেখায়, কিন্তু আসল অ্যাকাউন্ট তৈরি হয় না
- `registration_data.dart` + প্রতিটি স্টেপের হেডার: “UI ONLY — local
  mock state”, “TODO backend: replace with repository + Supabase insert
  on Step 12 confirm”।
- ১৩ ধাপ, প্রোগ্রেস, রিভিউ, সাকসেস সব দেখতে সম্পূর্ণ, কিন্তু Step 12-এর
  কনফার্ম কোনো আসল প্রোফাইল সেভ করে না।
- PHASE 5 FIX (2026-10-28, C5): Step 12 কনফার্ম এখন আসল প্রোফাইল সেভ
  করে — `profileService.createProfile` (লোকাল JSON + Supabase upsert
  চেষ্টা)। Supabase ফেল করলেও লোকাল সেভ থাকলে Step 13 দেখায়, আর
  Step 13-এ সৎভাবে “অনলাইনে সেভ হয়নি” লেখা থাকে; শুধু লোকাল সেভ
  ফেল করলেই Review-তে আটকে থাকে। গার্ডিয়ান লোকাল কপিতে থাকে,
  Supabase-এ `parent_links`-এ যায় (`profiles`-এ গার্ডিয়ান কলাম নেই);
  Settings-এর upsert থেকে গার্ডিয়ান কী বাদ দেওয়া হয়েছে যাতে তা
  ভেঙে না যায়। প্রোফাইল id এখন সাইন-আপের userId-র সঙ্গে মেলে।
  সীমা: `/register/success`-এ সরাসরি ঢুকলে এখনো সাকসেস দেখাবে
  (কোনো রুট গার্ড নেই) — ইন-ফ্লো গ্যারান্টি শুধু Step 12-এর মাধ্যমে;
  Supabase pending-এর কোনো রি-ট্রাই কিউ নেই; অ-মাউন্ট করা
  RegistrationWizard কনটেইনার এখনো Step 12-এর `_confirm` বাইপাস করে।

---

## HIGH

### H1. কোনো পেজ থেকেই ব্যাক বাটন নেই (ব্যবহারকারীর অভিযোগ সঠিক)
- নেভিগেশন প্রায় পুরোটাই `context.go()` (features-এ ১২৩টি, `push` মাত্র ~৮টি)।
  `go()` রুট বদলে দেয়, স্ট্যাকে আগের পেজ থাকে না, তাই AppBar-এর
  অটোমেটিক ব্যাক অ্যারো আসে না, Android সিস্টেম ব্যাক চাপলেও অ্যাপ
  থেকে বেরিয়ে যায়।
- ব্যাক বাটন নেই এমন স্ক্রিন (অন্তত): login (`showBack: false`),
  home (কোনো AppBar-ই নেই), practice, practice_tab, quiz_question,
  quiz_results, model_test_list, model_test_exam, model_test_results,
  book_library, progress, achievements, profile।
- ব্যাক আছে শুধু যেখানে explicit `leading` বা `push` ব্যবহার হয়েছে:
  subjects, chapters, lesson, chat, search, no_match, forgot, OTP, reset।
- অনবোর্ডিং-এ ব্যাক অ্যারো দেখা গেলেও কাজ করে না: `onboarding_shell.dart:37`
  `maybePop()` এক-এন্ট্রি স্ট্যাকে কিছুই করে না। Step 2 থেকে Step 1-এ,
  Step 3 থেকে Step 2-এ যাওয়ার কোনো উপায় নেই।
- OTP থেকে ব্যাক ভুল জায়গায় যায়: সবসময় `/forgot-password`, যদিও
  লগইন থেকেও OTP-তে ঢোকা যায় — তখন ব্যাক গিয়ে এমন পেজে পড়ে যেখানে
  ব্যবহারকারী কখনো যায়নি।
- অনবোর্ডিং-এ ফেরার উপায় নেই: splash একবার লগইনে পাঠালে আর
  অনবোর্ডিং দেখার রাস্তা নেই।
- বটম নেভিগেশন শুধু Home / Subjects / Search / Chapters-এ আছে;
  Practice / Progress / Profile / Quiz / Books-এ নেই।
- **প্রতিটি পেজে ব্যাক বাটন করতে হবে** — এটা ব্যবহারকারীর দাবি, অডিটও
  একমত।

### H2. কুইজে ক্লিক করলে সিলেক্টেড কালার হয় না
- `practice_widgets.dart` `OptionTile`: `correct` null থাকলে (চেক করার
  আগে) ব্যাকগ্রাউন্ড `null` থাকে, CircleAvatar-এর কালার সব অপশনে একই।
  ক্লিক করলে স্টেট সেভ হয়, কিন্তু দেখা যায় না।
- মডেল টেস্টে আরো খারাপ: চেক ধাপই নেই, তাই সিলেক্টেড অপশন কখনোই রঙ
  পায় না; শুধু নিচের ছোট চিপ দেখে বোঝা যায়।
- ইংরেজি মোডেও অপশন লেবেল ক/খ/গ/ঘ-ই থাকে, A/B/C/D হয় না
  (`quiz_question_screen.dart:107`, `model_test_exam_screen.dart:120`:
  হার্ডকোড `'কখগঘ'[i]`)।

### H3. “নোটবুকে সংরক্ষণ” কাজ করে বলে বোঝা যায় না
- লেখাটা আসলে সেভ হয় (`LocalStore.saveQuestion` → SharedPreferences
  `saved_questions`)। কিন্তু:
  - বাটনের কোনো সেভড/আনসেভড স্টেট নেই, বুকমার্ক আইকন বদলায় না,
    দুবার চাপলেও একই দেখায়।
  - ডুপ্লিকেট চাপলেও সবসময় “প্রশ্নটি সংরক্ষিত হয়েছে” SnackBar আসে,
    যদিও দ্বিতীয়বার কিছু সেভ হয়নি (সাইলেন্ট dedupe)।
  - কুইজ পেজ থেকে `/saved` রুটে যাওয়ার কোনো লিংক/বাটন নেই; শুধু
    ক্ষণস্থায়ী SnackBar-ই একমাত্র ফিডব্যাক।
- লেসন/চ্যাটের সেভ বাটন টগল করে, কুইজেরটা করে না — অসঙ্গতি।

### H4. “দৈনিক কুইজ” লেখা লম্বালম্বি হয়ে যায়
- কোনো ভার্টিক্যাল-টেক্সট উইজেট নেই। কারণ: `PracticeCard`-এ ডানদিকের
  “কুইজ শুরু করো” ElevatedButton-এর চওড়া + 20sp টাইটেল + ফন্ট স্কেলের
  কারণে টাইটেল কলাম একটা বাংলা শব্দের চেয়েও সরু হয়ে যায়, তখন
  Flutter অক্ষর অক্ষর করে ভেঙে দেয়: দৈ / নি / ক / কুই / জ।
- একই ঝুঁকি সব `PracticeCard`-এ: টাইটেলে `maxLines`/`overflow` নেই,
  trailing-এ কোনো width cap নেই।
- UI এজেন্টের সৎ সতর্কতা: বর্তমান কোড থেকে ঠিক ১-অক্ষর চওড়া হওয়ার
  মেকানিজম পুরোপুরি পুনরুৎপাদন করা যায়নি; ঝুঁকির কারণগুলো যাচাই করা,
  সঠিক পিক্সেল-কারণ অপ্রমাণিত।

### H5. ডেমো ব্যানারের কনট্রাস্ট — গাঢ় লেখা বেগুনি বারের উপর
- `demo_banner.dart:18`: ব্যাকগ্রাউন্ড `secondaryContainer`, কিন্তু
  `app_theme.dart`-এ `secondaryContainer`/`onSecondaryContainer` কখনো
  ডিফাইন করা হয়নি — Flutter `secondary` (বেগুনি `0xFF6D5BD0`) থেকে
  বানায়। টেক্সট গাঢ় ধূসর (`inkSecondary`) — পড়া কঠিন, স্ক্রিনশটে
  দেখা গেছে।

### H6. ভয়েস পৌঁছানোই যায় না + ক্যাপ মাসিক নয়, আজীবন
- DEMO-তে `isPremium()` কখনো true হয় না (কোথাও `setPremiumLocal(true)`
  কল নেই; sign-out-এ শুধু false করা হয়)। তাই VoiceTutorScreen সবসময়
  প্রিমিয়াম গেটে আটকে থাকে; ৩০ মিনিটের ফিচার চেষ্টাই করা যায় না।
- `voice_used_minutes` শুধুই বাড়ে, কোনো মাসের সীমানা/রিসেট নেই।
  “৩০ মিনিট/মাস” লেখা থাকলেও বাস্তবে “৩০ মিনিট আজীবন” — মাস ১-এ শেষ
  হলে মাস ২-এ মিনিট ফিরবে না, রিইনস্টল ছাড়া।
- সার্ভার লগিংও ভাঙা: `endCall()` `voice_sessions`-এ `user_id` ছাড়া
  ইনসার্ট করে, টেবিলে `user_id NOT NULL` + RLS — ইনসার্ট ফেল করে,
  `catch (_)`-এ গিলে ফেলা হয়।
- PHASE 11 FIX (2026-10-28, H6): (1) ক্যাপ এখন PER-PERIOD —
  `LocalStore` লোকাল কাউন্টারে `voice_period_key` (YYYY-MM)
  রাখে; মাস বদলালে `voiceUsedMinutes()` ০ ফেরায় ও কাউন্টার
  রিসেট করে; ক্যাপ ৩০ মিনিট অপরিবর্তিত। পুরোনো ইনস্টলে প্রথম
  রানে পুরোনো আজীবন সংখ্যাটা শুধু চলতি মাসের জন্য থাকে, পরের
  মাসে রিসেট হয়। সার্ভার `voice_minute_budgets.period_start`
  থাকলে সেটাই সত্যের উৎস (লোকাল কী শুধু DEMO/offline ফলব্যাক)।
  (2) `endCall()` এখন সার্ভার ইনসার্টে `user_id` দেয় — তবে
  শুধু লাইভ Supabase auth uid থাকলে; না থাকলে ইনসার্ট সৎভাবে
  বাদ যায় (লোকাল গোনা তবুও থাকে)। লোকাল 'demo-user' id
  ইচ্ছা করে ব্যবহার করা হয়নি: তা uuid নয় (FK ভাঙবে) এবং
  Supabase সেশন ছাড়া RLS (`auth.uid()=user_id`) যেকোনো id-ই
  বাতিল করবে। (3) DEMO টেস্ট টগল: Settings পেজের নিচে
  `DemoPremiumToggle` (`lib/features/profile/widgets/`) —
  শুধু DEMO মোডে (Supabase চাবি না থাকলে) দেখায়, স্পষ্ট
  DEMO-ONLY লেবেলসহ, ডিফল্ট OFF, পেওয়াল ফ্লোতে নেই; চালু
  করলে শুধু লোকাল `demo_premium` ফ্ল্যাগ বদলায়, আসল প্রিমিয়াম
  দেয় না। টেস্ট বিল্ডে এটি চালু করার আগে ব্যবহারকারীর
  স্পষ্ট অনুমতি লাগবে — ডিফল্ট শিপড অবস্থা premium=false।

### H7. প্যারেন্ট PIN ৩ভাবে বাইপাস করা যায়
- `/parent-dashboard` রুটে কোনো গার্ড নেই — PIN স্ক্রিন শুধু UI পথ।
- Forgot PIN দিলে কোনো পরিচয় যাচাই ছাড়াই পুরনো PIN মুছে নতুন বসানো
  যায় (`parent_pin_screen.dart:110-137`)।
- ৪-ডিজিট PIN, ফিক্সড সল্ট, ৩২-বিট হ্যাশ, আনলিমিটেড চেষ্টা, কোনো
  লকআউট/ডিলে নেই। কোড নিজেই বলে “NOT server-grade security”।

### H8. পেওয়াল মিথ্যা প্রতিশ্রুতি দেয় + প্রিমিয়াম কেনার পথ বন্ধ
- দাবি: “সব শ্রেণির পাঠ্যবই”, “মডেল টেস্ট, র‍্যাংক ও দুর্বল অধ্যায়
  বিশ্লেষণ”, “আনলিমিটেড প্রশ্ন”। বাস্তব: শুধু ক্লাস ৬-এর বই, র‍্যাংক
  ফিচার কোডে কোথাও নেই, টেক্সট AI চাবি ছাড়া বন্ধ, ভয়েস ৩০ মিনিটে ক্যাপ।
- Play-তে `yes_sir_ai_premium_monthly` প্রোডাক্ট এখনো বানানো হয়নি,
  তাই Subscribe সবসময় unavailable দেখাবে। Restore-ও প্রিমিয়াম দেবে
  না, কারণ সার্ভার-ভেরিফিকেশন সার্ভার/Edge Function নেই — fail-safe
  ঠিক আছে, কিন্তু কেনা আজ অসম্ভব, এটা পরিষ্কার বলতে হবে।

### H9. OTP বক্স সরু ফোনে overflow করবে
- রেজিস্ট্রেশন OTP: ৪ × ৬৪px = ২৫৬px বক্স + প্যাডিং; অথ OTP:
  ৬ × ৪৮px = ২৮৮px + গ্যাপ। ৩৬০px ফোনে টাইট, ৩২০px বা ১.২৫× ফন্ট
  স্কেলে overflow। কোনো `Expanded`/`Flexible` নেই।

### H10. রেজিস্ট্রেশন রিভিউতে ফোন/স্কুল/গার্ডিয়ান দেখায় না
- Step 12 রিভিউতে শুধু নাম, লিঙ্গ, ক্লাস, মিডিয়াম, গোল — ফোন, ইমেইল,
  স্কুল, গার্ডিয়ান, OTP কোনোটাই দেখা/যাচাই করা যায় না কনফার্মের আগে।

---

## MEDIUM

### M1. হোমের সাবজেক্ট গ্রিড নকল ডাটা, ৪টিতে কাটা
- `home_screen.dart:53`: `mockSubjects.where(!locked).take(4)` — গণিত,
  বিজ্ঞান, ইংরেজি, বাংলা। ICT আর BGS মক লিস্টে থাকলেও কাটা পড়ে।
  DB-র ৪৪টি বই থেকে আসে না।
- হোমের সার্চে লেখা টেক্সট সার্চ পেজে যায় না, ফেলে দেওয়া হয়
  (`home_screen.dart:94`: শুধু `go('/search')`)।

### M2. লগইনে আসল লোগো নেই, স্প্ল্যাশে আছে
- স্প্ল্যাশে আসল ৫১২ লোগো বসেছে, কিন্তু লগইনে এখনো কোডে আঁকা
  `RobotAvatar` (`login_screen.dart:107`) — দুই স্ক্রিনে দুই ব্র্যান্ড।

### M3. ভাষা বদল শুধু অথ স্ক্রিনে
- বাংলা/English টগল `auth_scaffold.dart`-এ আছে, হোমে নেই। লগইনের পর
  ভাষা বদলাতে হলে সেটিংসে যেতে হয়।

### M4. সেটিংসে ফন্ট/থিম লাইভ বদলায়, কিন্তু সেভ ছাড়া হারিয়ে যায়
- ফন্ট/থিম নোটিফায়ার সঙ্গে সঙ্গে বদলায়, কিন্তু পারসিস্ট হয় শুধু
  Save চাপলে (`settings_screen.dart:74-76`)। Save না চাপলে রিস্টার্টে
  আগেরটায় ফিরে যায়। ভাষা এর ব্যতিক্রম — সঙ্গে সঙ্গে সেভ হয়।
  অসঙ্গতি, আর Save বাটনের লেবেল থেকে বোঝা যায় না এটা অ্যাপিয়ারেন্সও
  সেভ করে।

### M5. সেটিংস না বুঝে ক্লাস ১০ বানিয়ে দিতে পারে
- প্রোফাইল না থাকলে `_load()` ডিফল্ট ক্লাস ১০, গোল ৩০ মিনিট রেখে দেয়;
  Save চাপলেই ব্যবহারকারী না বাছলেও ক্লাস ১০ লেখা হয়ে যায়।

### M6. প্রোগ্রেসের গোল ব্যবহারকারীর গোল নয়
- প্রোগ্রেসে হার্ডকোড ১০ প্রশ্ন/দিন (`progress_service.dart:39`);
  সেটিংসের গোল মিনিটে (৩০ মিনিট) — দুটো আলাদা সংখ্যা, একই নাম।
  ৩০ মিনিট সেট করলেও ১০-প্রশ্নের রিং দেখাবে।

### M7. প্যারেন্ট ড্যাশবোর্ডের দুর্বল অধ্যায় সবসময় খালি
- ড্যাশবোর্ড সবসময় “No saved weak-chapter data” দেখায়, যদিও
  `progress_service.summary()` দুর্বল অধ্যায় হিসাব করেই রাখে — ড্যাশবোর্ড
  সেটা পড়েই না।

### M8. নোটিফিকেশন স্ট্যাটিক ডেমো লিস্ট
- সবসময় একই ৫টি আইটেম, “Today” = প্রথম ৩টি, “Earlier” = শেষ ৩টি,
  তারিখের সঙ্গে সম্পর্ক নেই। সেটিংসের নোটিফিকেশন টগলগুলো প্রেফ
  সেভ করে, কিন্তু কোথাও পড়া হয় না; কোনো পুশ/লোকাল নোটিফিকেশন
  শিডিউলিং নেই।

### M9. স্প্ল্যাশ স্ক্রল হয় না; ডার্ক থিম অর্ধেক; সেপিয়া শুধু লেবেল
- স্প্ল্যাশে `SingleChildScrollView` নেই — ছোট ফোনে বা ১.২৫× ফন্টে
  overflow (হলুদ/কালো ডোরা) হবে। লগইন/অনবোর্ডিং স্ক্রল হয়।
- ডার্ক থিমে `textTheme`/`cardTheme`/`elevatedButtonTheme` নেই —
  Warm Paper স্টাইল রাতে উধাও হয়।
- সেপিয়া বাছলে লাইট মোডই দেখায় — সেপিয়ার কোনো ThemeData নেই,
  চোখের যত্নের দাবি অ্যাপে পূরণ হয় না।

### M10. সেভ করা প্রশ্ন শুধু লোকালে, অন্য ডিভাইসে যাবে না
- `learn_store.dart`: SharedPreferences-এ সেভ হয়; Supabase
  `saved_questions` টেবিলে কোনো রাইট নেই, যদিও টেবিল মাইগ্রেশনে আছে।
  অ্যাপ ডিলিট হলে মুছে যাবে।

### M11. সাইন-আউটে আগের ব্যবহারকারীর লোকাল ডাটা থেকে যায়
- `auth_service.dart:123-130`: শুধু সেশন + প্রিমিয়াম ফ্ল্যাগ মুছে।
  লোকাল প্রোফাইল, সেভ করা প্রশ্ন, ভয়েস মিনিট, প্যারেন্ট PIN হ্যাশ থেকে
  যায় — পরের অ্যাকাউন্ট আগের ব্যবহারকারীর ডাটা পেয়ে যাবে।

---

## LOW / COSMETIC / DEAD

- L1. About স্ক্রিনে যাওয়ার কোনো UI লিংক নেই (রুট আছে, বাটন নেই)।
  প্রোফাইলে Settings দুবার আছে (“My info” আর “Settings” দুটোই
  `/settings`-এ যায়); Notifications টাইল প্রোফাইলে নেই, শুধু হোমের
  টপ বার থেকে যাওয়া যায়।
- L2. Help-এর Contact বাটন কিছু পাঠায় না — ডায়ালগে সৎভাবে বলে কোনো
  সাপোর্ট চ্যানেল নেই। FAQ গুলো ঠিকমতো খোলে।
- L3. কুইজ টাইমার count-up, কখনো থামে না, ব্যাকগ্রাউন্ডেও চলে;
  মডেল টেস্টের time-up SnackBar নেভিগেশনে মিস হতে পারে।
- L4. সেভ করা প্রশ্নের Practice বাটন id-র prefix দেখে বিষয় আন্দাজ করে
  (`s` → science, নইলে math) — ভঙ্গুর অনুমান, স্টোর করা বিষয় নয়।
- L5. হোমের স্ট্যাট কার্ড ৩টির উচ্চতা অসমান (লম্বা বাংলা লেবেল
  আলাদা লাইনে ভাঙে, `maxLines` নেই)।
- L6. রেজিস্ট্রেশনে: Gender/Guardian-এ Next আর Skip একই কাজ করে;
  পাসওয়ার্ড ফিল্ডে চোখ (show/hide) নেই; ফোন ফরম্যাট যাচাই নেই,
  ইমেইলে `@` যাচাই নেই; OTP রিসেন্ডে টাইমার/লিমিট নেই, শুধু SnackBar;
  Step 1-এ ইন-অ্যাপ ব্যাক নেই।
- L7. প্রোগ্রেসের “আজ কুইজ করো” টাস্ক সবসময় গণিতে পাঠায়, ছাত্রের
  বিষয় যাই হোক।
- L8. Supabase প্রোগ্রেস fallback-এ সার্ভার সংখ্যা এনে UI ফেলে দেয়
  (totalAttempts == 0 হলে empty branch); আর `progress` টেবিলে অ্যাপ
  কখনো লেখেই না।

---

## যাচাই করে ঠিক পাওয়া গেছে (এগুলোর পেছনে সময় নষ্ট করবেন না)

- চেক/আগে/পরে/Skip ফ্লো ঠিক; উত্তর চেকের পর সবুজ/লাল রঙ ঠিক;
  Prev/Next-এ উত্তর সংরক্ষিত থাকে।
- স্কোর সেভিং লোকালে আসল; মডেল টেস্ট টাইমার auto-submit-এ গার্ড আছে;
  ফ্ল্যাগিং কাজ করে।
- প্রোগ্রেস/অ্যাচিভমেন্টের হিসাব আসল সেভ করা attempt থেকে (streak,
  XP = সঠিক×১০, লেভেল, গড়); নতুন ইনস্টলে সৎভাবে ০ দেখায়।
- ভাষা সঙ্গে সঙ্গে সেভ হয়, স্প্ল্যাশে রিস্টোর হয়; প্রোফাইল এডিট
  লোকালে মার্জ হয়, Supabase upsert ফেল করলে লোকাল কপি থাকে।
- প্যারেন্ট ড্যাশবোর্ড নিজে read-only (কোনো এডিট বাটন নেই); ভয়েসে
  কোনো অডিও স্টোর হয় না; পেওয়াল নিজে থেকে প্রিমিয়াম দেয় না;
  bKash/Nagad বাটন কোথাও নেই (নিয়ম অনুযায়ী)।
- সাইন-আউটে প্রিমিয়াম ফ্ল্যাগ মুছে; ভয়েস গেটের ক্রম ঠিক
  (প্রিমিয়াম → মিনিট → চাবি); মিনিট গোনা আসল (End/dispose-এ গোনে,
  ডাবল-কাউন্ট নেই স্বাভাবিক পথে)।

---

## এখন কী বাকি (কোড লেখা হয়নি, ব্যবহারকারীর নির্দেশ অনুযায়ী)

1. উপরের তালিকা থেকে ফিক্সের অগ্রাধিকার ঠিক করা — প্রস্তাব: C1, C2,
   H1, H2, H3, H6, H7, H8 আগে; তারপর H4, H5, H9, H10, M-গুলো।
2. ফিক্স শুরু হলে প্রতিটি ফিক্সের পর ডিভাইসে (বা অন্তত স্ক্রিনশটে)
   যাচাই করা — বিশেষ করে ব্যাক বাটন, সিলেক্টেড কালার, সেভ স্টেট,
   আর লোগো/ফন্ট।
3. Supabase চাবিসহ বিল্ড + OpenRouter/Gemini চাবি ছাড়া “ফুল লাইভ”
   দাবি করা যাবে না — ব্যানার-ফাঁক (M-এর ডেমো-ব্যানার অংশ) ঠিক না
   হওয়া পর্যন্ত AI-ফিচারগুলোর DEMO অবস্থা UI-তে দেখাতে হবে।

---

## FINAL FIX STATUS (2026-10-28, coordinator verification)

`flutter analyze` after all phases: **No issues found!** (verified by coordinator).
Every item below was fixed in code in phases 1–17, unless marked [BLOCKED].
[BLOCKED] means code is done but live behaviour needs a user key/account —
it is NOT a code gap left open.

- C1 [FIXED] Supabase books/chapters reads (books_public/subjects/chapters), DEMO fallback, locked + no-guess kept. Live read untested without keys.
- C2 + AI [FIXED in code, BLOCKED for live] Grounding gate + Edge Function explain-question + BOOK_IMPORT_CONTRACT.md. Live AI needs: Edge deploy (Supabase service-role via secure vault), OPENROUTER_API_KEY via secure flow, book_questions rows import.
- C3 [FIXED] Real profile stats, honest empty states; invented ID removed (real id or hidden; DEMO shows demo-user).
- C4 [WIRED 2026-10-29] Hind Siliguri OFL family registered in pubspec.yaml (fonts/HindSiliguri-{Light,Regular,Medium,SemiBold,Bold}.ttf, weights 300–700) and used explicitly by the answer screen's solution renderer for Bangla text; app-wide default fontFamily unchanged. Device test still pending (APK deferred).
- C5 [FIXED] Step 12 confirm persists profile (local always, Supabase when configured, honest pending note).
- H1 [FIXED in code] Back on every non-root page; device tap-through still recommended.
- H2 [FIXED] Selected-option blue colour before checking; A/B/C/D in English.
- H3 [FIXED] Save-to-notebook real toggle, truthful snackbars, link to /saved.
- H4 [FIXED] PracticeCard trailing cap 140px, maxLines 2 + ellipsis; device screenshot at 360px still recommended.
- H5 [FIXED] Banner contrast AAA (light 13.32:1, dark 7.19:1); banner disappears only when Supabase + OpenRouter + Gemini all present.
- H6 [FIXED in code] Voice cap per-period (local month key; server period_start is source of truth when present); voice_sessions user_id fix; DEMO test toggle in Settings, DEMO-only, OFF by default, user approval required before any test build enables it.
- H7 [FIXED] Parent dashboard route guard, forgot-PIN no longer erases gate, 5 attempts / 5-minute lockout. PIN hash strength unchanged (deliberate, would invalidate existing PINs).
- H8 [FIXED] Paywall claims corrected (Class 6 only, no rank, no unlimited, voice premium-only 30 min/period, server-verification note). Play product creation still outstanding (user/Play Console).
- H9 [FIXED] OTP boxes responsive (Expanded, capped row).
- H10 [FIXED] Review shows school/district/phone/email/OTP status/guardian with edit links; OTP honestly never labelled 'verified' (no verification API exists yet).
- M1 [FIXED] Home grid all subjects from Supabase source; search text passed to /search (stepper cannot resolve free text - honestly displayed).
- M2 [FIXED - already fixed in Phase 6] Login uses real logo asset.
- M3 [FIXED] Language chips on Home.
- M4 [FIXED] Settings font/theme persist immediately.
- M5 [FIXED] Settings no longer invents Class 10 / 30 min.
- M6 [FIXED] Progress goal = user's own daily-goal minutes, real attempt seconds.
- M7 [FIXED] Parent dashboard weak chapters from summary.
- M8 [FIXED] Notifications ungrouped honest demo list; toggles labelled not-yet-functional.
- M9 [FIXED] Splash scrolls (dark-theme incompleteness + sepia-as-label remain, out of M9 scroll scope).
- M10 [FIXED in code] Saved questions sync to Supabase when signed in, local always; live sync untested without keys.
- M11 [FIXED] Sign-out clears local profile/saved/voice/PIN data (language/theme/font/onboarding kept).
- L1 [FIXED] About + Notifications tiles on Profile; duplicate Settings tile removed.
- L2 [BLOCKED - needs user decision] No real support channel exists in codebase; none invented. Help dialog honestly says no channel yet.
- L3 [FIXED] Quiz timer pauses in background; model-test time-up shown as persistent card on results.
- L4 [FIXED] Saved Practice uses bank-derived subject; unknown ids show honest dialog instead of misrouting.
- L5 [FIXED] Home stats equal heights (IntrinsicHeight/stretch).
- L6 [FIXED] Skip distinct + guardian Skip no longer saves; password eye toggle; phone/email basic validation; OTP 30s resend cooldown; Step 1 back verified.
- L7 [FIXED] Progress quiz task uses last subject, not forced Maths.
- L8 [FIXED in code] Server progress numbers shown when present; best-effort progress upsert on quiz/model-test finish; live RLS test untested without keys.

Not device-tested: no phase ran on a real phone/emulator. A device tap-through (back, selection colour, save toggle, PracticeCard at 360px, OTP at 320px, parent lockout, voice gate with DEMO toggle approved) is still recommended before shipping.

## BATCH 2 — 2026-10-28 screenshots (6 separate agents, one per area)

- (1) Search/book-solution + Q5/Q7 bug [FIXED]: ready-text was a hardcoded 'page 45 question 7' string; now built live from the exact selection (bn+en). Quick-find rows navigate to real solutions; Recent = real LocalStore history with Clear, recorded only on found solutions. Still demo-limited: only 2 indexed questions in DEMO until book_questions rows land; live AI needs OpenRouter key.
- (2) Home hero card colour + stats [FIXED]: hero card was translucent purple (grey-lavender wash); now solid Warm Paper tints (#DCEBFF/#1A4AA6 light, #1E4FBF+white dark). Saved count now reads LocalStore (same as Saved screen); 'অধ্যায় শেষ' relabelled honestly to 'অধ্যায় খোলা' (no completion event exists - not invented); subjects/class now from single profile source, no-class shows honest choose-class state. Follow-ups: /home/subjects still hardcodes class 6; true chapter-completion needs a new event.
- (3) Model test submit + review flag [FIXED]: submit did nothing because saveAttempt crashed on an unmodifiable list on fresh installs and the submit latch bricked retries; fixed (in-memory first, mutable copies, resettable guard, spinner, timer pauses during dialog). Verified 8/8 and 4/8 submits in widget tests. Review flag now real: flagged list before submit, jump chips, clear-all, flags survive prev/next, results show flagged questions.
- (4) Settings profile picture + name [FIXED]: change-picture (gallery/camera, local profile_picture.jpg, Supabase avatars upload when signed in, honest local-only note in DEMO, initial-letter fallback). Name now single-source via profileNotifier (Settings edit refreshes Profile). Blocked: migration 006 + avatars bucket policy on live DB; Home top-bar avatar still initial-letter (needs shared ProfileAvatar swap).
- (5) DEMO test toggle [FIXED, not deleted]: was leaking into isPremium()/paywall; now DEMO voice-gate test only, OFF by default, clearly labelled test-only bn+en, no billing/paywall effect, ignored when a real backend is configured, cleared on sign-out. Live Gemini voice still blocked (no key/model).
- (6) Practice + question generation [FIXED with honest limit]: daily quiz now generated (daily seed, chapter round-robin, no repeats within a day); weak revision from real wrong answers via progress_service with honest disabled empty state. Bank kept ONLY as labelled fallback ('অনুশীলন ব্যাংক · বইয়ের প্রশ্ন নয়'). Scored book MCQs still blocked: book_questions rows have question_text only, no verified options/answer key - inventing options would fake scores. See QUESTION_GENERATION.md switch-over checklist; Edge Mode D added (source-only, not deployed).
