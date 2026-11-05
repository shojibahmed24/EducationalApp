// Settings section: AI provider (2026-11-04).
//
// Split out of settings_screen.dart on purpose — that file was
// already at the 250-line cap, and this section must not push
// it over. Both providers run server-side through the
// explain-question Edge Function (Mode GEN); the choice here
// only decides which provider the Edge uses. It persists
// IMMEDIATELY on tap, like language and theme — there is no
// separate Save step for it, and settings_screen's _save()
// never touches this preference.
import 'package:flutter/material.dart';

import '../../../core/services/ai_provider_service.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/settings_strings.dart';

class AiProviderSettingsSection extends StatefulWidget {
  const AiProviderSettingsSection({super.key});

  @override
  State<AiProviderSettingsSection> createState() =>
      _AiProviderSettingsSectionState();
}

class _AiProviderSettingsSectionState
    extends State<AiProviderSettingsSection> {
  // Default first, then the saved value replaces it: the radios
  // are never left without a group value while loading.
  String _provider = AiProviderService.openRouter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = await aiProviderService.load();
    if (!mounted) return;
    setState(() => _provider = provider);
  }

  Future<void> _choose(String? value) async {
    if (value == null) return;
    setState(() => _provider = value);
    await aiProviderService.save(value);
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s['aiProvider']!,
            style: Theme.of(context).textTheme.headlineMedium),
        Text(s['aiProviderSub']!,
            style: Theme.of(context).textTheme.bodySmall),
        RadioListTile<String>(
          title: Text(s['openRouter']!),
          value: AiProviderService.openRouter,
          groupValue: _provider,
          onChanged: _choose,
        ),
        RadioListTile<String>(
          title: Text(s['gemini']!),
          value: AiProviderService.gemini,
          groupValue: _provider,
          onChanged: _choose,
        ),
        Text(s['aiProviderNote']!,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
