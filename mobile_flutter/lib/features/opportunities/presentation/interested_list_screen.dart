import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/i18n/relative_time.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/top_bar.dart';
import '../../intros/presentation/intro_or_chat_button.dart';
import '../../intros/presentation/send_intro_sheet.dart';
import '../domain/interested_user.dart';
import '../providers/interested_provider.dart';

/// Author-only list of users who expressed interest in an opportunity.
///
/// Each row surfaces a **Send intro** inline action so the author can
/// reach out without bouncing through the user's public profile first.
/// Tapping the row body still routes to the public profile for richer
/// context.
///
/// Maps a `ForbiddenException` (non-author / RLS-denied) to a guarded
/// empty state so non-authors who hit the route via deep-link see the
/// right copy.
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
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(interestedProvider(opportunityId));
                  await ref.read(interestedProvider(opportunityId).future);
                },
                child: QueryState<List<InterestedUser>>(
                  value: async,
                  loading: ListView(
                    children: const <Widget>[
                      SkeletonListRow(),
                      SkeletonListRow(),
                      SkeletonListRow(),
                      SkeletonListRow(),
                      SkeletonListRow(),
                    ],
                  ),
                  onRetry: () =>
                      ref.invalidate(interestedProvider(opportunityId)),
                  // A ForbiddenException (non-author / RLS-denied) gets a
                  // tailored guard empty state; every other failure routes
                  // through the default localized QueryState error
                  // (messageForError — never a raw toString()).
                  error: (Object e, StackTrace st) {
                    if (e is ForbiddenException) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          EmptyState(
                            icon: LucideIcons.shieldAlert,
                            title: context.t(
                              'opportunities.interestedScreen.forbiddenTitle',
                            ),
                            body: context.t(
                              'opportunities.interestedScreen.forbiddenBody',
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        EmptyState(
                          icon: LucideIcons.triangleAlert,
                          title: context.t('errors.title'),
                          body: messageForError(context, e),
                          action: EmptyStateAction(
                            label: context.t('common.retry'),
                            onPressed: () => ref
                                .invalidate(interestedProvider(opportunityId)),
                          ),
                        ),
                      ],
                    );
                  },
                  data: (List<InterestedUser> users) {
                    if (users.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          EmptyState(
                            icon: LucideIcons.heart,
                            title: context.t('opportunities.interested.empty'),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext c, int i) {
                        return _InterestedRow(user: users[i]);
                      },
                    );
                  },
                ),
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
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return AppCard(
      onTap: () => context.push(Routes.publicProfile(user.handle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
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
                          relativeTimeAgo(context, user.createdAt),
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
          const SizedBox(height: 10),
          // Direct-connect action — author can reach out without
          // bouncing through the public profile. (Validation UX gap #2.)
          Row(
            children: <Widget>[
              Expanded(
                child: IntroOrChatButton(
                  buttonKey: Key('interested.${user.userId}.sendIntro'),
                  recipient: SendIntroRecipient(
                    id: user.userId,
                    name: user.name,
                    handle: user.handle,
                    photoUrl: user.photoUrl,
                  ),
                  introLabel: context.t('opportunities.interested.sendIntro'),
                  introVariant: AppButtonVariant.gold,
                  introIcon: LucideIcons.send,
                  size: AppButtonSize.small,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  key: Key('interested.${user.userId}.viewProfile'),
                  label: context.t('opportunities.interested.viewProfile'),
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  icon: LucideIcons.user,
                  onPressed: () =>
                      context.push(Routes.publicProfile(user.handle)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
