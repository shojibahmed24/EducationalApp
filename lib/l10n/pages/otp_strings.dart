// OTP screen strings - based on Stitch _1 (step 2/3, 6-digit OTP).
// Written WITH otp_screen.dart (page-wise rule).
const Map<String, String> otpStringsBn = {
  'step': 'ধাপ ২ / ৩ · কোড যাচাই',
  'title': 'যাচাইকরণ কোড লেখো',
  'subtitle':
      'ভুল হলেও চিন্তা নেই, শান্ত হয়ে কোডটি মিলিয়ে নাও। তোমার দেওয়া নম্বরে/ইমেইলে ৬ সংখ্যার কোড পাঠানো হয়েছে।',
  'changeNumber': 'নম্বর পরিবর্তন করো',
  'resend': 'আবার পাঠাও (০:৩০)',
  'verify': 'যাচাই করে এগিয়ে যাও',
  'noCode': 'কোড পাওনি? এসএমএস কিংবা হোয়াটসঅ্যাপে আবার চেষ্টা করো। কোনো ফি প্রযোজ্য নয়।',
  'safe': 'এনসিটিবি পাঠ্যক্রম · শিক্ষার্থী ডেটা সম্পূর্ণ সুরক্ষিত',
  'sentTo': 'কোড পাঠানো হয়েছে:',
  'incomplete': '৬ সংখ্যার পুরো কোড লেখো।',
  'demoResend': 'ডেমো মোড: আসল SMS পাঠানো হয়নি। যেকোনো ৬ সংখ্যার কোড দিয়ে ডেমো যাচাই চলবে।',
  'phoneNotConfigured': 'আসল SMS OTP এখনো চালু হয়নি — Supabase Phone Auth সেটআপ বাকি। ডেমো কোড দিয়ে এগিয়ে যাওয়া যাবে না, কারণ এটি আসল অ্যাকাউন্ট।',
  'phoneLabel': 'মোবাইল নম্বর',
  'phoneHint': '+880 দিয়ে শুরু, আন্তর্জাতিক ফরম্যাটে লেখো',
  'phoneRequired': 'প্রথমে মোবাইল নম্বর লেখো।',
  'phoneFormatError': 'নম্বর আন্তর্জাতিক ফরম্যাটে লেখো, যেমন +880 দিয়ে শুরু।',
  'codeSent': 'কোড পাঠানো হয়েছে।',
  'verifyFailed': 'যাচাই হয়নি, কোড মিলিয়ে আবার চেষ্টা করো।',
};
const Map<String, String> otpStringsEn = {
  'step': 'Step 2 / 3 · Verify code',
  'title': 'Enter the verification code',
  'subtitle':
      "Don't worry if you make a mistake, calmly match the code. A 6-digit code was sent to the number/email you gave.",
  'changeNumber': 'Change number',
  'resend': 'Resend (0:30)',
  'verify': 'Verify and continue',
  'noCode':
      'Did not get the code? Try again by SMS or WhatsApp. No fee applies.',
  'safe': 'NCTB curriculum · Student data fully protected',
  'sentTo': 'Code sent to:',
  'incomplete': 'Please enter the full 6-digit code.',
  'demoResend': 'DEMO mode: no real SMS was sent. Any 6-digit code completes the DEMO check.',
  'phoneNotConfigured': 'Real SMS OTP is not enabled yet — Supabase Phone Auth setup is still pending. This is a real account, so no DEMO code can stand in.',
  'phoneLabel': 'Phone number',
  'phoneHint': 'International format, starting with +880',
  'phoneRequired': 'Please enter your phone number first.',
  'phoneFormatError': 'Enter the number in international format, starting with +880.',
  'codeSent': 'Code sent.',
  'verifyFailed': 'Verification failed, check the code and try again.',
};
