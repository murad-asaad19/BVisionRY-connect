import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/connection.dart';

/// One row of the Connections list — shared between [InboxScreen]'s
/// Connections sub-tab and the standalone `/connections` screen.
///
/// Layout: 44px [Avatar] + name + primary_role + "Connected {{date}}"
/// caption. Tap opens the bridging chat at `/chats/:conversationId`;
/// long-press routes to the peer's public profile so users can sanity
/// check before messaging.
class ConnectionRow extends StatelessWidget {
  const ConnectionRow({super.key, required this.connection});

  final Connection connection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return InkWell(
      onTap: () => context.go(Routes.chat(connection.conversationId)),
      onLongPress: () => context.push(Routes.publicProfile(connection.handle)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Avatar(
              name: connection.name,
              photoUrl: connection.photoUrl,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.displaySm.copyWith(color: colors.navy),
                  ),
                  if (connection.primaryRole != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      connection.primaryRole!,
                      style: typo.bodyMd.copyWith(color: colors.muted),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    context.t(
                      'connections.connectedOn',
                      vars: <String, Object>{
                        'date': _formatDate(connection.connectedAt),
                      },
                    ),
                    style: typo.bodyXs.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight YYYY-MM-DD formatter — deterministic across locales so
/// goldens don't drift. Phase 13 can swap this for an `intl` short-date.
String _formatDate(DateTime utc) {
  final local = utc.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '${local.year}-$mm-$dd';
}
