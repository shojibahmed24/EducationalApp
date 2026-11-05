// Home design tokens + paper-aware display names (dashboard
// redesign, Phase 1 + 3). One spacing scale and one card radius
// for the whole Home screen: section gaps used to drift between
// 12/16/20 with no rule. Colours stay in AppTheme; these are
// layout only. Paper names are DISPLAY ONLY: server ids never
// change, routes never change.
class HomeDesign {
  static const double screenPadding = 20;
  static const double sectionGap = 20;
  static const double blockGap = 16;
  static const double tightGap = 12;
  static const double cardGap = 12;
  static const double cardRadius = 24;
}

/// Paper-aware tile name. The class-10 Bangla guide book shares
/// subject_id 'bangla' with 1st paper, so a plain server name
/// would just say "বাংলা" for both papers. The profile class
/// decides the paper label; any other class or subject falls
/// back to the server name untouched.
String paperSubjectName(
  String id,
  String fallback,
  bool bn,
  int? schoolClass,
) {
  if (id == 'bangla') {
    if (schoolClass == 10) {
      return bn ? 'বাংলা ২য় পত্র' : 'Bangla 2nd Paper';
    }
    if (schoolClass == 9) {
      return bn ? 'বাংলা ১ম পত্র' : 'Bangla 1st Paper';
    }
    return fallback;
  }
  if (id == 'english') {
    if (schoolClass == 9 || schoolClass == 10) {
      return bn ? 'ইংরেজি ১ম পত্র' : 'English 1st Paper';
    }
    return fallback;
  }
  if (id == 'english-2nd') {
    return bn ? 'ইংরেজি ২য় পত্র' : 'English 2nd Paper';
  }
  return fallback;
}
