// Shared menu tile for profile-group screens. No navigation logic here
// beyond the onTap passed in by the calling screen.
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap, this.accent});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    // UI palette (গ): the leading icon sits in a tinted chip.
    final chip = accent ?? AppTheme.primary;
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: chip.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: chip),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
