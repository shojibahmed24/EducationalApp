// Batch 2, item 6: the ONE avatar widget. Settings header and
// Profile both use it, fed from the single profile source
// (profile_service keys avatar_local_path / avatar_url) — never a
// second picture copy. No picture (or a deleted/broken file) keeps
// the initial-letter avatar: the fallback is the design, not an
// error state. Local file wins over the remote URL so a fresh pick
// shows immediately, even before any upload finishes.
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.localPath,
    this.remoteUrl,
    this.radius = 40,
  });
  final String name;
  final String? localPath;
  final String? remoteUrl;
  final double radius;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _imageBroken = false;

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localPath != widget.localPath ||
        oldWidget.remoteUrl != widget.remoteUrl) {
      _imageBroken = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.isEmpty
        ? '?'
        : widget.name.characters.first.toUpperCase();
    ImageProvider? image;
    if (!_imageBroken) {
      final local = widget.localPath;
      if (local != null && local.isNotEmpty && File(local).existsSync()) {
        image = FileImage(File(local));
      } else if (widget.remoteUrl != null && widget.remoteUrl!.isNotEmpty) {
        image = NetworkImage(widget.remoteUrl!);
      }
    }
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppTheme.primary,
      backgroundImage: image,
      onBackgroundImageError: image == null
          ? null
          : (_, _) {
              if (mounted) setState(() => _imageBroken = true);
            },
      child: image == null
          ? Text(initial,
              style: TextStyle(
                fontSize: widget.radius * 0.8,
                color: Colors.white,
              ))
          : null,
    );
  }
}
