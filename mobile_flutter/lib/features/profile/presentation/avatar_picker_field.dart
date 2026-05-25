import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../data/avatar_upload_service.dart';

/// Round avatar + edit-pencil overlay used inside the Profile-edit form.
///
/// Tap → invokes [AvatarUploadService.pickAndUpload] (which runs the full
/// pick → crop → compress → upload → cache-bust pipeline). On success the
/// new cache-busted URL is yielded via [onUploaded] so the parent form can
/// patch its local `photo_url` state.
///
/// While the pipeline is running we render a [Skeleton] over the avatar so
/// the user has visual feedback while bytes are being processed.
class AvatarPickerField extends ConsumerStatefulWidget {
  const AvatarPickerField({
    super.key,
    required this.name,
    required this.currentUrl,
    required this.onUploaded,
  });

  /// Display name used to seed initials when [currentUrl] is null.
  final String name;
  final String? currentUrl;
  final ValueChanged<String> onUploaded;

  @override
  ConsumerState<AvatarPickerField> createState() => _AvatarPickerFieldState();
}

class _AvatarPickerFieldState extends ConsumerState<AvatarPickerField> {
  bool _busy = false;
  String? _errorKey;

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      final AvatarUploadService svc = ref.read(avatarUploadServiceProvider);
      final String? url = await svc.pickAndUpload();
      if (url != null) widget.onUploaded(url);
    } on AvatarUploadException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorKey = switch (e.kind) {
          AvatarUploadError.tooLarge => 'media.imageTooLargeBody',
          AvatarUploadError.authRequired => 'auth.errors.signInFailed',
          AvatarUploadError.pickFailed => 'media.permissionPhotoBody',
          AvatarUploadError.uploadFailed => 'media.uploadFailed',
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          button: true,
          label: context.t('media.uploadAvatar'),
          child: InkWell(
            key: const Key('avatarPickerField.tap'),
            customBorder: const CircleBorder(),
            onTap: _busy ? null : _pick,
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
          const SizedBox(height: 6),
          Text(
            context.t(_errorKey!),
            style: TextStyle(color: colors.danger, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
