// Set-rows screen (level 3): rows for exactly one set — a
// written model set (appendix-model-test) or a board set
// (board-mcq + board-written). Board rows group under their
// section headers; tapping a row opens the answer flow.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_first_retry_state.dart';
import 'bangla_second_row_tile.dart';
import 'search_flow_answer_nav.dart';

class _SetRowsLoaded {
  const _SetRowsLoaded({required this.rows, required this.isPremium});
  final List<GuideBankQuestion>? rows;
  final bool isPremium;
}

class BanglaSecondSetRowsScreen extends StatefulWidget {
  const BanglaSecondSetRowsScreen({
    super.key,
    required this.group,
    required this.setId,
  });
  final String group;
  final String setId;

  @override
  State<BanglaSecondSetRowsScreen> createState() =>
      _BanglaSecondSetRowsScreenState();
}

class _BanglaSecondSetRowsScreenState
    extends State<BanglaSecondSetRowsScreen> {
  late Future<_SetRowsLoaded> _future;

  String get _selfUrl =>
      '/bangla-second-set-rows?group=${widget.group}&setId=${Uri.encodeComponent(widget.setId)}';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SetRowsLoaded> _load() async {
    final sections =
        widget.group == 'board' ? ['board-mcq', 'board-written'] : ['appendix-model-test'];
    final results = await Future.wait([
      for (final section in sections)
        banglaSecondFetch.fetchSectionRows(section),
      billingService.isPremium().catchError((_) => false),
    ]);
    final rows = <GuideBankQuestion>[];
    var failed = false;
    for (var i = 0; i < sections.length; i++) {
      final part = results[i] as List<GuideBankQuestion>?;
      if (part == null) {
        failed = true;
      } else {
        rows.addAll(part.where((q) => q.setId == widget.setId));
      }
    }
    rows.sort((a, b) {
      final sa = a.section ?? '';
      final sb = b.section ?? '';
      if (sa != sb) return sa.compareTo(sb);
      return a.id.compareTo(b.id);
    });
    return _SetRowsLoaded(
        rows: failed ? null : rows,
        isPremium: results.last as bool);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaSecondStringsBn : banglaSecondStringsEn;
        final title = widget.group == 'board'
            ? widget.setId
            : '${s['modelTestsTitle']!} ${widget.setId}';
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/bangla-second-model-tests'),
            ),
            title: Text(title),
          ),
          body: FutureBuilder<_SetRowsLoaded>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final loaded = snap.data!;
              final rows = loaded.rows;
              if (rows == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              if (rows.isEmpty) {
                return Center(child: Text(s['empty']!));
              }
              final children = <Widget>[];
              String? lastSection;
              for (var i = 0; i < rows.length; i++) {
                final q = rows[i];
                if (widget.group == 'board' &&
                    q.section != lastSection) {
                  lastSection = q.section;
                  children.add(Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      lastSection ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ));
                }
                children.add(BanglaSecondRowTile(
                  q: q,
                  onTap: () => openSearchFlowGuideAnswer(
                    context,
                    isPremium: loaded.isPremium,
                    index: i,
                    q: q,
                    subjectId: 'bangla',
                    chapterNumber: 0,
                    schoolClass: BanglaSecondFetch.schoolClass,
                    returnTo: _selfUrl,
                  ),
                ));
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: children,
              );
            },
          ),
        );
      },
    );
  }
}
