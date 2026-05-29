import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/gap.dart';
import '../../domain/message.dart';

/// Inline per-message send-status affordance shown beneath an own-message
/// bubble while it is optimistic.
///
/// - [MessageSendStatus.sending] → a muted "Sending…" caption.
/// - [MessageSendStatus.failed]  → a danger-tinted "Couldn't send" caption
///   with a tappable Retry control (the failure is sticky, not a transient
///   toast, per the optimistic-send spec).
///
/// Renders nothing for confirmed (`sent` / null) rows. Aligned by the
/// parent bubble's `crossAxisAlignment`.
class SendStatusFooter extends StatelessWidget {
  const SendStatusFooter({
    super.key,
    required this.status,
    this.onRetry,
  });

  final MessageSendStatus? status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;

    switch (status) {
      case MessageSendStatus.sending:
        return Padding(
          padding: EdgeInsets.only(
            right: spacing.md,
            left: spacing.md,
            bottom: spacing.xs,
          ),
          child: Text(
            context.t('chat.send.sending'),
            style: typo.bodyXs.copyWith(color: colors.muted),
          ),
        );
      case MessageSendStatus.failed:
        return Padding(
          padding: EdgeInsets.only(
            right: spacing.md,
            left: spacing.md,
            bottom: spacing.xs,
          ),
          child: InkWell(
            onTap: onRetry == null
                ? null
                : () {
                    Haptics.light();
                    onRetry!.call();
                  },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(LucideIcons.circleAlert, size: 13, color: colors.danger),
                Gap(spacing.xs),
                Text(
                  context.t('chat.send.failed'),
                  style: typo.bodyXs.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onRetry != null) ...<Widget>[
                  Gap(spacing.sm),
                  Text(
                    context.t('common.retry'),
                    style: typo.bodyXs.copyWith(
                      color: colors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case MessageSendStatus.sent:
      case null:
        return const SizedBox.shrink();
    }
  }
}
