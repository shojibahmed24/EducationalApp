// Pieces of SearchStepper, split out to keep search_stepper.dart
// under the 250-line file cap. The ready hint lives here: it is
// built from the CURRENT selection every time, never from a
// hardcoded page/question (the old labels['ready'] string always
// said page 45, question 7, even when the selector showed q.5).
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/services/explanation_service.dart';
import '../../../core/services/learn_service.dart';
import '../../../theme/app_theme.dart';
import 'digits.dart';

/// +/- number row (page / problem) used by the search stepper.
class StepperNumberRow extends StatelessWidget {
  const StepperNumberRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChange,
  });
  final String label;
  final int value;
  final void Function(int) onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => onChange(value - 1),
            ),
            Text('$value',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onChange(value + 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fill a {subject} {chapter} {page} {problem} template from the
/// exact current selection (Bangla digits in Bangla UI).
String formatSelectionText(
  Map<String, String> labels,
  String key,
  String subjectName,
  int chapter,
  int page,
  int problem,
  bool bn,
) {
  return labels[key]!
      .replaceAll('{subject}', subjectName)
      .replaceAll('{chapter}', numStr(chapter, bn))
      .replaceAll('{page}', numStr(page, bn))
      .replaceAll('{problem}', numStr(problem, bn));
}

/// The hint line under the stepper. Locked beats everything.
/// DEMO (unconfigured): the local index decides synchronously —
/// ready (exact selection) or plainly not-indexed, never a guess.
/// Configured: the Edge Function (book_questions, server-side)
/// decides. 'found' -> exact ready text; 'not-indexed' -> exact
/// not-indexed text; Edge missing / chapter-only -> the honest
/// chapter-exists fallback (a question is never claimed verified
/// when the server could not answer). While the Edge check is in
/// flight the hint says "checking".
class SearchReadyHint extends StatefulWidget {
  const SearchReadyHint({
    super.key,
    required this.locked,
    required this.lockedLabel,
    required this.labels,
    required this.bn,
    required this.subject,
    required this.chapter,
    required this.page,
    required this.problem,
    required this.subjectName,
    required this.configured,
    required this.chaptersLoading,
    required this.chaptersUnknown,
    required this.chapterExists,
  });
  final bool locked;
  final String lockedLabel;
  final Map<String, String> labels;
  final bool bn;
  final String subject;
  final int chapter;
  final int page;
  final int problem;
  final String subjectName;
  final bool configured;
  final bool chaptersLoading;
  final bool chaptersUnknown;
  final bool chapterExists;

  @override
  State<SearchReadyHint> createState() => _SearchReadyHintState();
}

class _SearchReadyHintState extends State<SearchReadyHint> {
  String _checkedKey = '';
  String? _edgeReason; // null = check in flight (configured only)
  Timer? _timer;

  String get _key =>
      '${widget.subject}|${widget.chapter}|${widget.page}|${widget.problem}';

  String _exact(String templateKey) => formatSelectionText(
        widget.labels,
        templateKey,
        widget.subjectName,
        widget.chapter,
        widget.page,
        widget.problem,
        widget.bn,
      );

  @override
  void initState() {
    super.initState();
    _maybeCheck();
  }

  @override
  void didUpdateWidget(SearchReadyHint old) {
    super.didUpdateWidget(old);
    if (old.subject != widget.subject ||
        old.chapter != widget.chapter ||
        old.page != widget.page ||
        old.problem != widget.problem ||
        (old.chaptersLoading && !widget.chaptersLoading) ||
        old.configured != widget.configured) {
      _maybeCheck();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _maybeCheck() {
    _timer?.cancel();
    if (!widget.configured ||
        widget.chaptersLoading ||
        widget.chaptersUnknown) {
      return;
    }
    final key = _key;
    if (key == _checkedKey && _edgeReason != null) return;
    setState(() => _edgeReason = null);
    // Debounce stepper taps so rapid +/- presses do not spam the
    // Edge Function; a stale result is dropped by the key check.
    _timer = Timer(const Duration(milliseconds: 300), () async {
      final reason = (await explanationService.resolve(
        subject: widget.subject,
        chapter: widget.chapter,
        page: widget.page,
        problem: widget.problem,
        bangla: widget.bn,
      ))
          .reason;
      if (!mounted || _key != key) return;
      setState(() {
        _checkedKey = key;
        _edgeReason = reason;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locked) {
      return Text(widget.lockedLabel,
          style: const TextStyle(color: AppTheme.error));
    }
    if (!widget.configured) {
      final found = learnService
          .resolve(
            subject: widget.subject,
            chapter: widget.chapter,
            page: widget.page,
            problem: widget.problem,
          )
          .found;
      return Text(
        found ? _exact('readyTemplate') : _exact('notIndexedTemplate'),
        style: found ? const TextStyle(color: AppTheme.success) : null,
      );
    }
    if (widget.chaptersLoading) {
      return Text(widget.labels['loadingChapters']!);
    }
    if (widget.chaptersUnknown) {
      return Text(widget.labels['chaptersLoadFailed']!);
    }
    final reason = _edgeReason;
    if (reason == 'found') {
      return Text(_exact('readyTemplate'),
          style: const TextStyle(color: AppTheme.success));
    }
    if (reason == 'not-indexed') {
      return Text(_exact('notIndexedTemplate'));
    }
    if (reason == null) return Text(widget.labels['checking']!);
    // 'chapter-only' / 'edge-missing': server could not verify the
    // question, so only the chapter fact is reported, honestly.
    return Text(widget.chapterExists
        ? widget.labels['chapterInBook']!
        : widget.labels['chapterNotInBook']!);
  }
}
