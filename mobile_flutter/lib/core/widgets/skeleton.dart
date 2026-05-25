import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Animated rectangular placeholder used for query loading states.
///
/// Drives a 800ms pulse between `slate100` and a 50% transparent variant
/// via [AnimationController] + [AnimatedBuilder] (no extra dependency).
/// Composites below ([SkeletonProfile], [SkeletonListRow]) compose this
/// primitive into shape-matching geometry so the loading state doesn't
/// jump when data arrives.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 12,
    this.rounded = 8,
    this.animate = true,
  });

  /// Absolute width. When null, the skeleton stretches to fill its parent.
  final double? width;

  /// Absolute height.
  final double height;

  /// Border radius in logical pixels.
  final double rounded;

  /// When `false`, paints the placeholder statically — useful for golden
  /// tests where a perpetually-pulsing animation blocks `pumpAndSettle`.
  final bool animate;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = 0.6 + (_controller.value * 0.4);
        return Container(
          key: const ValueKey('skeleton-frame'),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: c.slate100.withValues(alpha: t),
            borderRadius: BorderRadius.circular(widget.rounded),
          ),
        );
      },
    );
  }
}

/// List-row skeleton: 38px circle avatar + two stacked line skeletons.
///
/// Used as the loading placeholder for `UserCard`, intro / conversation
/// rows, and any list-style query — keeps spacing identical to the real
/// row so the layout doesn't shift when data arrives.
class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({super.key, this.animate = true});

  /// See [Skeleton.animate].
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Skeleton(width: 38, height: 38, rounded: 19, animate: animate),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 140, height: 12, animate: animate),
                const SizedBox(height: 6),
                Skeleton(width: 200, height: 10, animate: animate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile-header skeleton: hero block with 96px avatar circle + two
/// stacked title lines. Mirrors the production `ProfileView` layout.
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key, this.sections = 3, this.animate = true});

  /// Number of section panels to render below the hero. Defaults to 3.
  final int sections;

  /// See [Skeleton.animate].
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: palette.white,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Skeleton(width: 96, height: 96, rounded: 48, animate: animate),
              const SizedBox(height: 12),
              Skeleton(width: 180, height: 16, animate: animate),
              const SizedBox(height: 8),
              Skeleton(width: 120, height: 10, animate: animate),
            ],
          ),
        ),
        for (var i = 0; i < sections; i++)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.white,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 80, height: 10, animate: animate),
                const SizedBox(height: 10),
                Skeleton(height: 10, animate: animate),
                const SizedBox(height: 6),
                Skeleton(width: 240, height: 10, animate: animate),
                const SizedBox(height: 6),
                Skeleton(width: 180, height: 10, animate: animate),
              ],
            ),
          ),
      ],
    );
  }
}
