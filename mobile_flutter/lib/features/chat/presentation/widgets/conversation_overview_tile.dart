import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/conversation_overview.dart';
import '../../domain/message_kind.dart';

/// One row in the chats list (gallery F0).
///
/// Layout: 44px [Avatar] + (name w/ optional mute icon) over a single-line
/// last-message preview + right-side stack of timestamp + unread [Pill].
///
/// The preview adapts to the last message's kind — text uses the body
/// verbatim, image/voice/meeting render localised labels (voice includes
/// a `mm:ss` duration when available).
class ConversationOverviewTile extends StatelessWidget {
  const ConversationOverviewTile({
    super.key,
    required this.overview,
    required this.onTap,
    this.onLongPress,
  });

  final ConversationOverview overview;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return InkWell(
      key: ValueKey<String>('conv-tile-${overview.conversationId}'),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Avatar(
              name: overview.peerName,
              photoUrl: overview.peerPhotoUrl,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          overview.peerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typo.displaySm.copyWith(color: colors.navy),
                        ),
                      ),
                      if (overview.isMuted) ...[
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.bellOff,
                          size: 14,
                          color: colors.muted,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _previewFor(context, overview),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodyMd.copyWith(
                      color: overview.unreadCount > 0 ? colors.body : colors.muted,
                      fontWeight: overview.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (overview.lastMessageAt != null)
                  Text(
                    _formatRelative(overview.lastMessageAt!),
                    style: typo.bodyXs.copyWith(color: colors.muted),
                  ),
                if (overview.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Pill(
                    label: overview.unreadCount > 99
                        ? '99+'
                        : overview.unreadCount.toString(),
                    variant: PillVariant.navy,
                    size: PillSize.sm,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _previewFor(BuildContext context, ConversationOverview o) {
    if (o.lastMessageKind == null) return '';
    switch (o.lastMessageKind!) {
      case MessageKind.text:
        return o.lastMessageBody ?? '';
      case MessageKind.image:
        return context.t('chat.lastMessage.image');
      case MessageKind.voice:
        return context.t(
          'chat.lastMessage.voice',
          vars: <String, Object>{
            'duration': _formatDuration(o.lastMessageDurationMs ?? 0),
          },
        );
      case MessageKind.meeting:
        return context.t('chat.lastMessage.meeting');
    }
  }
}

/// Formats `mm:ss` for voice previews. Negative / null durations collapse
/// to `0:00`.
String _formatDuration(int durationMs) {
  if (durationMs <= 0) return '0:00';
  final s = (durationMs / 1000).floor();
  final mm = (s ~/ 60).toString();
  final ss = (s % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

/// Compact relative timestamp — Today shows `HH:mm`, yesterday `Yesterday`,
/// otherwise `YYYY-MM-DD`. Deterministic so goldens stay stable across
/// locales; Phase 13 can swap for `intl` short-date if needed.
String _formatRelative(DateTime utc) {
  final local = utc.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final localDay = DateTime(local.year, local.month, local.day);
  if (localDay == today) {
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
  final yesterday = today.subtract(const Duration(days: 1));
  if (localDay == yesterday) return 'Yesterday';
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '${local.year}-$mm-$dd';
}
