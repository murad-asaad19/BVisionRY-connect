import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../data/avatar_upload_service.dart';

/// Round avatar + edit-pencil overlay used inside the Profile-edit form.
///
/// Tap opens a bottom-sheet of source options — take a photo (camera),
/// choose from the gallery, and (when a photo is set) remove the current
/// one. Capture / gallery routes invoke [AvatarUploadService.pickAndUpload]
/// (which runs the full pick → crop → compress → upload → cache-bust
/// pipeline); the new cache-busted URL is yielded via [onUploaded]. Remove
/// clears `photo_url` via [AvatarUploadService.removeAvatar] and notifies
/// [onRemoved] so the parent form drops its local `photo_url`.
///
/// While the pipeline is running we render a [Skeleton] over the avatar so
/// the user has visual feedback while bytes are being processed.
class AvatarPickerField extends ConsumerStatefulWidget {
  const AvatarPickerField({
    super.key,
    required this.name,
    required this.currentUrl,
    required this.onUploaded,
    required this.onRemoved,
  });

  /// Display name used to seed initials when [currentUrl] is null.
  final String name;
  final String? currentUrl;
  final ValueChanged<String> onUploaded;
  final VoidCallback onRemoved;

  @override
  ConsumerState<AvatarPickerField> createState() => _AvatarPickerFieldState();
}

class _AvatarPickerFieldState extends ConsumerState<AvatarPickerField> {
  bool _busy = false;
  String? _errorKey;

  Future<void> _openOptions() async {
    Haptics.selection();
    final _AvatarAction? action = await showAppBottomSheet<_AvatarAction>(
      context: context,
      child: _AvatarOptionsSheet(hasPhoto: widget.currentUrl != null),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _AvatarAction.camera:
        await _pick(ImageSource.camera);
      case _AvatarAction.gallery:
        await _pick(ImageSource.gallery);
      case _AvatarAction.remove:
        await _remove();
    }
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      final AvatarUploadService svc = ref.read(avatarUploadServiceProvider);
      final String? url = await svc.pickAndUpload(source: source);
      if (url != null) {
        Haptics.light();
        widget.onUploaded(url);
      }
    } on AvatarUploadException catch (e) {
      if (!mounted) return;
      Haptics.error();
      setState(() => _errorKey = _errorKeyFor(e.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      await ref.read(avatarUploadServiceProvider).removeAvatar();
      if (!mounted) return;
      Haptics.light();
      widget.onRemoved();
    } on AvatarUploadException catch (e) {
      if (!mounted) return;
      Haptics.error();
      setState(() => _errorKey = _errorKeyFor(e.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorKeyFor(AvatarUploadError kind) => switch (kind) {
        AvatarUploadError.tooLarge => 'media.imageTooLargeBody',
        AvatarUploadError.authRequired => 'auth.errors.signInFailed',
        AvatarUploadError.pickFailed => 'media.permissionPhotoBody',
        AvatarUploadError.uploadFailed => 'media.uploadFailed',
      };

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          button: true,
          label: context.t('media.uploadAvatar'),
          child: InkWell(
            key: const Key('avatarPickerField.tap'),
            customBorder: const CircleBorder(),
            onTap: _busy ? null : _openOptions,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Avatar(
                  name: widget.name,
                  photoUrl: widget.currentUrl,
                  size: 76,
                ),
                if (_busy)
                  const Positioned.fill(
                    child: ClipOval(
                      child: Skeleton(width: 76, height: 76),
                    ),
                  ),
                // Edit pencil chip — bottom-right corner.
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.navy,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.white, width: 2),
                    ),
                    child: Icon(Icons.edit, size: 13, color: colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_errorKey != null) ...<Widget>[
          Gap(spacing.xs),
          Text(
            context.t(_errorKey!),
            style: typo.bodyXs.copyWith(color: colors.danger),
          ),
        ],
      ],
    );
  }
}

/// Source-selection actions surfaced by the avatar picker sheet.
enum _AvatarAction { camera, gallery, remove }

class _AvatarOptionsSheet extends StatelessWidget {
  const _AvatarOptionsSheet({required this.hasPhoto});

  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.xs,
        vertical: spacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _OptionRow(
            rowKey: const Key('avatarPicker.camera'),
            icon: Icons.photo_camera_outlined,
            label: context.t('profile.avatar.takePhoto'),
            onTap: () => Navigator.of(context).pop(_AvatarAction.camera),
          ),
          _OptionRow(
            rowKey: const Key('avatarPicker.gallery'),
            icon: Icons.photo_library_outlined,
            label: context.t('profile.avatar.chooseFromGallery'),
            onTap: () => Navigator.of(context).pop(_AvatarAction.gallery),
          ),
          if (hasPhoto)
            _OptionRow(
              rowKey: const Key('avatarPicker.remove'),
              icon: Icons.delete_outline,
              label: context.t('profile.avatar.removePhoto'),
              destructive: true,
              onTap: () => Navigator.of(context).pop(_AvatarAction.remove),
            ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.rowKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final Key rowKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final Color color = destructive ? colors.danger : colors.body;
    return ListTile(
      key: rowKey,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: typo.bodyLg.copyWith(color: color)),
      onTap: onTap,
    );
  }
}
