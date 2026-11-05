// Global picker model: ONE picker for the whole search flow.
// Every subject renders through this single node tree — no
// per-subject picker widgets anymore. A node is either a branch
// (tap drills one level deeper) or a leaf (tap picks). The pick
// itself is pure data; the screen applies it to the existing
// controller/extras state or navigates to an existing route, so
// list/jump behavior underneath never changes.
enum GlobalPickerNodeKind {
  chapter,
  lesson,
  section,
  set,
  setsGroup,
  banglaSecondType,
  englishSection,
  englishLesson,
}

/// What tapping a leaf node means. One constructor per meaning,
/// so the screen applies exactly one state change per pick and
/// the old mutual-exclusion rules stay in one place (the screen).
enum GlobalPickerPickKind {
  chapter,
  chapterLesson,
  section,
  sectionLesson,
  paper2,
  set,
  route,
}

class GlobalPickerPick {
  const GlobalPickerPick.chapter(this.chapter)
      : kind = GlobalPickerPickKind.chapter,
        lesson = null,
        banglaSection = null,
        paper2Section = null,
        setId = null,
        route = null;
  const GlobalPickerPick.chapterLesson(this.chapter, this.lesson)
      : kind = GlobalPickerPickKind.chapterLesson,
        banglaSection = null,
        paper2Section = null,
        setId = null,
        route = null;
  const GlobalPickerPick.section(this.banglaSection)
      : kind = GlobalPickerPickKind.section,
        chapter = null,
        lesson = null,
        paper2Section = null,
        setId = null,
        route = null;
  const GlobalPickerPick.sectionLesson(this.banglaSection, this.lesson)
      : kind = GlobalPickerPickKind.sectionLesson,
        chapter = null,
        paper2Section = null,
        setId = null,
        route = null;
  const GlobalPickerPick.paper2(this.paper2Section)
      : kind = GlobalPickerPickKind.paper2,
        chapter = null,
        lesson = null,
        banglaSection = null,
        setId = null,
        route = null;
  const GlobalPickerPick.set(this.setId)
      : kind = GlobalPickerPickKind.set,
        chapter = null,
        lesson = null,
        banglaSection = null,
        paper2Section = null,
        route = null;
  const GlobalPickerPick.route(this.route)
      : kind = GlobalPickerPickKind.route,
        chapter = null,
        lesson = null,
        banglaSection = null,
        paper2Section = null,
        setId = null;
  final GlobalPickerPickKind kind;
  final int? chapter;
  final String? lesson;
  final String? banglaSection;
  final String? paper2Section;
  final String? setId;
  final String? route;
}

class GlobalPickerNode {
  const GlobalPickerNode({
    required this.id,
    required this.title,
    this.subtitle,
    required this.kind,
    this.hasChildren = false,
    this.pick,
  });
  final String id;
  final String title;
  final String? subtitle;
  final GlobalPickerNodeKind kind;

  /// True when tapping drills deeper instead of picking.
  final bool hasChildren;

  /// Non-null for leaves: what the tap picks. Branch-only nodes
  /// (the sets group) carry no pick.
  final GlobalPickerPick? pick;
}

/// Snapshot tree for one subject + source + class. Everything is
/// synchronous on purpose: the data already lives in the
/// controller/extras state (loaded once per subject change and
/// reused across rebuilds), so the picker never fires its own
/// network call and never waits on one per keystroke. A null
/// children list means "still loading" — the widget shows a
/// spinner and the next screen rebuild delivers the rows.
class GlobalPickerTree {
  const GlobalPickerTree({
    required this.loading,
    required this.rootNodes,
    required this.childrenOf,
  });
  final bool loading;
  final List<GlobalPickerNode> rootNodes;
  final List<GlobalPickerNode>? Function(GlobalPickerNode node) childrenOf;
}
