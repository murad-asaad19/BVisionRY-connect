import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/widgets/widgets.dart';

/// Full-screen image viewer reachable by tapping an [ImageBubble].
///
/// Pinch-to-zoom via [InteractiveViewer]; single-finger vertical swipe
/// dismisses when the image is at its natural (1x) scale. When zoomed,
/// single-finger drags pan the image and dismiss is disabled until the
/// user double-taps back to 1x.
class ImageViewer extends StatefulWidget {
  const ImageViewer({super.key, required this.url});

  final String url;

  static Future<void> show(BuildContext context, {required String url}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      builder: (_) => ImageViewer(url: url),
    );
  }

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  late final TransformationController _controller;
  double _dragOffsetY = 0;

  static const double _dismissVelocity = 600;
  static const double _dismissDistance = 120;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _controller.addListener(_onTransform);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransform);
    _controller.dispose();
    super.dispose();
  }

  void _onTransform() {
    if (mounted) setState(() {});
  }

  bool get _isAtNaturalScale {
    final scale = _controller.value.getMaxScaleOnAxis();
    return (scale - 1.0).abs() < 0.01;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_isAtNaturalScale) return;
    setState(() => _dragOffsetY += d.delta.dy);
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_isAtNaturalScale) return;
    final velocity = d.primaryVelocity ?? 0;
    final shouldDismiss = velocity.abs() > _dismissVelocity ||
        _dragOffsetY.abs() > _dismissDistance;
    if (shouldDismiss) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _dragOffsetY = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final barrierOpacity =
        (1.0 - (_dragOffsetY.abs() / 400).clamp(0.0, 0.7)).clamp(0.3, 1.0);
    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: barrierOpacity),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: Transform.translate(
                offset: Offset(0, _dragOffsetY),
                child: Center(
                  child: InteractiveViewer(
                    transformationController: _controller,
                    minScale: 1.0,
                    maxScale: 5,
                    panEnabled: !_isAtNaturalScale,
                    child: CachedNetworkImage(
                      imageUrl: widget.url,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 32,
            right: 16,
            child: AppIconButton(
              key: const ValueKey('image-viewer-close'),
              icon: Icons.close,
              label: context.t('media.closeImage'),
              variant: AppIconButtonVariant.navy,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}
