import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Full-screen image viewer reachable by tapping an [ImageBubble].
///
/// Pinch-to-zoom is provided by [InteractiveViewer]; the user can also
/// swipe down (vertical drag) to dismiss without going via the close
/// button. Backdrop is opaque black to keep contrast at every zoom level.
class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key, required this.url});

  final String url;

  /// Convenience launcher — opens the viewer as a fullscreen [Dialog].
  static Future<void> show(BuildContext context, {required String url}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      builder: (_) => ImageViewer(url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0).abs() > 300) {
            Navigator.of(context).maybePop();
          }
        },
        child: Stack(
          children: <Widget>[
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            Positioned(
              top: 32,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  key: const ValueKey('image-viewer-close'),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
