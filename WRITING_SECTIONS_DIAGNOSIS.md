# লেখা সেকশন লোড না হওয়ার ডায়াগনোসিস (মার্ক করা এন্ট্রি)

তারিখ: 2026-11-03। তদন্ত মাত্র, ডাটাবেজ লেখা হয়নি, ডিপ্লয় হয়নি, জিপ বানানো হয়নি।

## প্রথমে সংশোধন: এটি Paper-II নয়, Paper-I

ব্যবহারকারীর স্ক্রিনশটের পিকার Paper-I-এর সেকশন তালিকা, Paper-II-এর নয়।
প্রমাণ:

- পিকারের Q1 লেবেল `Q1 · বহুনির্বাচনী প্রশ্ন` — এটি Paper-I স্ট্রিং
  `sectionMcq` (`lib/l10n/pages/search_flow_strings.dart:14`)।
  Paper-II-এর Q1 হতো `শূন্যস্থান পূরণ (বাক্স)` (`paper2SectionGapbox`)।
- পিকারটি `SearchFlowSectionField` থেকে আসে
  (`lib/features/learn/widgets/search_flow_section_field.dart`), যা
  `englishPaperOneSections` (`lib/core/data/english_guide_sections.dart`)
  রেন্ডার করে। Paper-II পিকার আলাদা ফাইল
  (`search_flow_paper2_section_field.dart`, `paperTwoSections`)।
- পেছনের সেট কার্ড main-03, ৯৩ প্রশ্ন — Paper-I মার্জড ডাটায় main-03-এর
  সারি ঠিক ৯৩টি। Paper-II-এর টেস্ট paper2-58…117, main-03 বলে কিছু নেই।

তাই বাকি নোটে বই = English Paper-I, সাবজেক্ট `english`, ফ্লো = আলাদা
ইংরেজি সার্চ ফ্লো।

## বক্স করা প্রতিটি এন্ট্রি: অ্যাপ যা চায়, ডাটায় যা আছে

সেকশন-ফিল্টার তালিকা সেট + ব্যাংক দুই ধাপে স্ক্যান করে
(`lib/core/services/english_set_scan.dart:150` `fetchFilteredPage`)।
ম্যাচ শুধু ক্লায়েন্ট-সাইডে (`r.section == section`), সার্ভারে সেকশন
পাঠানো হয় না। Paper-I মার্জড ডাটা (৪,৮৫৫ সারি, ৫৭ সেট, ১,৫৫৬ ব্যাংক সারি)
অনুযায়ী:

| পিকার লেবেল | সেকশন id | সেটে | ব্যাংকে | ফল |
|---|---|---|---|---|
| Q11 · সংলাপ-লেখা | writing-dialogue | ৫৬ (প্রতি সেটে ১, main-03-এও ১) | ৩৯ | প্রথম সেটেই ম্যাচ, দ্রুত লোড |
| অনুচ্ছেদ-লেখা | writing-paragraph | ০ | ৪৫ | ব্যাংক ধাপ পর্যন্ত পুরো স্ক্যান |
| চিঠি/আবেদন-লেখা | writing-letter | ০ | ৬২ | ব্যাংক ধাপ পর্যন্ত পুরো স্ক্যান |
| লেখচিত্র-বর্ণনা | writing-graph | ০ | ১ | ব্যাংক ধাপ পর্যন্ত পুরো স্ক্যান |
| রচনা-লেখা | writing-composition | ০ | ৪১ | ব্যাংক ধাপ পর্যন্ত পুরো স্ক্যান |
| ইমেইল-লেখা | writing-email | ০ | ১৮ | ব্যাংক ধাপ পর্যন্ত পুরো স্ক্যান |

পাঁচটি আননাম্বারড লেখা এন্ট্রিই ব্যাংক-মাত্র। main-03-এ এদের কোনো সারি
নেই (main-03-এর লেখা সারি শুধু dialogue ১টি আর story ১টি)।

## দুই লক্ষণের মেকানিজম (কোড দিয়ে প্রমাণিত)

লিস্ট স্ক্রিন `lib/features/learn/english_search_flow_list_screen.dart`।
টাইটেল = setId ?? section ?? lesson (লাইন ~১৩০), তাই টাইটেলে কাঁচা
সেকশন id (`writing-composition`, `writing-email`) দেখায় — এটা আলাদা
কোনো বাগ নয়, স্ক্রিনের ডিজাইন।

### ১. writing-composition: অনন্ত স্পিনার

- ব্যাংক-মাত্র সেকশনের জন্য স্ক্যানকে ৫৭টি সেটের সারি একের পর এক
  (প্রতি সেটে ৫০-সারি পেজিং, `model_test_set_service.dart:70`
  `fetchSetRows`) টেনে তারপর ১,৫৫৬ ব্যাংক সারি (৩২ পেজ,
  `fetchChapterlessBankRows`, লাইন ১১০) টানতে হয় — মোট ~১৫০টি
  সিকোয়েনশিয়াল Edge কল, কোনো প্রগতি UI ছাড়া। ধীর নেটওয়ার্কে এটি
  মিনিটের পর মিনিট স্পিনার দেখায়।
- আরো গুরুতর: পুরনো `_loadFirst`-এ কোনো try/catch ছিল না। স্ক্যানের
  ভেতরে যেকোনো throw (যেমন fromJson কাস্ট) হলে `setState` কখনো চলত
  না, `_loading` চিরকাল true থাকত — সত্যিকারের অনন্ত স্পিনার।
  জেনেরিক ফ্লোতে (`search_flow_list_screen.dart:96`) try আছে, ইংরেজি
  ফ্লোতে ছিল না।

### ২. writing-email: `প্রশ্ন আনা যায়নি` এরর

- `edgePost` কখনো throw করে না (`edge_post.dart`: catch-all → null,
  প্রতি ধাপে ৩০ সেকেন্ড টাইমআউট)। null ফেচ মানেই স্ক্যানের ভাষায়
  ব্যর্থতা।
- স্ক্যানের নিয়ম (`english_set_scan.dart`): প্রথম পেজে ব্যর্থতা আর
  ম্যাচ শূন্য হলে ফেরে `unavailable: true` — সেট null, প্রথম সেট-সারি
  null, বা ব্যাংক null, যেকোনো একটা হলেই। ব্যাংক-মাত্র সেকশনে ব্যাংক
  ধাপের আগে যেকোনো null হলেই ম্যাচ শূন্য থাকে, তাই সরাসরি এরর।
  (টেস্টেও এই নিয়ম লেখা আছে: "first-page bank failure with no set
  matches is unavailable", `test/english_bank_scan_test.dart`।)
- খালি তালিকা হলে অন্য লেখা দেখাত (`emptyList`: `কোনো প্রশ্ন পাওয়া
  যায়নি`)। স্ক্রিনশটে `unavailable` লেখা, তাই এটি শূন্য-সারি নয়,
  ফেচ-ব্যর্থতা।
- সতর্কতা: ফাইল থেকে প্রমাণ করা যায় না ১:৫৩-এর ব্যর্থতাটি
  ট্রানজিয়েন্ট সার্ভার-হিকআপ ছিল নাকি throw — দুই পথই ফিক্সে বন্ধ
  করা হয়েছে (নিচে)।

## Edge allowlist এই বাগের কারণ নয়

`supabase/functions/guide-bank/list.ts:42` `LIST_SECTION_VALUES`-এ
writing-paragraph/email/letter/application/composition আছে, কিন্তু
writing-dialogue/graph/story নেই। তবে এই ফ্লো সার্ভারে সেকশন পাঠায়ই
না (`english_set_scan.dart` হেডার কমেন্ট), তাই allowlist এখানে ৪০০
দিতে পারে না। সার্ভার শুধু সেট আর ব্যাংক সারি দেয়, সেকশন ম্যাচিং
ক্লায়েন্ট করে। (allowlist-ঘাটতি জেনেরিক ফ্লোর সার্ভার-সাইড ফিল্টারে
dialogue/graph/story-কে আটকাবে — আলাদা বিষয়, এই বাগ নয়।)

## ফিক্স (প্রস্তুত, কোড মাত্র — ডিপ্লয়/DB/APK নয়)

ফাইল: `lib/features/learn/english_search_flow_list_screen.dart`
(১৭৩ → ২১৬ লাইন, ২৫০-এর নিচে)।

- `_loadFirst`-এ try/catch: যেকোনো ব্যর্থতায় `_loading=false`,
  `_unavailable=true` — স্পিনার আর চিরকাল আটকে থাকবে না।
- `_loadMore`-এ try/catch: ব্যর্থতায় আগের সারি রেখে পেজিনেশন থামবে
  (`_hasMore=false`)।
- unavailable অবস্থায় রিট্রাই বোতাম (`setsRetry`: `আবার চেষ্টা করুন`,
  আগে থেকে থাকা স্ট্রিং পুনর্ব্যবহার, নতুন কী যোগ করা হয়নি)।
  বোতাম `_retry()` দিয়ে স্টেট রিসেট করে আবার লোড করে।

যাচাই:

- `flutter analyze` ওই ফাইলে: No issues found।
- `flutter test test/english_set_scan_test.dart
  test/english_bank_scan_test.dart`: ১৩/১৩ পাস।
- Edge ফাইল ছোঁয়া হয়নি, তাই deno চেক প্রযোজ্য নয়।

## বাকি ধাপ (ব্যবহারকারীর / পরের কাজের জন্য)

- ফোনে দেখতে নতুন APK লাগবে (অ্যাপ কোড বদলেছে)। Edge ডিপ্লয়
  লাগবে না, DB লেখা লাগবে না — ডাটায় সারি আছে, সমস্যা লোডের পথে।
- দীর্ঘমেয়াদি সুপারিশ (এই পাসে করা হয়নি): সেট-ফেচ সমান্তরাল করা
  বা ব্যাংক-মাত্র সেকশনের জন্য সার্ভার-সাইড সেকশন ফিল্টার — তবে তা
  শুধু allowlist-এর মানের জন্য সম্ভব; dialogue/graph/story-এর জন্য
  allowlist বাড়ানো লাগবে, যা ডাটা-ট্র্যাকের সিদ্ধান্ত।
