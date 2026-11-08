// Route: /chapter-questions/:subjectId/:chapter — the NCTB
// textbook question list for one chapter. Data is the Edge
// listByChapter payload ONLY (see textbook_chapter_service): no
// answer, hint, key, chunk or solution ever appears in this list.
// Class: saved class via loadSchoolClass ?? 6 (direct route) or
// the holder value set by Search (see ChapterListHolder); a
// visible class selector (6/7, plus the current class when it is
// another value) reloads the list. Rows are grouped by printed
// page ascending, problem ascending, unnumbered last; first 20
// rows, +20 per "আরো দেখুন" tap. Any filter change resets to 20.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/books_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/textbook_chapter_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/chapter_questions_strings.dart';
import 'lesson_selection.dart';
import 'widgets/chapter_questions_parts.dart';
import 'widgets/digits.dart';
import 'widgets/guide_list_loading_shimmer.dart';
import 'widgets/mock_data.dart';
import 'widgets/textbook_filter.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class ChapterQuestionsScreen extends StatefulWidget {
  const ChapterQuestionsScreen({
    super.key,
    required this.subjectId,
    required this.chapterNumber,
    this.schoolClass,
    this.bannerPage,
    this.service,
  });
  final String subjectId;
  final int chapterNumber;
  final int? schoolClass;
  final int? bannerPage;
  final TextbookChapterService? service;

  @override
  State<ChapterQuestionsScreen> createState() =>
      _ChapterQuestionsScreenState();
}

class _ChapterQuestionsScreenState extends State<ChapterQuestionsScreen> {
  int _schoolClass = 6;
  bool _loading = true;
  bool _unavailable = false;
  List<TextbookChapterQuestion> _all = [];
  String _query = '';
  String _pageText = '';
  String _type = 'all';
  int _visible = 20;
  int _filterEpoch = 0;
  String _chapterTitle = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<int> _savedClass() async {
    try {
      return await profileService.loadSchoolClass() ?? 6;
    } catch (_) {
      return 6;
    }
  }

  Future<void> _load({int? schoolClass}) async {
    if (!_loading) setState(() => _loading = true);
    final cls = schoolClass ?? widget.schoolClass ?? await _savedClass();
    final bn = languageNotifier.value.languageCode == 'bn';
    final svc = widget.service ?? textbookChapterService;
    final rows = await svc.fetchChapter(
        widget.subjectId, cls, widget.chapterNumber, bn);
    String title = '';
    try {
      final chapters = await booksService.chaptersForSubjectAsync(
          cls, widget.subjectId, bn);
      final match = chapters?.where((c) => c.number == widget.chapterNumber);
      if (match != null && match.isNotEmpty) title = match.first.title(bn);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _schoolClass = cls;
      _loading = false;
      _unavailable = rows == null;
      _all = rows ?? [];
      _chapterTitle = title;
    });
  }

  List<TextbookChapterQuestion> get _filtered =>
      filterTextbookQuestions(
        all: _all,
        type: _type,
        query: _query,
        page: int.tryParse(_pageText.trim()),
      );

  void _resetFilters() => setState(() {
        _query = '';
        _pageText = '';
        _type = 'all';
        _visible = 20;
        _filterEpoch++;
      });

  void _onFilterChanged() => setState(() => _visible = 20);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? chapterQuestionsStringsBn : chapterQuestionsStringsEn;
        final title = _chapterTitle.isNotEmpty
            ? _chapterTitle
            : '${bn ? 'অধ্যায়' : 'Chapter'} ${numStr(widget.chapterNumber, bn)}';
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/search'),
            ),
            title: Text(
                '${subjectNameFor(widget.subjectId, bn)} · $title'),
          ),
          body: _loading
              ? const GuideListLoadingShimmer()
              : _unavailable
                  ? ChapterMessage(
                      title: s['unavailableTitle']!,
                      body: s['unavailableBody']!)
                  : _all.isEmpty
                      ? ChapterMessage(title: s['emptyChapter']!)
                      : _list(context, s, bn, title),
        );
      },
    );
  }

  Widget _list(BuildContext context, Map<String, String> s, bool bn,
      String title) {
    final filtered = _filtered;
    final shown = filtered.take(_visible).toList();
    final rows = buildChapterQuestionRows(
      context: context,
      shown: shown,
      s: s,
      bn: bn,
      onTap: (q) {
        LessonSelectionHolder.set(LessonSelection(
          subject: widget.subjectId,
          chapter: widget.chapterNumber,
          page: q.page,
          problem: q.problem ?? 0,
          questionId: q.id,
          schoolClass: _schoolClass,
        ));
        context.go('/lesson');
      },
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ChapterClassSelector(
          schoolClass: _schoolClass,
          label: s['classLabel']!,
          onChanged: (v) {
            setState(() {
              _query = '';
              _pageText = '';
              _type = 'all';
              _visible = 20;
              _filterEpoch++;
            });
            _load(schoolClass: v);
          },
        ),
        if (widget.bannerPage != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(s['pageNotInVersion']!
                  .replaceAll('{page}', numStr(widget.bannerPage!, bn))),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        Text(s['totalQuestions']!
            .replaceAll('{n}', numStr(_all.length, bn))),
        const SizedBox(height: 12),
        TextbookFilterBar(
          key: ValueKey(_filterEpoch),
          s: s,
          presentTypes: textbookPresentTypes(_all),
          selectedType: _type,
          onTypeChanged: (v) => setState(() {
            _type = v;
            _onFilterChanged();
          }),
          onQueryChanged: (v) => setState(() {
            _query = v;
            _onFilterChanged();
          }),
          onPageChanged: (v) => setState(() {
            _pageText = v;
            _onFilterChanged();
          }),
        ),
        const SizedBox(height: 12),
        Text(s['showing']!
            .replaceAll('{total}', numStr(filtered.length, bn))
            .replaceAll('{shown}', numStr(shown.length, bn))),
        const SizedBox(height: 8),
        if (filtered.isEmpty) ...[
          Text(s['emptyFiltered']!),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _resetFilters,
            child: Text(s['clearFilters']!),
          ),
        ],
        ...rows,
        if (filtered.length > _visible) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _visible += 20),
            child: Text(s['loadMore']!),
          ),
        ],
      ],
    );
  }
}
