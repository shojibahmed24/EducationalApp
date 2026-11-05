// English set + bank scan (separate English search flow).
// English rows carry chapter_number NULL, so no chapter
// filter can ever match them: set rows arrive by book_id +
// set_id, bank rows (set_id NULL) by list with chapterless:
// true. Section/lesson filters run client-side over BOTH
// phases and never send an English section value as the
// server `section` parameter (the allowlist would 400).
// Filtered lists cover set + bank rows — complete.
import '../models/guide_bank_model.dart';
import 'model_test_set_service.dart';

typedef EnglishSetsFetch = Future<List<GuideModelSetInfo>?> Function(
    String subject,
    {int schoolClass});
typedef EnglishSetRowsFetch = Future<List<GuideBankQuestion>?> Function(
    String subject, String setId,
    {int schoolClass});
typedef EnglishBankRowsFetch = Future<List<GuideBankQuestion>?> Function(
    String subject,
    {int schoolClass});

/// Resume position for a filtered scan. Set phase: next set
/// + row index inside it. Bank phase (inBank): bankRowIndex
/// is the next bank row to read. A bank cursor parks at 0
/// on failure — the failed fetch contributed no rows, so
/// resuming from 0 cannot duplicate anything returned.
class EnglishScanCursor {
  const EnglishScanCursor(this.setIndex, this.rowIndex,
      {this.inBank = false, this.bankRowIndex = 0});
  final int setIndex;
  final int rowIndex;
  final bool inBank;
  final int bankRowIndex;
}

/// One 20-row display page from a set scan.
class EnglishScanPage {
  const EnglishScanPage({
    required this.rows,
    required this.hasMore,
    this.nextCursor,
    this.unavailable = false,
  });
  final List<GuideBankQuestion> rows;
  final bool hasMore;
  final EnglishScanCursor? nextCursor;

  /// True only when nothing could be fetched on the first page
  /// (server unreachable) — distinct from an honest empty list.
  final bool unavailable;
}

/// Redirect predicate for the old search flow: English guide
/// mode belongs to the separate English flow. Every other
/// combination (Math in any mode, English textbook mode) stays
/// on the old flow — Math behavior is untouched by it.
bool shouldUseEnglishSearchFlow(String subjectId, String source) =>
    subjectId == 'english' && source == 'guide';

class EnglishSetScanService {
  EnglishSetScanService(
      {EnglishSetsFetch? fetchSets,
      EnglishSetRowsFetch? fetchSetRows,
      EnglishBankRowsFetch? fetchBankRows})
      : _fetchSets = fetchSets ?? modelTestSetService.fetchSetsFromServer,
        _fetchSetRows = fetchSetRows ?? modelTestSetService.fetchSetRows,
        _fetchBankRows =
            fetchBankRows ?? modelTestSetService.fetchChapterlessBankRows;
  final EnglishSetsFetch _fetchSets;
  final EnglishSetRowsFetch _fetchSetRows;
  final EnglishBankRowsFetch _fetchBankRows;

  static const pageSize = 20;

  final Map<int, List<GuideModelSetInfo>> _setsCache = {};
  final Map<String, List<GuideBankQuestion>> _rowsCache = {};
  final Map<int, List<GuideBankQuestion>> _bankCache = {};
  final Map<int, List<String>> _lessonsCache = {};

  Future<List<GuideModelSetInfo>?> _sets(int schoolClass) async {
    final cached = _setsCache[schoolClass];
    if (cached != null) return cached;
    final sets = await _fetchSets('english', schoolClass: schoolClass);
    if (sets != null) _setsCache[schoolClass] = sets;
    return sets;
  }

  Future<List<GuideBankQuestion>?> _setRows(
      int schoolClass, String setId) async {
    final key = '$schoolClass:$setId';
    final cached = _rowsCache[key];
    if (cached != null) return cached;
    final rows =
        await _fetchSetRows('english', setId, schoolClass: schoolClass);
    if (rows != null) _rowsCache[key] = rows;
    return rows;
  }

  Future<List<GuideBankQuestion>?> _bankRows(int schoolClass) async {
    final cached = _bankCache[schoolClass];
    if (cached != null) return cached;
    final rows = await _fetchBankRows('english', schoolClass: schoolClass);
    if (rows != null) _bankCache[schoolClass] = rows;
    return rows;
  }

  /// Scan [rows] from [start], appending matches until the
  /// page is full. Returns the next unscanned index.
  int _scanList(List<GuideBankQuestion> rows, int start,
      bool Function(GuideBankQuestion) matches, List<GuideBankQuestion> out) {
    var i = start;
    while (i < rows.length && out.length < pageSize) {
      if (matches(rows[i])) out.add(rows[i]);
      i++;
    }
    return i;
  }

  /// Set metadata (counts only). Null = unreachable.
  Future<List<GuideModelSetInfo>?> fetchSets(
      {required int schoolClass}) async {
    final sets = await _sets(schoolClass);
    return sets == null ? null : List<GuideModelSetInfo>.unmodifiable(sets);
  }

  /// All rows of one set, cached. Null = unreachable.
  Future<List<GuideBankQuestion>?> fetchAllSetRows(
      {required int schoolClass, required String setId}) async {
    final rows = await _setRows(schoolClass, setId);
    return rows == null ? null : List<GuideBankQuestion>.unmodifiable(rows);
  }

  /// All chapter-less bank rows, cached. Null = unreachable.
  Future<List<GuideBankQuestion>?> fetchBankRows(
      {required int schoolClass}) async {
    final rows = await _bankRows(schoolClass);
    return rows == null ? null : List<GuideBankQuestion>.unmodifiable(rows);
  }
  /// One page of a single set's rows, paged locally (the set
  /// fetch already returns every row). Null rows on first page
  /// => unavailable page, never an empty list disguised as one.
  Future<EnglishScanPage> fetchSetPage({
    required int schoolClass,
    required String setId,
    int offset = 0,
  }) async {
    final rows = await _setRows(schoolClass, setId);
    if (rows == null) {
      return const EnglishScanPage(
          rows: [], hasMore: false, unavailable: true);
    }
    final page = rows.skip(offset).take(pageSize).toList();
    return EnglishScanPage(
        rows: page, hasMore: offset + page.length < rows.length);
  }

  /// One page of set + bank rows matching [section] and/or
  /// [lesson]: set phase first, then bank, with [resume]
  /// resumption across both. A mid-scan failure returns what
  /// matched so far with hasMore true and the cursor parked
  /// at the failed phase, so "আরো দেখুন" retries it. A
  /// first-page failure is unavailable, never empty.
  Future<EnglishScanPage> fetchFilteredPage({
    required int schoolClass,
    String? section,
    String? lesson,
    EnglishScanCursor? resume,
  }) async {
    final sets = await _sets(schoolClass);
    if (sets == null) {
      return const EnglishScanPage(
          rows: [], hasMore: false, unavailable: true);
    }
    bool matches(GuideBankQuestion r) =>
        (section == null || r.section == section) &&
        (lesson == null || r.lesson == lesson);
    final matched = <GuideBankQuestion>[];
    var setIndex = resume?.setIndex ?? 0;
    var rowIndex = resume?.rowIndex ?? 0;
    var bankRowIndex = resume?.bankRowIndex ?? 0;
    if (!(resume?.inBank ?? false)) {
      while (matched.length < pageSize && setIndex < sets.length) {
        final rows = await _setRows(schoolClass, sets[setIndex].setId);
        if (rows == null) {
          if (resume == null && matched.isEmpty) {
            return const EnglishScanPage(
                rows: [], hasMore: false, unavailable: true);
          }
          return EnglishScanPage(
              rows: matched,
              hasMore: true,
              nextCursor: EnglishScanCursor(setIndex, 0));
        }
        rowIndex = _scanList(rows, rowIndex, matches, matched);
        if (rowIndex >= rows.length) {
          setIndex++;
          rowIndex = 0;
        }
      }
      if (matched.length >= pageSize) {
        return EnglishScanPage(
            rows: matched,
            hasMore: true,
            nextCursor: EnglishScanCursor(setIndex, rowIndex));
      }
    }
    // Bank phase: reached when sets are exhausted, or when
    // the resume cursor already sits in the bank phase.
    final bankRows = await _bankRows(schoolClass);
    if (bankRows == null) {
      if (resume == null && matched.isEmpty) {
        return const EnglishScanPage(
            rows: [], hasMore: false, unavailable: true);
      }
      return EnglishScanPage(
          rows: matched,
          hasMore: true,
          nextCursor: EnglishScanCursor(sets.length, 0,
              inBank: true, bankRowIndex: 0));
    }
    bankRowIndex = _scanList(bankRows, bankRowIndex, matches, matched);
    final bankExhausted = bankRowIndex >= bankRows.length;
    return EnglishScanPage(
        rows: matched,
        hasMore: !bankExhausted,
        nextCursor: bankExhausted
            ? null
            : EnglishScanCursor(sets.length, 0,
                inBank: true, bankRowIndex: bankRowIndex));
  }

  /// Distinct lessons in set + bank rows, sorted, cached per
  /// class. Null = any fetch failed: a partial lesson list
  /// would mislead, so the picker shows retry instead.
  Future<List<String>?> fetchLessons({required int schoolClass}) async {
    final cached = _lessonsCache[schoolClass];
    if (cached != null) return cached;
    final sets = await _sets(schoolClass);
    if (sets == null) return null;
    final found = <String>{};
    void collect(List<GuideBankQuestion> rows) {
      for (final r in rows) {
        final lesson = r.lesson;
        if (lesson != null && lesson.isNotEmpty) found.add(lesson);
      }
    }

    for (final s in sets) {
      final rows = await _setRows(schoolClass, s.setId);
      if (rows == null) return null;
      collect(rows);
    }
    final bankRows = await _bankRows(schoolClass);
    if (bankRows == null) return null;
    collect(bankRows);
    final sorted = found.toList()..sort();
    _lessonsCache[schoolClass] = sorted;
    return sorted;
  }
}
