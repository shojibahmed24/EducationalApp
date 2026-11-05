// Pure chat-greeting helpers, split out of chat_screen.dart to
// keep it under the 250-line cap. No Flutter, no services, no
// Edge: every function here is unit-testable without a device.
// Names never come from a hardcoded fallback: greetingFirstName
// returns null when the profile carries no usable name, and the
// greeting is then built without any name.
import 'lesson_selection.dart';
import 'widgets/digits.dart';

/// First name for the greeting: nickname when non-empty, else
/// full_name; first whitespace-separated token only. Null when
/// the profile is missing or holds no usable name — callers
/// must then greet without a name, never invent one.
String? greetingFirstName(Map<String, dynamic>? profile) {
  if (profile == null) return null;
  String? raw;
  final nickname = profile['nickname'];
  final fullName = profile['full_name'];
  if (nickname is String && nickname.trim().isNotEmpty) {
    raw = nickname;
  } else if (fullName is String && fullName.trim().isNotEmpty) {
    raw = fullName;
  }
  if (raw == null) return null;
  final first = raw.trim().split(RegExp(r'\s+')).first;
  return first.isEmpty ? null : first;
}

/// Question line for the chat header + greeting: subject,
/// chapter, and page/problem ONLY when they are real numbers.
/// A questionId selection may carry page/problem 0 (unknown);
/// those are omitted, never displayed as 0.
String chatQuestionLine(LessonSelection sel, String subjectName, bool bn) {
  final parts = <String>[subjectName];
  // Guide set-based opens carry chapter 0 (unknown) — never
  // display it as a real chapter number (2026-11-03 fix: the
  // "অধ্যায় ০" title bug).
  if (sel.chapter > 0) {
    parts.add('${bn ? 'অধ্যায়' : 'Chapter'} ${numStr(sel.chapter, bn)}');
  }
  if (sel.page > 0) {
    parts.add('${bn ? 'পৃষ্ঠা' : 'Page'} ${numStr(sel.page, bn)}');
  }
  if (sel.problem > 0) {
    parts.add('${bn ? 'প্রশ্ন' : 'Question'} ${numStr(sel.problem, bn)}');
  }
  return parts.join(' · ');
}

/// Chat greeting: the named template with {name} replaced, the
/// plain template when there is no name, then the question line
/// and the stuck-part prompt. The prompt names only generic
/// parts (step / formula / calculation) — never a specific
/// problem's content.
String buildChatGreeting({
  String? name,
  required Map<String, String> s,
  required String questionLine,
}) {
  final trimmedName = name?.trim() ?? '';
  final greeting = trimmedName.isEmpty
      ? (s['greetingPlain'] ?? '')
      : (s['greetingNamed'] ?? '').replaceAll('{name}', trimmedName);
  final prompt = s['greetingPrompt'] ?? '';
  final bits = <String>[
    greeting,
    if (questionLine.isNotEmpty) questionLine,
    prompt,
  ].where((b) => b.isNotEmpty).toList();
  return bits.join(' ');
}

/// School class for a chat resolve: the selection's class first,
/// then the saved profile class, then 6. The 6 is only the
/// last-resort fallback when NO class is known anywhere.
int resolveChatSchoolClass({
  int? selectionClass,
  int? profileClass,
  int fallback = 6,
}) =>
    selectionClass ?? profileClass ?? fallback;

/// True when chat grounding must resolve by question id, exactly
/// like the lesson (see lesson_grounding.dart).
bool useQuestionIdGrounding(LessonSelection sel) => sel.questionId != null;
