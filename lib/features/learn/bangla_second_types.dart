// Bangla 2nd Paper picker logic (2026-11-04, revised 2026-11-04):
// THREE levels — অধ্যায় (type) -> লেসন (subdivision, with
// filter chips) -> "প্রশ্ন দেখুন" -> questions. Pure split rules
// derived from the verified live import file
// (ban2-import-ready.jsonl, 2,761 rows). No Flutter import:
// unit tests run this file directly. chapter_id is NULL live,
// so পরিচ্ছেদ grouping parses the bank id; nirmiti kinds parse
// the id prefix; the potro divisions use the id number,
// verified to match q_no order 1:1 for all 48 potro rows in
// the file. Nothing here invents a mapping: ids that carry no
// পরিচ্ছেদ number land in the extra bucket (key null), never
// in a numbered পরিচ্ছেদ; an out-of-range potro number maps
// to null, never to a guessed division.
// Potro divisions live in bangla_second_potro.dart (line-cap
// split, no cycle: that file imports nothing from here).
import '../../core/models/guide_bank_model.dart';
import 'bangla_second_potro.dart';

/// অধ্যায় items, in the exact order the picker shows them.
/// চিঠি and আবেদনপত্র are NOT separate অধ্যায় items: the
/// single চিঠিপত্র item covers all 48 potro rows, split into
/// divisions on the lesson screen. অনুবাদ (onubad, 39 nirmiti
/// rows) and সাজেশন (68 appendix rows) were added 2026-11-04
/// after রচনা, মডেল টেস্ট stays last. সাজেশন rows are NOT
/// question-answer rows: the Edge list serves শিরোনাম, তারকা,
/// পরিচ্ছেদ and linked-directive ids for them (2026-11-04),
/// so the lesson screen groups by পরিচ্ছেদ and the detail
/// screen resolves linked bank/nirmiti rows in linked order.
enum BanglaSecondType {
  mcq,
  onucched,
  chithipotro,
  sarangsho,
  sarmormo,
  bhab,
  songbad,
  rochona,
  onubad,
  suggestion,
  modelTest,
}

/// Picker order, fixed by the user's list (never re-sorted).
const banglaSecondTypesInOrder = <BanglaSecondType>[
  BanglaSecondType.mcq,
  BanglaSecondType.onucched,
  BanglaSecondType.chithipotro,
  BanglaSecondType.sarangsho,
  BanglaSecondType.sarmormo,
  BanglaSecondType.bhab,
  BanglaSecondType.songbad,
  BanglaSecondType.rochona,
  BanglaSecondType.onubad,
  BanglaSecondType.suggestion,
  BanglaSecondType.modelTest,
];

/// Nirmiti id prefix per type; null for mcq / modelTest.
/// রচনা shows the probondho block (data name প্রবন্ধ stays in
/// code comments; the UI label is রচনা).
const _nirmitiPrefixes = <BanglaSecondType, String>{
  BanglaSecondType.onucched: 'onucched',
  BanglaSecondType.chithipotro: 'potro',
  BanglaSecondType.sarangsho: 'sarangsho',
  BanglaSecondType.sarmormo: 'sarmormo',
  BanglaSecondType.bhab: 'bhab',
  BanglaSecondType.songbad: 'songbad',
  BanglaSecondType.rochona: 'probondho',
  BanglaSecondType.onubad: 'onubad',
};

String? banglaSecondNirmitiPrefix(BanglaSecondType type) =>
    _nirmitiPrefixes[type];

/// Nirmiti screen kind params (one per nirmiti অধ্যায় item).
/// সাজেশন is NOT a nirmiti kind: it has its own screen and
/// never enters the nirmiti/MCQ question flows.
const banglaSecondNirmitiKinds = <String>[
  'onucched',
  'potro',
  'sarangsho',
  'sarmormo',
  'bhab',
  'songbad',
  'probondho',
  'onubad',
];

/// Route opened when an অধ্যায় type is tapped.
String banglaSecondRoute(BanglaSecondType type) {
  switch (type) {
    case BanglaSecondType.mcq:
      return '/bangla-second-mcq';
    case BanglaSecondType.modelTest:
      return '/bangla-second-model-tests';
    case BanglaSecondType.onucched:
      return '/bangla-second-nirmiti?kind=onucched';
    case BanglaSecondType.chithipotro:
      return '/bangla-second-nirmiti?kind=potro';
    case BanglaSecondType.sarangsho:
      return '/bangla-second-nirmiti?kind=sarangsho';
    case BanglaSecondType.sarmormo:
      return '/bangla-second-nirmiti?kind=sarmormo';
    case BanglaSecondType.bhab:
      return '/bangla-second-nirmiti?kind=bhab';
    case BanglaSecondType.songbad:
      return '/bangla-second-nirmiti?kind=songbad';
    case BanglaSecondType.rochona:
      return '/bangla-second-nirmiti?kind=probondho';
    case BanglaSecondType.onubad:
      return '/bangla-second-nirmiti?kind=onubad';
    case BanglaSecondType.suggestion:
      return '/bangla-second-suggestion';
  }
}

final _bankIdPattern = RegExp(r'^ban2-ch(\d+)-mcq-bank-\d+$');

/// পরিচ্ছেদ number from a bank id, or null when the id carries
/// none (the 41 ban2-extra-mcq-bank-* rows).
int? parseBanglaSecondChapter(String id) {
  final m = _bankIdPattern.firstMatch(id);
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// True for the extra bank rows (no পরিচ্ছেদ number in the id).
bool isBanglaSecondExtraBankId(String id) =>
    id.startsWith('ban2-extra-mcq-bank-');

final _nirmitiPattern = RegExp(r'^ban2-nirmiti-([a-z]+)-\d+$');

/// Nirmiti kind prefix from a nirmiti id, or null.
String? parseBanglaSecondNirmitiKind(String id) {
  final m = _nirmitiPattern.firstMatch(id);
  return m?.group(1);
}

/// True when a nirmiti row id belongs to a nirmiti screen kind.
/// kind 'potro' matches every potro row; divisions filter
/// separately on the lesson screen.
bool nirmitiRowMatchesKind(String id, String kind) {
  if (kind == 'potro') {
    return parseBanglaSecondPotroNumber(id) != null;
  }
  return parseBanglaSecondNirmitiKind(id) == kind;
}

/// Model-test set number from a set id (model-1..model-40).
int? parseBanglaSecondModelSetNumber(String setId) {
  final m = RegExp(r'^model-(\d+)$').firstMatch(setId);
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// Bangla-digit year from a board set id ('ঢাকা বোর্ড ২০২৪').
int? parseBanglaSecondBoardYear(String setId) {
  const digits = {'০': 0, '১': 1, '২': 2, '৩': 3, '৪': 4,
    '৫': 5, '৬': 6, '৭': 7, '৮': 8, '৯': 9};
  final tail = setId.split(' ').last;
  if (tail.length != 4 || tail.split('').any((c) => !digits.containsKey(c))) {
    return null;
  }
  var year = 0;
  for (final c in tail.split('')) {
    year = year * 10 + digits[c]!;
  }
  return year;
}

/// Generic grouping used by the picker screens: key function
/// over rows, order of first appearance preserved.
Map<K, List<T>> groupBanglaSecondRows<T, K>(
    Iterable<T> items, K Function(T) key) {
  final out = <K, List<T>>{};
  for (final item in items) {
    final k = key(item);
    (out[k] ??= []).add(item);
  }
  return out;
}

/// Picker label for a type in the active language map.
String banglaSecondTypeLabel(BanglaSecondType type, Map<String, String> s) {
  switch (type) {
    case BanglaSecondType.mcq:
      return s['typeMcq']!;
    case BanglaSecondType.onucched:
      return s['typeOnucched']!;
    case BanglaSecondType.chithipotro:
      return s['typeChithipotro']!;
    case BanglaSecondType.sarangsho:
      return s['typeSarangsho']!;
    case BanglaSecondType.sarmormo:
      return s['typeSarmormo']!;
    case BanglaSecondType.bhab:
      return s['typeBhab']!;
    case BanglaSecondType.songbad:
      return s['typeSongbad']!;
    case BanglaSecondType.rochona:
      return s['typeRochona']!;
    case BanglaSecondType.onubad:
      return s['typeOnubad']!;
    case BanglaSecondType.suggestion:
      return s['typeSuggestion']!;
    case BanglaSecondType.modelTest:
      return s['typeModelTest']!;
  }
}

/// True for appendix suggestion ids (ban2-appendix-suggestion-*).
/// These ids carry no পরিচ্ছেদ number and no nirmiti kind, so
/// every parser above returns null for them by construction.
bool isBanglaSecondSuggestionId(String id) =>
    id.startsWith('ban2-appendix-suggestion-');

/// Suggestion linked-question resolution, in linked-id order.
/// [rows] are the bank + nirmiti rows to match against.
/// Unmatched ids count only — never an invented question, and
/// dropped directives never appear because they are not in
/// the linked list at all.
({List<GuideBankQuestion> matched, int unmatched})
    resolveBanglaSecondLinked(
  List<String> linkedIds,
  Iterable<GuideBankQuestion> rows,
) {
  final byId = <String, GuideBankQuestion>{};
  for (final q in rows) {
    byId[q.id] = q;
  }
  final matched = <GuideBankQuestion>[];
  var unmatched = 0;
  for (final id in linkedIds) {
    final match = byId[id];
    if (match == null) {
      unmatched++;
    } else {
      matched.add(match);
    }
  }
  return (matched: matched, unmatched: unmatched);
}
