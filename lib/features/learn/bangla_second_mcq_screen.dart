// MCQ lesson screen (level 2): পরিচ্ছেদ cards from the bank
// section + নিজেকে যাচাই করি set cards from the assessment
// section. Filter chips (সব / NCTB / exam-common / exam) use
// the live mcq_group field, which bank rows carry (assessment
// rows carry none, so their cards always show). Tapping a card
// opens the questions screen for exactly that section — only
// that section's MCQs, never mixed with other sections.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_first_retry_state.dart';
import 'bangla_second_chapter_titles.dart';
import 'bangla_second_types.dart';
import 'widgets/digits.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

const _chips = ['all', 'nctb', 'exam-common', 'exam'];

class _McqLoaded {
  const _McqLoaded(
      {required this.bank, required this.assessment, required this.isPremium});
  final List<GuideBankQuestion>? bank;
  final List<GuideBankQuestion>? assessment;
  final bool isPremium;
}

class BanglaSecondMcqScreen extends StatefulWidget {
  const BanglaSecondMcqScreen({super.key});

  @override
  State<BanglaSecondMcqScreen> createState() =>
      _BanglaSecondMcqScreenState();
}

class _BanglaSecondMcqScreenState extends State<BanglaSecondMcqScreen> {
  late Future<_McqLoaded> _future;
  String _chip = 'all';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_McqLoaded> _load() async {
    final results = await Future.wait([
      banglaSecondFetch.fetchSectionRows('bank'),
      banglaSecondFetch.fetchSectionRows('byakoron-assessment'),
      billingService.isPremium().catchError((_) => false),
    ]);
    return _McqLoaded(
      bank: results[0] as List<GuideBankQuestion>?,
      assessment: results[1] as List<GuideBankQuestion>?,
      isPremium: results[2] as bool,
    );
  }

  bool _matchesChip(GuideBankQuestion q) =>
      _chip == 'all' || q.mcqGroup == _chip;

  String _chipLabel(String chip, Map<String, String> s) =>
      chip == 'all' ? s['chipAll']! : chip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaSecondStringsBn : banglaSecondStringsEn;
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/bangla-second'),
            ),
            title: Text(s['typeMcq']!),
          ),
          body: FutureBuilder<_McqLoaded>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final loaded = snap.data!;
              final bank = loaded.bank;
              final assessment = loaded.assessment;
              if (bank == null || assessment == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              final chapters = groupBanglaSecondRows<GuideBankQuestion, int?>(
                  bank, (q) => parseBanglaSecondChapter(q.id));
              final numbers = chapters.keys
                  .whereType<int>()
                  .toList()
                ..sort();
              final extras = chapters[null] ?? [];
              final extraShown =
                  _chip == 'all' || extras.any(_matchesChip);
              final sets = groupBanglaSecondRows<GuideBankQuestion, String?>(
                  assessment, (q) => q.setId);
              final setIds = sets.keys.whereType<String>().toList()..sort();
              Widget card({
                required String key,
                required String title,
                required String subtitle,
              }) {
                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(
                        '/bangla-second-mcq-questions?group=$key&sub=$_chip'),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(s['filtersLabel']!,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final chip in _chips)
                        ChoiceChip(
                          label: Text(_chipLabel(chip, s)),
                          selected: _chip == chip,
                          onSelected: (_) =>
                              setState(() => _chip = chip),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final n in numbers)
                    Builder(builder: (_) {
                      final rows =
                          chapters[n]!.where(_matchesChip).toList();
                      if (rows.isEmpty) return const SizedBox.shrink();
                      return card(
                        key: 'ch$n',
                        title:
                            '${s['chapterPrefix']!} ${numStr(n, bn)}: ${banglaSecondChapterTitles[n]!}',
                        subtitle:
                            '${numStr(rows.length, bn)}${s['questionsSuffix']!}',
                      );
                    }),
                  if (extraShown)
                    card(
                      key: 'extra',
                      title: s['extraGroup']!,
                      subtitle:
                          '${numStr(_chip == 'all' ? extras.length : extras.where(_matchesChip).length, bn)}${s['questionsSuffix']!}',
                    ),
                  const SizedBox(height: 16),
                  Text(s['assessmentGroup']!,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final setId in setIds)
                    card(
                      key: 'set:$setId',
                      title: setId,
                      subtitle:
                          '${numStr(sets[setId]!.length, bn)}${s['questionsSuffix']!}',
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
