// Home subject grid, split out to keep home_screen.dart under the
// 250-line file cap. Batch 2, item 3: subjects come from the same
// Supabase books source as Subjects/Books (booksService.
// subjectsAsync: subjects table + books_public + chapter counts when
// configured, DEMO fallback list otherwise) — ALL unlocked subjects,
// no mock list and no take(4) cut (ICT/BGS were cut before).
// The class is the PROFILE class (single source of truth, the same
// one Settings reads), never a hardcoded 6: the old grid always
// showed Class 6 subjects even when Settings said no class had
// been chosen yet. Null class shows an honest choose-class state
// instead of pretending Class 6.
//
// Cache-once grid: on mount it shows the PERSISTED last-good
// list instantly (no spinner, no server fetch). A fresh fetch
// happens only on first-ever load, on profile-class change, or
// on an explicit refresh (Subjects screen) — never on every
// mount, never periodically. A failed refresh keeps the old list
// silently and must never produce the empty state; the honest
// load-failed state (with retry) renders only when no saved list
// exists and the fetch fails. (Companion rules: only complete
// enrichments are persisted; DEMO fallbacks never are.)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/backend_models.dart';
import '../../../core/services/books_service.dart';
import '../../../l10n/pages/home_strings.dart';
import '../../../theme/staggered_list.dart';
import '../home_design.dart';
import 'home_subject_tile.dart';

/// Home-visible subjects: every unlocked subject, plus locked
/// subjects that have guide content. Locked subjects with neither
/// a book nor a guide stay hidden (honest empty, not a dead tile).
/// Guide sourcing (all classes): a subject whose textbook is locked
/// BUT which has guide-bank chapters (SubjectInfo.hasGuide, set by
/// subjectsAsync) is ALSO shown, and its tile goes to the new
/// search flow instead of the textbook chapters — so Class 9/10
/// Math is no longer an empty home.
List<SubjectInfo> visibleHomeSubjects(List<SubjectInfo> all) =>
    all.where((x) => !x.locked || x.hasGuide).toList();

/// Tile subtitle: guide-only subjects show their GUIDE count
/// (chapters, else model-test sets, else a generic guide note —
/// labelled as guide, never passed off as textbook chapters);
/// textbook subjects show their textbook count.
String _tileLabel(SubjectInfo s, bool bn) {
  if (s.locked && s.hasGuide) {
    if (s.guideSetCount > 0) {
      final suffix = bn
          ? homeStringsBn['guideSets']!
          : homeStringsEn['guideSets']!;
      return bn ? '${s.guideSetCount}$suffix' : '${s.guideSetCount} $suffix';
    }
    if (s.guideChapterCount > 0) {
      return bn
          ? '${s.guideChapterCount}টি গাইড অধ্যায়'
          : '${s.guideChapterCount} guide chapters';
    }
    return bn
        ? homeStringsBn['guideAvailable']!
        : homeStringsEn['guideAvailable']!;
  }
  return bn ? '${s.chapterCount}টি অধ্যায়' : '${s.chapterCount} chapters';
}

/// True when two subject lists would render identical tiles.
bool _sameSubjects(List<SubjectInfo> a, List<SubjectInfo> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i], y = b[i];
    if (x.id != y.id ||
        x.nameBn != y.nameBn ||
        x.locked != y.locked ||
        x.hasGuide != y.hasGuide ||
        x.chapterCount != y.chapterCount ||
        x.guideChapterCount != y.guideChapterCount ||
        x.guideSetCount != y.guideSetCount) {
      return false;
    }
  }
  return true;
}

class HomeSubjectGrid extends StatefulWidget {
  const HomeSubjectGrid({
    super.key,
    required this.bn,
    required this.schoolClass,
    required this.loadingLabel,
    required this.noSubjectsLabel,
    required this.chooseClassTitle,
    required this.chooseClassBody,
    required this.chooseClassAction,
    this.service,
  });
  final bool bn;
  final int? schoolClass;
  final String loadingLabel;
  final String noSubjectsLabel;
  final String chooseClassTitle;
  final String chooseClassBody;
  final String chooseClassAction;

  /// Overridable for tests; production uses the global service.
  final BooksService? service;

  @override
  State<HomeSubjectGrid> createState() => _HomeSubjectGridState();
}

class _HomeSubjectGridState extends State<HomeSubjectGrid> {
  List<SubjectInfo>? _subjects;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(HomeSubjectGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schoolClass != widget.schoolClass ||
        oldWidget.bn != widget.bn) {
      _subjects = null;
      _loadFailed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final cls = widget.schoolClass;
    if (cls == null) return;
    final svc = widget.service ?? booksService;
    // Cache-once: a saved list shows instantly and no server
    // fetch runs at all on this mount.
    final cached = await svc.loadPersistedSubjects(cls, widget.bn);
    if (!mounted) return;
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _subjects = cached;
        _loadFailed = false;
      });
      return;
    }
    // First-ever load (or a class with no saved list): fetch.
    // A failure keeps _subjects null so the honest load-failed
    // state renders — never the DEMO fallback disguised as
    // "no subjects".
    final result = await svc.fetchSubjectsFresh(cls, widget.bn);
    if (!mounted) return;
    if (result.kind == SubjectsFetchKind.failed) {
      if (_subjects == null) setState(() => _loadFailed = true);
      return;
    }
    if (_subjects == null || !_sameSubjects(_subjects!, result.subjects)) {
      setState(() {
        _subjects = result.subjects;
        _loadFailed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.schoolClass;
    if (cls == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.chooseClassTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(widget.chooseClassBody),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go('/settings'),
            child: Text(widget.chooseClassAction),
          ),
        ],
      );
    }
    final subjects = _subjects;
    if (subjects == null) {
      // Load-failed state: no saved list AND the fetch failed.
      // This is a load failure, never "no subjects" — the server
      // never said the class has no subjects.
      if (_loadFailed) {
        final strings = widget.bn ? homeStringsBn : homeStringsEn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings['subjectsLoadFailed']!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: Text(strings['subjectsRetry']!),
            ),
          ],
        );
      }
      return Text(widget.loadingLabel);
    }
    final visible = visibleHomeSubjects(subjects);
    if (visible.isEmpty) return Text(widget.noSubjectsLabel);
    // Batch 2, item 2: the old GridView fixed every tile height
    // via childAspectRatio 1.3, so a 2-3 line Bangla name at
    // headlineMedium pushed the chapter-count line outside the
    // card (Card clips nothing by default). Rows now size to
    // their tallest tile: IntrinsicHeight + stretch, the same
    // pattern that fixed the step-5 medium cards. Names wrap,
    // never truncate, and no text can paint outside a card.
    // UI palette (গ): grid rows stagger in (first 6 only).
    return StaggeredList(
      children: [
        for (var r = 0; r < visible.length; r += 2) ...[
          if (r > 0) const SizedBox(height: HomeDesign.cardGap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: HomeSubjectTile(
                    name: paperSubjectName(visible[r].id, visible[r].name(widget.bn), widget.bn, widget.schoolClass),
                    chaptersLabel: _tileLabel(visible[r], widget.bn),
                    subjectId: visible[r].id,
                  ),
                ),
                const SizedBox(width: HomeDesign.cardGap),
                if (r + 1 < visible.length)
                  Expanded(
                    child: HomeSubjectTile(
                      name: paperSubjectName(visible[r + 1].id, visible[r + 1].name(widget.bn), widget.bn, widget.schoolClass),
                      chaptersLabel: _tileLabel(visible[r + 1], widget.bn),
                      subjectId: visible[r + 1].id,
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
