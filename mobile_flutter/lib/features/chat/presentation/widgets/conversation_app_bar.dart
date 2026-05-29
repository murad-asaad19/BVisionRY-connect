import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../discovery/domain/role_label.dart';

/// Custom in-thread top bar (gallery F3).
///
/// Visual: 1px-bottom-border white bar; back chevron on the left; peer
/// [Avatar] (32px) + name + (optional) verified checkmark in the middle;
/// subtitle below the name showing either the peer's headline OR
/// "typing..." when they're actively composing. A trailing overflow menu
/// exposes View profile / Mute / Report.
///
/// All data comes through props so the widget stays pure — the parent
/// screen wires it up against `peerProfileProvider`, `typingProvider`, and
/// `conversationOverviewProvider`.
class ConversationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ConversationAppBar({
    super.key,
    required this.peerName,
    required this.peerHandle,
    required this.peerPhotoUrl,
    required this.peerHeadline,
    required this.isMuted,
    required this.isVerified,
    required this.isTyping,
    required this.onTapProfile,
    required this.onToggleMute,
    required this.onReport,
    this.onBlock,
    this.peerRole,
  });

  final String peerName;
  final String peerHandle;
  final String? peerPhotoUrl;
  final String? peerHeadline;
  final bool isMuted;
  final bool isVerified;
  final bool isTyping;
  final VoidCallback onTapProfile;
  final VoidCallback onToggleMute;
  final VoidCallback onReport;

  /// When non-null, renders a "Block @handle" row between Mute and Report
  /// in the overflow menu. The chat screen wires this to the privacy
  /// service via the [BlockButton]'s confirm-and-block flow.
  final VoidCallback? onBlock;

  /// Peer's primary role (e.g. "builder", "founder") — used to label the
  /// inline verified pill next to their name. When null, the verified
  /// state falls back to the gold-check icon used by [Avatar].
  final String? peerRole;

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final topInset = MediaQuery.of(context).padding.top.clamp(0.0, 64.0);
    final subtitle = isTyping
        ? context.t('chat.typing')
        : (peerHeadline?.isNotEmpty ?? false)
            ? peerHeadline!
            : '@$peerHandle';
    return Container(
      padding: EdgeInsets.fromLTRB(4, topInset + 6, 4, 8),
      decoration: BoxDecoration(
        color: colors.white,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AppIconButton(
            icon: Icons.chevron_left,
            label: context.t('common.back'),
            size: AppIconButtonSize.md,
            onPressed: () {
              // The conversation screen can be reached via context.push (back
              // stack present) OR context.go after accept_intro / deep-link
              // (stack empty). Try pop first; fall back to the Inbox hub
              // (which now hosts the chats list as a segment).
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.inbox);
              }
            },
          ),
          InkWell(
            onTap: onTapProfile,
            child: Avatar(
              name: peerName,
              photoUrl: peerPhotoUrl,
              size: 32,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onTapProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          peerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typo.displayMd.copyWith(color: colors.navy),
                        ),
                      ),
                      if (isVerified) ...<Widget>[
                        const SizedBox(width: 6),
                        if (peerRole != null && peerRole!.isNotEmpty)
                          Pill(
                            label: roleLabel(context, peerRole!),
                            variant: PillVariant.success,
                            icon: Icons.check,
                          )
                        else
                          Icon(
                            LucideIcons.badgeCheck,
                            size: 14,
                            color: colors.gold,
                          ),
                      ],
                      if (isMuted) ...<Widget>[
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.bellOff,
                          size: 12,
                          color: colors.muted,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodyXs.copyWith(
                      color: isTyping ? colors.navy : colors.muted,
                      fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.ellipsisVertical, color: colors.navy),
            tooltip: context.t('common.more'),
            itemBuilder: (ctx) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'profile',
                child: Text(ctx.t('chat.menu.viewProfile')),
              ),
              PopupMenuItem<String>(
                value: 'mute',
                child: Text(
                  isMuted
                      ? ctx.t('chat.mute.menuUnmute')
                      : ctx.t('chat.mute.menuMute'),
                ),
              ),
              if (onBlock != null)
                PopupMenuItem<String>(
                  value: 'block',
                  child: Text(
                    ctx.t(
                      'chat.menu.blockHandle',
                      vars: <String, Object>{'handle': peerHandle},
                    ),
                  ),
                ),
              PopupMenuItem<String>(
                value: 'report',
                child: Text(ctx.t('chat.actions.report')),
              ),
            ],
            onSelected: (v) {
              switch (v) {
                case 'profile':
                  onTapProfile();
                case 'mute':
                  onToggleMute();
                case 'block':
                  onBlock?.call();
                case 'report':
                  onReport();
              }
            },
          ),
        ],
      ),
    );
  }
}
