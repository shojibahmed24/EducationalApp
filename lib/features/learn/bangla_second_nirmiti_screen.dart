// Nirmiti lesson screen (level 2): the kind's topic list with
// filter chips, then a pinned "প্রশ্ন দেখুন" button for the
// selected topic. Sub-bank chips (সব / NCTB / exam-common /
// exam) use the live mcq_group field, which nirmiti rows
// carry. The potro kind adds a division filter row (সব + the
// six divisions, by id number). Tapping "প্রশ্ন দেখুন" opens
// the existing answer flow: topic as title, model text as the
// guide answer — except onubad, which opens the passage-pinned
// group flow so the English passage stays visible (see
// bangla_second_answer_open.dart). রচনা is the UI label for
// the probondho block.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_first_retry_state.dart';
import 'bangla_second_answer_open.dart';
import 'bangla_second_potro.dart';
import 'bangla_second_row_tile.dart';
import 'bangla_second_types.dart';
import 'widgets/digits.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

const _kindTypes = <String, BanglaSecondType>{
  'onucched': BanglaSecondType.onucched,
  'potro': BanglaSecondType.chithipotro,
  'sarangsho': BanglaSecondType.sarangsho,
  'sarmormo': BanglaSecondType.sarmormo,
  'bhab': BanglaSecondType.bhab,
  'songbad': BanglaSecondType.songbad,
  'probondho': BanglaSecondType.rochona,
  'onubad': BanglaSecondType.onubad,
};

const _subChips = ['all', 'nctb', 'exam-common', 'exam'];

class _NirmitiLoaded {
  const _NirmitiLoaded({required this.rows, required this.isPremium});
  final List<GuideBankQuestion>? rows;
  final bool isPremium;
}

class BanglaSecondNirmitiScreen extends StatefulWidget {
  const BanglaSecondNirmitiScreen({super.key, required this.kind});
  final String kind;

  @override
  State<BanglaSecondNirmitiScreen> createState() =>
      _BanglaSecondNirmitiScreenState();
}

class _BanglaSecondNirmitiScreenState
    extends State<BanglaSecondNirmitiScreen> {
  late Future<_NirmitiLoaded> _future;
  String _sub = 'all';
  String _division = 'all';
  String? _selection;

  String get _selfUrl => '/bangla-second-nirmiti?kind=${widget.kind}';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NirmitiLoaded> _load() async {
    final results = await Future.wait([
      banglaSecondFetch.fetchSectionRows('nirmiti'),
      billingService.isPremium().catchError((_) => false),
    ]);
    final rows = results[0] as List<GuideBankQuestion>?;
    final filtered = rows == null
        ? null
        : (rows.where((q) => nirmitiRowMatchesKind(q.id, widget.kind)).toList()
          ..sort((a, b) => a.id.compareTo(b.id)));
    return _NirmitiLoaded(
        rows: filtered, isPremium: results[1] as bool);
  }

  bool _matches(GuideBankQuestion q) {
    if (_sub != 'all' && q.mcqGroup != _sub) return false;
    if (widget.kind == 'potro' && _division != 'all') {
      final n = parseBanglaSecondPotroNumber(q.id);
      if (n == null || potroDivisionForNumber(n) != _division) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaSecondStringsBn : banglaSecondStringsEn;
        final type = _kindTypes[widget.kind];
        final title =
            type == null ? s['title']! : banglaSecondTypeLabel(type, s);
        return ThemedScaffold(calm: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/bangla-second'),
            ),
            title: Text(title),
          ),
          body: FutureBuilder<_NirmitiLoaded>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final loaded = snap.data!;
              final rows = loaded.rows;
              if (rows == null || type == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              final shown = rows.where(_matches).toList();
              GuideBankQuestion? selected;
              for (final q in shown) {
                if (q.id == _selection) selected = q;
              }
              final selectedIndex =
                  selected == null ? -1 : shown.indexOf(selected);
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(s['filtersLabel']!,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final chip in _subChips)
                              ChoiceChip(
                                label: Text(chip == 'all'
                                    ? s['chipAll']!
                                    : chip),
                                selected: _sub == chip,
                                onSelected: (_) => setState(() {
                                  _sub = chip;
                                  _selection = null;
                                }),
                              ),
                          ],
                        ),
                        if (widget.kind == 'potro') ...[
                          const SizedBox(height: 12),
                          Text(s['divisionLabel']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(s['chipAll']!),
                                selected: _division == 'all',
                                onSelected: (_) => setState(() {
                                  _division = 'all';
                                  _selection = null;
                                }),
                              ),
                              for (final d in banglaSecondPotroDivisions)
                                ChoiceChip(
                                  label: Text(
                                      banglaSecondDivisionLabel(d.$1, s)),
                                  selected: _division == d.$1,
                                  onSelected: (_) => setState(() {
                                    _division = d.$1;
                                    _selection = null;
                                  }),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          '${numStr(shown.length, bn)}${widget.kind == 'onubad' ? s['translationsSuffix']! : s['topicsSuffix']!}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (shown.isEmpty)
                          Center(child: Text(s['empty']!))
                        else
                          for (final q in shown)
                            BanglaSecondRowTile(
                              q: q,
                              selected: _selection == q.id,
                              onTap: () =>
                                  setState(() => _selection = q.id),
                            ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selected == null
                            ? null
                            : () => openBanglaSecondNirmitiAnswer(
                                  context,
                                  kind: widget.kind,
                                  isPremium: loaded.isPremium,
                                  index: selectedIndex,
                                  q: selected!,
                                  returnTo: _selfUrl,
                                ),
                        child: Text(s['viewQuestions']!),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
