// Route: /books — Book Library, Class 6 ONLY.
// Books come from BooksService.classBooksAsync: the real
// books_public rows when Supabase is configured (one card per book
// row in the UI language — Bangla has 3 books, English 2, the rest
// 1 each), the DEMO 6-subject list otherwise. Locked cards (a book
// row with supplied=false, or a subject with no supplied book at
// all) show Locked and open NO lesson/viewer. The dropped
// minority-language book is not listed at all. Continue opens the
// last opened book, or the first book when none has been opened
// yet. Books open at page 1 (the old page-45 default was the DEMO
// lesson page, not a book start).
// NOTE: no bKash here — deliberately absent, Play Billing only.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/books_service.dart';
import 'package:yes_sir_ai/features/books/widgets/book_widgets.dart';
import 'package:yes_sir_ai/features/learn/learn_store.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/book_library_strings.dart';
import '../../theme/themed_scaffold.dart';

class BookLibraryScreen extends StatelessWidget {
  const BookLibraryScreen({super.key});

  void _open(
    BuildContext context, String subject, String id, String entry) {
    BookSelectionHolder.set(subject, id, 1);
    LearnStore.addRecentBook(entry);
    context.go('/books/viewer');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? bookLibraryStringsBn : bookLibraryStringsEn;
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            title: Text(s['title']!),
          ),
          body: FutureBuilder<List<dynamic>>(
            future: Future.wait([
              booksService.classBooksAsync(6, bn),
              booksService.subjectsAsync(6, bn),
            ]),
            builder: (context, snap) {
              if (!snap.hasData) {
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
              final books = snap.data![0] as List<BookInfo>;
              final subjects = snap.data![1] as List<SubjectInfo>;
              final open = books.where((b) => b.supplied).toList();
              final lockedBooks =
                  books.where((b) => !b.supplied).toList();
              final lockedIds =
                  lockedBooks.map((b) => b.subject).toSet();
              final lockedSubjects = subjects
                  .where((x) => x.locked && !lockedIds.contains(x.id))
                  .toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(s['subtitle']!,
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(s['class6Only']!,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  if (books.isEmpty) Text(s['noBooks']!),
                  ...open.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookCard(
                          title: b.title(bn),
                          meta: bn ? 'ক্লাস ৬ · এনসিটিবি' : 'Class 6 · NCTB',
                          progress: 0,
                          onTap: () => _open(
                            context,
                            b.subject,
                            b.id,
                            '${b.subject}|${b.titleBn}|${b.titleEn}',
                          ),
                        ),
                      )),
                  ...lockedBooks.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookCard(
                          title: b.title(bn),
                          meta: s['lockedSub']!,
                          progress: 0,
                          locked: true,
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(content: Text(s['lockedNoLesson']!)),
                          ),
                        ),
                      )),
                  ...lockedSubjects.map((x) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookCard(
                          title: x.name(bn),
                          meta: s['lockedSub']!,
                          progress: 0,
                          locked: true,
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(content: Text(s['lockedNoLesson']!)),
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                  FutureBuilder<LearnSummary>(
                    future: LearnStore.summary(),
                    builder: (context, snap2) {
                      final recent = snap2.data?.recentBooks ?? const [];
                      return ElevatedButton(
                        onPressed: () {
                          if (recent.isNotEmpty) {
                            final parts = recent.first.split('|');
                            if (parts.isNotEmpty) {
                              _open(
                                context,
                                parts[0],
                                'class6-${parts[0]}-${bn ? 'bn' : 'en'}',
                                recent.first,
                              );
                              return;
                            }
                          }
                          if (open.isNotEmpty) {
                            final b = open.first;
                            _open(
                              context,
                              b.subject,
                              b.id,
                              '${b.subject}|${b.titleBn}|${b.titleEn}',
                            );
                          }
                        },
                        child: Text(
                          recent.isEmpty
                              ? s['continueNoBook']!
                              : s['continue']!,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
