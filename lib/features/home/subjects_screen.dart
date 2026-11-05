// Route: /home/subjects — SubjectsScreen, Stitch subjects.
// Subjects come from BooksService.subjectsAsync: the real subjects
// table + real DB chapter counts when configured, DEMO fallback
// otherwise. Every unlocked card navigates to that subject's
// chapters; the locked card shows Locked and navigates nowhere (no
// lesson is offered for a subject whose book has not been
// supplied). The overall card uses real counts: supplied books
// (books_public rows) + lessons opened from LearnStore — no
// invented percentage.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/backend_models.dart';
import '../../core/services/books_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/subjects_strings.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../../l10n/pages/home_strings.dart';
import '../../theme/themed_scaffold.dart';
import '../learn/learn_store.dart';
import '../learn/widgets/digits.dart';
import '../learn/widgets/subject_guide_card.dart';
import 'widgets/subject_card.dart';
import 'widgets/home_bottom_nav.dart';

/// Subjects screen with a manual refresh: the cache-once home
/// grid never refetches on mount, so new server subjects appear
/// only through this button (or a class change / first load).
/// Refresh drops the in-memory entry and refetches; a failed
/// refresh leaves the previous list on screen.
class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  Future<List<dynamic>>? _future;
  bool? _futureBn;

  Future<List<dynamic>> _loadFuture(bool bn) => Future.wait([
    LearnStore.summary(),
    LearnStore.chaptersList(),
    booksService.subjectsAsync(6, bn),
    booksService.classBooksAsync(6, bn),
  ]);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? subjectsStringsBn : subjectsStringsEn;
        final gs = bn ? guideBankStringsBn : guideBankStringsEn;
        final nav = bn ? homeStringsBn : homeStringsEn;
        if (_future == null || _futureBn != bn) {
          _future = _loadFuture(bn);
          _futureBn = bn;
        }
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            title: Text(s['title']!),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: nav['refreshSubjects'],
                onPressed: () {
                  booksService.invalidateSubjectsCache(6, bn);
                  setState(() => _future = null);
                },
              ),
            ],
          ),
          body: FutureBuilder<List<dynamic>>(
            future: _future,
            builder: (context, snap) {
              final lessons = snap.data == null
                  ? 0
                  : (snap.data![0] as LearnSummary).lessonsOpened;
              final opened = snap.data == null
                  ? const <String>[]
                  : snap.data![1] as List<String>;
              final subjects = snap.data == null
                  ? const <SubjectInfo>[]
                  : snap.data![2] as List<SubjectInfo>;
              final supplied = snap.data == null
                  ? 0
                  : (snap.data![3] as List<BookInfo>)
                        .where((b) => b.supplied)
                        .length;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    s['subtitle']!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['overall']!,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            '${numStr(supplied, bn)} ${s['booksSupplied']!}',
                          ),
                          Text('${numStr(lessons, bn)} ${s['lessonsOpened']!}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s['allSubjects']!,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  ...subjects.map(
                    (subj) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: SubjectCard(
                            name: subj.name(bn),
                            chapters: subj.chapterCount,
                            done: opened
                                .where((c) => c.startsWith('${subj.id}|'))
                                .length,
                            locked: subj.locked,
                            subjectId: subj.id,
                            chaptersLabel: s['chapters']!,
                            lockedLabel:
                                '${s['locked']!} — ${s['lockedHint']!}',
                          ),
                        ),
                        // Renders nothing for guide-less subjects.
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SubjectGuideCard(
                            subjectId: subj.id,
                            bn: bn,
                            s: gs,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['advice']!,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(s['adviceText']!),
                        ],
                      ),
                    ),
                  ),
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
              nav['profile']!,
            ],
          ),
        );
      },
    );
  }
}
