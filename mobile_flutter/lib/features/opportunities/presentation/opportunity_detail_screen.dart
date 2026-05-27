import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/query_state.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/variants.dart';
import '../../auth/providers/session_provider.dart';
import '../data/opportunities_service.dart';
import '../domain/opportunity_status.dart';
import '../domain/opportunity_with_counts.dart';
import '../providers/my_opportunities_provider.dart';
import '../providers/opportunities_feed_provider.dart';
import '../providers/opportunity_provider.dart';
import '_relative_time.dart';
import 'express_interest_sheet.dart';
import 'opportunity_kind_pill.dart';

/// Public detail screen for an opportunity.
///
/// Renders the author-specific (Edit / Close kebab + "N interested" link) or
/// viewer-specific (Express interest CTA / "You expressed interest" banner)
/// chrome depending on the relationship between the viewer and the
/// opportunity row.
class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OpportunityWithCounts> async =
        ref.watch(opportunityProvider(opportunityId));
    final String? viewerId = ref.watch(currentSessionProvider)?.user.id;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(opportunityProvider(opportunityId));
            await ref.read(opportunityProvider(opportunityId).future);
          },
          child: QueryState<OpportunityWithCounts>(
            value: async,
            data: (OpportunityWithCounts d) {
              final bool isAuthor = viewerId != null &&
                  viewerId == d.withAuthor.opportunity.authorId;
              return _Body(detail: d, isAuthor: isAuthor);
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.detail, required this.isAuthor});

  final OpportunityWithCounts detail;
  final bool isAuthor;

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await ref.read(confirmServiceProvider).confirm(
      context,
      title: context.t('opportunities.detail.closeConfirmTitle'),
      body: context.t('opportunities.detail.closeConfirmBody'),
      confirmLabel: context.t('opportunities.detail.closeConfirmCta'),
      cancelLabel: 'Cancel',
      destructive: true,
      onConfirm: () async {
        final String oppId = detail.withAuthor.opportunity.id;
        await ref.read(opportunitiesServiceProvider).closeOpportunity(oppId);
        // Invalidate + await the next future so the detail screen
        // repaints with the Closed pill before the success toast fires.
        // Previously the screen stayed on the stale (status='open')
        // snapshot until the next manual interaction.
        ref.invalidate(opportunityProvider(oppId));
        ref.invalidate(myOpportunitiesProvider);
        ref.invalidate(opportunitiesFeedProvider);
        await ref.read(opportunityProvider(oppId).future);
      },
    );
    if (!context.mounted) return;
    if (confirmed) {
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('opportunities.detail.closeSuccess'),
            intent: AppIntent.success,
          );
    }
  }

  Future<void> _showKebab(BuildContext context, WidgetRef ref) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Offset offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final int? choice = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + (box?.size.width ?? 0) - 200,
        offset.dy + 56,
        12,
        offset.dy + 220,
      ),
      items: <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          value: 0,
          child: Text(context.t('opportunities.edit.title')),
        ),
        if (detail.withAuthor.opportunity.status == OpportunityStatus.open)
          PopupMenuItem<int>(
            value: 1,
            child: Text(context.t('opportunities.detail.closeCta')),
          ),
      ],
    );
    if (!context.mounted) return;
    if (choice == 0) {
      unawaited(
        context.push(
          Routes.opportunityEdit(detail.withAuthor.opportunity.id),
        ),
      );
    } else if (choice == 1) {
      await _close(context, ref);
    }
  }

  Future<void> _onExpressInterest(BuildContext context) async {
    await showExpressInterestSheet(
      context,
      opportunityId: detail.withAuthor.opportunity.id,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final o = detail.withAuthor.opportunity;
    final bool isClosed = o.status != OpportunityStatus.open;
    final bool isExpired = o.expiresAt.isBefore(DateTime.now().toUtc());

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        TopBar(
          title: context.t('opportunities.detail.title'),
          back: true,
          actions: isAuthor
              ? <TopBarAction>[
                  TopBarAction(
                    icon: LucideIcons.ellipsisVertical,
                    label: 'Menu',
                    onPressed: () => _showKebab(context, ref),
                  ),
                ]
              : null,
        ),
        Padding(
          padding: EdgeInsets.all(spacing.cardLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Author hero ────────────────────────────────────────
              InkWell(
                onTap: () => context.push(
                  Routes.publicProfile(detail.withAuthor.authorHandle),
                ),
                child: Row(
                  children: <Widget>[
                    AvatarCircle(
                      name: detail.withAuthor.authorName,
                      photoUrl: detail.withAuthor.authorPhotoUrl,
                      size: 48,
                    ),
                    SizedBox(width: spacing.card),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            detail.withAuthor.authorName,
                            style: typo.displayLg.copyWith(
                              color: colors.navy,
                            ),
                          ),
                          Text(
                            '@${detail.withAuthor.authorHandle} · ${relativeShort(o.createdAt)}',
                            style: typo.bodySm.copyWith(color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.cardLg),
              // ── Kind + status pills ───────────────────────────────
              Row(
                children: <Widget>[
                  OpportunityKindPill(kind: o.kind),
                  if (isClosed) ...<Widget>[
                    const SizedBox(width: 6),
                    Pill(
                      label: context.t('opportunities.detail.closedBadge'),
                      variant: PillVariant.muted,
                    ),
                  ],
                ],
              ),
              SizedBox(height: spacing.cardLg),
              // ── Title ─────────────────────────────────────────────
              Text(
                o.title,
                style: typo.displayLg.copyWith(color: colors.navy),
              ),
              SizedBox(height: spacing.card),
              // ── Body ──────────────────────────────────────────────
              Text(
                o.body,
                style: typo.bodyLg.copyWith(color: colors.body),
              ),
              if (o.tags.isNotEmpty) ...<Widget>[
                SizedBox(height: spacing.cardLg),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: o.tags
                      .map(
                        (String t) => Pill(
                          label: t,
                          size: PillSize.sm,
                          variant: PillVariant.muted,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              SizedBox(height: spacing.cardLg),
              // ── Meta row ──────────────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (o.locationCity != null || o.locationCountry != null)
                      _MetaRow(
                        icon: LucideIcons.mapPin,
                        text: <String?>[o.locationCity, o.locationCountry]
                            .where((String? s) => s != null && s.isNotEmpty)
                            .join(' · '),
                      ),
                    if (o.remoteOk)
                      _MetaRow(
                        icon: LucideIcons.globe,
                        text: context.t('opportunities.filter.remoteOnly'),
                      ),
                    _MetaRow(
                      icon: LucideIcons.clock,
                      text: relativeFuture(o.expiresAt),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.cardLg),
              // ── Action area ──────────────────────────────────────
              if (isAuthor)
                _AuthorActions(detail: detail)
              else
                _ViewerActions(
                  detail: detail,
                  isClosed: isClosed,
                  isExpired: isExpired,
                  onExpressInterest: () => _onExpressInterest(context),
                ),
              SizedBox(height: spacing.cardLg),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: colors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: typo.bodyMd.copyWith(color: colors.body),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorActions extends StatelessWidget {
  const _AuthorActions({required this.detail});

  final OpportunityWithCounts detail;

  @override
  Widget build(BuildContext context) {
    final int count = detail.interestedCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (count > 0)
          AppButton(
            label: context.t(
              count == 1
                  ? 'opportunities.detail.viewInterested_one'
                  : 'opportunities.detail.viewInterested_other',
              vars: <String, Object>{'count': count},
            ),
            variant: AppButtonVariant.outline,
            onPressed: () => context.push(
              Routes.opportunityInterested(
                detail.withAuthor.opportunity.id,
              ),
            ),
          ),
      ],
    );
  }
}

class _ViewerActions extends StatelessWidget {
  const _ViewerActions({
    required this.detail,
    required this.isClosed,
    required this.isExpired,
    required this.onExpressInterest,
  });

  final OpportunityWithCounts detail;
  final bool isClosed;
  final bool isExpired;
  final VoidCallback onExpressInterest;

  @override
  Widget build(BuildContext context) {
    if (detail.viewerHasExpressedInterest) {
      return AppBanner(
        intent: AppIntent.success,
        title: context.t('opportunities.detail.expressedAlready'),
        child: const SizedBox.shrink(),
      );
    }
    if (isClosed || isExpired) {
      return AppBanner(
        intent: AppIntent.neutral,
        title: context.t('opportunities.detail.closedBadge'),
        child: const SizedBox.shrink(),
      );
    }
    return AppButton(
      label: context.t('opportunities.detail.expressInterestCta'),
      variant: AppButtonVariant.gold,
      onPressed: onExpressInterest,
    );
  }
}
