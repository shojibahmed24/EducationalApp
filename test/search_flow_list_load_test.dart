// List-load proof (2026-11-01): the guide list must LOAD
// even when the billing check never resolves. The old _load
// awaited isPremium first, so a stalled billing query left
// the list spinning forever. Now fetchPage runs immediately
// and billing resolves concurrently; a throw still lands on
// the unavailable state, never the spinner.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/guide_flow_list_service.dart';
import 'package:yes_sir_ai/features/learn/search_flow_list_screen.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';

Map<String, dynamic> _row(String id, String text) => {
  'id': id,
  'questionText': text,
  'questionType': 'mcq',
  'options': ['A', 'B', 'C', 'D'],
  'marks': 1,
  'important': false,
  'setId': null,
  'hasKey': false,
  'guideError': false,
  'lesson': null,
  'section': 'mcq_bank',
  'stimulusId': null,
  'stimulusText': null,
  'hasSolution': true,
};

Future<Map<String, dynamic>?> _fakeServer(
  Map<String, dynamic> body, {
  String? endpoint,
}) async {
  final rows = [_row('r1', 'টেস্ট প্রশ্ন এক'), _row('r2', 'টেস্ট প্রশ্ন দুই')];
  return {
    'found': true,
    'total': rows.length,
    'lesson': body['lesson'],
    'section': body['section'],
    'questions': rows,
  };
}

Widget _screen({
  required GuideFlowListService listService,
  required Future<bool> Function() premiumCheck,
}) => MaterialApp(
  home: SearchFlowListScreen(
    subjectId: 'math',
    schoolClass: 9,
    source: 'guide',
    chapterNumber: 3,
    type: SearchFlowType.mcq,
    premiumCheck: premiumCheck,
    listService: listService,
  ),
);

void main() {
  setUp(() => languageNotifier.value = const Locale('bn'));

  testWidgets('rows render while the billing check never resolves', (
    tester,
  ) async {
    var premiumInvoked = false;
    Future<bool> hanging() {
      premiumInvoked = true;
      return Completer<bool>().future;
    }

    await tester.pumpWidget(
      _screen(
        listService: GuideFlowListService(post: _fakeServer),
        premiumCheck: hanging,
      ),
    );
    await tester.pumpAndSettle();
    // The billing check started (concurrent) but never blocked.
    expect(premiumInvoked, isTrue);
    expect(find.text('টেস্ট প্রশ্ন এক'), findsOneWidget);
    expect(find.text('টেস্ট প্রশ্ন দুই'), findsOneWidget);
    expect(find.text('প্রশ্ন লোড হচ্ছে…'), findsNothing);
  });

  testWidgets('a throwing fetch lands on unavailable, not the spinner', (
    tester,
  ) async {
    Future<Map<String, dynamic>?> throwing(
      Map<String, dynamic> body, {
      String? endpoint,
    }) async {
      throw StateError('network down');
    }

    await tester.pumpWidget(
      _screen(
        listService: GuideFlowListService(post: throwing),
        premiumCheck: () async => false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('প্রশ্নের তালিকা পাওয়া যায়নি'), findsOneWidget);
    expect(find.text('প্রশ্ন লোড হচ্ছে…'), findsNothing);
  });
}
