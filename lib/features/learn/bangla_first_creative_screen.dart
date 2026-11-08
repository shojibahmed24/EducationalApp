// Creative group list: one lesson's lesson-creative rows, or one
// model-creative set's rows (set mode). Lesson creative only:
// bank creative (answers not printed) never appears here from a
// lesson open. Tapping a group opens the group detail screen:
// stimulus pinned, part chips to jump, prev/next below.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/bangla_first_fetch.dart';
import '../../core/services/model_test_set_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_first_strings.dart';
import 'bangla_creative_grouping.dart';
import 'bangla_first_retry_state.dart';
import 'widgets/guide_creative_parts.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class BanglaFirstCreativeScreen extends StatefulWidget {
  const BanglaFirstCreativeScreen({
    super.key,
    required this.section,
    required this.lessonTitle,
    this.setId,
    this.setTitle,
  });
  final String section;
  final String lessonTitle;
  final String? setId;
  final String? setTitle;

  @override
  State<BanglaFirstCreativeScreen> createState() =>
      _BanglaFirstCreativeScreenState();
}

class _BanglaFirstCreativeScreenState
    extends State<BanglaFirstCreativeScreen> {
  late Future<List<BanglaCreativeGroup>?> _future;

  bool get _isSet => widget.setId != null;

  String get _selfUrl => _isSet
      ? '/bangla-first-creative-set?setId=${widget.setId}&section=${widget.section}'
      : '/bangla-first-creative?section=${widget.section}&lesson=${Uri.encodeComponent(widget.lessonTitle)}';

  String get _backUrl => _isSet
      ? '/bangla-first-model-tests?section=${widget.section}'
      : '/bangla-first-lesson?section=${widget.section}&lesson=${Uri.encodeComponent(widget.lessonTitle)}';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<BanglaCreativeGroup>?> _load() async {
    final rows = _isSet
        ? await modelTestSetService
            .fetchSetRows('bangla', widget.setId!,
                schoolClass: BanglaFirstFetch.schoolClass)
            .catchError((_) => null)
        : await banglaFirstFetch.fetchLessonRows(
            lesson: widget.lessonTitle, section: 'creative');
    if (rows == null) return null;
    return groupBanglaCreative(rows);
  }

  String _groupTitle(BanglaCreativeGroup g, Map<String, String> s) {
    final stim = g.stimulusText.trim();
    final preview = stim.length > 120 ? '${stim.substring(0, 120)}…' : stim;
    final letters = orderedCreativeParts(g.parts)
        .asMap()
        .entries
        .map((e) => creativePartLabel(e.key))
        .join(', ');
    final suffix = '$letters (${g.parts.length} ${s['partsSuffix']!})';
    return preview.isEmpty ? suffix : '$preview\n$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaFirstStringsBn : banglaFirstStringsEn;
        return ThemedScaffold(calm: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(_backUrl),
            ),
            title: Text(widget.setTitle ?? s['creativeTitle']!),
          ),
          body: FutureBuilder<List<BanglaCreativeGroup>?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Center(child: Text(s['loading']!));
              }
              final groups = snap.data;
              if (groups == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              if (groups.isEmpty) {
                return Center(child: Text(s['creativeEmpty']!));
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final g in groups)
                    Card(
                      child: ListTile(
                        title: Text(_groupTitle(g, s)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(
                          '/bangla-first-creative-group',
                          extra: {
                            'parts': g.parts,
                            'stimulusText': g.stimulusText,
                            'returnTo': _selfUrl,
                          },
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
