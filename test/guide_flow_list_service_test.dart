// Step 5 guide-list service tests: server echo verification,
// old-server client fallback, honest pending/unavailable states,
// positional jump, and creative grouping in the list.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/guide_flow_list_service.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_groups.dart';

Map<String, dynamic> _row(String id, String type,
    {String? lesson, String? section, String? stimulus}) => {
      'id': id,
      'questionText': 'Q $id',
      'questionType': type,
      'options': <String>[],
      'marks': 1,
      'important': false,
      'setId': null,
      'hasKey': true,
      'guideError': false,
      'lesson': lesson,
      'section': section,
      'stimulusId': stimulus,
      'stimulusText': null,
      'hasSolution': true,
    };

final _allRows = <Map<String, dynamic>>[
  for (var i = 1; i <= 10; i++)
    _row('m$i', 'mcq', lesson: '2.1', section: 'mcq_bank'),
  for (var i = 11; i <= 25; i++)
    _row('m$i', 'mcq', lesson: '2.2', section: 'mcq_bank'),
  for (var i = 1; i <= 5; i++) _row('s$i', 'short', section: 'short'),
  for (var i = 1; i <= 3; i++)
    _row('p$i', 'problem', section: 'practice_work'),
];

/// New-server fake: applies lesson/section exactly, echoes them.
Future<Map<String, dynamic>?> _newServer(Map<String, dynamic> body,
    {String? endpoint}) async {
  final lesson = body['lesson'] as String?;
  final section = body['section'] as String?;
  final offset = (body['offset'] as num?)?.toInt() ?? 0;
  final limit = (body['limit'] as num?)?.toInt() ?? 20;
  final filtered = _allRows.where((r) {
    if (lesson != null && r['lesson'] != lesson) return false;
    if (section != null && r['section'] != section) return false;
    return true;
  }).toList();
  return {
    'found': true,
    'total': filtered.length,
    'lesson': lesson,
    'section': section,
    'questions': filtered.skip(offset).take(limit).toList(),
  };
}

/// Old-server (v7) fake: ignores lesson/section, echoes neither.
Future<Map<String, dynamic>?> _oldServer(Map<String, dynamic> body,
    {String? endpoint}) async {
  final offset = (body['offset'] as num?)?.toInt() ?? 0;
  final limit = (body['limit'] as num?)?.toInt() ?? 20;
  return {
    'found': true,
    'total': _allRows.length,
    'questions': _allRows.skip(offset).take(limit).toList(),
  };
}

Future<Map<String, dynamic>?> _pilotMissing(Map<String, dynamic> body,
    {String? endpoint}) async =>
    {'found': false, 'reason': 'pilot-columns-missing'};

Future<Map<String, dynamic>?> _unreachable(Map<String, dynamic> body,
    {String? endpoint}) async =>
    null;

void main() {
  test('new server: filtered page has exact total + hasMore', () async {
    final svc = GuideFlowListService(post: _newServer);
    final p1 = await svc.fetchPage(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq, lesson: '2.1');
    expect(p1.mode, GuideFlowMode.serverFiltered);
    expect(p1.total, 10);
    expect(p1.rows.length, 10);
    expect(p1.hasMore, isFalse);
    final all = await svc.fetchPage(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq);
    expect(all.total, 25);
    expect(all.rows.length, 20);
    expect(all.hasMore, isTrue);
    final p2 = await svc.fetchPage(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq, offset: 20);
    expect(p2.rows.length, 5);
    expect(p2.hasMore, isFalse);
  });

  test('old server: mcq falls back to client scan, total unknown',
      () async {
    final svc = GuideFlowListService(post: _oldServer);
    final p1 = await svc.fetchPage(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq);
    expect(p1.mode, GuideFlowMode.clientFiltered);
    expect(p1.total, isNull);
    expect(p1.rows.length, 20);
    expect(p1.rows.every((r) => r.questionType == 'mcq'), isTrue);
    expect(p1.hasMore, isTrue);
    final p2 = await svc.fetchPage(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq, scanOffset: p1.nextScanOffset);
    expect(p2.rows.length, 5);
    expect(p2.hasMore, isFalse);
  });

  test('old server: lesson filter and practice_work are pending, '
      'never false-empty', () async {
    final svc = GuideFlowListService(post: _oldServer);
    final lessonPage = await svc.fetchPage(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq, lesson: '2.1');
    expect(lessonPage.mode, GuideFlowMode.filterPending);
    final practicePage = await svc.fetchPage(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.practiceWork);
    expect(practicePage.mode, GuideFlowMode.filterPending);
  });

  test('pilot-columns-missing and unreachable are honest states',
      () async {
    final pending = GuideFlowListService(post: _pilotMissing);
    final p = await pending.fetchPage(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq, lesson: '2.1');
    expect(p.mode, GuideFlowMode.filterPending);
    final down = GuideFlowListService(post: _unreachable);
    final u = await down.fetchPage(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq);
    expect(u.mode, GuideFlowMode.unavailable);
  });

  test('positional jump: server and old-server client scan agree',
      () async {
    final svc = GuideFlowListService(post: _newServer);
    final hit = await svc.jumpToPosition(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq, lesson: null, position: 3);
    expect(hit.outcome, GuideFlowJumpOutcome.found);
    expect(hit.question!.id, 'm3');
    final miss = await svc.jumpToPosition(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq, lesson: null, position: 99);
    expect(miss.outcome, GuideFlowJumpOutcome.notFound);
    final old = GuideFlowListService(post: _oldServer);
    final oldHit = await old.jumpToPosition(
        subject: 'math', schoolClass: 9, chapter: 2,
        type: SearchFlowType.mcq, lesson: null, position: 22);
    expect(oldHit.outcome, GuideFlowJumpOutcome.found);
    expect(oldHit.question!.id, 'm22');
  });

  test('creative grouping in the list: one row per stimulus', () {
    GuideBankQuestion q(String id, String? stim) => GuideBankQuestion(
        id: id, questionText: 'Q $id', questionType: 'creative',
        stimulusId: stim);
    final groups = groupQuestionRows([
      (0, q('c1', 'stim-a')),
      (1, q('c2', 'stim-a')),
      (2, q('c3', 'stim-a')),
      (3, q('c4', null)),
    ]);
    expect(groups.length, 2);
    expect(groups.first.parts.length, 3);
    expect(groups.last.parts.length, 1);
  });
}
