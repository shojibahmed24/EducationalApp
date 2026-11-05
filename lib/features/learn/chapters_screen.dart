// Route: /home/subjects/:subjectId/chapters. Header uses the REAL
// subjectId from the route. Chapter rows come from
// BooksService.chaptersForSubjectAsync when Supabase is
// configured (real titles/numbers, grouped per book — Bangla has
// several books per subject). DEMO fallback ONLY when the backend
// is genuinely unconfigured, with a clear DEMO label; a failed
// fetch shows error + retry, never silent demo chapters. A subject
// with no book/chapters shows an honest empty state. Chapter state
// is real (opened in LearnStore vs remaining). Locked subjects are
// never linked here; a deep link to one shows the empty state.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/backend_models.dart';
import '../../core/services/app_config.dart';
import '../../core/services/books_service.dart';
import '../../core/services/resolve_school_class.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/chapters_strings.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../../l10n/pages/home_strings.dart';
import '../home/widgets/home_bottom_nav.dart';
import 'learn_store.dart';
import 'widgets/chapter_card.dart';
import 'widgets/digits.dart';
import 'widgets/guide_toggle.dart';
import 'widgets/mock_data.dart';
import '../../theme/themed_scaffold.dart';

class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key, this.subjectId = 'math'});
  final String subjectId;

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() async {
    final schoolClass = await resolveSchoolClass(); // Saved profile class.
    return Future.wait([
      booksService.chaptersForSubjectAsync(schoolClass, widget.subjectId, languageNotifier.value.languageCode == 'bn'),
      LearnStore.chaptersList(),
    ]);
  }

  List<MockChapter> _demoChapters() {
    if (widget.subjectId == 'math') return mockChapters;
    return List.generate(
      5,
      (i) => MockChapter(
        'অধ্যায় ${i + 1}',
        'Chapter ${i + 1}',
        '',
        'remaining',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? chaptersStringsBn : chaptersStringsEn;
        final gs = bn ? guideBankStringsBn : guideBankStringsEn;
        final nav = bn ? homeStringsBn : homeStringsEn;
        final subjectName = subjectNameFor(widget.subjectId, bn);
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home/subjects'),
            ),
            title: Text('$subjectName · ${s['subtitle']!}'),
          ),
          body: FutureBuilder<List<dynamic>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                if (snap.hasError) return _error(s);
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(s['loading']!),
                    ],
                  ),
                );
              }
              final dbChapters = snap.data![0] as List<ChapterInfo>?;
              final opened = snap.data![1] as List<String>;
              final openedHere = opened
                  .where((c) => c.startsWith('${widget.subjectId}|'))
                  .length;
              // Configured backend + null fetch = failure, never
              // demo: error state + retry. Unconfigured (null
              // here) = demo list WITH the demo label below.
              if (AppConfig.supabaseConfigured && dbChapters == null) {
                return _error(s);
              }
              // Configured empty -> honest empty state, no rows.
              // Configured non-empty -> rows grouped by book.
              final groups = <String, List<ChapterInfo>>{};
              if (dbChapters != null) {
                for (final c in dbChapters) {
                  groups.putIfAbsent(c.bookId, () => []).add(c);
                }
              }
              final demo = dbChapters == null ? _demoChapters() : null;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GuideToggle(
                    value: 'textbook',
                    onChanged: (v) {
                      // Step 7: old /guide-chapters deleted;
                      // the toggle now opens the new search
                      // flow for this subject (source
                      // selector on that screen picks guide).
                      if (v == 'guide') {
                        context.go(
                          '/search-flow?subject=${widget.subjectId}',
                        );
                      }
                    },
                    s: gs,
                  ),
                  const SizedBox(height: 16),
                  if (demo != null) ...[
                    Text(s['demoLabel']!,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                  ],
                  Text(s['subtitle']!),
                  const SizedBox(height: 8),
                  Text(
                    '${numStr(openedHere, bn)} ${s['chaptersOpened']!}',
                  ),
                  Text(s['tapChapterHint']!,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Text(s['all']!,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  if (dbChapters != null && dbChapters.isEmpty)
                    Text(s['noChapters']!),
                  if (demo != null)
                    ...demo.asMap().entries.map((e) {
                      final n = e.key + 1;
                      final c = e.value;
                      final isOpened =
                          opened.contains('${widget.subjectId}|$n');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChapterCard(
                          chapter: MockChapter(
                            c.bn,
                            c.en,
                            c.pages,
                            isOpened ? 'inProgress' : 'remaining',
                          ),
                          bn: bn,
                          statusLabel: isOpened
                              ? s['inProgress']!
                              : s['remaining']!,
                          pagesLabel: s['pages']!,
                          subjectId: widget.subjectId,
                          chapterNumber: n,
                        ),
                      );
                    }),
                  for (final entry in groups.entries) ...[
                    if (groups.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(
                          entry.value.first.bookTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ...entry.value.map((c) {
                      final isOpened =
                          opened.contains('${widget.subjectId}|${c.number}');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChapterCard(
                          chapter: MockChapter(
                            c.titleBn,
                            c.titleEn,
                            '',
                            isOpened ? 'inProgress' : 'remaining',
                          ),
                          bn: bn,
                          statusLabel: isOpened
                              ? s['inProgress']!
                              : s['remaining']!,
                          pagesLabel: s['pages']!,
                          subjectId: widget.subjectId,
                          chapterNumber: c.number,
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          ),
          bottomNavigationBar: HomeBottomNav(
            current: 0,
            labels: [
              nav['home']!,
              nav['search']!,
              nav['practice']!,
              nav['progress']!,
              nav['profile']!
            ],
          ),
        );
      },
    );
  }

  Widget _error(Map<String, String> s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s['loadFailed']!),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => setState(() => _future = _load()),
            child: Text(s['retry']!),
          ),
        ],
      ),
    );
  }
}
