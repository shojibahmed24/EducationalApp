// New search screen (Step 3): home tile -> this screen. Order (plan
// §1): শ্রেণি -> বিষয় -> সোর্স (পাঠ্যবই / গাইড) -> ONE global
// picker (subject-wise items load below, same widget for every
// subject) -> প্রশ্ন নম্বর ইনপুট (NO page field anywhere) -> টাইপ
// (exactly 5; guide mode shows the exact count per type). State +
// resolution live in SearchFlowController; this file only renders
// and navigates. The English guide tree and Bangla 2nd types open
// their existing routes. UI (plan §5): shared SearchFlowField
// inputs, actions pinned at the bottom, hint while chapter/type
// are unpicked. No old screen/route is touched.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/search_flow_strings.dart';
import 'global_picker_english.dart';
import 'global_picker_tree.dart';
import 'guide_answer_holder.dart';
import 'lesson_selection.dart';
import 'search_flow_bangla_papers.dart';
import 'search_flow_browse_extras.dart';
import 'search_flow_controller.dart';
import 'search_flow_list_query.dart';
import 'search_flow_picker_host.dart';
import 'search_flow_types.dart';
import 'widgets/global_picker.dart';
import 'widgets/search_flow_actions.dart';
import 'widgets/search_flow_board_tile.dart';
import 'widgets/search_flow_field.dart';
import 'widgets/search_flow_type_field.dart';
import 'widgets/search_flow_field_states.dart';
import 'widgets/search_flow_identity_fields.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class SearchFlowScreen extends StatefulWidget {
  const SearchFlowScreen({
    super.key,
    this.initialSubjectId = 'math',
    this.initialSchoolClass,
  });
  final String initialSubjectId;
  final int? initialSchoolClass;

  @override
  State<SearchFlowScreen> createState() => _SearchFlowScreenState();
}

class _SearchFlowScreenState extends State<SearchFlowScreen> {
  late final SearchFlowController _c;
  late final SearchFlowBrowseExtras _extras;
  final _englishHost = GlobalPickerEnglishHost();
  String? _jumpMessage;

  void _ensureEnglish() => _englishHost.ensure(
      subjectId: _c.subjectId, source: _c.source, schoolClass: _c.schoolClass,
      onChanged: () { if (mounted) setState(() {}); });

  @override
  void initState() {
    super.initState();
    _c = SearchFlowController(
      initialSubjectId: widget.initialSubjectId,
      initialSchoolClass: widget.initialSchoolClass,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    _extras = SearchFlowBrowseExtras(onChanged: () { if (mounted) setState(() {}); });
    _c.init(languageNotifier.value.languageCode == 'bn').then((_) {
      if (mounted) {
        _extras.refreshGuide(_c.effectiveSubjectId, _c.effectiveClass);
        prefetchFirstSubjectPickerData(_c, _extras);
        _ensureEnglish();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _goList({int? questionNumber}) {
    final banglaFirst = isBanglaFirstMode(_c.subjectId, _c.source);
    final banglaSecond = isBanglaSecondMode(_c.subjectId, _c.source);
    final paper2Mode = _c.source == 'guide' && _c.subjectId == 'english-2nd';
    if (banglaSecond) {
      context.go('/bangla-second');
      return;
    }
    context.go('/search-flow-list?${_c.listQuery(questionNumber: questionNumber, setId: _extras.setId, paper2Section: _extras.paper2Section, chapterless: _extras.setId == null && (banglaFirst || paper2Mode))}');
  }

  Future<void> _jump(Map<String, String> s, bool bn) async {
    final result = await _c.jump(s, bn);
    if (!mounted) return;
    switch (result.kind) {
      case SearchFlowJumpKind.guideQuestion:
        // Step 7: back from the answer returns to this
        // search screen (the jump came from here, not a list).
        GuideAnswerHolder.set(q: result.question!, subject: _c.subjectId,
            chapter: _c.chapter!, schoolClass: _c.schoolClass, returnTo: '/search-flow?subject=${_c.subjectId}');
        context.go('/guide-answer');
      case SearchFlowJumpKind.lesson:
        LessonSelectionHolder.set(result.lesson!);
        context.go('/lesson');
      case SearchFlowJumpKind.list:
        final n = normalizeQuestionNumber(_c.numberCtrl.text);
        if (n != null) _goList(questionNumber: n);
      case SearchFlowJumpKind.message:
        setState(() => _jumpMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? searchFlowStringsBn : searchFlowStringsEn;
        final englishGuideMode =
            _c.source == 'guide' && _c.subjectId == 'english';
        final paper2Mode = _c.source == 'guide' && _c.subjectId == 'english-2nd';
        final banglaFirst = isBanglaFirstMode(_c.subjectId, _c.source);
        final banglaSecond = isBanglaSecondMode(_c.subjectId, _c.source);
        final setMode = _extras.setId != null;
        final needType = setMode || banglaFirst || banglaSecond ? false : paper2Mode ? _extras.paper2Section == null : _c.type == null;
        final canSubmit = (setMode || banglaFirst || banglaSecond || paper2Mode || _c.chapter != null) && !needType;
        final String? actionHint = setMode || banglaFirst || banglaSecond ? null : paper2Mode ? (_extras.paper2Section == null ? s['actionHintSection'] : null) : _c.chapter == null && needType ? s['actionHintBoth'] : _c.chapter == null ? s['actionHintChapter'] : needType ? s['actionHintType'] : null;
        const gap = SizedBox(height: 12);
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
            title: Text(s['title']!),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['subtitle']!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      SearchFlowGroupLabel(s['identityGroup']!),
                      const SizedBox(height: 12),
                      SearchFlowIdentityFields(
                        controller: _c,
                        s: s,
                        bn: bn,
                        onClass: (v) => _c.changeClass(v, bn).then((_) {
                          if (mounted) {
                            _extras.refreshGuide(_c.effectiveSubjectId, _c.effectiveClass);
                            _ensureEnglish();
                          }
                        }),
                        onSubject: (v) {
                          _c.applySubject(v);
                          _extras.refreshGuide(_c.effectiveSubjectId, _c.effectiveClass);
                          _ensureEnglish();
                        },
                        onSource: (v) {
                          _c.changeSource(v);
                          _extras.refreshGuide(_c.effectiveSubjectId, _c.effectiveClass);
                          _ensureEnglish();
                        },
                      ),
                      const SizedBox(height: 20),
                      SearchFlowGroupLabel(s['questionGroup']!),
                      const SizedBox(height: 12),
                      // THE picker: one widget for every subject.
                      // Subject-wise items load below it; English
                      // guide navigates to its list/reader routes
                      // from here instead of a separate screen.
                      if (englishGuideMode &&
                          _englishHost.controller == null)
                        SearchFlowLoadingBars(label: s['pickerLoading']!, semanticsLabel: s['pickerLoading']!)
                      else
                        GlobalPicker(
                          treeKey: '${_c.subjectId}|${_c.source}|${_c.schoolClass}',
                          tree: englishGuideMode
                              ? buildEnglishPickerTree(c: _englishHost.controller!, schoolClass: _c.schoolClass, s: s, bn: bn)
                              : buildGlobalPickerTree(c: _c, extras: _extras, s: s, bn: bn),
                          s: s,
                          selectedId: globalPickerSelectedId(_c, _extras),
                          onPick: (pick) => applyGlobalPickerPick(context: context, c: _c, extras: _extras, pick: pick, onChanged: () => setState(() {})),
                          onBranch: (node) => onGlobalPickerBranch(node: node, c: _c, extras: _extras, english: _englishHost),
                        ),
                      // Board tile (migration 018 flag, Board
                      // revision): chapter-like row, no chapter
                      // number, guide source only.
                      if (_c.source == 'guide')
                        SearchFlowBoardTile(subjectId: _c.effectiveSubjectId, schoolClass: _c.effectiveClass, s: s, bn: bn),
                      if (!englishGuideMode) ...[
                        gap,
                        SearchFlowTextField(
                          label: s['questionNumberLabel']!, icon: Icons.numbers,
                          controller: _c.numberCtrl, hint: s['questionNumberHint']!,
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            if (_jumpMessage != null) {
                              setState(() => _jumpMessage = null);
                            }
                          },
                          onSubmitted: () => _jump(s, bn),
                        ),
                      ],
                      if (!englishGuideMode &&
                          !banglaFirst &&
                          !banglaSecond &&
                          !setMode &&
                          !paper2Mode) ...[
                        gap,
                        SearchFlowTypeField(
                          value: _c.type, s: s, bn: bn, chapter: _c.chapter,
                          guide: _c.source == 'guide', lesson: _c.lesson,
                          subject: _c.effectiveSubjectId,
                          schoolClass: _c.effectiveClass,
                          onChanged: (v) => setState(() => _c.type = v),
                        ),
                      ],
                      if (_jumpMessage != null) ...[
                        const SizedBox(height: 12),
                        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_jumpMessage!))),
                      ],
                    ],
                  ),
                ),
              ),
              if (!englishGuideMode)
                SearchFlowActions(
                  canSubmit: canSubmit,
                  jumping: _c.jumping,
                  actionHint: actionHint,
                  s: s,
                  onShowList: () => _goList(),
                  onJump: () => _jump(s, bn),
                ),
            ],
          ),
        );
      },
    );
  }
}
