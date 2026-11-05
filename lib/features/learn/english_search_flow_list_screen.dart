// English search-flow list (separate English flow).
// Three modes, all chapter-free: one set's rows (setId),
// or set + bank rows filtered by section and/or lesson
// (client-side scan). Rows render with the shared guide
// list; tapping a row opens the guide answer with returnTo
// back here.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/english_set_scan.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/english_search_flow_strings.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../../l10n/pages/search_flow_strings.dart';
import 'search_flow_answer_nav.dart';
import 'search_flow_types.dart';
import 'widgets/search_flow_guide_list.dart';

class EnglishSearchFlowListScreen extends StatefulWidget {
  const EnglishSearchFlowListScreen({
    super.key,
    required this.schoolClass,
    this.setId,
    this.section,
    this.lesson,
  });
  final int schoolClass;
  final String? setId;
  final String? section;
  final String? lesson;

  @override
  State<EnglishSearchFlowListScreen> createState() =>
      _EnglishSearchFlowListScreenState();
}

class _EnglishSearchFlowListScreenState
    extends State<EnglishSearchFlowListScreen> {
  final _scan = EnglishSetScanService();
  bool _loading = true;
  bool _unavailable = false;
  bool _isPremium = false;
  List<GuideBankQuestion> _rows = [];
  bool _hasMore = false;
  int _offset = 0;
  EnglishScanCursor? _cursor;

  bool get _setMode => widget.setId != null;

  String _listUrl() {
    final q = StringBuffer(
        '/english-search-flow-list?class=${widget.schoolClass}');
    if (widget.setId != null) q.write('&setId=${widget.setId}');
    if (widget.section != null) q.write('&section=${widget.section}');
    if (widget.lesson != null) {
      q.write('&lesson=${Uri.encodeComponent(widget.lesson!)}');
    }
    return q.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    // A throw here used to leave _loading true forever (endless
    // spinner): every failure must land in the unavailable state
    // instead, with a retry button below.
    try {
      final premium =
          await billingService.isPremium().catchError((_) => false);
      final page = _setMode
          ? await _scan.fetchSetPage(
              schoolClass: widget.schoolClass, setId: widget.setId!)
          : await _scan.fetchFilteredPage(
              schoolClass: widget.schoolClass,
              section: widget.section,
              lesson: widget.lesson);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isPremium = premium;
        _unavailable = page.unavailable;
        _rows = page.rows;
        _hasMore = page.hasMore;
        _offset = page.rows.length;
        _cursor = page.nextCursor;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _unavailable = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _unavailable = false;
      _rows = [];
      _hasMore = false;
      _offset = 0;
      _cursor = null;
    });
    _loadFirst();
  }

  Future<void> _loadMore() async {
    try {
      final page = _setMode
          ? await _scan.fetchSetPage(
              schoolClass: widget.schoolClass,
              setId: widget.setId!,
              offset: _offset)
          : await _scan.fetchFilteredPage(
              schoolClass: widget.schoolClass,
              section: widget.section,
              lesson: widget.lesson,
              resume: _cursor);
      if (!mounted) return;
      setState(() {
        _rows = [..._rows, ...page.rows];
        _hasMore = page.hasMore;
        _offset += page.rows.length;
        _cursor = page.nextCursor;
      });
    } catch (_) {
      // Keep the rows already shown; stop pagination instead of
      // leaving "load more" retrying a failing page forever.
      if (!mounted) return;
      setState(() {
        _hasMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? searchFlowStringsBn : searchFlowStringsEn;
        final gs = bn ? guideBankStringsBn : guideBankStringsEn;
        final es = bn
            ? englishSearchFlowStringsBn
            : englishSearchFlowStringsEn;
        final title = widget.setId ??
            widget.section ??
            widget.lesson ??
            es['title']!;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/search-flow?subject=english&class=${widget.schoolClass}')),
            title: Text(title),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _unavailable
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(es['unavailable']!),
                          TextButton(
                            onPressed: _retry,
                            child: Text(es['setsRetry']!),
                          ),
                        ],
                      ),
                    )
                  : _rows.isEmpty
                      ? Center(child: Text(es['emptyList']!))
                      : Column(
                          children: [
                            Expanded(
                              child: SearchFlowGuideListView(
                                rows: _rows,
                                total: null,
                                hasMore: _hasMore,
                                isPremium: _isPremium,
                                subjectId: 'english',
                                chapterNumber: 0,
                                type: SearchFlowType.mcq,
                                bn: bn,
                                s: s,
                                gs: gs,
                                onOpen: (index, q) =>
                                    openSearchFlowGuideAnswer(
                                  context,
                                  isPremium: _isPremium,
                                  index: index,
                                  q: q,
                                  subjectId: 'english',
                                  chapterNumber: 0,
                                  schoolClass: widget.schoolClass,
                                  returnTo: _listUrl(),
                                ),
                                onLoadMore: _loadMore,
                              ),
                            ),
                          ],
                        ),
        );
      },
    );
  }
}
