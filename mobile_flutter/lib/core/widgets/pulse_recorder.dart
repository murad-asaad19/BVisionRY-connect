import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Phase 15 — three-ring pulse around a danger-coloured mic disc.
///
/// Mirrors the gallery reference: while [isRecording] is true, three
/// concentric scaled circles animate outward from the central mic, each
/// staggered by 0.33 of the 1200ms cycle. When paused, all rings collapse
/// to a static disc.
class PulseRecorder extends StatefulWidget {
  const PulseRecorder({
    super.key,
    required this.isRecording,
    this.size = 80,
  });

  final bool isRecording;
  final double size;

  @override
  State<PulseRecorder> createState() => _PulseRecorderState();
}

class _PulseRecorderState extends State<PulseRecorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isRecording) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant PulseRecorder old) {
    super.didUpdateWidget(old);
    if (widget.isRecording && !_ctrl.isAnimating) {
      _ctrl.repeat();
    }
    if (!widget.isRecording && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: widget.size * 2.2,
      height: widget.size * 2.2,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in const <double>[0.0, 0.33, 0.66])
                _Ring(
                  progress: (_ctrl.value + offset) % 1.0,
                  size: widget.size,
                  color: colors.danger,
                ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.danger,
                ),
                child: Icon(
                  Icons.mic,
                  color: colors.white,
                  size: widget.size * 0.45,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.progress,
    required this.size,
    required this.color,
  });

  final double progress;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + progress * 1.1;
    final opacity = 0.35 * (1.0 - progress);
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
