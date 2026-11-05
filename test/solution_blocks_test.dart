// Tests for the shared block renderer: paragraph/bullet/
// numbered/heading/table parsing, no raw markdown markers in
// visible text, and explicit colours on the inline renderer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/widgets/chat_bubble.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_blocks.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_rich_text.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

const sample = '''
প্রথম প্যারাগ্রাফ, **বোল্ড** শব্দসহ।

দ্বিতীয় প্যারাগ্রাফ।

- প্রথম বুলেট
- দ্বিতীয় বুলেট

| আইটেম | বিপরীত |
| --- | --- |
| ওজন বৃদ্ধি | ওজন হ্রাস |
''';

String visibleText(WidgetTester tester) {
  final buf = StringBuffer();
  for (final e in tester.elementList(find.byType(RichText))) {
    final w = e.widget as RichText;
    buf.write(w.text.toPlainText());
    buf.write('\n');
  }
  for (final e in tester.elementList(find.byType(Text))) {
    final w = e.widget as Text;
    final d = w.data;
    if (d != null) buf.write(d);
    buf.write('\n');
  }
  return buf.toString();
}

void main() {
  test('parseBlocks splits paragraphs, bullets and a table', () {
    final blocks = parseBlocks(sample);
    expect(blocks.length, 4);
    expect(blocks[0].text, contains('প্রথম প্যারাগ্রাফ'));
    expect(blocks[1].text, contains('দ্বিতীয় প্যারাগ্রাফ'));
    expect(blocks[2].items, ['প্রথম বুলেট', 'দ্বিতীয় বুলেট']);
    expect(blocks[3].headers, ['আইটেম', 'বিপরীত']);
    expect(blocks[3].rows, [
      ['ওজন বৃদ্ধি', 'ওজন হ্রাস'],
    ]);
  });

  test('separator rows are dropped, not rendered', () {
    final blocks = parseBlocks('| a | b |\n| --- | --- |\n| x | y |');
    expect(blocks.length, 1);
    expect(blocks[0].rows, [
      ['x', 'y'],
    ]);
  });

  test('numbered lines and headings parse', () {
    final blocks = parseBlocks('# শিরোনাম\n\n1. প্রথম ধাপ\n2. দ্বিতীয় ধাপ');
    expect(blocks[0].text, 'শিরোনাম');
    expect(blocks[1].items, ['প্রথম ধাপ', 'দ্বিতীয় ধাপ']);
  });

  test('lone bold line parses as a heading', () {
    final blocks = parseBlocks('**মনে রাখার টিপস**\n\nসাধারণ লেখা।');
    expect(blocks[0].text, 'মনে রাখার টিপস');
    expect(blocks[1].text, 'সাধারণ লেখা।');
  });

  test('stray pipes in a paragraph fall back to clean text', () {
    final blocks = parseBlocks('ক | খ | গ');
    expect(blocks[0].text, isNot(contains('|')));
  });

  testWidgets('block renderer shows no raw *, ** or | in visible text',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SolutionBlocks(text: sample, fontSize: 16),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final visible = visibleText(tester);
    expect(visible, contains('বোল্ড'));
    expect(visible, contains('ওজন বৃদ্ধি'));
    expect(visible, isNot(contains('*')));
    expect(visible, isNot(contains('|')));
    expect(find.byType(Table), findsOneWidget);
  });

  testWidgets('chat AI bubble renders markdown clean, user bubble plain',
      (tester) async {
    const aiText = '| **(ক)** | ওজন বৃদ্ধি | **ওজন হ্রাস** |\n'
        '| --- | --- | --- |\n'
        '* মনে রাখার টিপস';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: const [
                ChatBubble(text: aiText, isUser: false),
                ChatBubble(text: 'আমার নিজের *লেখা* যেমন আছে', isUser: true),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final visible = visibleText(tester);
    expect(visible, contains('ওজন হ্রাস'));
    // The user bubble is plain Text and must stay exactly as typed.
    expect(find.text('আমার নিজের *লেখা* যেমন আছে'), findsOneWidget);
  });

  testWidgets('rich text carries explicit colours, theme-aware default',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SolutionRichText(text: 'সাধারণ', fontSize: 16),
              SolutionRichText(
                text: 'চূড়ান্ত',
                fontSize: 16,
                color: AppTheme.heroTintOn,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final rich = tester.widgetList<RichText>(find.byType(RichText)).toList();
    // Default (no explicit colour) now resolves to the theme's
    // onSurface, not the forced light ink — see item 2 of this round.
    expect(rich[0].text.style!.color,
        ThemeData().colorScheme.onSurface);
    expect(rich[1].text.style!.color, AppTheme.heroTintOn);
  });

  testWidgets('repeated bold text does not misplace spans',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SolutionRichText(
            text: '**একই** মাঝে **একই** শেষে',
            fontSize: 16,
          ),
        ),
      ),
    );
    await tester.pump();
    final rich = tester.widget<RichText>(find.byType(RichText));
    expect(rich.text.toPlainText(), 'একই মাঝে একই শেষে');
  });
}
