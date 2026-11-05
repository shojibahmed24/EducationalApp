// Board tile for the guide search screen (migration 018
// flag, Board revision 2026-11-02). Renders NOTHING when
// the subject has no flagged board rows: a dead tile is
// worse than no tile, and counts are never invented. The
// tile is chapter-like (same row shape as a chapter entry)
// but carries no chapter number — Board is a flag scope,
// not a chapter — and it navigates to the Board
// sub-section screen, never straight to a mixed list.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/guide_bank_service.dart';
import 'digits.dart';

class SearchFlowBoardTile extends StatelessWidget {
  const SearchFlowBoardTile({
    super.key,
    required this.subjectId,
    required this.schoolClass,
    required this.s,
    required this.bn,
  });
  final String subjectId;
  final int schoolClass;
  final Map<String, String> s;
  final bool bn;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({int total, int mcq, int creative})?>(
      future: guideBankService.fetchGuideBoard(subjectId,
          schoolClass: schoolClass),
      builder: (context, snap) {
        final board = snap.data;
        if (board == null || board.total <= 0) {
          return const SizedBox.shrink();
        }
        return Card(
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(
                '${s['boardQuestions']!} · ${numStr(board.total, bn)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(
              '/search-flow-board?subject=$subjectId&class=$schoolClass',
            ),
          ),
        );
      },
    );
  }
}
