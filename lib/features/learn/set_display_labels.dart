// Set display labels for the global picker: a raw set id (e.g.
// ict-board-barishal-2023-set-kha-mcq) is NEVER the title. One
// rule for every subject, Bengali in Bn mode, romanized in En.
// A number embedded in the id is used as-is (normalized, no
// zero padding); only ids with no number at all fall back to
// the displayed position (serial). An id that is already
// Bengali (Bangla 2nd board sets) passes through unchanged.
// Unknown tokens are shown as-is, never invented.
import 'widgets/digits.dart';

const _setLetters = {'ka': 'ক', 'kha': 'খ', 'ga': 'গ', 'gha': 'ঘ'};

const _boards = {
  'dhaka': 'ঢাকা',
  'barishal': 'বরিশাল',
  'chattogram': 'চট্টগ্রাম',
  'cumilla': 'কুমিল্লা',
  'dinajpur': 'দিনাজপুর',
  'jessore': 'যশোর',
  'jashore': 'যশোর',
  'mymensingh': 'ময়মনসিংহ',
  'rajshahi': 'রাজশাহী',
  'sylhet': 'সিলেট',
};

const _boardsEn = {
  'dhaka': 'Dhaka',
  'barishal': 'Barishal',
  'chattogram': 'Chattogram',
  'cumilla': 'Cumilla',
  'dinajpur': 'Dinajpur',
  'jessore': 'Jashore',
  'jashore': 'Jashore',
  'mymensingh': 'Mymensingh',
  'rajshahi': 'Rajshahi',
  'sylhet': 'Sylhet',
};

const _rivers = {
  'kirtonkhola': 'কীর্তনখোলা',
  'ichhamati': 'ইছামতী',
  'karnaphuli': 'কর্ণফুলী',
  'dholeshwari': 'ধলেশ্বরী',
  'gomti': 'গোমতী',
  'shitalakkhya': 'শীতলক্ষ্যা',
  'buriganga': 'বুড়িগঙ্গা',
  'punarbhaba': 'পুনর্ভবা',
  'surma': 'সুরমা',
  'gorai': 'গড়াই',
  'bhairab': 'ভৈরব',
  'brahmaputra': 'ব্রহ্মপুত্র',
  'khowai': 'খোয়াই',
  'jamuna': 'যমুনা',
};

bool _isYear(String t) => t.length == 4 && int.tryParse(t) != null;
bool _isNum(String t) => int.tryParse(t) != null;
String _n(String t, bool bn) =>
    bn ? toBnDigits('${int.parse(t)}') : '${int.parse(t)}';
String _river(String t, bool bn) => bn ? (_rivers[t] ?? t) : t;

String _modelTitle(String? n, bool bn, int serial) {
  final num = n == null ? numStr(serial, bn) : _n(n, bn);
  return bn ? 'মডেল টেস্ট $num' : 'Model Test $num';
}

String? _boardTitle(List<String> t, bool bn) {
  final bi = t.indexOf('board');
  if (bi < 0) return null;
  final yi = t.indexWhere(_isYear, bi);
  if (yi < 0) return null;
  final boardTokens = t.sublist(bi + 1, yi);
  final after = t.sublist(yi + 1);
  String? kind;
  var setTokens = after;
  if (after.isNotEmpty && (after.last == 'mcq' || after.last == 'creative')) {
    kind = after.last == 'mcq' ? 'MCQ' : (bn ? 'সৃজনশীল' : 'Creative');
    setTokens = after.sublist(0, after.length - 1);
  }
  if (setTokens.isNotEmpty && setTokens.first == 'set') {
    setTokens = setTokens.sublist(1);
  }
  String? setPart;
  if (setTokens.isNotEmpty) {
    final first = setTokens.first;
    final river = setTokens.length > 1 ? _river(setTokens[1], bn) : null;
    if (first == 'single') {
      setPart = bn ? 'একক সেট' : 'Single set';
    } else if (first == 'noset') {
      setPart = null;
    } else if (_isNum(first)) {
      setPart = bn ? 'সেট ${_n(first, bn)}' : 'Set ${int.parse(first)}';
      if (river != null) setPart = '$setPart · $river';
    } else if (_setLetters.containsKey(first)) {
      setPart = bn ? 'সেট ${_setLetters[first]}' : 'Set $first';
      if (river != null) setPart = '$setPart · $river';
    } else {
      // River-only creative set: the river IS the set name.
      setPart = _river(first, bn);
    }
  }
  final String boardLabel;
  if (boardTokens.length == 1 && boardTokens.first == 'all') {
    boardLabel = bn ? 'সকল বোর্ড' : 'All boards';
  } else if (boardTokens.length == 1) {
    final name = bn
        ? (_boards[boardTokens.first] ?? boardTokens.first)
        : (_boardsEn[boardTokens.first] ?? boardTokens.first);
    boardLabel = bn ? '$name বোর্ড' : '$name Board';
  } else {
    boardLabel = bn
        ? '${numStr(boardTokens.length, bn)} বোর্ড'
        : '${boardTokens.length} boards';
  }
  final year = bn ? toBnDigits(t[yi]) : t[yi];
  final parts = ['$boardLabel $year'];
  if (setPart != null) parts.add(setPart);
  if (kind != null) parts.add(kind);
  return parts.join(' · ');
}

String? _chapterModelTitle(List<String> t, bool bn) {
  final ci = t.indexWhere((x) => RegExp(r'^ch\d+$').hasMatch(x));
  if (ci < 0) return null;
  final mi = t.indexOf('model', ci);
  if (mi < 0) return null;
  final ch = t[ci].substring(2);
  String? num;
  String? kind;
  for (final r in t.sublist(mi + 1)) {
    if (_isNum(r)) {
      num ??= r;
    } else if (r == 'mcq') {
      kind = 'MCQ';
    } else if (r == 'written') {
      kind = bn ? 'লিখিত' : 'Written';
    }
  }
  final base = bn
      ? 'অধ্যায় ${_n(ch, bn)} মডেল টেস্ট'
      : 'Chapter $ch Model Test';
  final titled = num == null ? base : '$base ${_n(num, bn)}';
  return kind == null ? titled : '$titled · $kind';
}

/// Bangla-1st lesson-model set ids: ban1-<section>-<lesson-slug>
/// -model-mcq (or -creative, optional trailing -set). Returns the
/// lesson slug, or null for any other id. The tree looks the
/// lesson title up for the subtitle.
String? ban1LessonSlug(String setId) {
  final t = setId.split('-');
  if (t.first != 'ban1') return null;
  final mi = t.indexOf('model');
  if (mi < 3) return null; // need section + at least one slug token
  return t.sublist(2, mi).join('-');
}

String setDisplayTitle(String setId, bool bn, int serial) {
  if (setId.runes.any((r) => r > 127)) return setId; // already Bengali
  final t = setId.split('-');
  final board = _boardTitle(t, bn);
  if (board != null) return board;
  if (t.first == 'ban1') return _modelTitle(null, bn, serial);
  final chapterModel = _chapterModelTitle(t, bn);
  if (chapterModel != null) return chapterModel;
  if (t.contains('special')) {
    final n = t.last;
    if (_isNum(n)) {
      return bn ? 'বিশেষ মডেল টেস্ট ${_n(n, bn)}' : 'Special Model Test $n';
    }
  }
  if (t.first == 'model' && t.length >= 2 && t[1] == 'test') {
    if (t.length == 2) return bn ? 'মডেল টেস্ট' : 'Model Test';
    if (t.length == 3 && _isNum(t[2])) {
      return _modelTitle(t[2], bn, serial);
    }
  }
  if (t.first == 'model' && t.length == 2 && _isNum(t[1])) {
    return _modelTitle(t[1], bn, serial);
  }
  if (t.first == 'paper2' && t.length == 2 && _isNum(t[1])) {
    return 'Paper-II ${bn ? 'মডেল টেস্ট' : 'Model Test'} ${_n(t[1], bn)}';
  }
  return _modelTitle(null, bn, serial);
}
