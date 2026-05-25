import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../media/data/media_service.dart';
import 'image_viewer.dart';
import 'text_bubble.dart';

/// Single-image chat message (gallery F1/F3).
///
/// Reads the signed URL for [mediaPath] through [signedChatMediaUrlProvider]
/// (TTL-cached). While the URL resolves, a fixed-size shimmering skeleton
/// reserves space so the list doesn't reflow. Tap → full-screen [ImageViewer].
class ImageBubble extends ConsumerWidget {
  const ImageBubble({
    super.key,
    required this.mediaPath,
    required this.variant,
    this.onLongPress,
  });

  final String mediaPath;
  final BubbleVariant variant;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final isMe = variant == BubbleVariant.me;
    final urlAsync = ref.watch(signedChatMediaUrlProvider(mediaPath));
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        onTap: () => urlAsync.whenData(
          (url) => ImageViewer.show(context, url: url),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 280),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radii.card),
              color: colors.slate100,
              border: Border.all(color: colors.border),
            ),
            child: urlAsync.when(
              data: (url) => CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: 240,
                height: 280,
                placeholder: (_, __) => Container(color: colors.slate100),
                errorWidget: (_, __, ___) => SizedBox(
                  width: 240,
                  height: 180,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: colors.muted,
                      size: 32,
                    ),
                  ),
                ),
              ),
              loading: () => SizedBox(
                width: 240,
                height: 180,
                child: Container(color: colors.slate100),
              ),
              error: (_, __) => SizedBox(
                width: 240,
                height: 180,
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: colors.muted,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
