// English redesign picker vocabulary + title matching (2026-11-03).
// The picker no longer offers Q1–Q7 question types: it offers
// collections (practice, model tests, poems, stories, writing).
// The old data vocabulary (englishPaperOneSections) is untouched:
// this file only adds the picker vocabulary and the pure rules
// that match rows to poem/story titles. No server calls, no
// BuildContext — every function here is unit-testable.
import 'english_guide_sections.dart';

/// Picker sections in display order (plan §2 + bucket §11).
const englishRedesignSections = [
  'practice',
  'model',
  'special',
  'poem',
  'story',
  'bucket',
  'writing-story',
  'writing-dialogue',
  'writing-paragraph',
  'writing-letter',
  'writing-graph',
  'writing-composition',
  'writing-email',
];

/// True for the three new collection entries (not data sections).
bool isRedesignCollection(String section) =>
    section == 'practice' || section == 'model' || section == 'special';

/// search_flow_strings key for a redesign picker entry.
String englishRedesignSectionStringKey(String value) {
  switch (value) {
    case 'practice':
      return 'sectionPractice';
    case 'model':
      return 'sectionModel';
    case 'special':
      return 'sectionSpecial';
    case 'bucket':
      // Unnamed poem/story sets: its own key, never the
      // sectionMcq fallback of englishSectionStringKey.
      return 'sectionPoemStory';
    default:
      // Poem/story/writing reuse the locked Paper-I label keys.
      return englishSectionStringKey(value);
  }
}

/// The 7 poems (plan §3; count is 7, NOT 5 — user note 03:08).
const englishPoemNames = [
  'Books',
  'Two Mothers Remembered',
  'The Sands of Dee',
  'Time, You Old Gipsy Man',
  'Stopping by Woods on a Snowy Evening',
  'Solitude',
  'O Me! O Life!',
];

/// The 2 stories (plan §3).
const englishStoryNames = [
  'The Purple Jar',
  'Merchant of Venice',
];

/// Stopwords stripped when matching a row's stimulus ref to a
/// work title. Ref spellings vary wildly ('Poem: Books',
/// "Poem 'Books' (textbook)", 'textbook poem: Books'); the
/// title words are what survives.
const _refStopwords = {
  'poem',
  'poems',
  'textbook',
  'story',
  'stories',
  'of',
  'the',
  'set',
  'q8',
  'q9',
  'mt18',
  'a',
  'an',
};

/// Normalized core of a ref or title: lowercase words minus
/// stopwords and parenthetical notes, joined with spaces.
String normalizeWorkRef(String? value) {
  if (value == null) return '';
  final noParen = value.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  final words = noParen
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.isNotEmpty && !_refStopwords.contains(w));
  return words.join(' ');
}

/// Poem name whose title words appear in [ref], or null.
/// Generic refs ('textbook poems', 'Poems of textbook (Q8 set,
/// main-19)') name no title, so they match nothing — never
/// guessed into a poem.
String? poemNameForRef(String? ref) {
  final norm = normalizeWorkRef(ref);
  if (norm.isEmpty) return null;
  for (final poem in englishPoemNames) {
    final key = normalizeWorkRef(poem);
    if (key.isNotEmpty && norm.contains(key)) return poem;
  }
  return null;
}

/// Story name whose title words appear in [ref], or null.
/// 'Rosamond' is the Purple Jar protagonist, so a Rosamond
/// ref belongs to The Purple Jar.
String? storyNameForRef(String? ref) {
  final norm = normalizeWorkRef(ref);
  if (norm.isEmpty) return null;
  if (norm.contains('purple jar') || norm.contains('rosamond')) {
    return 'The Purple Jar';
  }
  if (norm.contains('merchant venice')) return 'Merchant of Venice';
  return null;
}

/// True for a poem/story row whose source work cannot be
/// identified: the section's own matcher returns no title.
/// These rows form the 'bucket' (গল্প ও কবিতা) section. A
/// titled row can never land here, so no row appears in both
/// a title entry and the bucket.
bool isBucketPoemStoryRow(String? section, String? ref) {
  if (section == 'poem') return poemNameForRef(ref) == null;
  if (section == 'story') return storyNameForRef(ref) == null;
  return false;
}

/// Bengali digits for serial labels (মডেল টেস্ট ১, not 1).
String bnDigits(int n) {
  const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return n
      .toString()
      .split('')
      .map((c) => digits[int.parse(c)])
      .join();
}

/// Display label for one lesson item of a collection.
String redesignLessonLabel(String kind, int index, String? name, bool bn) {
  switch (kind) {
    case 'model':
      return bn ? 'মডেল টেস্ট ${bnDigits(index)}' : 'Model Test $index';
    case 'special':
      return bn
          ? 'বিশেষ মডেল টেস্ট ${bnDigits(index)}'
          : 'Special Model Test $index';
    case 'practice':
      return bn
          ? 'পাঠ্যভিত্তিক অনুশীলনী ${bnDigits(index)}'
          : 'Lesson Practice $index';
    default:
      return name ?? '';
  }
}
