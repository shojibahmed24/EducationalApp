import 'package:flutter/material.dart';
import '../../../core/models/backend_models.dart';
import '../../../core/services/books_fallback.dart';
import '../../../core/services/books_service.dart';
import '../../../core/services/supabase_client.dart';
import '../lesson_selection.dart';
import 'mock_data.dart';
import 'search_stepper_parts.dart';

/// 4-step search selector: subject -> chapter -> page -> problem.
/// Every control actually changes the selection and reports it via
/// onChanged. Subjects/chapters come from BooksService for
/// [schoolClass] (never a hardcoded class); locked subjects (no
/// supplied book) report a locked selection, so the parent
/// disables the actions. Page/problem default to 1/1, never 45/5.
class SearchStepper extends StatefulWidget {
  const SearchStepper({
    super.key,
    required this.labels,
    required this.bn,
    required this.onChanged,
    required this.lockedLabel,
    this.initial,
    this.schoolClass = 6,
  });
  final Map<String, String> labels;
  final bool bn;
  final void Function(LessonSelection sel, bool locked) onChanged;
  final String lockedLabel;
  final LessonSelection? initial;
  final int schoolClass;

  @override
  State<SearchStepper> createState() => _SearchStepperState();
}

class _SearchStepperState extends State<SearchStepper> {
  late String _subject;
  late int _chapter;
  late int _page;
  late int _problem;
  late List<SubjectInfo> _subjects;
  List<ChapterInfo>? _dbChapters;
  bool _dbUnknown = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _subject = i?.subject ?? 'math';
    _chapter = i?.chapter ?? 3;
    _page = i?.page ?? 1;
    _problem = i?.problem ?? 1;
    _subjects = fallbackSubjects();
    _loadSubjects();
    _loadChapters(_subject);
  }

  @override
  void didUpdateWidget(SearchStepper old) {
    super.didUpdateWidget(old);
    if (old.bn != widget.bn || old.schoolClass != widget.schoolClass) {
      _loadSubjects();
      _loadChapters(_subject);
    }
  }

  Future<void> _loadSubjects() async {
    final list =
        await booksService.subjectsAsync(widget.schoolClass, widget.bn);
    if (!mounted) return;
    final missing = !list.any((s) => s.id == _subject);
    setState(() {
      _subjects = list;
      if (missing) {
        _subject = _subjects.isEmpty ? 'math' : _subjects.first.id;
        _chapter = 1;
      }
    });
    if (missing) _loadChapters(_subject);
  }

  Future<void> _loadChapters(String subject) async {
    setState(() {
      _dbChapters = null;
      _dbUnknown = false;
    });
    final chapters = await booksService.chaptersForSubjectAsync(
        widget.schoolClass, subject, widget.bn);
    if (!mounted) return;
    setState(() {
      _dbChapters = chapters ?? const [];
      _dbUnknown = chapters == null;
      final numbers = _dbChapters!.map((c) => c.number).toSet();
      if (numbers.isNotEmpty && !numbers.contains(_chapter)) {
        _chapter = numbers.first;
        _emit();
      }
    });
  }

  bool get _locked {
    final match = _subjects.where((s) => s.id == _subject);
    if (match.isEmpty) return true;
    return match.first.locked;
  }

  String _subjectName(String id) => subjectNameFor(id, widget.bn);

  String _chapterName(int n) {
    if (_dbChapters != null && _dbChapters!.isNotEmpty) {
      final match = _dbChapters!.where((c) => c.number == n);
      if (match.isNotEmpty) return match.first.title(widget.bn);
      return widget.bn ? 'অধ্যায় $n' : 'Chapter $n';
    }
    if (_dbUnknown && _subject == 'math' && n >= 1 && n <= mockChapters.length) {
      final c = mockChapters[n - 1];
      return widget.bn ? c.bn : c.en;
    }
    return widget.bn ? 'অধ্যায় $n' : 'Chapter $n';
  }

  List<int> get _chapterNumbers =>
      _dbChapters != null && _dbChapters!.isNotEmpty
          ? _dbChapters!.map((c) => c.number).toList()
          : List.generate(5, (i) => i + 1);

  // Class stamp: widget.schoolClass is the parent-supplied class
  // (Search loads the saved profile class). The constructor
  // default 6 is the explicit last-resort fallback when no parent
  // value is supplied — never a silent per-selection guess.
  void _emit() {
    widget.onChanged(
      LessonSelection(
        subject: _subject,
        chapter: _chapter,
        page: _page,
        problem: _problem,
        schoolClass: widget.schoolClass,
      ),
      _locked,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Text(widget.labels['stepSubject']!)),
                DropdownButton<String>(
                  value: _subject,
                  items: _subjects
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              '${s.name(widget.bn)}${s.locked ? ' 🔒' : ''}',
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _subject = v;
                      _chapter = 1;
                    });
                    _emit();
                    _loadChapters(v);
                  },
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Text(widget.labels['stepChapter']!)),
                DropdownButton<int>(
                  value: _chapterNumbers.contains(_chapter)
                      ? _chapter
                      : _chapterNumbers.first,
                  items: _chapterNumbers
                      .map((n) => DropdownMenuItem(
                            value: n,
                            child: Text(_chapterName(n)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _chapter = v);
                    _emit();
                  },
                ),
              ],
            ),
          ),
        ),
        StepperNumberRow(
          label: widget.labels['pageLabel']!,
          value: _page,
          onChange: (v) => setState(() {
            _page = v < 1 ? 1 : v;
            _emit();
          }),
        ),
        StepperNumberRow(
          label: widget.labels['problemLabel']!,
          value: _problem,
          onChange: (v) => setState(() {
            _problem = v < 1 ? 1 : v;
            _emit();
          }),
        ),
        const SizedBox(height: 8),
        // Ready text is built from the live selection inside
        // SearchReadyHint (DEMO index, or the Edge Function when
        // configured) — never a hardcoded page/question.
        SearchReadyHint(
          locked: _locked,
          lockedLabel: widget.lockedLabel,
          labels: widget.labels,
          bn: widget.bn,
          subject: _subject,
          chapter: _chapter,
          page: _page,
          problem: _problem,
          subjectName: _subjectName(_subject),
          configured: supabaseOrNull != null,
          chaptersLoading: _dbChapters == null && !_dbUnknown,
          chaptersUnknown: _dbUnknown,
          chapterExists:
              _dbChapters?.any((c) => c.number == _chapter) ?? false,
        ),
        const SizedBox(height: 4),
        Text(
          '${_subjectName(_subject)} · ${_chapterName(_chapter)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
