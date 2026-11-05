// Fence stripping + lenient partial parsing for structured
// solutions, split out of structured_explanation_service.dart
// to keep it under the 250-line limit. The strict contract
// (parseStructuredSolution) still governs fully-valid payloads;
// this file only handles what strict parsing rejects.
import 'dart:convert';

import '../models/solution_model.dart';

/// Strips one markdown fence pair (```json / ``` / ```JSON) and
/// surrounding whitespace. The result is what the fallback path
/// may show — raw fences never reach the user.
String stripStructuredFences(String raw) {
  var t = raw.trim();
  if (!t.startsWith('```')) return t;
  final firstNl = t.indexOf('\n');
  if (firstNl < 0) return '';
  t = t.substring(firstNl + 1);
  if (t.endsWith('```')) t = t.substring(0, t.length - 3);
  return t.trim();
}

SolutionStep? _partialStep(dynamic raw) {
  if (raw is! Map) return null;
  final n = raw['n'] is num ? (raw['n'] as num).toInt() : null;
  final text = raw['text'] is String ? raw['text'] as String : '';
  if (n == null || text.isEmpty) return null;
  final title = raw['title'] is String ? raw['title'] as String : '';
  final formula =
      raw['formulaLatex'] is String ? raw['formulaLatex'] as String : '';
  final label =
      raw['sectionLabel'] is String ? raw['sectionLabel'] as String : '';
  return SolutionStep(
    n: n,
    title: title,
    text: text,
    formulaLatex: formula.isEmpty ? null : formula,
    table: _partialTable(raw['table']),
    sectionLabel: label.isEmpty ? null : label,
    sectionMarks:
        raw['sectionMarks'] is num ? (raw['sectionMarks'] as num).toInt() : null,
  );
}

SolutionTable? _partialTable(dynamic v) {
  if (v is! Map) return null;
  final headers = (v['headers'] as List?)
      ?.whereType<String>()
      .where((s) => s.isNotEmpty)
      .toList();
  final rows = (v['rows'] as List?)
      ?.whereType<List>()
      .map((r) => r.whereType<String>().toList())
      .where((r) => r.isNotEmpty)
      .toList();
  if (headers == null || headers.isEmpty || rows == null || rows.isEmpty) {
    return null;
  }
  return SolutionTable(headers: headers, rows: rows);
}

/// Lenient partial parse: when ONE step fails (bad number, empty
/// text, wrong type), keep every valid step instead of dropping
/// the whole solution to fallback. Still requires a summary, a
/// final answer, and at least one valid step — otherwise null,
/// exactly like the strict parse.
StructuredSolution? parsePartialStructuredSolution(dynamic data) {
  if (data is! Map) return null;
  final summary = data['summary'] is String ? data['summary'] as String : '';
  final finalAnswer =
      data['finalAnswer'] is String ? data['finalAnswer'] as String : '';
  final rawSteps = data['steps'];
  if (summary.isEmpty || finalAnswer.isEmpty || rawSteps is! List) {
    return null;
  }
  final steps = <SolutionStep>[];
  for (final raw in rawSteps) {
    final step = _partialStep(raw);
    if (step != null) steps.add(step);
  }
  if (steps.isEmpty) return null;
  final correct =
      data['correctOption'] is String ? data['correctOption'] as String : '';
  final why = data['whyCorrect'] is String ? data['whyCorrect'] as String : '';
  final whyNot = data['whyOthersWrong'] is String
      ? data['whyOthersWrong'] as String
      : '';
  return StructuredSolution(
    summary: summary,
    steps: steps,
    finalAnswer: finalAnswer,
    correctOption: correct.isEmpty ? null : correct,
    whyCorrect: why.isEmpty ? null : why,
    whyOthersWrong: whyNot.isEmpty ? null : whyNot,
  );
}

/// Salvage for TRUNCATED structured JSON (2026-11-01 diagnosis:
/// the slow free model sometimes drops the connection mid-output,
/// so a reply can arrive cut off mid-step). Extracts every
/// complete `"text"` value (i.e. every finished step body) and
/// returns them as numbered plain-text lines — the model's own
/// words only, nothing invented, nothing re-ordered. Returns ''
/// when no complete step text exists, so the caller still shows
/// the honest failed row. The result is prose fallback, never a
/// claimed structured solution (no summary/finalAnswer is faked
/// from a truncated draft).
String salvageTruncatedJsonText(String cleaned) {
  final lines = <String>[];
  final pattern = RegExp(r'"text"\s*:\s*"((?:[^"\\]|\\.)*)"');
  for (final m in pattern.allMatches(cleaned)) {
    final raw = m.group(1);
    if (raw == null) continue;
    try {
      final decoded = jsonDecode('"$raw"');
      if (decoded is String && decoded.trim().isNotEmpty) {
        lines.add(decoded.trim());
      }
    } catch (_) {
      // Broken tail fragment (cut mid-escape): skip it, keep
      // the complete steps before it.
    }
  }
  if (lines.isEmpty) return '';
  final buf = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    buf.writeln('${i + 1}. ${lines[i]}');
  }
  return buf.toString().trim();
}

/// Normalization for the summary == finalAnswer comparison
/// (shared by the service-side retry guard and the renderer-side
/// duplicate-card skip): trim, collapse whitespace, convert
/// Bangla digits ০-৯ to ASCII, strip trailing punctuation.
/// Pure string work — no Flutter import, so widgets can use it
/// without a circular import.
String normalizeSummaryFinal(String text) {
  var t = text.trim();
  final buf = StringBuffer();
  for (var i = 0; i < t.length; i++) {
    final c = t.codeUnitAt(i);
    if (c >= 0x09E6 && c <= 0x09EF) {
      buf.writeCharCode(0x30 + (c - 0x09E6));
    } else {
      buf.writeCharCode(c);
    }
  }
  t = buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  const trailing = '।॥.!?:;,—-)';
  while (t.isNotEmpty && trailing.contains(t[t.length - 1])) {
    t = t.substring(0, t.length - 1).trimRight();
  }
  return t;
}

/// True when summary and finalAnswer are the same text under
/// [normalizeSummaryFinal]. Empty sides never count as equal,
/// so a missing summary is not hidden as a "duplicate".
bool summaryEqualsFinal(String summary, String finalAnswer) {
  final a = normalizeSummaryFinal(summary);
  final b = normalizeSummaryFinal(finalAnswer);
  return a.isNotEmpty && b.isNotEmpty && a == b;
}
