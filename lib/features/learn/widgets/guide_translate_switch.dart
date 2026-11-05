// Translator switch for the shared guide answer screen
// (2026-11-03). Same preference as the reader switch
// (english_reader_translate_bangla): one translator state
// for all of Paper-I. Owns its persisted state and keeps
// the service's enabledNotifier in sync, so translated
// fields below rebuild without the screen owning switch
// state. The caller shows it only for English; other
// subjects never see it.
import 'package:flutter/material.dart';

import '../../../core/services/english_translation_service.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/english_search_flow_strings.dart';

class GuideTranslateSwitch extends StatefulWidget {
  const GuideTranslateSwitch({super.key, this.service});

  /// Injectable in tests; defaults to the shared singleton.
  final EnglishTranslationService? service;

  @override
  State<GuideTranslateSwitch> createState() => _GuideTranslateSwitchState();
}

class _GuideTranslateSwitchState extends State<GuideTranslateSwitch> {
  bool _enabled = false;

  EnglishTranslationService get _svc =>
      widget.service ?? englishTranslationService;

  @override
  void initState() {
    super.initState();
    _svc.loadEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bn = languageNotifier.value.languageCode == 'bn';
    final es = bn ? englishSearchFlowStringsBn : englishSearchFlowStringsEn;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(es['readerTranslate']!),
        Switch(
          value: _enabled,
          onChanged: (v) async {
            setState(() => _enabled = v);
            await _svc.setEnabled(v);
          },
        ),
      ],
    );
  }
}
