// Books + subjects + chapters. Supabase when configured, DEMO
// fallback otherwise. Schema (migrations/002_books.sql):
// books_public VIEW (id, class_id, subject_id, language, title,
// supplied, created_at) is the only book source clients query —
// the books table holds server-only source_link with no client
// RLS policy. subjects (id, name_bn, name_en); chapters (id,
// book_id, number, title_bn, title_en). book_questions is NEVER
// queried from the app (no client read policy; server / Edge
// only) — question resolution lives in LearnService as a DB
// chapter check + no-match gate, not a question lookup (C2).
// Async methods fall back to DEMO lists on failure, never crash;
// a query that SUCCEEDS with zero rows is returned as-is.
// Locked = no supplied book. The dropped minority-language
// book is not listed anywhere.
import '../models/backend_models.dart';
import 'books_fallback.dart';
import 'guide_subject_flags.dart';
import 'subjects_cache.dart';
import 'supabase_client.dart';

class BooksService {
  final _booksCache = TtlCache<List<BookInfo>>();
  final _subjectsCache = TtlCache<List<SubjectInfo>>();
  final _chaptersCache = TtlCache<List<ChapterInfo>>();
  // DEMO fallbacks live in books_fallback.dart; the async methods
  // below are the real Supabase reads.
  List<BookInfo> classBooks(int schoolClass, bool bangla) =>
      fallbackClassBooks(schoolClass, bangla);

  List<BookInfo> lockedBooks(bool bangla) => fallbackLockedBooks(bangla);

  List<String> chaptersFor(String subject) => fallbackChapters();

  List<SubjectInfo> _fallbackSubjects(int schoolClass) =>
      fallbackSubjectsForClass(schoolClass);

  List<Map<String, dynamic>> _rows(dynamic res) {
    if (res is List) return res.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  void _sortSubjects(List<SubjectInfo> list) {
    list.sort((a, b) {
      final ia = coreSubjectOrder.indexOf(a.id);
      final ib = coreSubjectOrder.indexOf(b.id);
      if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
      if (ia >= 0) return -1;
      if (ib >= 0) return 1;
      return a.id.compareTo(b.id);
    });
  }

  /// Drops one cached subjects entry, so the next call
  /// revalidates against the server (manual refresh).
  void invalidateSubjectsCache(int schoolClass, bool bangla) {
    _subjectsCache.remove('$schoolClass:$bangla');
  }

  /// The view has one title column: titleBn == titleEn == the row's title.
  Future<List<BookInfo>> classBooksAsync(int schoolClass, bool bangla) async {
    final client = supabaseOrNull;
    if (client == null) return classBooks(schoolClass, bangla);
    final key = '$schoolClass:$bangla';
    final hit = _booksCache.get(key);
    if (hit != null) return hit;
    try {
      final res = await client
          .from('books_public')
          .select('id, class_id, subject_id, language, title, supplied')
          .eq('class_id', schoolClass)
          .eq('language', bangla ? 'bn' : 'en')
          .order('subject_id')
          .order('title');
      final out = _rows(res)
          .map(
            (r) => BookInfo(
              id: '${r['id']}',
              titleBn: '${r['title']}',
              titleEn: '${r['title']}',
              subject: '${r['subject_id']}',
              schoolClass: schoolClass,
              supplied: r['supplied'] == true,
            ),
          )
          .toList();
      _booksCache.set(key, out);
      return out;
    } catch (_) {
      return classBooks(schoolClass, bangla);
    }
  }

  /// All subjects + locked state + real chapter counts for one
  /// class + UI language. LOCKED subjects are enriched with guide
  /// content (withGuideFlags): chapters, else sets, else bank
  /// rows. Complete enrichments are cached (5-min TTL) and
  /// persisted as last-good; INCOMPLETE ones are served but
  /// NEVER cached or persisted.
  Future<List<SubjectInfo>> subjectsAsync(int schoolClass, bool bangla) async {
    if (supabaseOrNull == null) return _fallbackSubjects(schoolClass);
    final key = '$schoolClass:$bangla';
    final hit = _subjectsCache.get(key);
    if (hit != null) return hit;
    return (await _fetchSubjects(schoolClass, bangla)).subjects;
  }

  /// Fresh fetch reporting how it resolved (server / demo /
  /// failed), never silently substituting DEMO for a failure.
  /// Bypasses the memory cache; complete success refreshes both.
  /// Each server query is capped at 10s, so a stall becomes a failure with retry UI, never loading forever.
  Future<SubjectsFetchResult> fetchSubjectsFresh(
    int schoolClass,
    bool bangla,
  ) => _fetchSubjects(schoolClass, bangla);

  /// Last-good list across restarts. Null = no usable cache.
  Future<List<SubjectInfo>?> loadPersistedSubjects(
    int schoolClass,
    bool bangla,
  ) => loadPersistedSubjectsList(subjectsLastGoodKey(schoolClass, bangla));

  Future<SubjectsFetchResult> _fetchSubjects(
    int schoolClass,
    bool bangla,
  ) async {
    final client = supabaseOrNull;
    if (client == null) {
      return SubjectsFetchResult(
        subjects: _fallbackSubjects(schoolClass),
        kind: SubjectsFetchKind.demo,
      );
    }
    final key = '$schoolClass:$bangla';
    try {
      final lang = bangla ? 'bn' : 'en';
      final subjRes = await client
          .from('subjects')
          .select('id, name_bn, name_en').timeout(const Duration(seconds: 10));
      final bookRes = await client
          .from('books_public')
          .select('id, subject_id, title, supplied')
          .eq('class_id', schoolClass)
          .eq('language', lang).timeout(const Duration(seconds: 10));
      final books = _rows(bookRes);
      final bookSubject = <String, String>{};
      final suppliedSubjects = <String>{};
      for (final b in books) {
        bookSubject['${b['id']}'] = '${b['subject_id']}';
        if (b['supplied'] == true) suppliedSubjects.add('${b['subject_id']}');
      }
      final counts = <String, int>{};
      if (books.isNotEmpty) {
        final chapRes = await client
            .from('chapters')
            .select('book_id')
            .inFilter('book_id', books.map((b) => '${b['id']}').toList()).timeout(const Duration(seconds: 10));
        for (final c in _rows(chapRes)) {
          final s = bookSubject['${c['book_id']}'];
          if (s != null) counts[s] = (counts[s] ?? 0) + 1;
        }
      }
      final out = _rows(subjRes).map((r) {
        final id = '${r['id']}';
        return SubjectInfo(
          id: id,
          nameBn: '${r['name_bn']}',
          nameEn: '${r['name_en']}',
          locked: !suppliedSubjects.contains(id),
          chapterCount: counts[id] ?? 0,
        );
      }).toList();
      _sortSubjects(out);
      final enriched = await withGuideFlags(out, schoolClass);
      if (enriched.complete) {
        _subjectsCache.set(key, enriched.subjects);
        await persistSubjectsList(key, enriched.subjects);
      }
      return SubjectsFetchResult(
        subjects: enriched.subjects,
        kind: SubjectsFetchKind.server,
      );
    } catch (_) {
      return SubjectsFetchResult(
        subjects: _fallbackSubjects(schoolClass),
        kind: SubjectsFetchKind.failed,
      );
    }
  }

  /// Chapters of one subject's book(s), ordered by book then
  /// number. Null when unconfigured / on failure (DEMO fallback
  /// by caller); empty when the subject has no book / chapters.
  Future<List<ChapterInfo>?> chaptersForSubjectAsync(
    int schoolClass,
    String subject,
    bool bangla,
  ) async {
    final client = supabaseOrNull;
    if (client == null) return null;
    final key = '$schoolClass:$subject:$bangla';
    final hit = _chaptersCache.get(key);
    if (hit != null) return hit;
    try {
      final lang = bangla ? 'bn' : 'en';
      final bookRes = await client
          .from('books_public')
          .select('id, subject_id, title, supplied')
          .eq('class_id', schoolClass)
          .eq('subject_id', subject)
          .eq('language', lang)
          .order('title');
      final books = _rows(bookRes);
      if (books.isEmpty) {
        _chaptersCache.set(key, const []);
        return const [];
      }
      final titles = {for (final b in books) '${b['id']}': '${b['title']}'};
      final bookOrder = books.map((b) => '${b['id']}').toList();
      final chapRes = await client
          .from('chapters')
          .select('id, book_id, number, title_bn, title_en')
          .inFilter('book_id', bookOrder)
          .order('number');
      final chapters = _rows(chapRes)
          .map(
            (r) => ChapterInfo(
              id: '${r['id']}',
              bookId: '${r['book_id']}',
              bookTitle: titles['${r['book_id']}'] ?? '',
              number: (r['number'] as num?)?.toInt() ?? 0,
              titleBn: '${r['title_bn']}',
              titleEn: '${r['title_en']}',
            ),
          )
          .toList();
      chapters.sort((a, b) {
        final ia = bookOrder.indexOf(a.bookId);
        final ib = bookOrder.indexOf(b.bookId);
        if (ia != ib) return ia.compareTo(ib);
        return a.number.compareTo(b.number);
      });
      _chaptersCache.set(key, chapters);
      return chapters;
    } catch (_) {
      return null;
    }
  }
}

final booksService = BooksService();
