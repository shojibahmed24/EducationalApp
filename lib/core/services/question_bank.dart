// The labelled practice bank's DEMO-only worked solutions.
//
// These are NOT book-verified and NOT AI answers. They exist only
// so a quiz taken with no server path at all still gets an
// explanation, labelled DEMO. A live lookup that finds no book
// match must NEVER fall back to this map (see explanation_service).
// The bank itself (mq/sq/mm/sm items) still lives in
// practice_service.dart; only the solution texts moved here so
// that service stays under the 250-line limit.
String bankExplanation(String id, bool bangla) {
  const bn = {'mq1': 'পরিসীমা = ২ × (দৈর্ঘ্য + প্রস্থ) = ২ × ৭০ = ১৪০ মিটার।',
    'mq2': 'মোট ৫ ভাগ, প্রতি ভাগ ৮ — বড় ভাগ ৩ × ৮ = ২৪।',
    'mq3': 'মোট ৮ ভাগ, প্রতি ভাগ ৫ — ছোট ভাগ ৩ × ৫ = ১৫।',
    'mq4': 'লম্ব = ৫ সেমি (৫-১২-১৩), ক্ষেত্রফল = ½ × ১২ × ৫ = ৩০।',
    'mq5': '১৫ × ২০ ÷ ১০০ = ৩।', 'sq1': 'বেগ = ত্বরণ × সময় = ২ × ৫ = ১০ মি/সে।',
    'sq2': 'পানি = দুটি হাইড্রোজেন + একটি অক্সিজেন = H₂O।',
    'sq3': 'সালোকসংশ্লেষণে উদ্ভিদ CO₂ নেয়, O₂ ছাড়ে।',
    'sq4': 'পরমাণুর কেন্দ্রের নাম নিউক্লিয়াস।',
    'sq5': 'সূর্যের আলো ফুরায় না — এটি নবায়নযোগ্য।'};
  const en = {'mq1': 'Perimeter = 2 × (length + width) = 2 × 70 = 140 m.',
    'mq2': '5 parts total, 8 each — larger part 3 × 8 = 24.',
    'mq3': '8 parts total, 5 each — smaller part 3 × 5 = 15.',
    'mq4': 'Height = 5 cm (5-12-13), area = ½ × 12 × 5 = 30.',
    'mq5': '15 × 20 ÷ 100 = 3.', 'sq1': 'Velocity = acceleration × time = 2 × 5 = 10 m/s.',
    'sq2': 'Water = two hydrogen + one oxygen = H₂O.',
    'sq3': 'Plants take in CO₂ and release O₂ in photosynthesis.',
    'sq4': 'The centre of an atom is the nucleus.',
    'sq5': 'Sunlight never runs out — it is renewable.'};
  final map = bangla ? bn : en;
  return map[id] ?? (bangla ? 'সঠিক উত্তরটি মিলিয়ে দেখো।' : 'Check the correct answer.');
}
