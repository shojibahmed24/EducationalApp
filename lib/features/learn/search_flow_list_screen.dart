// Type list screen (Step 5): one type, 20 rows at a time, with
// "আরো দেখুন" for the next 20. NEVER all rows at once, and NO
// "all questions" option exists anywhere in this flow.
// Guide mode: server-filtered paging when the new server echoes
// the filter, client-filtered scan on the old server (see
// guide_flow_list_service). Textbook mode: the chapter list
// (existing listByChapter path) filtered client-side by the
// verified type mapping; rows show NO marks (textbooks print
// none — never invented). questionNumber (textbook jump with
// several same-number rows): the list shows ONLY those rows.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/guide_flow_list_service.dart';
import '../../core/services/model_test_set_service.dart';
import '../../core/services/textbook_chapter_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/chapter_questions_strings.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../../l10n/pages/search_flow_strings.dart';
import 'search_flow_answer_nav.dart';
import 'search_flow_board.dart';
import 'search_flow_chapterless.dart';
import 'search_flow_types.dart';
import 'widgets/search_flow_book_list.dart';
import 'widgets/search_flow_guide_list.dart';
import 'widgets/search_flow_message.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class SearchFlowListScreen extends StatefulWidget {
  const SearchFlowListScreen({
    super.key,
    required this.subjectId,
    required this.schoolClass,
    required this.source,
    required this.chapterNumber,
    required this.type,
    this.lesson,
    this.questionNumber,
    this.section,
    this.setId, this.chapterless = false, this.board = false,
    this.premiumCheck,
    this.listService,
  });
  final String subjectId;
  final int schoolClass;

  /// 'textbook' or 'guide'.
  final String source;
  final int chapterNumber;
  final SearchFlowType type;
  final String? lesson;
  final int? questionNumber;

  /// English guide section filter (ENGLISH_REDO_PLAN §3, Paper-I
  /// only). Null = type-driven list (Math behavior unchanged).
  final String? section;

  /// Phase 1 set scope: one set's rows, chapter-free (setId wins).
  final String? setId;

  /// Chapterless: bank rows, chapter_number NULL. Board (018): flagged board rows only.
  final bool chapterless, board;

  /// Test seams only; production passes null (= live globals).
  final Future<bool> Function()? premiumCheck;
  final GuideFlowListService? listService;

  @override
  State<SearchFlowListScreen> createState() => _SearchFlowListScreenState();
}

class _SearchFlowListScreenState extends State<SearchFlowListScreen> {
  bool _loading = true;
  GuideFlowMode _mode = GuideFlowMode.serverFiltered;
  List<GuideBankQuestion> _guideRows = [];
  int? _guideTotal;
  bool _guideHasMore = false;
  int _scanOffset = 0;
  List<GuideBankQuestion> _allSetRows = [];
  List<TextbookChapterQuestion> _bookRows = [];
  int _visible = 20;
  bool _isPremium = false;

  bool get _guide => widget.source == 'guide';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Safety net only: a throw must never leave the spinner forever.
    try {
      if (_guide) {
        // Billing resolves concurrently; rows never wait for it.
        (widget.premiumCheck ?? billingService.isPremium)().then((v) {
          if (mounted) setState(() => _isPremium = v);
        }, onError: (_) {});
        if (widget.setId != null) {
          // Phase 1 set scope: all rows of one set, client-paged 20 by whole stimulus groups (visibleSetRows).
          final rows = await modelTestSetService.fetchSetRows(widget.subjectId, widget.setId!, schoolClass: widget.schoolClass);
          if (!mounted) return;
          setState(() { _loading = false; _mode = rows == null ? GuideFlowMode.unavailable : GuideFlowMode.serverFiltered; _allSetRows = rows ?? []; _visible = 20; });
        } else if (widget.chapterless || widget.board) {
          // Chapterless or Board (018): same paging shape,
          // different Edge scope; Board lists carry section
          // + type from the route, so they render exactly.
          final page = widget.board ? await fetchBoardPage(subject: widget.subjectId, schoolClass: widget.schoolClass, section: widget.section) : await fetchChapterlessLessonPage(subject: widget.subjectId, schoolClass: widget.schoolClass, lesson: widget.lesson, section: widget.section);
          if (!mounted) return;
          setState(() { _loading = false; _mode = page.mode; _guideRows = page.rows; _guideTotal = page.total; _guideHasMore = page.hasMore; });
        } else {
          final page = await (widget.listService ?? guideFlowListService).fetchPage(
              subject: widget.subjectId, schoolClass: widget.schoolClass,
              chapter: widget.chapterNumber, type: widget.type,
              lesson: widget.lesson, section: widget.section);
          if (!mounted) return;
          setState(() {
            _loading = false;
            _mode = page.mode;
            _guideRows = page.rows;
            _guideTotal = page.total;
            _guideHasMore = page.hasMore;
            _scanOffset = page.nextScanOffset;
          });
        }
      } else {
        final bn = languageNotifier.value.languageCode == 'bn';
        final rows = await textbookChapterService.fetchChapter(
            widget.subjectId, widget.schoolClass, widget.chapterNumber, bn);
        if (!mounted) return;
        final filtered = (rows ?? [])
            .where((r) =>
                searchFlowTextbookMatches(widget.type, r.questionType) &&
                (widget.questionNumber == null ||
                    r.problem == widget.questionNumber))
            .toList();
        setState(() {
          _loading = false;
          _mode = rows == null
              ? GuideFlowMode.unavailable
              : GuideFlowMode.serverFiltered;
          _bookRows = filtered;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _mode = GuideFlowMode.unavailable;
      });
    }
  }

  Future<void> _loadMoreGuide() async {
    if (widget.setId != null) {
      if (mounted) setState(() => _visible += 20);
      return;
    }
    if (widget.chapterless || widget.board) {
      final page = widget.board ? await fetchBoardPage(subject: widget.subjectId, schoolClass: widget.schoolClass, section: widget.section, offset: _guideRows.length) : await fetchChapterlessLessonPage(subject: widget.subjectId, schoolClass: widget.schoolClass, lesson: widget.lesson, section: widget.section, offset: _guideRows.length);
      if (!mounted) return;
      setState(() { _mode = page.mode; _guideRows = [..._guideRows, ...page.rows]; _guideTotal = page.total; _guideHasMore = page.hasMore; });
      return;
    }
    final page = await guideFlowListService.fetchPage(
        subject: widget.subjectId, schoolClass: widget.schoolClass,
        chapter: widget.chapterNumber, type: widget.type,
        lesson: widget.lesson, section: widget.section,
        offset: _guideRows.length, scanOffset: _scanOffset);
    if (!mounted) return;
    setState(() {
      _mode = page.mode;
      _guideRows = [..._guideRows, ...page.rows];
      _guideTotal = page.total;
      _guideHasMore = page.hasMore;
      _scanOffset = page.nextScanOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? searchFlowStringsBn : searchFlowStringsEn;
        final back = '/search-flow?subject=${widget.subjectId}';
        // Answer openings live in answer_nav; returnTo carries all filters.
        final returnTo = searchFlowListUrl(subjectId: widget.subjectId, schoolClass: widget.schoolClass, source: widget.source, chapterNumber: widget.chapterNumber, typeName: widget.type.name, lesson: widget.lesson, questionNumber: widget.questionNumber, section: widget.section, setId: widget.setId, chapterless: widget.chapterless, board: widget.board);
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(back),
            ),
            title: Text(s['listTitle']!),
          ),
          body: _loading
              ? const GuideListLoadingShimmer()
              : _mode == GuideFlowMode.unavailable
                  ? searchFlowMessage(context, s['unavailableTitle']!,
                      s['unavailableBody']!, s, back)
                  : _mode == GuideFlowMode.filterPending
                      ? searchFlowMessage(context, s['filterPendingTitle']!,
                          s['filterPendingBody']!, s, back)
                      : _guide
                          ? (widget.setId != null ? _allSetRows : _guideRows).isEmpty
                              ? searchFlowMessage(context, s[widget.section != null ? 'emptyListSection' : 'emptyList']!, '', s, back)
                              : SearchFlowGuideListView(
                                  rows: widget.setId != null ? visibleSetRows(_allSetRows, _visible) : _guideRows,
                                  total: widget.setId != null ? _allSetRows.length : _guideTotal,
                                  hasMore: widget.setId != null ? visibleSetRows(_allSetRows, _visible).length < _allSetRows.length : _guideHasMore,
                                  isPremium: _isPremium,
                                  subjectId: widget.subjectId,
                                  chapterNumber: widget.chapterNumber,
                                  // Mixed-type lists: creative groups by stimulus, rest singletons.
                                  // Board lists are single-section by route; route type renders them.
                                  type: widget.setId != null || (widget.chapterless && widget.section == null) ? SearchFlowType.creative : widget.type,
                                  bn: bn,
                                  s: s,
                                  gs: bn
                                      ? guideBankStringsBn
                                      : guideBankStringsEn,
                                  onOpen: (i, q) => openSearchFlowGuideAnswer(context, isPremium: _isPremium, index: i, q: q, subjectId: widget.subjectId, chapterNumber: q.chapterNumber ?? widget.chapterNumber, schoolClass: widget.schoolClass, returnTo: returnTo),
                                  onOpenGroup: (fi, parts, st) => openSearchFlowGuideGroupAnswer(context, isPremium: _isPremium, firstIndex: fi, parts: parts, stimulusText: st, subjectId: widget.subjectId, chapterNumber: widget.chapterNumber, schoolClass: widget.schoolClass, returnTo: returnTo),
                                  onLoadMore: _loadMoreGuide,
                                )
                          : _bookRows.isEmpty
                              ? searchFlowMessage(context, s['emptyList']!, '', s, back)
                              : SearchFlowBookListView(
                                  rows: _bookRows,
                                  visible: _visible,
                                  bn: bn,
                                  s: s,
                                  cs: bn
                                      ? chapterQuestionsStringsBn
                                      : chapterQuestionsStringsEn,
                                  onOpen: (q) => openSearchFlowBookAnswer(context, q: q, subjectId: widget.subjectId, chapterNumber: widget.chapterNumber, schoolClass: widget.schoolClass),
                                  onLoadMore: () =>
                                      setState(() => _visible += 20),
                                ),
        );
      },
    );
  }
}
