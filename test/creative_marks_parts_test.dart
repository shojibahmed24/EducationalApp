// Creative marks_parts normaliser + part ordering tests. Fixtures
// are fake (নকল); shapes mirror the four database formats.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/creative_marks_parts.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/creative_part_marks.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_parts.dart';

GuideBankQuestion row(String id, int? marks) => GuideBankQuestion(
      id: id,
      questionText: 'নকল প্রশ্ন $id',
      questionType: 'creative',
      marks: marks,
      stimulusId: 's',
    );

void main() {
  group('normalizeMarksParts', () {
    test('Bangla keys, total ignored', () {
      expect(
        normalizeMarksParts({'ক': 2, 'খ': 4, 'গ': 4, 'মোট': 10}),
        [2, 4, 4],
      );
    });
    test('Bangla keys without total', () {
      expect(normalizeMarksParts({'ক': 1, 'খ': 2, 'গ': 3, 'ঘ': 4}),
          [1, 2, 3, 4]);
    });
    test('roman keys', () {
      expect(
        normalizeMarksParts({'ga': 3, 'ka': 1, 'gha': 4, 'kha': 2}),
        [1, 2, 3, 4],
      );
    });
    test('part-N keys', () {
      expect(
        normalizeMarksParts(
            {'part-1': 1, 'part-2': 2, 'part-3': 3, 'part-4': 4}),
        [1, 2, 3, 4],
      );
    });
    test('plain list', () {
      expect(normalizeMarksParts([2, 4, 4]), [2, 4, 4]);
    });
    test('gap, null, junk and non-positive give null', () {
      expect(normalizeMarksParts({'ক': 2, 'গ': 4}), isNull);
      expect(normalizeMarksParts(null), isNull);
      expect(normalizeMarksParts('2/4/4'), isNull);
      expect(normalizeMarksParts([2, 0, 4]), isNull);
      expect(normalizeMarksParts(<String, int>{}), isNull);
      expect(normalizeMarksParts([1, 2, 3, 4, 5]), isNull);
    });
  });

  group('part order and marks', () {
    test('2/4/4 tie: id order decides খ before গ', () {
      final parts = orderedCreativeParts([
        row('pilot21-creative-003', 4),
        row('pilot21-creative-001', 2),
        row('pilot21-creative-002', 4),
      ]);
      expect(parts.map((p) => p.id).toList(), [
        'pilot21-creative-001',
        'pilot21-creative-002',
        'pilot21-creative-003',
      ]);
    });
    test('natural id order: 9 before 10', () {
      expect(compareIdsNatural('q-9', 'q-10'), lessThan(0));
      expect(compareIdsNatural('q-10', 'q-9'), greaterThan(0));
    });
    test('idOrderedParts is stable and id based', () {
      final out = idOrderedParts([row('b-2', 10), row('b-1', 10)]);
      expect(out.map((p) => p.id).toList(), ['b-1', 'b-2']);
    });
    test('row total 10 on every part shows no part mark', () {
      final parts = idOrderedParts([row('a-1', 10), row('a-2', 10)]);
      expect(creativePartMarks(parts), [null, null]);
    });
    test('own part marks are used when below the total', () {
      final parts = idOrderedParts([row('a-1', 2), row('a-2', 4)]);
      expect(creativePartMarks(parts), [2, 4]);
    });
    test('matching marks_parts wins over row marks', () {
      final parts =
          idOrderedParts([row('a-1', 10), row('a-2', 10), row('a-3', 10)]);
      expect(creativePartMarks(parts, marksParts: [2, 4, 4]), [2, 4, 4]);
    });
    test('marks_parts of a different length is not guessed', () {
      final parts = idOrderedParts([row('a-1', 10), row('a-2', 10)]);
      expect(creativePartMarks(parts, marksParts: [2, 4, 4]), [null, null]);
    });
  });
}
