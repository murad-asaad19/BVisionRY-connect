import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Phase 15 — Shimmer-based skeleton primitive.
///
/// Wraps a rounded-rectangle in `Shimmer.fromColors` with brand-aligned
/// slate-grey base and white highlight. Drop-in replacement for the
/// pre-Phase-15 [Skeleton] animation (still kept as a public widget for
/// backwards compatibility — internally [Skeleton] delegates here when a
/// real animation is requested).
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius,
    this.animate = true,
  });

  final double? width;
  final double height;
  final double? radius;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.slate100,
        borderRadius: BorderRadius.circular(radius ?? 8),
      ),
    );
    if (!animate) return box;
    return Shimmer.fromColors(
      baseColor: colors.slate100,
      highlightColor: colors.white,
      period: const Duration(milliseconds: 1400),
      child: box,
    );
  }
}
