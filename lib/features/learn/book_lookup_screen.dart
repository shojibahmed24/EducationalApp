// Route: /book-lookup — subject + printed page -> verbatim
// questions on that page (Edge Function Mode C), plus a
// question-text search box (Mode B). Tap a question to see its
// verbatim text + AI explanation (explanation_service, DEMO or
// live labelled). No question bank lives here: against an empty
// book_questions table every lookup honestly reports "no questions
// indexed for this page yet" and asks for the exact page/question
// or a book photo. Subjects come from books_public (Class 6, this
// UI language); a subject with no supplied book is shown locked
// and cannot be looked up. Detail is keyed per question so picking
// another question re-runs the explanation for that question.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/backend_models.dart';
import '../../core/services/book_lookup_service.dart';
import '../../core/services/books_service.dart';
import '../../core/services/explanation_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/book_lookup_strings.dart';
import 'widgets/book_lookup_detail.dart';
import 'widgets/book_lookup_page_list.dart';
import 'widgets/book_lookup_text_search.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class BookLookupScreen extends StatefulWidget {
  const BookLookupScreen({super.key});
  @override
  State<BookLookupScreen> createState() => _BookLookupScreenState();
}

class _Catalog {
  final List<SubjectInfo> subjects;
  final List<BookInfo> books;
  const _Catalog(this.subjects, this.books);
}

class _BookLookupScreenState extends State<BookLookupScreen> {
  final _pageCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  bool _catalogBn = true;
  late Future<_Catalog> _catalog = _load(true);
  String? _subject;
  PageLookup? _pageResult;
  bool _pageBusy = false;
  bool _textBusy = false;
  String _textState = ''; // '' | 'edge-missing' | 'not-found'
  Grounding? _selected;

  static Future<_Catalog> _load(bool bn) async {
    final subjects = await booksService.subjectsAsync(6, bn);
    final books = await booksService.classBooksAsync(6, bn);
    return _Catalog(subjects, books);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  String? _suppliedBookId(_Catalog cat, String subject) {
    for (final b in cat.books) {
      if (b.subject == subject && b.supplied) return b.id;
    }
    return null;
  }

  Future<void> _listPage(_Catalog cat, String subject, bool bn) async {
    final page = int.tryParse(_pageCtrl.text.trim());
    final bookId = _suppliedBookId(cat, subject);
    if (page == null || bookId == null) return;
    setState(() {
      _pageBusy = true;
      _pageResult = null;
      _selected = null;
    });
    final res = await bookLookupService.listByPage(bookId: bookId, page: page);
    if (!mounted) return;
    setState(() {
      _pageBusy = false;
      _pageResult = res;
    });
  }

  Future<void> _searchText(String subject, bool bn) async {
    final text = _textCtrl.text.trim();
    if (text.length < 3) return;
    setState(() {
      _textBusy = true;
      _textState = '';
      _selected = null;
    });
    final g = await explanationService.resolveByText(
      subject: subject,
      questionText: text,
      bangla: bn,
    );
    if (!mounted) return;
    setState(() {
      _textBusy = false;
      if (g.reason == 'edge-missing') {
        _textState = 'edge-missing';
      } else if (!g.found) {
        _textState = 'not-found';
      } else {
        _selected = g;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? bookLookupStringsBn : bookLookupStringsEn;
        if (_catalogBn != bn) {
          _catalogBn = bn;
          _catalog = _load(bn);
        }
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/search'),
            ),
            title: Text(s['title']!),
          ),
          body: FutureBuilder<_Catalog>(
            future: _catalog,
            builder: (context, snap) {
              final cat = snap.data;
              if (cat == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final offered = cat.subjects
                  .where((x) => cat.books.any((b) => b.subject == x.id))
                  .toList();
              String? firstUnlocked() {
                for (final x in offered) {
                  if (!x.locked) return x.id;
                }
                return offered.isEmpty ? null : offered.first.id;
              }

              bool isLocked(String? id) {
                for (final x in offered) {
                  if (x.id == id) return x.locked;
                }
                return true;
              }

              final subject = _subject != null &&
                      offered.any((x) => x.id == _subject)
                  ? _subject!
                  : firstUnlocked();
              final locked = subject == null || isLocked(subject);
              final page = _pageResult;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['subtitle']!,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    Text(s['subjectLabel']!,
                        style: Theme.of(context).textTheme.headlineMedium),
                    DropdownButton<String>(
                      value: subject,
                      isExpanded: true,
                      hint: Text(s['selectSubject']!),
                      items: offered
                          .map((x) => DropdownMenuItem(
                                value: x.id,
                                enabled: !x.locked,
                                child: Text(x.name(bn)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _subject = v;
                        _pageResult = null;
                        _textState = '';
                        _selected = null;
                      }),
                    ),
                    if (locked) ...[
                      const SizedBox(height: 8),
                      Text(s['lockedSubject']!),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pageCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: s['pageLabel']!),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: (subject == null || locked || _pageBusy)
                          ? null
                          : () => _listPage(cat, subject, bn),
                      child: Text(_pageBusy ? s['listing']! : s['listButton']!),
                    ),
                    if (page != null) ...[
                      const SizedBox(height: 12),
                      BookLookupPageList(
                        result: page,
                        s: s,
                        onTap: (q) => setState(
                            () => _selected = q.toGrounding(subject!, 6)),
                      ),
                    ],
                    const Divider(height: 32),
                    BookLookupTextSearch(
                      controller: _textCtrl,
                      s: s,
                      busy: _textBusy,
                      state: _textState,
                      enabled: subject != null &&
                          !locked &&
                          _textCtrl.text.trim().length >= 3,
                      onSearch: () => _searchText(subject!, bn),
                      onChanged: () => setState(() {}),
                    ),
                    if (_selected != null)
                      BookLookupDetail(
                        key: ValueKey(
                          '${_selected!.context!.subject}|${_selected!.context!.chapterNumber}|${_selected!.context!.page}|${_selected!.context!.problem}|${_selected!.context!.questionText}',
                        ),
                        grounding: _selected!,
                        bn: bn,
                        s: s,
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
