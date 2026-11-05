// Host helpers for the global picker inside the search screen:
// the selected-row id, the one place that turns a pick into the
// exact state change the old per-subject dropdowns used to make,
// and the lazily created English controller for the English
// guide tree (sets/bank load once, on first English use).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/load_connectivity.dart';
import '../../core/services/picker_cache_service.dart';
import 'english_search_flow_controller.dart';
import 'global_picker_model.dart';
import 'search_flow_bangla_papers.dart';
import 'search_flow_browse_extras.dart';
import 'search_flow_chapter_fetch.dart';
import 'search_flow_controller.dart';

String? globalPickerSelectedId(
    SearchFlowController c, SearchFlowBrowseExtras extras) {
  if (extras.setId != null) return 'set:${extras.setId}';
  if (c.lesson != null) {
    if (c.banglaSection != null) {
      return 'lesson:${c.banglaSection}:${c.lesson}';
    }
    if (c.chapter != null) return 'lesson:${c.chapter}:${c.lesson}';
    return 'lesson:__all:${c.lesson}';
  }
  if (c.banglaSection != null) return 'section:${c.banglaSection}';
  if (extras.paper2Section != null) return 'paper2:${extras.paper2Section}';
  if (c.chapter != null) return 'chapter:${c.chapter}';
  return null;
}

/// Applies one pick, preserving the old mutual-exclusion rules:
/// a set pick clears lesson + Paper-II section, a lesson pick
/// clears the set, a Paper-II section pick clears the set, a
/// Bangla section pick clears lesson + set, a chapter pick
/// clears the lesson but keeps a picked set (the list lets the
/// set win, as before). Route picks navigate and change nothing.
void applyGlobalPickerPick({
  required BuildContext context,
  required SearchFlowController c,
  required SearchFlowBrowseExtras extras,
  required GlobalPickerPick pick,
  required VoidCallback onChanged,
}) {
  switch (pick.kind) {
    case GlobalPickerPickKind.route:
      context.go(pick.route!);
      return;
    case GlobalPickerPickKind.set:
      extras.setId = pick.setId;
      c.lesson = null;
      extras.paper2Section = null;
      break;
    case GlobalPickerPickKind.paper2:
      extras.paper2Section = pick.paper2Section;
      extras.setId = null;
      break;
    case GlobalPickerPickKind.section:
      c.banglaSection = pick.banglaSection;
      c.lesson = null;
      extras.setId = null;
      break;
    case GlobalPickerPickKind.sectionLesson:
      c.banglaSection = pick.banglaSection;
      c.lesson = pick.lesson;
      extras.setId = null;
      break;
    case GlobalPickerPickKind.chapter:
      c.chapter = pick.chapter;
      c.lesson = null;
      break;
    case GlobalPickerPickKind.chapterLesson:
      c.chapter = pick.chapter;
      c.lesson = pick.lesson;
      extras.setId = null;
      break;
  }
  onChanged();
}

class GlobalPickerEnglishHost {
  EnglishSearchFlowController? controller;
  int? _schoolClass;

  void ensure({
    required String subjectId,
    required String source,
    required int schoolClass,
    required VoidCallback onChanged,
  }) {
    if (subjectId != 'english' || source != 'guide') return;
    final existing = controller;
    if (existing == null) {
      controller = EnglishSearchFlowController(onChanged: onChanged);
      _schoolClass = schoolClass;
      controller!.init(schoolClass);
      return;
    }
    if (_schoolClass != schoolClass) {
      _schoolClass = schoolClass;
      existing.changeClass(schoolClass);
    }
  }
}

/// Warms the picker cache for the first subject in the list
/// (when it is not the current one) so a later tap on it
/// renders from disk instantly. WiFi-only, fire-and-forget,
/// failures swallowed: warming must never surface an error.
/// The fetches share in-flight work with a live load for the
/// same subject (dedupe keys match), so warming while the
/// user taps that subject costs no second network run.
void prefetchFirstSubjectPickerData(
    SearchFlowController c, SearchFlowBrowseExtras extras) {
  () async {
    try {
      if (c.subjects.length < 2) return;
      final first = c.subjects.first;
      if (first.id == c.subjectId) return;
      if (!await isWifiOnlyPrefetchAllowed()) return;
      final src = first.locked ? 'guide' : 'textbook';
      final subj = banglaPaperSubject(first.id);
      final cls = banglaPaperClass(first.id, src, c.schoolClass);
      final lang = c.bangla ? 'bn' : 'en';
      final kind = src == 'guide'
          ? pickerCacheKindGuideChapters
          : pickerCacheKindTextbookChapters;
      final key = pickerCacheKey(cls, subj, lang, kind);
      if (!await pickerCacheService.isFresh(key)) {
        final tuples = await pickerCacheService
            .dedupe(
              'fetch:$key',
              () => fetchSearchFlowChapterTuples(
                source: src,
                subject: subj,
                schoolClass: cls,
                bangla: c.bangla,
              ),
            )
            .catchError((_) => null);
        if (tuples != null) {
          await pickerCacheService.write(key, encodeChapterTuples(tuples));
        }
      }
      await extras.warmGuideCache(subj, cls);
    } catch (_) {}
  }();
}
