// Type dropdown with counts: label + exact count in guide mode,
// plain labels otherwise, unknown count never shown.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/guide_flow_count_service.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';
import 'package:yes_sir_ai/features/learn/widgets/search_flow_type_field.dart';

const _s = {
  'typeLabel': 'ধরন',
  'typeMcq': 'এমসিকিউ',
  'typeShort': 'সংক্ষিপ্ত',
  'typeCreative': 'সৃজনশীল',
  'typePracticeWork': 'অনুশীলনীমূলক কাজ',
  'typeTextbookExercise': 'পাঠ্যবইয়ের অনুশীলনী',
};

Widget _host(GuideFlowCountService svc,
        {required bool guide, int? chapter}) =>
    MaterialApp(
      home: Scaffold(
        body: SearchFlowTypeField(
          value: SearchFlowType.creative,
          onChanged: (_) {},
          s: _s,
          bn: true,
          guide: guide,
          subject: 'math',
          schoolClass: 9,
          chapter: chapter,
          lesson: null,
          service: svc,
        ),
      ),
    );

GuideFlowCountService _svc(Map<String, int?> bySection) =>
    GuideFlowCountService(post: (b, {endpoint}) async {
      final n = bySection[b['section']];
      if (n == null) return null;
      return {
        'found': true,
        'total': n,
        'lesson': b['lesson'],
        'section': b['section'],
      };
    });

void main() {
  testWidgets('guide + chapter: selected type shows its exact count',
      (tester) async {
    await tester.pumpWidget(_host(
        _svc({'creative': 50, 'mcq_bank': 12}),
        guide: true, chapter: 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('সৃজনশীল · ৫০'), findsOneWidget);
  });

  testWidgets('no chapter: plain label, no service call', (tester) async {
    var calls = 0;
    final svc = GuideFlowCountService(post: (b, {endpoint}) async {
      calls++;
      return null;
    });
    await tester.pumpWidget(_host(svc, guide: true, chapter: null));
    await tester.pumpAndSettle();
    expect(find.text('সৃজনশীল'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('textbook source: plain label, no service call',
      (tester) async {
    var calls = 0;
    final svc = GuideFlowCountService(post: (b, {endpoint}) async {
      calls++;
      return null;
    });
    await tester.pumpWidget(_host(svc, guide: false, chapter: 3));
    await tester.pumpAndSettle();
    expect(find.text('সৃজনশীল'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('unknown count (old server) keeps the plain label',
      (tester) async {
    await tester.pumpWidget(_host(_svc({}), guide: true, chapter: 3));
    await tester.pumpAndSettle();
    expect(find.text('সৃজনশীল'), findsOneWidget);
  });

  testWidgets('zero is shown as ০, not hidden', (tester) async {
    await tester.pumpWidget(
        _host(_svc({'creative': 0}), guide: true, chapter: 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('সৃজনশীল · ০'), findsOneWidget);
  });
}
