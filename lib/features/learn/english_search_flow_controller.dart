// State for the redesigned English search flow (2026-11-03).
// No chapter anywhere; entry paths are the 12-value section
// picker and the lesson picker, whose items are STRICTLY
// filtered by the selected section (a model section never
// shows practice items, and vice versa). Model/special items
// come from set metadata only (no row scan); practice items
// come from bank rows only; poem/story items are constants.
// The screen only renders; this controller owns state.
import 'package:flutter/material.dart';

import '../../core/data/english_redesign.dart';
import '../../core/data/english_redesign_lessons.dart';
import '../../core/models/guide_bank_model.dart';
import '../../core/services/english_reader_service.dart';
import '../../core/services/english_set_scan.dart';
import '../../core/services/picker_cache_service.dart';
import '../../core/services/profile_service.dart';

class EnglishSearchFlowController {
  EnglishSearchFlowController({
    required this.onChanged,
    EnglishSetScanService? scanService,
  }) : _scan = scanService ?? EnglishSetScanService();
  final VoidCallback onChanged;
  final EnglishSetScanService _scan;
  EnglishReaderService? _readerService;
  EnglishReaderService get _reader =>
      _readerService ??= EnglishReaderService(scan: _scan);

  int schoolClass = 9;
  List<GuideModelSetInfo>? sets;
  bool setsLoading = true;
  bool setsUnavailable = false;
  List<GuideBankQuestion>? bankRows;
  bool bankLoading = true;
  bool bankUnavailable = false;
  List<EnglishRedesignLesson>? bucketItems;
  bool bucketLoading = false;
  bool bucketUnavailable = false;
  String? section;
  EnglishRedesignLesson? lesson;

  void _notify() => onChanged();

  /// Lesson items for the current section, or null while the
  /// underlying data is still loading. A failed load yields
  /// an empty list with the unavailable flags set, so the
  /// screen shows retry instead of a partial list.
  List<EnglishRedesignLesson>? get lessonItems {
    switch (section) {
      case 'model':
        if (sets == null) return null;
        return modelLessonItems(sets!);
      case 'special':
        if (sets == null) return null;
        return specialLessonItems(sets!);
      case 'practice':
        if (bankRows == null) return null;
        return practiceSerials(bankRows!);
      case 'poem':
        return [
          for (final name in englishPoemNames)
            EnglishRedesignLesson(
                kind: 'poem', index: 0, workName: name),
        ];
      case 'story':
        return [
          for (final name in englishStoryNames)
            EnglishRedesignLesson(
                kind: 'story', index: 0, workName: name),
        ];
      case 'bucket':
        return bucketItems;
      default:
        // Writing sections keep the old list behavior: no
        // lesson items, the section button opens the list.
        return const [];
    }
  }

  bool get lessonsLoading {
    if (section == 'model' || section == 'special') return setsLoading;
    if (section == 'practice') return bankLoading;
    if (section == 'bucket') return bucketLoading;
    return false;
  }

  bool get lessonsUnavailable {
    if (section == 'model' || section == 'special') return setsUnavailable;
    if (section == 'practice') return bankUnavailable;
    if (section == 'bucket') return bucketUnavailable;
    return false;
  }

  Future<void> init(int? initialClass) async {
    final saved =
        await profileService.loadSchoolClass().catchError((_) => null);
    schoolClass = initialClass ?? saved ?? 9;
    await loadSets();
    await loadBankRows();
  }

  /// Cache-first (stale-while-revalidate) for set metadata:
  /// saved sets render instantly, then a fresh fetch
  /// overwrites them. Unreachable + cache keeps the cache, so
  /// the model/special pickers still work offline; unreachable
  /// + no cache keeps the old unavailable flag. Bank rows are
  /// untouched here: they already have their own disk cache
  /// (chapterless rows, SWR) through the scan service.
  Future<void> loadSets() async {
    setsLoading = true;
    setsUnavailable = false;
    _notify();
    final key = pickerCacheKey(
        schoolClass, 'english', 'all', pickerCacheKindEnglishSets);
    var showedCache = false;
    final cached = await pickerCacheService.read(key);
    if (cached != null) {
      final decoded = decodeModelSets(cached);
      if (decoded != null) {
        sets = decoded;
        setsLoading = false;
        setsUnavailable = false;
        showedCache = true;
        _notify();
      }
    }
    final loaded = await _scan.fetchSets(schoolClass: schoolClass);
    setsLoading = false;
    if (loaded != null) {
      sets = loaded;
      setsUnavailable = false;
      await pickerCacheService.write(key, encodeModelSets(loaded));
    } else if (!showedCache) {
      sets = null;
      setsUnavailable = true;
    }
    _notify();
  }

  Future<void> loadBankRows() async {
    bankLoading = true;
    bankUnavailable = false;
    _notify();
    final loaded = await _scan.fetchBankRows(schoolClass: schoolClass);
    bankRows = loaded;
    bankLoading = false;
    bankUnavailable = loaded == null;
    _notify();
  }

  Future<void> changeClass(int cls) async {
    if (cls == schoolClass) return;
    schoolClass = cls;
    section = null;
    lesson = null;
    bucketItems = null;
    bucketLoading = false;
    bucketUnavailable = false;
    await loadSets();
    await loadBankRows();
  }

  Future<void> loadBucketItems() async {
    bucketLoading = true;
    bucketUnavailable = false;
    _notify();
    final loaded = await _reader.bucketLessonItems(schoolClass);
    bucketItems = loaded;
    bucketLoading = false;
    bucketUnavailable = loaded == null;
    _notify();
  }

  void selectSection(String? value) {
    section = value;
    lesson = null;
    // Bucket items need a full row scan: load lazily on first
    // select, never at init (poem/story items are constants).
    if (value == 'bucket' && bucketItems == null && !bucketLoading) {
      loadBucketItems();
    }
    _notify();
  }

  void selectLesson(EnglishRedesignLesson? value) {
    lesson = value;
    _notify();
  }

  Future<void> retryLessons() async {
    if (section == 'model' || section == 'special') {
      await loadSets();
    } else if (section == 'practice') {
      await loadBankRows();
    } else if (section == 'bucket') {
      await loadBucketItems();
    }
  }
}
