// Area 2 local persistence, via SharedPreferences directly.
// LocalStore is owned by another area and is NOT edited here; this
// helper only adds the keys Area 2 needs (recents, counts, notes,
// save-toggles). Saved-question ids are ALSO written to LocalStore
// so the Saved screen (another area) can read them.
// NOTE: no bKash here — deliberately absent, Play Billing only.
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/saved_sync_service.dart';

class LearnSummary {
  const LearnSummary({
    required this.lessonsOpened,
    required this.lessonsToday,
    required this.chaptersOpened,
    required this.savedCount,
    required this.recentBooks,
    required this.recentSearches,
    required this.lastLessonKey,
  });
  final int lessonsOpened;
  final int lessonsToday;
  final int chaptersOpened;
  final int savedCount;
  final List<String> recentBooks; // 'subject|titleBn|titleEn'
  final List<String> recentSearches; // 'label|key'
  final String? lastLessonKey;
}

class LearnStore {
  static const _lessons = 'area2_lessons';
  static const _lessonsToday = 'area2_lessons_today';
  static const _lessonsTodayIds = 'area2_lessons_today_ids';
  static const _today = 'area2_today';
  static const _chapters = 'area2_chapters';
  static const _saved = 'area2_saved_ids';
  static const _books = 'area2_recent_books';
  static const _searches = 'area2_recent_searches';
  static const _lastLesson = 'area2_last_lesson';
  static const _photoNotes = 'area2_photo_notes';

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static Future<void> recordLesson(String key, String chapterKey) async {
    final p = await SharedPreferences.getInstance();
    final lessons = p.getStringList(_lessons) ?? [];
    if (!lessons.contains(key)) {
      lessons.add(key);
      await p.setStringList(_lessons, lessons);
    }
    final chapters = p.getStringList(_chapters) ?? [];
    if (!chapters.contains(chapterKey)) {
      chapters.add(chapterKey);
      await p.setStringList(_chapters, chapters);
    }
    if (p.getString(_today) != _todayStr()) {
      await p.setString(_today, _todayStr());
      await p.setStringList(_lessonsTodayIds, []);
      await p.setInt(_lessonsToday, 0);
    }
    // Lessons-today counts NEW lessons only: re-opening the
    // same lesson never inflates the day's count.
    final todayIds = p.getStringList(_lessonsTodayIds) ?? [];
    if (!todayIds.contains(key)) {
      todayIds.add(key);
      await p.setStringList(_lessonsTodayIds, todayIds);
      await p.setInt(_lessonsToday, todayIds.length);
    }
    await p.setString(_lastLesson, key);
  }

  static Future<void> addRecentBook(String entry) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_books) ?? [];
    list.remove(entry);
    list.insert(0, entry);
    await p.setStringList(_books, list.take(5).toList());
  }

  static Future<void> addRecentSearch(String entry) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_searches) ?? [];
    list.remove(entry);
    list.insert(0, entry);
    await p.setStringList(_searches, list.take(5).toList());
  }

  /// Search screen "Clear": wipes only the recent-search list.
  static Future<void> clearRecentSearches() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_searches);
  }

  static Future<void> addPhotoNote(String note) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_photoNotes) ?? [];
    list.add(note);
    // Cap 50: the oldest notes drop off first.
    if (list.length > 50) {
      list.removeRange(0, list.length - 50);
    }
    await p.setStringList(_photoNotes, list);
  }

  static Future<List<String>> photoNotes() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_photoNotes) ?? const [];
  }

  static Future<bool> isSaved(String id) async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_saved) ?? const []).contains(id);
  }

  static Future<bool> toggleSaved(String id) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_saved) ?? [];
    final nowSaved = !list.contains(id);
    if (nowSaved) {
      list.add(id);
    } else {
      list.remove(id);
    }
    await p.setStringList(_saved, list);
    // Sync the Saved screen's list (LocalStore 'saved_questions' key):
    // unsave must remove the id there too, otherwise Saved keeps
    // showing a question the user just unsaved from lesson/chat.
    final shared = p.getStringList('saved_questions') ?? [];
    if (nowSaved) {
      if (!shared.contains(id)) shared.add(id);
    } else {
      shared.remove(id);
    }
    await p.setStringList('saved_questions', shared);
    // Phase 16 (M10): best-effort cloud sync, local list kept either way.
    if (nowSaved) {
      await savedSyncService.syncSave(id);
    } else {
      await savedSyncService.syncUnsave(id);
    }
    return nowSaved;
  }

  static Future<LearnSummary> summary() async {
    final p = await SharedPreferences.getInstance();
    final todayCount = p.getString(_today) == _todayStr()
        ? (p.getInt(_lessonsToday) ?? 0)
        : 0;
    return LearnSummary(
      lessonsOpened: (p.getStringList(_lessons) ?? const []).length,
      lessonsToday: todayCount,
      chaptersOpened: (p.getStringList(_chapters) ?? const []).length,
      savedCount: (p.getStringList(_saved) ?? const []).length,
      recentBooks: p.getStringList(_books) ?? const [],
      recentSearches: p.getStringList(_searches) ?? const [],
      lastLessonKey: p.getString(_lastLesson),
    );
  }

  /// Today's lesson keys, same day-rollover semantics as
  /// summary(): a stale stored day yields an empty list, never
  /// yesterday's lessons. Counting in summary()/recordLesson()
  /// is untouched — this only exposes the stored ids.
  static Future<List<String>> lessonsTodayList() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_today) != _todayStr()) return const [];
    return p.getStringList(_lessonsTodayIds) ?? const [];
  }

  static Future<List<String>> chaptersList() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_chapters) ?? const [];
  }

  static Future<List<String>> savedIds() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_saved) ?? const [];
  }

  static Future<int> chaptersOpenedFor(String subject) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_chapters) ?? const [];
    return list.where((c) => c.startsWith('$subject|')).length;
  }
}
