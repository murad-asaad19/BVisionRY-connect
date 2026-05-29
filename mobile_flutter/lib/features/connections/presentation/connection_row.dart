import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/connection.dart';

/// One row of the Connections list — shared between [InboxScreen]'s
/// Connections sub-tab and the standalone `/connections` screen.
///
/// Layout: 44px [Avatar] + name + primary_role + "Connected {{date}}"
/// caption, with a trailing chevron button that opens the peer's public
/// profile so the profile is reachable via a discoverable affordance (not
/// just a hidden long-press).
///
/// Interactions:
///   * Tap the row → the bridging chat at `/chats/:conversationId` (the
///     primary action for a connection).
///   * Tap the trailing chevron → the peer's public profile.
///   * Long-press the row → the peer's public profile (secondary shortcut).
class ConnectionRow extends StatelessWidget {
  const ConnectionRow({super.key, required this.connection});

  final Connection connection;

  void _openProfile(BuildContext context) {
    Haptics.selection();
    context.push(Routes.publicProfile(connection.handle));
  }

  void _openChat(BuildContext context) {
    Haptics.selection();
    context.push(Routes.chat(connection.conversationId));
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return InkWell(
      onTap: () => _openChat(context),
      onLongPress: () => _openProfile(context),
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
        child: Row(
          children: <Widget>[
            // Name is rendered adjacent, so the avatar needs no SR label.
            Avatar(
              name: connection.name,
              photoUrl: connection.photoUrl,
              size: 44,
              semanticLabel: null,
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    connection.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.displaySm.copyWith(color: colors.navy),
                  ),
                  if (connection.primaryRole != null) ...<Widget>[
                    SizedBox(height: spacing.xs / 2),
                    Text(
                      connection.primaryRole!,
                      style: typo.bodyMd.copyWith(color: colors.muted),
                    ),
                  ],
                  SizedBox(height: spacing.xs / 2),
                  Text(
                    context.t(
                      'connections.connectedOn',
                      vars: <String, Object>{
                        'date': DateFormat.yMMMd()
                            .format(connection.connectedAt.toLocal()),
                      },
                    ),
                    style: typo.bodyXs.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
            // Discoverable affordance to open the peer's profile.
            AppIconButton(
              key: const Key('connectionRow.viewProfile'),
              icon: LucideIcons.chevronRight,
              label: context.t('connections.viewProfile'),
              size: AppIconButtonSize.sm,
              onPressed: () => _openProfile(context),
            ),
          ],
        ),
      ),
    );
  }
}
