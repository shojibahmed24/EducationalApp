// Local practice question banks, split out of
// practice_service.dart to keep it under the 250-line limit.
// DEMO-ONLY fallback pools (ids are stable: saved/weak logic
// keys on them). Never book-verified, never AI answers.
import '../models/backend_models.dart';

QuizItem _q(String id, String bn, String en, List<String> o, int c) =>
    QuizItem(id: id, questionBn: bn, questionEn: en, options: o, correctIndex: c);

class PracticeBanks {
  static List<QuizItem> mathQuiz() => [
    _q('mq1', 'একটি আয়তাকার বাগানের দৈর্ঘ্য ৪০ মিটার এবং প্রস্থ ৩০ মিটার হলে, পরিসীমা কত?',
        'A rectangular garden is 40 m long and 30 m wide. What is its perimeter?',
        ['70 মিটার / 70 m', '120 মিটার / 120 m', '140 মিটার / 140 m', '1200 বর্গমিটার / 1200 sq m'], 2),
    _q('mq2', '২:৩ অনুপাতে ৪০ ভাগ করলে বড় ভাগ কত?',
        'Divide 40 in ratio 2:3. What is the larger part?',
        ['15', '20', '24', '25'], 2),
    _q('mq3', '৩:৫ অনুপাতে ৪০টি কলম ভাগ করলে ছোট ভাগ কয়টি?',
        'Divide 40 pens in ratio 3:5. How many in the smaller part?',
        ['10', '15', '20', '25'], 1),
    _q('mq4', 'একটি সমকোণী ত্রিভুজের অতিভুজ ১৩ সেমি এবং ভূমি ১২ সেমি হলে, ক্ষেত্রফল কত?',
        'A right triangle has hypotenuse 13 cm and base 12 cm. What is its area?',
        ['25 বর্গ সেমি', '30 বর্গ সেমি', '60 বর্গ সেমি', '65 বর্গ সেমি'], 1),
    _q('mq5', '১৫-এর ২০% কত?', 'What is 20% of 15?',
        ['2', '3', '4', '5'], 1),
  ];

  static List<QuizItem> scienceQuiz() => [
    _q('sq1', 'একটি বস্তু স্থির অবস্থা থেকে ২ মি/সে² ত্বরণে চললে ৫ সেকেন্ড পর বেগ কত?',
        'An object starts from rest at 2 m/s². What is its velocity after 5 s?',
        ['5 মি/সে', '10 মি/সে', '12 মি/সে', '25 মি/সে'], 1),
    _q('sq2', 'পানির রাসায়নিক সংকেত কোনটি?', 'What is the chemical formula of water?',
        ['CO₂', 'O₂', 'H₂O', 'NaCl'], 2),
    _q('sq3', 'সালোকসংশ্লেষণে উদ্ভিদ কোন গ্যাস গ্রহণ করে?',
        'Which gas do plants take in during photosynthesis?',
        ['অক্সিজেন / Oxygen', 'কার্বন ডাই-অক্সাইড / Carbon dioxide', 'নাইট্রোজেন / Nitrogen', 'হাইড্রোজেন / Hydrogen'], 1),
    _q('sq4', 'পরমাণুর কেন্দ্রকে কী বলে?', 'What is the centre of an atom called?',
        ['ইলেকট্রন / Electron', 'নিউক্লিয়াস / Nucleus', 'প্রোটন / Proton', 'অরবিট / Orbit'], 1),
    _q('sq5', 'কোনটি নবায়নযোগ্য শক্তির উৎস?', 'Which is a renewable energy source?',
        ['কয়লা / Coal', 'পেট্রোল / Petrol', 'সৌরশক্তি / Solar power', 'ডিজেল / Diesel'], 2),
  ];

  static List<QuizItem> modelMath() => [...mathQuiz(),
    _q('mm6', '৭ × ৮ = ?', 'What is 7 × 8?', ['54', '56', '64', '48'], 1),
    _q('mm7', '১০০-এর বর্গমূল কত?', 'What is the square root of 100?',
        ['5', '10', '20', '50'], 1),
    _q('mm8', 'একটি বর্গের বাহু ৯ সেমি হলে ক্ষেত্রফল কত?',
        'A square has side 9 cm. What is its area?',
        ['18 বর্গ সেমি', '36 বর্গ সেমি', '81 বর্গ সেমি', '90 বর্গ সেমি'], 2),
    _q('mm9', '১/২ + ১/৪ = ?', 'What is 1/2 + 1/4?',
        ['1/4', '1/2', '3/4', '2/6'], 2),
    _q('mm10', '৩০০-এর ১০% কত?', 'What is 10% of 300?',
        ['3', '10', '30', '60'], 2),
  ];

  static List<QuizItem> modelScience() => [...scienceQuiz(),
    _q('sm6', 'পৃথিবীর নিকটতম নক্ষত্র কোনটি?', 'Which star is nearest to Earth?',
        ['চাঁদ / Moon', 'সূর্য / Sun', 'মঙ্গল / Mars', 'শুক্র / Venus'], 1),
    _q('sm7', 'বায়ুমণ্ডলে সবচেয়ে বেশি কোন গ্যাস?', 'Which gas is most abundant in air?',
        ['অক্সিজেন / Oxygen', 'কার্বন ডাই-অক্সাইড / CO₂', 'নাইট্রোজেন / Nitrogen', 'আর্গন / Argon'], 2),
    _q('sm8', 'মানুষের হৃৎপিণ্ডে কয়টি প্রকোষ্ঠ?', 'How many chambers does the human heart have?',
        ['2', '3', '4', '5'], 2),
  ];
}
