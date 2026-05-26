import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/top_bar.dart';
import '../domain/interested_user.dart';
import '../providers/interested_provider.dart';
import '_relative_time.dart';

/// Author-only list of users who expressed interest in an opportunity.
///
/// Maps a `ForbiddenException` (non-author / RLS-denied) to a guarded empty
/// state so non-authors who hit the route via deep-link see the right copy.
class InterestedListScreen extends ConsumerWidget {
  const InterestedListScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InterestedUser>> async =
        ref.watch(interestedProvider(opportunityId));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            TopBar(
              title: context.t('opportunities.interestedScreen.title'),
              back: true,
            ),
            Expanded(
              child: async.when(
                loading: () => ListView(
                  children: const <Widget>[
                    SkeletonListRow(),
                    SkeletonListRow(),
                    SkeletonListRow(),
                    SkeletonListRow(),
                    SkeletonListRow(),
                  ],
                ),
                error: (Object e, _) {
                  if (e is ForbiddenException) {
                    return EmptyState(
                      icon: LucideIcons.shieldAlert,
                      title: context.t(
                        'opportunities.interestedScreen.forbiddenTitle',
                      ),
                      body: context.t(
                        'opportunities.interestedScreen.forbiddenBody',
                      ),
                    );
                  }
                  return EmptyState(
                    icon: LucideIcons.triangleAlert,
                    title: 'Something went wrong.',
                    body: e.toString(),
                  );
                },
                data: (List<InterestedUser> users) {
                  if (users.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.heart,
                      title: context.t('opportunities.interested.empty'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(interestedProvider(opportunityId));
                      await ref
                          .read(interestedProvider(opportunityId).future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (BuildContext c, int i) {
                        return _InterestedRow(user: users[i]);
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

class _InterestedRow extends StatelessWidget {
  const _InterestedRow({required this.user});

  final InterestedUser user;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo =
        Theme.of(context).extension<AppTypography>()!;
    final AppSpacing spacing =
        Theme.of(context).extension<AppSpacing>()!;
    return AppCard(
      onTap: () => context.push(Routes.publicProfile(user.handle)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        user.name,
                        style: typo.displaySm.copyWith(color: colors.navy),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      relativeShort(user.createdAt),
                      style: typo.bodyXs.copyWith(color: colors.muted),
                    ),
                  ],
                ),
                if (user.primaryRole != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Pill(
                    label: user.primaryRole!,
                    size: PillSize.sm,
                    variant: PillVariant.muted,
                  ),
                ],
                if (user.note != null && user.note!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    user.note!,
                    style: typo.bodyMd.copyWith(
                      color: colors.body,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
