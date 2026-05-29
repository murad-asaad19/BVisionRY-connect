import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Decorative 13-bar audio waveform (gallery F1/F2/F3).
///
/// Pure [CustomPaint] — no real spectral analysis. Bar heights default to a
/// stable, deterministic pseudo-noise so goldens stay reproducible; callers
/// can pass [heights] (0..1 per bar) for a custom pattern.
///
/// [progress] is the fraction (0..1) of bars that should render as "played"
/// in [activeColor]; remaining bars use [inactiveColor]. Used by VoiceBubble
/// (with [voicePlayerProvider]'s position/total) and VoiceRecorderSheet
/// (with recordingMs / maxVoiceMs).
class VoiceWaveform extends StatelessWidget {
  const VoiceWaveform({
    super.key,
    this.progress = 0,
    this.barCount = 13,
    this.heights,
    this.activeColor,
    this.inactiveColor,
    this.height = 22,
    this.onSeek,
    this.seekSemanticLabel,
  });

  final double progress;
  final int barCount;
  final List<double>? heights;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;

  /// When non-null the waveform becomes scrubbable: tapping or dragging
  /// reports the target position as a 0..1 fraction so the caller can seek
  /// the player. Null keeps the waveform purely decorative (recorder).
  final ValueChanged<double>? onSeek;

  /// Screen-reader label for the scrub surface (required-ish when [onSeek]
  /// is set so the gesture target is announced).
  final String? seekSemanticLabel;

  /// Deterministic pseudo-random heights so the same bar count always
  /// renders identically — important for golden tests.
  static List<double> defaultHeights(int barCount) {
    return <double>[
      for (int i = 0; i < barCount; i++) _pattern(i, barCount),
    ];
  }

  static double _pattern(int index, int total) {
    // Sinusoid-like wobble; ranges roughly 0.35..1.0 so even the shortest
    // bars stay visible.
    final t = index / (total - 1);
    final wave = 0.65 + 0.35 * (((t * 7.0) % 1.0) * 2 - 1).abs();
    return wave.clamp(0.35, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final painter = CustomPaint(
      size: Size(double.infinity, height),
      painter: _WavePainter(
        progress: progress.clamp(0, 1),
        barCount: barCount,
        heights: heights ?? defaultHeights(barCount),
        active: activeColor ?? colors.navy,
        inactive: inactiveColor ?? colors.slate300,
      ),
    );
    if (onSeek == null) {
      return SizedBox(
        key: const ValueKey('voice-waveform'),
        width: double.infinity,
        height: height,
        child: painter,
      );
    }
    // Scrubbable: translate the local x position into a 0..1 fraction. A
    // taller hit area than the bars keeps the gesture comfortable.
    return Semantics(
      slider: true,
      label: seekSemanticLabel,
      value: '${(progress.clamp(0, 1) * 100).round()}%',
      child: LayoutBuilder(
        builder: (context, constraints) {
          void report(double dx) {
            final w = constraints.maxWidth;
            if (w <= 0) return;
            onSeek!((dx / w).clamp(0.0, 1.0));
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => report(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => report(d.localPosition.dx),
            child: SizedBox(
              key: const ValueKey('voice-waveform'),
              width: double.infinity,
              height: height,
              child: painter,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.barCount,
    required this.heights,
    required this.active,
    required this.inactive,
  });

  final double progress;
  final int barCount;
  final List<double> heights;
  final Color active;
  final Color inactive;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 3.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final activeBars = (progress * barCount).round();
    for (int i = 0; i < barCount; i++) {
      final h = heights[i] * size.height;
      final paint = Paint()..color = i < activeBars ? active : inactive;
      final x = i * (barWidth + gap);
      final y = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, h),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress ||
      old.barCount != barCount ||
      old.heights != heights ||
      old.active != active ||
      old.inactive != inactive;
}
