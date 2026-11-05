// Batch 2, item 6: Settings header + change-picture control.
// It reads the SAVED profile from the single source itself
// (profileService.loadProfile + profileNotifier), so the name and
// picture here update the moment a Save or a picture pick lands —
// never the edit-field draft, never a second stored copy. Typing a
// new name does not pretend it is saved; the Save button still owns
// name edits, while a picture pick saves immediately (local copy +
// best-effort Supabase upload via profile_picture_service).
// Picker cancel does nothing; permission denial and picker/storage
// failure show a message and never crash.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/profile_picture_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/profile_source.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/settings_strings.dart';
import 'profile_avatar.dart';

class SettingsProfileHeader extends StatefulWidget {
  const SettingsProfileHeader({super.key, required this.classText});
  final String classText;

  @override
  State<SettingsProfileHeader> createState() => _SettingsProfileHeaderState();
}

class _SettingsProfileHeaderState extends State<SettingsProfileHeader> {
  Map<String, dynamic>? _profile;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    profileNotifier.addListener(_onProfileChanged);
    profileService.loadProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    });
  }

  void _onProfileChanged() {
    if (mounted) setState(() => _profile = profileNotifier.value);
  }

  @override
  void dispose() {
    profileNotifier.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await profilePictureService.pickAndSave(source);
    if (!mounted) return;
    setState(() => _busy = false);
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    switch (result.outcome) {
      case PictureOutcome.cancelled:
        break;
      case PictureOutcome.denied:
        _snack(s['pictureDenied']!);
      case PictureOutcome.unavailable:
        _snack(s['pictureUnavailable']!);
      case PictureOutcome.picked:
        // Notifier already refreshed _profile; just report honestly:
        // uploaded=true only when Storage really accepted the file.
        _snack(result.uploaded
            ? s['pictureSaved']!
            : s['pictureSavedLocal']!);
    }
  }

  Future<void> _chooseSource() async {
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(s['pictureGallery']!),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(s['pictureCamera']!),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) _pick(source);
  }

  Future<void> _remove() async {
    if (_busy) return;
    setState(() => _busy = true);
    await profilePictureService.removePicture();
    if (!mounted) return;
    setState(() => _busy = false);
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    _snack(s['pictureRemoved']!);
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    final name = ProfileFields.name(_profile);
    final localPath = ProfileFields.localPicture(_profile);
    final remoteUrl = ProfileFields.remotePicture(_profile);
    final hasPicture = (localPath != null && localPath.isNotEmpty) ||
        (remoteUrl != null && remoteUrl.isNotEmpty);
    // Honest DEMO/upload-failed note: a picture with no remote URL
    // lives on this device only.
    final note =
        hasPicture && remoteUrl == null ? s['pictureLocalOnlyNote']! : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ProfileAvatar(
              name: name,
              localPath: localPath,
              remoteUrl: remoteUrl,
              radius: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? s['student']! : name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text(widget.classText,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _busy ? null : _chooseSource,
              icon: const Icon(Icons.camera_alt, size: 18),
              label:
                  Text(_busy ? s['pictureSaving']! : s['changePicture']!),
            ),
            if (hasPicture)
              TextButton(
                onPressed: _busy ? null : _remove,
                child: Text(s['removePicture']!),
              ),
          ],
        ),
        if (note != null)
          Text(note, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
