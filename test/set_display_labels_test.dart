// Set display labels: one rule for every subject. Raw ids are
// never titles; embedded numbers are used (normalized, no zero
// padding); numberless ids fall back to the displayed position;
// Bengali ids pass through; unknown tokens show as-is.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/set_display_labels.dart';

void main() {
  group('board sets, Bengali mode', () {
    test('single board + set letter + MCQ', () {
      expect(
        setDisplayTitle('ict-board-barishal-2023-set-kha-mcq', true, 1),
        'বরিশাল বোর্ড ২০২৩ · সেট খ · MCQ',
      );
    });
    test('single board + numeric set + creative', () {
      expect(
        setDisplayTitle('bio-board-dhaka-2023-set-03-creative', true, 1),
        'ঢাকা বোর্ড ২০২৩ · সেট ৩ · সৃজনশীল',
      );
    });
    test('river-only creative set', () {
      expect(
        setDisplayTitle(
          'che-board-barishal-2023-set-kirtonkhola-creative',
          true,
          1,
        ),
        'বরিশাল বোর্ড ২০২৩ · কীর্তনখোলা · সৃজনশীল',
      );
    });
    test('numeric set + river + creative', () {
      expect(
        setDisplayTitle(
          'phy-board-barishal-2024-set-03-ichhamati-creative',
          true,
          1,
        ),
        'বরিশাল বোর্ড ২০২৪ · সেট ৩ · ইছামতী · সৃজনশীল',
      );
    });
    test('multi-board set counts boards, not names', () {
      expect(
        setDisplayTitle(
          'ict-board-dhaka-rajshahi-cumilla-chattogram-sylhet-barishal-dinajpur-2019-set-kha-mcq',
          true,
          1,
        ),
        '৭ বোর্ড ২০১৯ · সেট খ · MCQ',
      );
    });
    test('all-board set', () {
      expect(
        setDisplayTitle('ict-board-all-2020-set-ka-mcq', true, 1),
        'সকল বোর্ড ২০২০ · সেট ক · MCQ',
      );
    });
    test('jessore and jashore both map to যশোর', () {
      expect(
        setDisplayTitle('bio-board-jessore-2023-set-03-mcq', true, 1),
        'যশোর বোর্ড ২০২৩ · সেট ৩ · MCQ',
      );
      expect(
        setDisplayTitle('bio-board-jashore-2024-set-01-mcq', true, 1),
        'যশোর বোর্ড ২০২৪ · সেট ১ · MCQ',
      );
    });
    test('single + noset', () {
      expect(
        setDisplayTitle('che-board-dhaka-2024-set-single-mcq', true, 1),
        'ঢাকা বোর্ড ২০২৪ · একক সেট · MCQ',
      );
      expect(
        setDisplayTitle('che-board-dhaka-2024-set-noset-mcq', true, 1),
        'ঢাকা বোর্ড ২০২৪ · MCQ',
      );
    });
    test('unknown board token shows as-is, never invented', () {
      expect(
        setDisplayTitle('ict-board-unknownboard-2023-set-kha-mcq', true, 1),
        'unknownboard বোর্ড ২০২৩ · সেট খ · MCQ',
      );
    });
    test('unknown river token (kaibarta) shows as-is', () {
      expect(
        setDisplayTitle('che-board-dhaka-2023-set-kaibarta-creative', true, 1),
        'ঢাকা বোর্ড ২০২৩ · kaibarta · সৃজনশীল',
      );
    });
  });

  group('chapter + special + numbered models', () {
    test('bare chapter model', () {
      expect(setDisplayTitle('bio-ch1-model', true, 1), 'অধ্যায় ১ মডেল টেস্ট');
    });
    test('numbered chapter model', () {
      expect(
        setDisplayTitle('ict-ch2-model-2', true, 1),
        'অধ্যায় ২ মডেল টেস্ট ২',
      );
    });
    test('chapter model with MCQ / written kind', () {
      expect(
        setDisplayTitle('bio-ch11-model-mcq', true, 1),
        'অধ্যায় ১১ মডেল টেস্ট · MCQ',
      );
      expect(
        setDisplayTitle('bio-ch11-model-written', true, 1),
        'অধ্যায় ১১ মডেল টেস্ট · লিখিত',
      );
    });
    test('special model uses its embedded number', () {
      expect(
        setDisplayTitle('ict-special-model-01', true, 1),
        'বিশেষ মডেল টেস্ট ১',
      );
    });
    test('model-N uses its embedded number, not position', () {
      expect(setDisplayTitle('model-10', true, 2), 'মডেল টেস্ট ১০');
    });
    test('bare model-test has no number', () {
      expect(setDisplayTitle('model-test', true, 1), 'মডেল টেস্ট');
    });
    test('model-test-N', () {
      expect(setDisplayTitle('model-test-01', true, 1), 'মডেল টেস্ট ১');
    });
    test('paper2 keeps the Paper-II mark', () {
      expect(setDisplayTitle('paper2-100', true, 1), 'Paper-II মডেল টেস্ট ১০০');
    });
  });

  group('Bangla 1st + passthrough + fallback', () {
    test('ban1 lesson models number by displayed position', () {
      expect(
        setDisplayTitle('ban1-goddo-amar-bari-model-creative', true, 3),
        'মডেল টেস্ট ৩',
      );
    });
    test('ban1 slug extraction handles the -set suffix quirk', () {
      expect(
        ban1LessonSlug('ban1-poddo-seidin-ei-math-model-creative-set'),
        'seidin-ei-math',
      );
      expect(ban1LessonSlug('ban1-goddo-amar-bari-model-mcq'), 'amar-bari');
      expect(ban1LessonSlug('ict-board-dhaka-2023-set-kha-mcq'), isNull);
    });
    test('already-Bengali ids pass through unchanged', () {
      expect(setDisplayTitle('ঢাকা বোর্ড ২০২৪', true, 1), 'ঢাকা বোর্ড ২০২৪');
    });
    test('unknown id falls back to position serial', () {
      expect(setDisplayTitle('something-unexpected', true, 5), 'মডেল টেস্ট ৫');
    });
  });

  group('English mode', () {
    test('board set romanized, set letter kept', () {
      expect(
        setDisplayTitle('ict-board-barishal-2023-set-kha-mcq', false, 1),
        'Barishal Board 2023 · Set kha · MCQ',
      );
    });
    test('model + chapter model romanized', () {
      expect(setDisplayTitle('model-10', false, 2), 'Model Test 10');
      expect(
        setDisplayTitle('bio-ch11-model-written', false, 1),
        'Chapter 11 Model Test · Written',
      );
    });
    test('paper2 in English mode', () {
      expect(
        setDisplayTitle('paper2-100', false, 1),
        'Paper-II Model Test 100',
      );
    });
  });
}
