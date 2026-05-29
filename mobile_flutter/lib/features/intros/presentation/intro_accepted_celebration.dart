import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';

/// The signature "intro accepted" celebration — a brief, tasteful payoff for
/// the app's core moment.
///
/// Floats a success check + expanding sparkle ring in the centre of the
/// screen, then fades out and removes itself after ~700ms. It is inserted
/// into the ROOT overlay (not the current route's overlay) so it keeps
/// playing above the chat screen that [IntroDetailScreen] pushes to on
/// accept — the celebration never blocks navigation.
///
/// Dependency-free: pure [AnimatedBuilder] + implicit-curve tweens. Pointer
/// events pass straight through (`IgnorePointer`) so a tap during the
/// animation isn't swallowed.
abstract final class IntroAcceptedCelebration {
  /// Total lifetime of the overlay before it self-removes.
  static const Duration _lifetime = Duration(milliseconds: 720);

  /// Plays the celebration above [context]'s root overlay. Safe to call and
  /// then immediately navigate away — the overlay outlives the route change.
  static void play(BuildContext context) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final colors = Theme.of(context).extension<AppColors>()!;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationLayer(
        colors: colors,
        duration: _lifetime,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _CelebrationLayer extends StatefulWidget {
  const _CelebrationLayer({
    required this.colors,
    required this.duration,
    required this.onDone,
  });

  final AppColors colors;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<_CelebrationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Check scales in with a gentle overshoot, then holds.
  late final Animation<double> _checkScale;
  // Whole badge fades in fast, holds, then fades out near the end.
  late final Animation<double> _opacity;
  // Sparkle ring expands outward and fades as it grows.
  late final Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });

    _checkScale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.4, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(_controller);

    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 55),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);

    _ring = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0),
              child: SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Expanding sparkle ring — grows past the badge and fades.
                    Transform.scale(
                      scale: 0.7 + _ring.value * 0.9,
                      child: Opacity(
                        opacity: (1.0 - _ring.value) * 0.5,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.gold, width: 3),
                          ),
                        ),
                      ),
                    ),
                    // Scale-in success badge.
                    Transform.scale(
                      scale: _checkScale.value,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.success,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.check,
                          size: 40,
                          color: colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
