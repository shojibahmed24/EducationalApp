// Route: /settings — ONLY place where class can be changed.
// Language, font, theme, notifications and profile edits persist
// here and apply LIVE app-wide. Sepia falls back to light.
// No bKash anywhere: premium is Google Play Billing only.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/profile_service.dart';
import 'widgets/ai_provider_settings_section.dart';
import 'widgets/demo_premium_toggle.dart';
import 'widgets/settings_profile_header.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/settings_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_mode.dart';
import '../../theme/themed_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _font = 'normal';
  String _theme = 'day';
  bool _daily = true, _tests = true, _streak = true;
  // Phase 16 (M5): NO invented defaults. Null class / empty goal mean
  // "not chosen yet"; Save must never write Class 10 / 30 min unchosen.
  String? _cls;
  late final _name = TextEditingController();
  late final _school = TextEditingController();
  late final _goal = TextEditingController();
  late final _guardianName = TextEditingController(), _guardianPhone = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await profileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _daily = prefs.getBool('ys_notif_daily') ?? true;
      _tests = prefs.getBool('ys_notif_tests') ?? true;
      _streak = prefs.getBool('ys_notif_streak') ?? true;
      _theme = prefs.getString('ys_theme') ?? 'day';
      final scale = prefs.getDouble('ys_font_scale') ?? 1.0;
      _font = scale < 1.0 ? 'small' : scale > 1.0 ? 'large' : 'normal';
      if (profile != null) {
        _name.text = (profile['full_name'] as String?) ?? '';
        _school.text = (profile['school_name'] as String?) ?? '';
        _guardianName.text = (profile['guardian_name'] as String?) ?? ''; _guardianPhone.text = (profile['guardian_phone'] as String?) ?? '';
        final goal = profile['daily_goal_minutes'];
        if (goal != null) _goal.text = '$goal';
        // Batch 2, item 3: shared class parser — the same source
        // Home reads, so a String/double-stored class cannot show
        // here while vanishing on Home (or vice versa).
        final cls = ProfileService.parseSchoolClass(profile['school_class']);
        if (cls != null) _cls = '$cls';
      }
      _loaded = true;
    });
  }

  double _scaleFor(String font) =>
      font == 'small' ? 0.85 : font == 'large' ? 1.25 : 1.0;

  Future<void> _save() async {
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    // Phase 16 (M5): empty goal / no class = null = "not chosen";
    // updateProfileFields leaves a null field untouched, so Save
    // writes no default the user never chose.
    final goal = int.tryParse(_goal.text.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ys_notif_daily', _daily);
    await prefs.setBool('ys_notif_tests', _tests);
    await prefs.setBool('ys_notif_streak', _streak);
    persistTheme(_theme);
    persistFontScale(_scaleFor(_font));
    final ok = await profileService.updateProfileFields(
      fullName: _name.text.trim(),
      schoolName: _school.text.trim(),
      dailyGoalMinutes: goal,
      schoolClass: _cls == null ? null : int.tryParse(_cls!),
      guardianName: _guardianName.text.trim(),
      guardianPhone: _guardianPhone.text.trim(),
    );
    if (!mounted) return;
    // Local copy is always saved; ok=false only means the Supabase
    // cloud upsert failed, and the local copy still holds the edit.
    // The header refreshes itself from the profile notifier on Save.
    if (!ok) debugPrint('Settings: Supabase upsert failed, local kept');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s['saved']!)),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _school.dispose();
    _goal.dispose();
    _guardianName.dispose(); _guardianPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    final fontSize = _font == 'small' ? 13.0 : _font == 'large' ? 19.0 : 15.0;
    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        title: Text(s['title']!),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Batch 2, item 6: header reads the SAVED name and
                // picture from the single profile source itself.
                SettingsProfileHeader(
                  classText: _cls == null
                      ? s['notChosen']!
                      : '${s['classLabel']} $_cls',
                ),
                const SizedBox(height: 16),
                Text(s['language']!,
                    style: Theme.of(context).textTheme.headlineMedium),
                Text(s['languageSub']!,
                    style: Theme.of(context).textTheme.bodySmall),
                RadioListTile<String>(
                    title: Text(s['bangla']!),
                    value: 'bn',
                    groupValue: languageNotifier.value.languageCode,
                    onChanged: (v) { if (v != null) setLanguage(v); setState(() {}); }),
                RadioListTile<String>(
                    title: Text(s['english']!),
                    value: 'en',
                    groupValue: languageNotifier.value.languageCode,
                    onChanged: (v) { if (v != null) setLanguage(v); setState(() {}); }),
                const SizedBox(height: 16),
                Text(s['fontSize']!,
                    style: Theme.of(context).textTheme.headlineMedium),
                Text(s['fontSizeSub']!,
                    style: Theme.of(context).textTheme.bodySmall),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'small', label: Text(s['small']!)),
                    ButtonSegment(value: 'normal', label: Text(s['normal']!)),
                    ButtonSegment(value: 'large', label: Text(s['large']!)),
                  ],
                  selected: {_font},
                  // Phase 16 (M4): font persists IMMEDIATELY, like
                  // language — no lost-on-exit trap if Save is skipped.
                  onSelectionChanged: (v) { setState(() => _font = v.first); fontScaleNotifier.value = _scaleFor(v.first); persistFontScale(_scaleFor(v.first)); },
                ),
                const SizedBox(height: 12),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(s['preview']!,
                            style:
                                TextStyle(fontSize: fontSize, height: 1.7)))),
                const SizedBox(height: 16),
                Text(s['theme']!,
                    style: Theme.of(context).textTheme.headlineMedium),
                Text(s['themeSub']!,
                    style: Theme.of(context).textTheme.bodySmall),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'day', label: Text(s['day']!)),
                    ButtonSegment(value: 'night', label: Text(s['night']!)),
                    ButtonSegment(value: 'sepia', label: Text(s['sepia']!)),
                  ],
                  selected: {_theme},
                  // Phase 16 (M4): theme persists IMMEDIATELY too.
                  onSelectionChanged: (v) { setState(() => _theme = v.first); themeModeNotifier.value = v.first == 'night' ? ThemeMode.dark : ThemeMode.light; persistTheme(v.first); },
                ),
                if (_theme == 'sepia') ...[
                  const SizedBox(height: 8),
                  Text(s['sepiaNote']!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 16),
                Text(s['notifications']!,
                    style: Theme.of(context).textTheme.headlineMedium),
                SwitchListTile(
                    title: Text(s['dailyReminder']!),
                    subtitle: Text(s['reminderTime']!),
                    value: _daily,
                    onChanged: (v) => setState(() => _daily = v)),
                SwitchListTile(
                    title: Text(s['testUpdates']!),
                    value: _tests,
                    onChanged: (v) => setState(() => _tests = v)),
                SwitchListTile(
                    title: Text(s['streakAlert']!),
                    value: _streak,
                    onChanged: (v) => setState(() => _streak = v)),
                // Phase 16 (M8): honest label — these toggles save a
                // preference but control no real push/local notification
                // yet, because no notification scheduling exists.
                Text(s['notifNote']!,
                    style: Theme.of(context).textTheme.bodySmall),
                const AiProviderSettingsSection(),
                const SizedBox(height: 16),
                Text(s['classSection']!,
                    style: Theme.of(context).textTheme.headlineMedium),
                Text(s['classSub']!,
                    style: Theme.of(context).textTheme.bodySmall),
                DropdownButton<String>(
                  value: _cls,
                  hint: Text(s['selectClass']!),
                  isExpanded: true,
                  items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                      .map((c) => DropdownMenuItem(value: c, child: Text('${s['classLabel']} $c')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _cls = v);
                  },
                ),
                const SizedBox(height: 16),
                TextField(controller: _name, decoration: InputDecoration(labelText: s['editName']!)),
                const SizedBox(height: 12),
                TextField(controller: _school, decoration: InputDecoration(labelText: s['editSchool']!)),
                const SizedBox(height: 12),
                TextField(controller: _goal, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: s['editGoal']!)),
                const SizedBox(height: 12),
                TextField(controller: _guardianName, decoration: InputDecoration(labelText: s['editGuardianName']!)),
                const SizedBox(height: 12),
                TextField(controller: _guardianPhone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s['editGuardianPhone']!)),
                const SizedBox(height: 16),
                const DemoPremiumToggle(),
                const SizedBox(height: 16),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white), onPressed: _save, child: Text(s['save']!)),
              ],
            ),
    );
  }
}
