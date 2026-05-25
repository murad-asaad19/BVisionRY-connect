import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import 'text_bubble.dart';

/// Renders a soft-deleted message as italic, muted "Message deleted" copy.
///
/// Uses [BubbleVariant] for left/right alignment + tail-corner asymmetry
/// (matching the kind of bubble that was deleted) but always uses the
/// muted slate background regardless of who sent it. No long-press
/// affordance — tombstones are terminal.
class TombstoneBubble extends StatelessWidget {
  const TombstoneBubble({super.key, required this.variant});

  final BubbleVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final isMe = variant == BubbleVariant.me;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: colors.slate100,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          context.t('chat.messageDeleted'),
          style: typo.bodyMd.copyWith(
            color: colors.muted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
