// Phase 1 browse extras for the generic guide search flow: set
// picking, server-driven lessons, and the Paper-II section pick.
// Split out of SearchFlowController so the controller stays under
// the 250-line cap. The screen owns one instance next to the
// controller and refreshes it on subject/source/class change.
// Picks reset on refresh: a pick belongs to its subject, never
// the next one — the Edge list applies lesson/section filters
// INSIDE the set scope too, so a stale pick would silently
// intersect the next list instead of replacing it.
import 'package:flutter/material.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/app_config.dart';
import '../../core/services/edge_post.dart';
import '../../core/services/model_test_set_service.dart';
import '../../core/services/picker_cache_service.dart';

class SearchFlowBrowseExtras {
  SearchFlowBrowseExtras({required this.onChanged});
  final VoidCallback onChanged;

  /// Picked model-test set (null = no set picked). When set, the
  /// list uses the set scope and chapter/type/lesson/section
  /// picks are ignored (Edge precedence: setId wins).
  String? setId;

  /// Server set metadata for the current guide subject, or empty
  /// when none / unreachable. Null from the service means
  /// unreachable, never "no sets" — the picker hides either way.
  List<GuideModelSetInfo> sets = const [];
  bool setsLoading = false;

  /// Server lesson values (lesson -> totalCount) for the current
  /// guide subject, Bangla only. Empty when none / unreachable /
  /// non-Bangla. Sent VERBATIM to the list filter (see lessons
  /// docs: grouping is verbatim, so the picker never trims).
  Map<String, int> serverLessons = const {};
  bool serverLessonsLoading = false;

  /// Paper-II section pick (english-2nd only). Null = none.
  String? paper2Section;

  int _generation = 0;

  void _notify() => onChanged();

  /// Reload sets (+ Bangla lessons) for a subject. Resets
  /// the picks first. Safe to call for any source — the
  /// pickers only render in guide source — while clearGuide()
  /// is the cheaper call when leaving the flow. A newer
  /// refresh or a clear supersedes an older in-flight one
  /// (generation guard), so rapid subject changes never land
  /// a stale picker. Cache-first (stale-while-revalidate):
  /// saved sets/lessons render instantly, then a fresh fetch
  /// overwrites them; unreachable + cache keeps the cache.
  /// Sets are language-independent (lang 'all'); lessons are
  /// Bangla-only. Fresh fetches share in-flight work with a
  /// prefetch for the same subject (dedupe keys match).
  Future<void> refreshGuide(String subjectId, int schoolClass) async {
    final gen = ++_generation;
    setId = null;
    paper2Section = null;
    sets = const [];
    serverLessons = const {};
    setsLoading = true;
    serverLessonsLoading = subjectId == 'bangla';
    _notify();
    final setsKey = pickerCacheKey(
        schoolClass, subjectId, 'all', pickerCacheKindSets);
    final lessonsKey = pickerCacheKey(
        schoolClass, subjectId, 'bn', pickerCacheKindServerLessons);
    var showedSetsCache = false;
    var showedLessonsCache = false;
    final cachedSets = await pickerCacheService.read(setsKey);
    if (gen == _generation && cachedSets != null) {
      final decoded = decodeModelSets(cachedSets);
      if (decoded != null) {
        sets = decoded;
        setsLoading = false;
        showedSetsCache = true;
      }
    }
    if (subjectId == 'bangla') {
      final cachedLessons = await pickerCacheService.read(lessonsKey);
      if (gen == _generation && cachedLessons != null) {
        final decoded = decodeServerLessons(cachedLessons);
        if (decoded != null) {
          serverLessons = decoded;
          serverLessonsLoading = false;
          showedLessonsCache = true;
        }
      }
    } else {
      serverLessonsLoading = false;
    }
    if (showedSetsCache || showedLessonsCache) _notify();
    final loadedSets = await pickerCacheService
        .dedupe(
          'fetch:$setsKey',
          () => modelTestSetService
              .fetchSetsFromServer(subjectId, schoolClass: schoolClass)
              .catchError((_) => null),
        )
        .catchError((_) => null);
    Map<String, int>? lessons;
    if (subjectId == 'bangla') {
      lessons = await pickerCacheService
          .dedupe(
            'fetch:$lessonsKey',
            () => _fetchServerLessons(subjectId, schoolClass),
          )
          .catchError((_) => null);
    }
    if (gen != _generation) return;
    if (loadedSets != null) {
      sets = loadedSets;
      await pickerCacheService.write(setsKey, encodeModelSets(loadedSets));
    } else if (!showedSetsCache) {
      sets = const [];
    }
    setsLoading = false;
    if (lessons != null) {
      serverLessons = lessons;
      await pickerCacheService.write(
          lessonsKey, encodeServerLessons(lessons));
    } else if (!showedLessonsCache && subjectId == 'bangla') {
      serverLessons = const {};
    }
    serverLessonsLoading = false;
    _notify();
  }

  /// Warms the sets/lessons cache without touching picker
  /// state. Stale or missing entries only: a fresh entry is
  /// never refetched. Failures are swallowed — warming must
  /// never surface an error, the live load retries anyway.
  Future<void> warmGuideCache(String subjectId, int schoolClass) async {
    try {
      final setsKey = pickerCacheKey(
          schoolClass, subjectId, 'all', pickerCacheKindSets);
      if (!await pickerCacheService.isFresh(setsKey)) {
        final freshSets = await pickerCacheService
            .dedupe(
              'fetch:$setsKey',
              () => modelTestSetService
                  .fetchSetsFromServer(subjectId,
                      schoolClass: schoolClass)
                  .catchError((_) => null),
            )
            .catchError((_) => null);
        if (freshSets != null) {
          await pickerCacheService.write(
              setsKey, encodeModelSets(freshSets));
        }
      }
      if (subjectId == 'bangla') {
        final lessonsKey = pickerCacheKey(
            schoolClass, subjectId, 'bn', pickerCacheKindServerLessons);
        if (!await pickerCacheService.isFresh(lessonsKey)) {
          final freshLessons = await pickerCacheService
              .dedupe(
                'fetch:$lessonsKey',
                () => _fetchServerLessons(subjectId, schoolClass),
              )
              .catchError((_) => null);
          if (freshLessons != null) {
            await pickerCacheService.write(
                lessonsKey, encodeServerLessons(freshLessons));
          }
        }
      }
    } catch (_) {}
  }

  /// Clear everything (textbook source, or leaving the flow).
  void clearGuide() {
    _generation++;
    setId = null;
    paper2Section = null;
    sets = const [];
    serverLessons = const {};
    setsLoading = false;
    serverLessonsLoading = false;
    _notify();
  }

  /// guideLessons action (Phase 1 Edge addition). Null = the
  /// action is unreachable, the book is unknown, or the server
  /// predates the lesson column (found:false) — the lesson
  /// picker hides and lesson stays optional either way.
  Future<Map<String, int>?> _fetchServerLessons(
      String subjectId, int schoolClass) async {
    if (AppConfig.guideBankEndpoint.isEmpty) return null;
    final res = await edgePost({
      'action': 'guideLessons',
      'classId': schoolClass,
      'subject': subjectId,
    }, endpoint: AppConfig.guideBankEndpoint).catchError((_) => null);
    if (res == null || res['found'] != true) return null;
    final list = res['lessons'];
    if (list is! List) return null;
    final out = <String, int>{};
    for (final e in list.whereType<Map>()) {
      final lesson = e['lesson'];
      final total = e['totalCount'];
      if (lesson is String && lesson.isNotEmpty && total is num) {
        out[lesson] = total.toInt();
      }
    }
    return out;
  }
}
