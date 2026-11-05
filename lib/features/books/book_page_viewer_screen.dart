// Route: /books/viewer — Book Reader.
// Prev/Next/Jump REALLY change the page and the label, in both
// languages (Bangla digits for bn, Latin digits for en — the old
// replaceAll hack is gone). There is NO fixed page total: the books
// table carries no page count, so the old "240 pages for every book"
// claim is gone — pages go up from 1 without a fake ceiling, and
// Jump only requires 1 or more. View Explanation goes to /lesson
// with grounding for that page in DEMO (indexed questions only);
// when Supabase is configured it goes straight to /lesson/no-match
// and says so plainly, because a page cannot be mapped to a
// verified question from the client (book_questions is server-only
// by design) — never an invented question. Bookmark toggles and
// persists. No real PDF rendering yet: the placeholder says exactly
// that (source_link is NULL until PDFs are hosted in Storage).
// NOTE: no bKash here — deliberately absent, Play Billing only.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/services/learn_service.dart';
import 'package:yes_sir_ai/core/services/local_store.dart';
import 'package:yes_sir_ai/core/services/profile_service.dart';
import 'package:yes_sir_ai/core/services/supabase_client.dart';
import 'package:yes_sir_ai/features/learn/learn_store.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';
import 'package:yes_sir_ai/features/learn/widgets/digits.dart';
import 'package:yes_sir_ai/features/learn/widgets/mock_data.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/book_page_viewer_strings.dart';

class BookPageViewerScreen extends StatefulWidget {
  const BookPageViewerScreen({super.key});
  @override
  State<BookPageViewerScreen> createState() => _BookPageViewerScreenState();
}

class _BookPageViewerScreenState extends State<BookPageViewerScreen> {
  late int _page;
  late String _subject;
  bool _bookmarked = false;
  final _jumpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _page = BookSelectionHolder.page;
    _subject = BookSelectionHolder.subject;
    LearnStore.isSaved('book:$_subject|$_page').then((v) {
      if (mounted) setState(() => _bookmarked = v);
    });
  }

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  void _setPage(int p) {
    setState(() {
      _page = p < 1 ? 1 : p;
      BookSelectionHolder.page = _page;
    });
    LearnStore.isSaved('book:$_subject|$_page').then((v) {
      if (mounted) setState(() => _bookmarked = v);
    });
  }

  Future<void> _toggleBookmark(Map<String, String> s) async {
    final id = 'book:$_subject|$_page';
    final nowSaved = await LearnStore.toggleSaved(id);
    if (nowSaved) await LocalStore.saveQuestion(id);
    if (!mounted) return;
    setState(() => _bookmarked = nowSaved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowSaved ? s['bookmarked']! : s['bookmarkRemoved']!),
      ),
    );
  }

  Future<void> _viewExplanation(BuildContext context, bool bn) async {
    // Class stamp: saved profile class when available; null = no
    // class known — downstream resolves from it, never a silent 6.
    final schoolClass = await profileService.loadSchoolClass();
    if (!mounted) return;
    // Configured: no client-verifiable question for this page, so
    // never route through the DEMO index — straight to no-match.
    if (supabaseOrNull != null) {
      LessonSelectionHolder.set(LessonSelection(
        subject: _subject, schoolClass: schoolClass,
        chapter: 1,
        page: _page,
        problem: 1,
        bookId: BookSelectionHolder.bookId,
        queryText: bn ? 'পৃষ্ঠা ${numStr(_page, true)}' : 'Page $_page',
      ));
      context.go('/lesson/no-match');
      return;
    }
    final key = learnService.keyForPage(_subject, _page);
    if (key != null) {
      final p = key.split('|');
      LessonSelectionHolder.set(LessonSelection(
        subject: p[0], schoolClass: schoolClass,
        chapter: int.parse(p[1]),
        page: int.parse(p[2]),
        problem: int.parse(p[3]),
        bookId: BookSelectionHolder.bookId,
      ));
      context.go('/lesson');
      return;
    }
    LessonSelectionHolder.set(LessonSelection(
      subject: _subject, schoolClass: schoolClass,
      chapter: 1,
      page: _page,
      problem: 1,
      bookId: BookSelectionHolder.bookId,
      queryText: bn ? 'পৃষ্ঠা ${numStr(_page, true)}' : 'Page $_page',
    ));
    context.go('/lesson/no-match');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? bookPageViewerStringsBn : bookPageViewerStringsEn;
        final subjectName = subjectNameFor(_subject, bn);
        // Configured: the DEMO index must not answer for real books.
        final grounded = supabaseOrNull != null
            ? null
            : learnService.resolveForPage(_subject, _page);
        final pageLabel = bn
            ? 'পৃষ্ঠা ${numStr(_page, true)}'
            : 'Page $_page';
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/books'),
            ),
            title: Text(s['title']!),
            actions: [
              IconButton(
                icon: Icon(
                  _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                onPressed: () => _toggleBookmark(s),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Text(pageLabel,
                    style: Theme.of(context).textTheme.headlineMedium),
              ]),
              const SizedBox(height: 8),
              Text('$subjectName · ${bn ? 'ক্লাস ৬' : 'Class 6'}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grounded == null
                            ? s['noIndexedQuestion']!
                            : grounded.question,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        grounded == null
                            ? s['pagePlaceholder']!
                            : s['aiReady']!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _viewExplanation(context, bn),
                child: Text(s['viewSolution']!),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _page > 1 ? () => _setPage(_page - 1) : null,
                    child: Text(s['prev']!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setPage(_page + 1),
                    child: Text(s['next']!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _jumpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: s['jumpLabel'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final v = int.tryParse(_jumpController.text.trim());
                    if (v == null || v < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s['invalidPage']!)),
                      );
                      return;
                    }
                    _jumpController.clear();
                    _setPage(v);
                  },
                  child: Text(s['jump']!),
                ),
              ]),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _toggleBookmark(s),
                child: Text(s['bookmark']!),
              ),
            ],
          ),
        );
      },
    );
  }
}
