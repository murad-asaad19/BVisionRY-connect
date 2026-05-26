import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/privacy_service.dart';
import '../domain/blocked_user.dart';
import '../providers/blocks_provider.dart';

/// `/settings/blocked-users` — lists users the caller has blocked.
///
/// Empty state matches gallery section H5: an icon halo, "You haven't
/// blocked anyone." title, and the forward-intent hint about
/// "blocked users can never re-request even if you unblock".
///
/// Populated branch renders each row as `(avatar, name + @handle,
/// blocked-on date, Unblock outline button)`. Unblock opens a ConfirmDialog
/// then calls `unblock_user` and invalidates `blocksProvider`.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BlockedUser>> async = ref.watch(blocksProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            TopBar(
              title: context.t('settings.blockedUsers'),
              back: true,
            ),
            Expanded(
              child: QueryState<List<BlockedUser>>(
                value: async,
                onRetry: () => ref.invalidate(blocksProvider),
                data: (List<BlockedUser> list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.shieldOff,
                      title: context.t('privacy.blockedListEmpty'),
                      body: context.t('privacy.blockedListHint'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(blocksProvider);
                      await ref.read(blocksProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      // +1 to render the hint banner at the top.
                      itemCount: list.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext c, int i) {
                        if (i == 0) {
                          return AppBanner(
                            intent: AppIntent.info,
                            child: Text(context.t('privacy.blockedListHint')),
                          );
                        }
                        return _BlockedRow(user: list[i - 1]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the blocked list — avatar + identity column + Unblock CTA.
class _BlockedRow extends ConsumerWidget {
  const _BlockedRow({required this.user});

  final BlockedUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AvatarCircle(
            name: user.name,
            photoUrl: user.photoUrl,
            size: 38,
            tone: AvatarTone.muted,
          ),
          SizedBox(width: spacing.card),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.name,
                  style: typo.displaySm.copyWith(color: colors.navy),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.handle}',
                  style: typo.bodyXs.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  context.t(
                    'privacy.blockedAt',
                    vars: <String, Object>{
                      'date': _formatDate(user.createdAt),
                    },
                  ),
                  style: typo.bodyXs.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            label: context.t('privacy.unblock'),
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
            fullWidth: false,
            onPressed: () => _onUnblock(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _onUnblock(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await ref.read(confirmServiceProvider).confirm(
          context,
          title: context.t('privacy.unblock'),
          body: context.t('privacy.blockedListHint'),
          confirmLabel: context.t('privacy.unblock'),
        );
    if (!confirmed) return;
    await ref.read(privacyServiceProvider).unblockUser(user.blockedId);
    ref.invalidate(blocksProvider);
  }

  /// `YYYY-MM-DD` — locale-agnostic date format suitable for the gallery's
  /// muted "blocked at" line.
  static String _formatDate(DateTime d) {
    final DateTime local = d.toLocal();
    final String mm = local.month.toString().padLeft(2, '0');
    final String dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }
}
