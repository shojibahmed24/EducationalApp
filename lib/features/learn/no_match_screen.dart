// Route: /lesson/no-match — Stitch no_match_found.
// Rule: never guess. The user can (1) type the exact question in
// the text chat, or (2) save a note about the book photo. Photo
// UPLOAD itself needs real storage, which is not wired yet, so the
// screen says that plainly and never claims an upload succeeded —
// the note is persisted locally for later use.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/no_match_strings.dart';
import 'learn_store.dart';
import 'lesson_selection.dart';
import 'widgets/digits.dart';
import 'widgets/mock_data.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class NoMatchScreen extends StatefulWidget {
  const NoMatchScreen({super.key});
  @override
  State<NoMatchScreen> createState() => _NoMatchScreenState();
}

class _NoMatchScreenState extends State<NoMatchScreen> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// No upload happens here: the note is only saved locally, and
  /// the snackbar says exactly that.
  Future<void> _saveNote(Map<String, String> s) async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s['photoNotAvailable']!)),
      );
      return;
    }
    await LearnStore.addPhotoNote(
      '${LessonSelectionHolder.current.key} :: $note',
    );
    if (!mounted) return;
    _noteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s['photoNoteSaved']!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? noMatchStringsBn : noMatchStringsEn;
        final sel = LessonSelectionHolder.current;
        final subjectName = subjectNameFor(sel.subject, bn);
        final query = sel.queryText.isNotEmpty
            ? sel.queryText
            : '$subjectName · '
                '${bn ? 'অধ্যায়' : 'Chapter'} ${numStr(sel.chapter, bn)} · '
                '${bn ? 'পৃষ্ঠা' : 'Page'} ${numStr(sel.page, bn)} · '
                '${bn ? 'প্রশ্ন' : 'Question'} ${numStr(sel.problem, bn)}';
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/search'),
            ),
            title: Text(s['title']!),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.help_outline, size: 48),
                const SizedBox(height: 12),
                Text(s['title']!,
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(s['body']!,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                Text(s['searchLabel']!,
                    style: Theme.of(context).textTheme.bodySmall),
                Card(child: ListTile(title: Text(query))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/lesson/chat'),
                  child: Text(s['typeExact']!),
                ),
                const SizedBox(height: 12),
                Text(s['photoNotAvailable']!,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: s['photoNoteLabel'],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _saveNote(s),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(s['sendPhoto']!),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => _saveNote(s),
                  child: Text(s['saveNote']!),
                ),
                const SizedBox(height: 8),
                Text(s['photoHint']!,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/search'),
                  child: Text(s['searchAgain']!),
                ),
                const SizedBox(height: 16),
                Text(s['tips']!,
                    style: Theme.of(context).textTheme.headlineMedium),
                Text('• ${s['tip1']!}'),
                Text('• ${s['tip2']!}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
