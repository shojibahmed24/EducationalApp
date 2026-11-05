// English reader shaping (redesign 2026-11-03): pure rules
// that turn fetched rows into question groups, a passage and
// its parts. No server calls here — unit-testable with fakes.
import '../models/guide_bank_model.dart';
import 'english_redesign.dart';

/// Sections whose answers come from the passage (plan §4, Q1–Q7).
const englishPassageBasedSections = [
  'mcq',
  'short',
  'gapfill',
  'table',
  'summary',
  'matching',
  'rearranging',
];

/// Q-number label for a passage-based section (same both locales).
String? englishTestQuestionLabel(String section) {
  const order = englishPassageBasedSections;
  final i = order.indexOf(section);
  return i < 0 ? null : 'Q${i + 1}';
}

/// One reader group: questions sharing a section (tests,
/// practice) or a set (poems, stories), in row order.
class EnglishReaderGroup {
  const EnglishReaderGroup({
    required this.key,
    required this.section,
    required this.setId,
    required this.questions,
  });
  final String key;
  final String? section;
  final String? setId;
  final List<GuideBankQuestion> questions;
}

/// Groups in first-appearance order (preserves the guide's
/// printed order: Q1→Q7 in tests, exercise order in practice).
List<EnglishReaderGroup> buildReaderGroups(
    List<GuideBankQuestion> rows, String kind) {
  final groups = <EnglishReaderGroup>[];
  final byKey = <String, int>{};
  for (final r in rows) {
    final key = (kind == 'poem' || kind == 'story')
        ? 'set:${r.setId ?? ''}'
        : 'sec:${r.section ?? ''}';
    final i = byKey[key];
    if (i == null) {
      byKey[key] = groups.length;
      groups.add(EnglishReaderGroup(
          key: key,
          section: r.section,
          setId: r.setId,
          questions: [r]));
    } else {
      groups[i].questions.add(r);
    }
  }
  return groups;
}

/// The reader's passage: the stimulus text carried by the most
/// rows (the test's main passage, a poem's text, a story's
/// full text). Ties break toward the longest text. Null when
/// no row carries text — the honest note shows instead.
String? readerPassage(List<GuideBankQuestion> rows) {
  final counts = <String, int>{};
  for (final r in rows) {
    final t = r.stimulusText;
    if (t != null && t.trim().isNotEmpty) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return null;
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      if (a.value != b.value) return b.value.compareTo(a.value);
      return b.key.length.compareTo(a.key.length);
    });
  return sorted.first.key;
}

/// Passage parts: paragraphs (blank-line split) grouped three
/// to a part, so a long story shows a few parts with a Next
/// button after each group instead of one part per paragraph.
/// A poem with no blank lines stays one part and shows whole.
List<String> splitPassageParts(String text) {
  final paras = text
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  final parts = <String>[];
  for (var i = 0; i < paras.length; i += 3) {
    final end = (i + 3 < paras.length) ? i + 3 : paras.length;
    parts.add(paras.sublist(i, end).join('\n\n'));
  }
  return parts;
}

/// Display label for a set chip in poem/story readers:
/// 'main-03' → মডেল টেস্ট ৩, 'special1-44' → বিশেষ ১, bank → ব্যাংক.
String setDisplayLabel(String? setId, bool bn) {
  if (setId == null || setId.isEmpty) return bn ? 'ব্যাংক' : 'Bank';
  final main = RegExp(r'^main-(\d+)$').firstMatch(setId);
  if (main != null) {
    final n = int.parse(main.group(1)!);
    return bn ? 'মডেল ${bnDigits(n)}' : 'Model $n';
  }
  final special = RegExp(r'^special\d*-(\d+)$').firstMatch(setId);
  if (special != null) {
    final n = int.parse(special.group(1)!) - 43;
    return bn ? 'বিশেষ ${bnDigits(n)}' : 'Special $n';
  }
  return setId;
}
