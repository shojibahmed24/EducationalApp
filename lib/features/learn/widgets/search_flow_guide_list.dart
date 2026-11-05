// Guide portion of the new type list (Step 5). Creative rows are
// GROUPED by stimulus_id into one row per question; other types
// render one row per bank row. Grouping is per loaded page:
// set lists are group-paged by the screen (visibleSetRows), so
// their groups never split; server-paged lists keep the known
// interim limit of a group split across a page boundary.
// Practice-work lists carry the warning banner. The parent owns
// paging state and the paywall gate; this widget only renders.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/app_config.dart';
import '../../../core/services/guide_bank_service.dart';
import '../search_flow_types.dart';
import 'digits.dart';
import 'guide_creative_groups.dart';
import 'guide_question_row.dart';

// Re-exported for search_flow_list_screen (at the 250-line cap:
// it cannot add its own import for the loading shimmer, nor for
// the set slice).
export 'guide_list_loading_shimmer.dart';
export '../search_flow_set_slice.dart';

class SearchFlowGuideListView extends StatelessWidget {
  const SearchFlowGuideListView({
    super.key,
    required this.rows,
    required this.total,
    required this.hasMore,
    required this.isPremium,
    required this.subjectId,
    required this.chapterNumber,
    required this.type,
    required this.bn,
    required this.s,
    required this.gs,
    required this.onOpen,
    this.onOpenGroup,
    required this.onLoadMore,
  });
  final List<GuideBankQuestion> rows;
  final int? total;
  final bool hasMore;
  final bool isPremium;
  final String subjectId;
  final int chapterNumber;
  final SearchFlowType type;
  final bool bn;

  /// search_flow strings (Bn or En).
  final Map<String, String> s;

  /// guide_bank strings (Bn or En) for GuideQuestionRow.
  final Map<String, String> gs;
  final void Function(int index, GuideBankQuestion q) onOpen;

  /// Step 7 (Fix A): creative group tap. Null = fall back to
  /// the single-question onOpen for the first part. Args: the
  /// first part's list index (paywall gate), ALL currently
  /// loaded parts of the stimulus, and the stimulus text.
  final void Function(
    int firstIndex,
    List<GuideBankQuestion> parts,
    String stimulusText,
  )?
  onOpenGroup;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final entries = [for (var i = 0; i < rows.length; i++) (i, rows[i])];
    final groups = type == SearchFlowType.creative
        ? groupQuestionRows(entries)
        : [
            for (final e in entries) GroupedRows(stimulusId: null, parts: [e]),
          ];
    final showing = total != null
        ? s['showingTotal']!
              .replaceAll('{total}', numStr(total!, bn))
              .replaceAll('{shown}', numStr(rows.length, bn))
        : s['showingOf']!.replaceAll('{shown}', numStr(rows.length, bn));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (type == SearchFlowType.practiceWork)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(s['practiceWorkWarning']!),
            ),
          ),
        Text(showing),
        const SizedBox(height: 8),
        for (final g in groups) ...[
          if (g.stimulusId != null && g.parts.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s['groupParts']!.replaceAll('{n}', numStr(g.parts.length, bn)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          // Step 7 (Fix A): a creative group opens worker E's
          // grouped view with ALL currently loaded parts; any
          // other row keeps the single-question path. Known
          // limit kept, not hidden (server-paged lists only;
          // set lists page by whole groups): a group split
          // across a 20-row page boundary still renders as two
          // groups until the next page loads (grouping above
          // runs over all loaded rows, so loading more merges
          // them); tapping the first half before that opens
          // only that half — groups are never merged across
          // rows that have not been loaded, so no wrong
          // group can be assembled.
          GuideQuestionRow(
            question: g.parts.first.$2,
            locked: !guideBankService.isUnlocked(
              isPremium: isPremium,
              index: g.parts.first.$1,
              freeLimit: AppConfig.freeGuideLimit,
            ),
            s: gs,
            subjectId: subjectId,
            chapterNumber: chapterNumber,
            onTap: () {
              final openGroup = onOpenGroup;
              if (type == SearchFlowType.creative &&
                  g.stimulusId != null &&
                  openGroup != null) {
                openGroup(g.parts.first.$1, [
                  for (final p in g.parts) p.$2,
                ], g.parts.first.$2.stimulusText ?? '');
              } else {
                onOpen(g.parts.first.$1, g.parts.first.$2);
              }
            },
          ),
        ],
        if (hasMore) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onLoadMore, child: Text(s['loadMore']!)),
        ],
      ],
    );
  }
}
