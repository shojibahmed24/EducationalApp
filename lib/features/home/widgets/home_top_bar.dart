import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/profile_service.dart';
import '../../../l10n/language_provider.dart';
import '../../../theme/app_theme.dart';

/// Home top bar: avatar -> /profile, gear -> /settings, bell ->
/// /notifications. The gear previously pointed at /profile; fixed.
/// Greeting/class/avatar now come from the saved profile (Settings
/// edits show here); the passed-in strings are only the fallback
/// when no profile has been saved yet - never a hardcoded person.
class HomeTopBar extends StatefulWidget {
  const HomeTopBar({
    super.key,
    required this.greeting,
    required this.classChip,
  });
  final String greeting;
  final String classChip;

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  String? _name;
  int? _schoolClass;

  @override
  void initState() {
    super.initState();
    profileService.loadProfile().then((p) {
      if (!mounted || p == null) return;
      setState(() {
        final n = p['full_name'];
        if (n is String && n.isNotEmpty) _name = n;
        // Batch 2, item 3: parse via the shared profile source,
        // not `is int` — a String-stored class used to vanish
        // here while Settings still showed it.
        _schoolClass = ProfileService.parseSchoolClass(p['school_class']);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    final name = _name;
    final greeting = name == null
        ? widget.greeting
        : bn
        ? 'হ্যালো, $name'
        : 'Hello, $name';
    final classChip = _schoolClass == null
        ? widget.classChip
        : bn
        ? 'ক্লাস $_schoolClass'
        : 'Class $_schoolClass';
    final initial = name == null || name.isEmpty ? '?' : name.characters.first;
    // Phase 16 (M3): language toggle reachable from Home itself, not
    // only auth screens + Settings. Language names need no translation.
    final langCode = languageNotifier.value.languageCode;
    Widget langChip(String label, String code) {
      final active = langCode == code;
      return GestureDetector(
        onTap: () => setLanguage(code),
        child: Container(
          // J1: touch target is at least 44px tall (minHeight
          // constraint, not padding alone, so it holds at any
          // font scale).
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary,
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Chip(
                    label: Text(classChip),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.go('/notifications'),
              tooltip: 'Notifications',
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/settings'),
              tooltip: 'Settings',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(children: [langChip('বাংলা', 'bn'), langChip('English', 'en')]),
      ],
    );
  }
}
