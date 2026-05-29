import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../media/data/media_service.dart';
import '../../domain/message.dart';
import 'image_viewer.dart';
import 'send_status_footer.dart';
import 'text_bubble.dart';

/// Single-image chat message (gallery F1/F3).
///
/// Reads the signed URL for [mediaPath] through [signedChatMediaUrlProvider]
/// (TTL-cached). The image renders within max bounds preserving its natural
/// aspect ratio. While optimistic, the locally-picked [localBytes] render
/// immediately under an upload overlay. Tap → full-screen [ImageViewer].
class ImageBubble extends ConsumerWidget {
  const ImageBubble({
    super.key,
    required this.mediaPath,
    required this.variant,
    this.onLongPress,
    this.localBytes,
    this.sendStatus,
    this.onRetry,
  });

  final String mediaPath;
  final BubbleVariant variant;
  final VoidCallback? onLongPress;

  /// Locally-picked bytes shown immediately for an optimistic bubble before
  /// the upload completes; null for confirmed server rows.
  final Uint8List? localBytes;
  final MessageSendStatus? sendStatus;
  final VoidCallback? onRetry;

  static const double _maxWidth = 240;
  static const double _maxHeight = 280;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final isMe = variant == BubbleVariant.me;
    final isOptimistic = sendStatus != null;

    final Widget content = isOptimistic && localBytes != null
        ? _LocalPreview(
            bytes: localBytes!,
            colors: colors,
            isUploading: sendStatus == MessageSendStatus.sending,
          )
        : _RemoteImage(mediaPath: mediaPath);

    final bubble = Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        button: !isOptimistic,
        image: true,
        label: context.t('chat.photoMessage'),
        onLongPressHint:
            onLongPress != null ? context.t('chat.messageActionsHint') : null,
        child: GestureDetector(
          onLongPress: onLongPress,
          onTap: isOptimistic
              ? null
              : () => ref
                  .read(signedChatMediaUrlProvider(mediaPath))
                  .whenData((url) => ImageViewer.show(context, url: url)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _maxWidth,
              maxHeight: _maxHeight,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radii.card),
                color: colors.slate100,
                border: Border.all(color: colors.border),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );

    if (sendStatus == null) return bubble;
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        bubble,
        SendStatusFooter(status: sendStatus, onRetry: onRetry),
      ],
    );
  }
}

/// Optimistic local image with an optional dimming + spinner overlay while
/// the upload is in flight.
class _LocalPreview extends StatelessWidget {
  const _LocalPreview({
    required this.bytes,
    required this.colors,
    required this.isUploading,
  });

  final Uint8List bytes;
  final AppColors colors;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Image.memory(bytes, fit: BoxFit.contain),
        if (isUploading)
          Positioned.fill(
            child: ColoredBox(
              color: colors.navy.withValues(alpha: 0.35),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Confirmed server image fetched via signed URL, sized within bounds while
/// preserving its natural aspect ratio.
class _RemoteImage extends ConsumerWidget {
  const _RemoteImage({required this.mediaPath});

  final String mediaPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final urlAsync = ref.watch(signedChatMediaUrlProvider(mediaPath));
    Widget fallback({required IconData icon}) => SizedBox(
          width: ImageBubble._maxWidth,
          height: 180,
          child: Center(child: Icon(icon, color: colors.muted, size: 32)),
        );
    return urlAsync.when(
      data: (url) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, __) => SizedBox(
          width: ImageBubble._maxWidth,
          height: 180,
          child: ColoredBox(color: colors.slate100),
        ),
        errorWidget: (_, __, ___) => fallback(icon: Icons.broken_image),
      ),
      loading: () => SizedBox(
        width: ImageBubble._maxWidth,
        height: 180,
        child: ColoredBox(color: colors.slate100),
      ),
      error: (_, __) => fallback(icon: Icons.broken_image),
    );
  }
}
