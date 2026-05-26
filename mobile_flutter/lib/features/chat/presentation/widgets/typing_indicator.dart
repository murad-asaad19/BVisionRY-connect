import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// "Typing..." badge with animated dots, anchored above the input bar.
///
/// Parent is responsible for hiding this widget when no one is typing —
/// the indicator itself always renders the animation when mounted. The
/// dots cycle through three opacity stages on a 900ms loop.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.peerName});

  /// Optional peer name. When omitted, falls back to the generic
  /// localised "typing…" copy.
  final String? peerName;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final label = widget.peerName != null
        ? '${widget.peerName} ${context.t('chat.typing')}'
        : context.t('chat.typing');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => _Dots(progress: _ctrl.value, color: colors.muted),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: typo.bodyXs.copyWith(
              color: colors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.progress, required this.color});

  final double progress;
  final Color color;

  double _opacityFor(int i) {
    // Each dot's "active" window covers 1/3 of the cycle, staggered.
    final stagger = (i / 3.0);
    final phase = ((progress + stagger) % 1.0);
    // Triangular wave 0..1..0.
    final v = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.3 + 0.7 * v;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < 3; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 3),
          Opacity(
            opacity: _opacityFor(i),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
