// Subject tree for the global picker: turns the existing
// controller/extras state into ONE node tree per subject. No new
// network calls here — chapters come from the controller (loaded
// once per subject change), sets and server lessons from extras,
// Math lessons and Bangla sections from verified static maps.
// Behavior underneath is unchanged: a pick maps to exactly the
// state change the old per-subject dropdowns used to make.
import '../../core/data/bangla_first_lessons.dart';
import '../../core/data/paper2_sections.dart';
import '../../l10n/pages/bangla_first_strings.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_second_types.dart';
import 'global_picker_model.dart';
import 'search_flow_bangla_papers.dart';
import 'search_flow_browse_extras.dart';
import 'search_flow_controller.dart';
import 'search_flow_lesson_counts.dart';
import 'search_flow_types.dart';
import 'set_display_labels.dart';
import 'widgets/digits.dart';

/// Set row subtitle: Bangla-1st lesson-model sets show the lesson
/// title plus the question count; every other set shows the count.
String _setSubtitle(bool firstMode, String setId, int count, bool bn) {
  final slug = firstMode ? ban1LessonSlug(setId) : null;
  final lesson = slug == null ? null : banglaFirstLessonBySlug(slug);
  final countStr = numStr(count, bn);
  return lesson == null ? countStr : '${lesson.title} · $countStr';
}

GlobalPickerTree buildGlobalPickerTree({
  required SearchFlowController c,
  required SearchFlowBrowseExtras extras,
  required Map<String, String> s,
  required bool bn,
}) {
  final firstMode = isBanglaFirstMode(c.subjectId, c.source);
  final secondMode = isBanglaSecondMode(c.subjectId, c.source);
  final paper2Mode = c.source == 'guide' && c.subjectId == 'english-2nd';
  final guide = c.source == 'guide';
  final s1 = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
  final s2 = bn ? banglaSecondStringsBn : banglaSecondStringsEn;

  GlobalPickerNode setsGroupNode() => GlobalPickerNode(
    id: 'sets-group',
    title: s['setLabel']!,
    subtitle: extras.setsLoading ? null : numStr(extras.sets.length, bn),
    kind: GlobalPickerNodeKind.setsGroup,
    hasChildren: true,
  );

  List<GlobalPickerNode> roots;
  bool loading;
  if (secondMode) {
    // The 11 অধ্যায় items are constants: instant, no load.
    // Tapping one opens the existing dedicated picker route —
    // the same destination the old chapter dropdown used.
    roots = [
      for (final t in banglaSecondTypesInOrder)
        GlobalPickerNode(
          id: 'b2:${t.name}',
          title: banglaSecondTypeLabel(t, s2),
          kind: GlobalPickerNodeKind.banglaSecondType,
          pick: GlobalPickerPick.route(banglaSecondRoute(t)),
        ),
    ];
    loading = false;
  } else if (firstMode) {
    roots = [
      for (final sec in banglaFirstSections)
        GlobalPickerNode(
          id: 'section:$sec',
          title: banglaFirstSectionName(sec, s1),
          kind: GlobalPickerNodeKind.section,
          hasChildren: true,
          pick: GlobalPickerPick.section(sec),
        ),
    ];
    // Old UI with no section picked listed ALL server lessons,
    // including titles the verified map does not know (they belong
    // to no section, so a picked section hides them). This branch
    // preserves that reachability instead of orphaning them.
    if (extras.serverLessons.isNotEmpty) {
      roots.add(
        GlobalPickerNode(
          id: 'section:__all',
          title: s['lessonAll']!,
          kind: GlobalPickerNodeKind.section,
          hasChildren: true,
        ),
      );
    }
    if (extras.sets.isNotEmpty) roots.add(setsGroupNode());
    loading = false;
  } else if (paper2Mode) {
    roots = [
      for (final v in paperTwoSections)
        GlobalPickerNode(
          id: 'paper2:$v',
          title: s[paperTwoSectionStringKey(v)]!,
          kind: GlobalPickerNodeKind.section,
          pick: GlobalPickerPick.paper2(v),
        ),
    ];
    if (extras.sets.isNotEmpty) roots.add(setsGroupNode());
    loading = false;
  } else {
    roots = [
      for (final ch in c.chapters)
        GlobalPickerNode(
          id: 'chapter:${ch.$1}',
          title: searchFlowChapterLabel(ch.$1, ch.$2, bn, s),
          kind: GlobalPickerNodeKind.chapter,
          hasChildren:
              guide &&
              lessonsForChapter(c.subjectId, c.schoolClass, ch.$1).isNotEmpty,
          pick: GlobalPickerPick.chapter(ch.$1),
        ),
    ];
    if (guide && extras.sets.isNotEmpty) roots.add(setsGroupNode());
    loading = c.chaptersLoading;
  }

  List<GlobalPickerNode>? childrenOf(GlobalPickerNode node) {
    switch (node.kind) {
      case GlobalPickerNodeKind.chapter:
        final n = int.tryParse(node.id.split(':').last) ?? 0;
        final lessons = lessonsForChapter(c.subjectId, c.schoolClass, n);
        return [
          GlobalPickerNode(
            id: 'lesson:$n:all',
            title: s['lessonAll']!,
            subtitle: lessonCountsLine(extras.lessonCounts.of(n, null), s, bn),
            kind: GlobalPickerNodeKind.lesson,
            pick: GlobalPickerPick.chapterLesson(n, null),
          ),
          for (final e in lessons.entries)
            GlobalPickerNode(
              id: 'lesson:$n:${e.key}',
              title: e.key == e.value ? e.key : '${e.key} · ${e.value}',
              subtitle:
                  lessonCountsLine(extras.lessonCounts.of(n, e.key), s, bn),
              kind: GlobalPickerNodeKind.lesson,
              pick: GlobalPickerPick.chapterLesson(n, e.key),
            ),
        ];
      case GlobalPickerNodeKind.section:
        // Bangla 1st only: other section nodes are leaves.
        if (!firstMode) return const [];
        if (extras.serverLessonsLoading) return null;
        if (node.id == 'section:__all') {
          return [
            for (final e in extras.serverLessons.entries)
              GlobalPickerNode(
                id: 'lesson:__all:${e.key}',
                title: e.key,
                subtitle: numStr(e.value, bn),
                kind: GlobalPickerNodeKind.lesson,
                pick: GlobalPickerPick.sectionLesson(null, e.key),
              ),
          ];
        }
        final sec = node.id.split(':').last;
        final filtered = extras.serverLessons.entries
            .where((e) => banglaFirstLessonByTitle(e.key)?.section == sec)
            .toList();
        return [
          GlobalPickerNode(
            id: 'lesson:$sec:all',
            title: s['lessonAll']!,
            kind: GlobalPickerNodeKind.lesson,
            pick: GlobalPickerPick.sectionLesson(sec, null),
          ),
          for (final e in filtered)
            GlobalPickerNode(
              id: 'lesson:$sec:${e.key}',
              title: e.key,
              subtitle: numStr(e.value, bn),
              kind: GlobalPickerNodeKind.lesson,
              pick: GlobalPickerPick.sectionLesson(sec, e.key),
            ),
        ];
      case GlobalPickerNodeKind.setsGroup:
        if (extras.setsLoading) return null;
        return [
          for (var i = 0; i < extras.sets.length; i++)
            GlobalPickerNode(
              id: 'set:${extras.sets[i].setId}',
              title: setDisplayTitle(extras.sets[i].setId, bn, i + 1),
              subtitle: _setSubtitle(
                firstMode,
                extras.sets[i].setId,
                extras.sets[i].totalCount,
                bn,
              ),
              kind: GlobalPickerNodeKind.set,
              pick: GlobalPickerPick.set(extras.sets[i].setId),
            ),
        ];
      default:
        return const [];
    }
  }

  return GlobalPickerTree(
    loading: loading,
    rootNodes: roots,
    childrenOf: childrenOf,
  );
}
