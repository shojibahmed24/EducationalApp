// Backend-related user-facing strings only (new states introduced
// by the backend phase). bn + en together, per the page-wise rule.
const Map<String, String> backendStringsBn = {
  'demoMode': 'ডেমো মোড — ব্যাকএন্ড কী এখনো দেওয়া হয়নি, তাই লোকাল ডেটা দেখাচ্ছে।',
  // H5: Supabase যুক্ত কিন্তু AI কী বাকি — ব্যানার উঠে যাবে না।
  'backendConnectedAiMissing':
      'ব্যাকএন্ড যুক্ত হয়েছে, কিন্তু AI এখনো চালু হয়নি — AI লেসন ও ভয়েস ডেমো চলছে।',
  'backendConnectedAiPartialText':
      'ব্যাকএন্ড যুক্ত হয়েছে — লেখা-AI চালু, ভয়েস-AI এখনো চালু হয়নি।',
  'backendConnectedAiPartialVoice':
      'ব্যাকএন্ড যুক্ত হয়েছে — ভয়েস-AI চালু, লেখা-AI এখনো চালু হয়নি।',
  'backendError': 'ব্যাকএন্ডে সমস্যা হয়েছে। আবার চেষ্টা করো।',
  'voiceNotPremium': 'ভয়েস শুধু প্রিমিয়াম সদস্যদের জন্য।',
  'voiceNoMinutes': 'এই মাসের ভয়েস মিনিট শেষ হয়ে গেছে।',
  'voiceNotConfigured': 'ভয়েস এখনো চালু হয়নি — প্রিমিয়াম পেজ দেখো।',
  'noMatch': 'এই প্রশ্ন বইয়ে মেলেনি। ঠিক প্রশ্নটি লেখো বা ছবি দাও।',
};
const Map<String, String> backendStringsEn = {
  'demoMode': 'Demo mode — backend keys are not set yet, so local data is shown.',
  // H5: Supabase connected but AI key(s) missing — banner stays up.
  'backendConnectedAiMissing':
      'Backend connected, but AI is not enabled yet — AI lessons and voice are still demo.',
  'backendConnectedAiPartialText':
      'Backend connected — text AI is live, voice AI is not enabled yet.',
  'backendConnectedAiPartialVoice':
      'Backend connected — voice AI is live, text AI is not enabled yet.',
  'backendError': 'Something went wrong with the backend. Try again.',
  'voiceNotPremium': 'Voice is for premium members only.',
  'voiceNoMinutes': 'This month’s voice minutes are used up.',
  'voiceNotConfigured': 'Voice is not live yet — see the Premium page.',
  'noMatch': 'This question was not found in the book. Type the exact question or send a photo.',
};
