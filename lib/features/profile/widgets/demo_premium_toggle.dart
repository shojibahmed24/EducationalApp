// DEMO-ONLY test control (item 7). It renders ONLY when no
// Supabase backend is configured (AppConfig.demoMode); with a
// real backend it renders nothing, and the stored value is
// ignored there anyway (BillingService.isDemoVoiceTestEnabled
// requires demoMode). It flips ONLY the local demo flag
// (SharedPreferences 'demo_premium'): the flag opens just the
// DEMO voice-gate test path in AiVoiceService — it is NOT a
// purchase, grants no real premium, and is never read by
// BillingService.isPremium(), buy(), restore() or the paywall.
// Default: OFF (the flag ships false; sign-out also clears it).
// The switch applies immediately on tap (it is a test control,
// not a Settings Save field). Never delete silently: if this
// control is ever removed, the DEMO voice-gate test path must
// be removed with it, not left gated on a hidden flag.
import 'package:flutter/material.dart';
import '../../../core/services/app_config.dart';
import '../../../core/services/local_store.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/settings_strings.dart';

class DemoPremiumToggle extends StatefulWidget {
  const DemoPremiumToggle({super.key});
  @override
  State<DemoPremiumToggle> createState() => _DemoPremiumToggleState();
}

class _DemoPremiumToggleState extends State<DemoPremiumToggle> {
  bool _on = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    LocalStore.isPremiumLocal().then((v) {
      if (!mounted) return;
      setState(() {
        _on = v;
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.demoMode) return const SizedBox.shrink();
    if (!_loaded) return const SizedBox.shrink();
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s['demoTestSection']!,
            style: Theme.of(context).textTheme.headlineMedium),
        SwitchListTile(
          title: Text(s['demoVoiceTest']!),
          subtitle: Text(s['demoVoiceTestNote']!),
          value: _on,
          onChanged: (v) async {
            await LocalStore.setPremiumLocal(v);
            if (mounted) setState(() => _on = v);
          },
        ),
      ],
    );
  }
}
