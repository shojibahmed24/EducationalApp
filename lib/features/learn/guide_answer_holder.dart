// One-shot holder passing the tapped guide question to the
// /guide-answer route (same pattern as LessonSelectionHolder);
// the route itself carries no question data. Split out of
// guide_answer_screen.dart to keep that file under the 250-line cap.
// Step 6: the route ALSO accepts an optional creative group via
// GoRouter extra (see learn_routes.dart), transferred here by
// the route builder. When group is set, the screen renders the
// grouped view; when null, exactly the single-question behavior.
import '../../core/models/guide_bank_model.dart';

class GuideAnswerHolder {
  static GuideBankQuestion? question;
  static String subjectId = '';
  static int chapterNumber = 0;
  // Documented last resort only: the bank screen always passes the
  // resolved class to set(); this default is reached only by a
  // direct /guide-answer entry with no class known anywhere.
  static int schoolClass = 6;

  /// All parts of one creative stimulus, when the answer route
  /// was opened as a group. Null = single-question mode.
  static List<GuideBankQuestion>? group;

  /// Group stimulus text ('' = fall back to the parts' own
  /// stimulusText fields; never invented).
  static String stimulusText = '';

  /// Effective chat stimulus for one open question: the part's
  /// own stimulusText, else the group stimulus; '' = none.
  static String chatStimulus(GuideBankQuestion q) =>
      q.stimulusText?.isNotEmpty == true ? q.stimulusText! : stimulusText;

  /// Where the answer screen's back button returns (Step 7):
  /// the exact new-flow list URL when opened from a list, else
  /// the search-flow screen. Never the deleted /guide-bank route.
  static String returnTo = '/search-flow';

  static void set({
    required GuideBankQuestion q,
    required String subject,
    required int chapter,
    int schoolClass = 6,
    String? returnTo,
  }) {
    question = q;
    subjectId = subject;
    chapterNumber = chapter;
    GuideAnswerHolder.schoolClass = schoolClass;
    group = null;
    stimulusText = '';
    if (returnTo != null) GuideAnswerHolder.returnTo = returnTo;
  }

  /// Group mode: question becomes the first part (fallback for
  /// any single-mode reader); an empty list clears group mode.
  static void setGroup({
    required List<GuideBankQuestion> parts,
    required String subject,
    required int chapter,
    int schoolClass = 6,
    String stimulusText = '',
    String? returnTo,
  }) {
    if (parts.isEmpty) {
      group = null;
      GuideAnswerHolder.stimulusText = '';
      return;
    }
    group = parts;
    question = parts.first;
    subjectId = subject;
    chapterNumber = chapter;
    GuideAnswerHolder.schoolClass = schoolClass;
    GuideAnswerHolder.stimulusText = stimulusText;
    if (returnTo != null) GuideAnswerHolder.returnTo = returnTo;
  }

  static void clear() {
    question = null;
    group = null;
    stimulusText = '';
  }
}
