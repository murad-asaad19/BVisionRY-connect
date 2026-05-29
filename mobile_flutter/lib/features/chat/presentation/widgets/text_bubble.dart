import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/message.dart';
import 'send_status_footer.dart';

/// "Me" (sender) vs "Them" (receiver) visual orientation for chat bubbles.
///
/// The variant chooses the bubble's fill, text colour, and tail-corner
/// asymmetry; it does NOT affect alignment — the parent layout is
/// responsible for left/right placement. Shared by every bubble widget so
/// they composit consistently.
enum BubbleVariant { me, them }

/// One text message bubble (gallery F1/F3).
///
/// Visual:
/// - `me`: navy fill, white text, tail bottom-right (4dp corner)
/// - `them`: white fill, body text, 1px border, tail bottom-left
///
/// The "me" bubble uses the gallery's navy fill with white text — this is
/// the brand convention for outgoing chat content (navy = self, white =
/// peer) and matches the outgoing voice bubble's navy fill. Edited copy
/// stays muted-tone on `them`; on `me` it uses a translucent white tone.
///
/// When [isEdited] is `true` a small "(edited)" suffix is rendered on a
/// second line in a muted tone. Long-press fires [onLongPress] so the
/// parent screen can open the message-actions sheet — the bubble itself
/// stays passive about which actions are available (the sheet gates by
/// `Message.canEditBy` / `Message.canDeleteBy`).
class TextBubble extends StatelessWidget {
  const TextBubble({
    super.key,
    required this.body,
    required this.variant,
    this.isEdited = false,
    this.onLongPress,
    this.sendStatus,
    this.onRetry,
  });

  final String body;
  final BubbleVariant variant;
  final bool isEdited;
  final VoidCallback? onLongPress;

  /// Optimistic send state — drives the inline "Sending…" / "Couldn't send"
  /// footer. Null for confirmed server rows.
  final MessageSendStatus? sendStatus;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final isMe = variant == BubbleVariant.me;
    final bubble = Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        // Only own messages can be long-pressed for the actions sheet.
        onLongPressHint:
            onLongPress != null ? context.t('chat.messageActionsHint') : null,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? colors.navyFill : colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
                border: isMe ? null : Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    body,
                    style: typo.bodyLg.copyWith(
                      color: isMe ? colors.onNavy : colors.body,
                    ),
                  ),
                  if (isEdited) ...[
                    const SizedBox(height: 2),
                    Text(
                      '(${context.t('chat.edited')})',
                      style: typo.bodyXs.copyWith(
                        color: isMe
                            ? colors.onNavy.withValues(alpha: 0.7)
                            : colors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (sendStatus == null) return bubble;
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        bubble,
        SendStatusFooter(status: sendStatus, onRetry: onRetry),
      ],
    );
  }
}
