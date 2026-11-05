// Phase 2 sampling (pure + fake-post, offline): proportional
// allocation, seeded determinism, seen exclusion, and the
// unfiltered-frame fallback when the server ignores the section
// filter. No network, no cache writes (sampling never touches
// the chapter cache — the fake post records every call and the
// tests assert no page ever claims to be a full chapter).
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/guide_quiz_pool.dart';
import 'package:yes_sir_ai/core/services/guide_quiz_sampling.dart';

/// Fake list/guideChapters post. Chapter 3: 120 section MCQ
/// rows (200 unfiltered); chapter 7: 60 (100 unfiltered).
/// Unfiltered rows alternate mcq/short so the client filter
/// has something to do.
Future<Map<String, dynamic>?> _fakePost(
  Map<String, dynamic> body, {
  String? endpoint,
}) async {
  if (body['action'] == 'guideChapters') {
    return {
      'found': true,
      'guideChapters': [
        {'chapter': 3, 'totalCount': 200, 'keyedCount': 180},
        {'chapter': 7, 'totalCount': 100, 'keyedCount': 90},
      ],
    };
  }
  final chapter = body['chapter'] as int;
  final section = body['section'] as String?;
  final offset = body['offset'] as int;
  final limit = body['limit'] as int;
  final total = section == 'mcq_bank'
      ? (chapter == 3 ? 120 : 60)
      : (chapter == 3 ? 200 : 100);
  final rows = <Map<String, dynamic>>[];
  for (var i = offset; i < offset + limit && i < total; i++) {
    final isMcq = section == 'mcq_bank' || i.isEven;
    rows.add({
      'id': 'ch$chapter-q$i',
      'questionText': 'q$i',
      'questionType': isMcq ? 'mcq' : 'short',
      'options': isMcq ? ['A', 'B', 'C', 'D'] : [],
      'hasKey': isMcq,
      'guideError': false,
      'setId': null,
    });
  }
  return {
    'found': true,
    'section': section,
    'total': total,
    'questions': rows,
  };
}

/// Same fake, but the server NEVER echoes the section filter
/// (old-server shape): section-filtered totals fall back to
/// the unfiltered frame.
Future<Map<String, dynamic>?> _noEchoPost(
  Map<String, dynamic> body, {
  String? endpoint,
}) async {
  final res = await _fakePost(body, endpoint: endpoint);
  if (res != null && body['action'] == 'list') {
    return {...res, 'section': null};
  }
  return res;
}

void main() {
  group('allocateProportional', () {
    test('shares proportional to totals', () {
      expect(allocateProportional([100, 50], 60), [40, 20]);
    });
    test('caps at each chapter total, remainder to the other', () {
      // 60*2/102 = 1.18 -> 1, 60*100/102 = 58.82 -> 59.
      expect(allocateProportional([2, 100], 60), [1, 59]);
    });
    test('zero totals yield zero allocation', () {
      expect(allocateProportional([0, 0], 5), [0, 0]);
    });
    test('want larger than the pool yields the whole pool', () {
      expect(allocateProportional([3, 4], 100), [3, 4]);
    });
  });

  group('sample', () {
    test('seeded sampling is deterministic', () async {
      final s = GuideQuizSampling(post: _fakePost);
      final a = await s.sample(
          subject: 'math', schoolClass: 9, want: 20,
          seedKey: 'daily-9-math-2026-11-01');
      final b = await s.sample(
          subject: 'math', schoolClass: 9, want: 20,
          seedKey: 'daily-9-math-2026-11-01');
      expect(a.map((c) => c.question.id).toList(),
          b.map((c) => c.question.id).toList());
      expect(a.length, 20);
    });

    test('every sampled row is scorable', () async {
      final s = GuideQuizSampling(post: _fakePost);
      final out = await s.sample(
          subject: 'math', schoolClass: 9, want: 20,
          seedKey: 'daily-9-math-2026-11-01');
      expect(out.every((c) => isScorableGuideMcq(c.question)), isTrue);
    });

    test('seen ids are excluded on the first pass', () async {
      final s = GuideQuizSampling(post: _fakePost);
      final first = await s.sample(
          subject: 'math', schoolClass: 9, want: 10,
          seedKey: 'daily-9-math-2026-11-01');
      final seen = first.map((c) => c.question.id).toSet();
      final second = await s.sample(
          subject: 'math', schoolClass: 9, want: 10, seenIds: seen);
      expect(second.any((c) => seen.contains(c.question.id)), isFalse);
    });

    test('unfiltered frame still yields only scorable MCQs', () async {
      final s = GuideQuizSampling(post: _noEchoPost);
      final out = await s.sample(
          subject: 'math', schoolClass: 9, want: 20,
          seedKey: 'daily-9-math-2026-11-01');
      expect(out.isNotEmpty, isTrue);
      expect(out.every((c) => c.question.questionType == 'mcq'), isTrue);
      expect(out.every((c) => isScorableGuideMcq(c.question)), isTrue);
    });
  });
}
