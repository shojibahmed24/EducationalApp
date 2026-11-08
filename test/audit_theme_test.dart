// Audit-fix tests (Worker A: theme/dark + learn rendering).
// Covers Bangla-digit lists, |x| preservation, fence stripping,
// dark/light theme-aware colours, the chat font-size control,
// the renderer ValueKey reset, and the smaller static chips.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/solution_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/chat_bubble.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_blocks.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_renderer.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_source_chips.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';
import 'package:yes_sir_ai/theme/app_tokens.dart';

double _lum(Color c) {
  double ch(int v) {
    final x = v / 255;
    return x <= 0.03928 ? x / 12.92 : math.pow((x + 0.055) / 1.055, 2.4) as double;
  }

  final argb = c.toARGB32();
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b);
}

double _ratio(Color a, Color b) {
  final l1 = _lum(a);
  final l2 = _lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

const _s = {
  'solutionSummary': 'সারাংশ',
  'showFullSolution': 'পুরো সমাধান দেখো',
  'showSummaryOnly': 'শুধু সারাংশ দেখো',
  'finalAnswer': 'চূড়ান্ত উত্তর',
  'marksWord': 'নম্বর',
  'whyCorrect': 'কেন সঠিক',
  'whyOthersWrong': 'কেন বাকিগুলো ভুল',
};

const _solution = StructuredSolution(
  summary: 'সারাংশের লেখা এখানে।',
  steps: [],
  finalAnswer: 'চূড়ান্ত উত্তরের লেখা এখানে।',
);

Widget _renderer(Key key) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SolutionRenderer(
            key: key,
            solution: _solution,
            sourceChips: ['বইয়ের প্রশ্ন (হুবহু)', 'AI ব্যাখ্যা (বইয়ের ভিত্তিতে)'],
            fontSize: 16,
            s: _s,
            marksPrinted: false,
            isMcq: true,
            questionText: 'মূল প্রশ্নের লেখা এখানে।',
            questionLabel: 'বইয়ের প্রশ্ন (হুবহু)',
            explanationLabel: 'AI ব্যাখ্যা (বইয়ের ভিত্তিতে)',
          ),
        ),
      ),
    );

void main() {
  test('Bangla-digit numbered lines parse as a numbered list', () {
    final blocks = parseBlocks('১. প্রথম ধাপ\n২. দ্বিতীয় ধাপ');
    expect(blocks.length, 1);
    expect(blocks[0].items, ['প্রথম ধাপ', 'দ্বিতীয় ধাপ']);
  });

  test('mixed Latin and Bangla numbered lines parse', () {
    final blocks = parseBlocks('1. এক\n২. দুই');
    expect(blocks[0].items, ['এক', 'দুই']);
  });

  test('math pipes |x| survive in a non-table line', () {
    final blocks = parseBlocks('f(x) = |x| এর মান ধনাত্মক।');
    expect(blocks[0].text, contains('|x|'));
  });

  test('a lone |x| line is kept verbatim, not split as a table', () {
    final blocks = parseBlocks('|x|\n\nপরের প্যারাগ্রাফ।');
    expect(blocks[0].text, '|x|');
    expect(blocks[1].text, 'পরের প্যারাগ্রাফ।');
  });

  test('spaced separator pipes are still dropped', () {
    final blocks = parseBlocks('ক | খ | গ');
    expect(blocks[0].text, isNot(contains('|')));
  });

  test('fence lines never reach visible text', () {
    final blocks = parseBlocks('```dart\nকোড লেখা\n```\n\nপরের লেখা।');
    for (final b in blocks) {
      expect(b.text, isNot(contains('```')));
    }
    expect(blocks.map((b) => b.text).join(' '), contains('কোড লেখা'));
  });

  test('tables still parse and consume their pipes', () {
    final blocks = parseBlocks('| a | b |\n| --- | --- |\n| x | y |');
    expect(blocks.length, 1);
    expect(blocks[0].headers, ['a', 'b']);
    expect(blocks[0].rows, [
      ['x', 'y'],
    ]);
  });

  testWidgets('table pipes and fences do not appear in visible text',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SolutionBlocks(
              text: '```\n| a | b |\n| --- | --- |\n| x | y |\n```',
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final visible = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((w) => w.text.toPlainText())
        .join('\n');
    expect(visible, contains('x'));
    expect(visible, isNot(contains('|')));
    expect(visible, isNot(contains('`')));
    expect(find.byType(Table), findsOneWidget);
  });

  testWidgets('block colour follows the theme, not forced ink',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('dark'),
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: SolutionBlocks(text: 'সাধারণ লেখা', fontSize: 16),
        ),
      ),
    );
    await tester.pump();
    final dark = tester.widget<RichText>(find.byType(RichText));
    expect(dark.text.style!.color, AppTheme.dark().colorScheme.onSurface);
    expect(dark.text.style!.color, isNot(AppTheme.ink));
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('light'),
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SolutionBlocks(text: 'সাধারণ লেখা', fontSize: 16),
        ),
      ),
    );
    await tester.pump();
    final light = tester.widget<RichText>(find.byType(RichText));
    expect(light.text.style!.color, AppTheme.ink);
  });

  testWidgets('chat bubble honours fontSize, defaulting to 15',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ChatBubble(text: 'বড় লেখা', isUser: false, fontSize: 20),
              ChatBubble(text: 'ডিফল্ট লেখা', isUser: false),
              ChatBubble(text: 'ইউজার লেখা', isUser: true, fontSize: 18),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final rich = tester.widgetList<RichText>(find.byType(RichText)).toList();
    expect(rich[0].text.style!.fontSize, 20);
    expect(rich[1].text.style!.fontSize, 15);
    final user = tester.widget<Text>(find.text('ইউজার লেখা'));
    expect(user.style!.fontSize, 18);
  });

  testWidgets('renderer state resets when its ValueKey changes',
      (tester) async {
    await tester.pumpWidget(_renderer(const ValueKey('q1')));
    await tester.pump();
    await tester.tap(find.text('বইয়ের প্রশ্ন (হুবহু)').first);
    await tester.pump();
    expect(find.text('মূল প্রশ্নের লেখা এখানে।', findRichText: true), findsOneWidget);
    await tester.pumpWidget(_renderer(const ValueKey('q2')));
    await tester.pump();
    expect(find.text('মূল প্রশ্নের লেখা এখানে।', findRichText: true), findsNothing);
    final rich = tester.widgetList<RichText>(find.byType(RichText));
    expect(
      rich.any((w) => w.text.toPlainText().contains('সারাংশের লেখা')),
      isTrue,
    );
  });

  testWidgets('static source chips are smaller and muted', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SolutionSourceChips(labels: ['বইয়ের প্রশ্ন (হুবহু)']),
        ),
      ),
    );
    await tester.pump();
    final label = tester.widget<Text>(find.text('বইয়ের প্রশ্ন (হুবহু)'));
    expect(label.style!.fontSize, 12);
  });

  test('theme contrast pairs all clear 4.5:1', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();
    expect(light.cardTheme.color, AppTheme.card);
    expect(dark.cardTheme.color, DarkPalette.surface);
    expect(
      light.textButtonTheme.style?.foregroundColor?.resolve({}),
      AppTheme.primaryDark,
    );
    expect(_ratio(AppTheme.ink, AppTheme.card), greaterThanOrEqualTo(4.5));
    expect(
      _ratio(dark.colorScheme.onSurface, dark.colorScheme.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _ratio(dark.textTheme.bodySmall!.color!, dark.scaffoldBackgroundColor),
      greaterThanOrEqualTo(4.5),
    );
    expect(_ratio(AppTheme.heroTintOn, AppTheme.heroTint),
        greaterThanOrEqualTo(4.5));
    expect(_ratio(const Color(0xFFFFFFFF), AppTheme.primaryDark),
        greaterThanOrEqualTo(4.5));
    expect(_ratio(AppTheme.primaryDark, AppTheme.paper),
        greaterThanOrEqualTo(4.5));
    expect(_ratio(const Color(0xFFFFFFFF), AppTheme.primary),
        greaterThanOrEqualTo(4.5));
  });
}
