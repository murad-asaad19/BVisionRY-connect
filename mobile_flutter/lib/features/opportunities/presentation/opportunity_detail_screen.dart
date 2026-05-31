import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/i18n/relative_time.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
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

    // Resolve author status from whatever value we currently have so the
    // kebab can live on the single persistent TopBar (no second bar inside
    // the scroll body).
    final OpportunityWithCounts? resolved = async.valueOrNull;
    final bool isAuthor = resolved != null &&
        viewerId != null &&
        viewerId == resolved.withAuthor.opportunity.authorId;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            // Persistent chrome — stays mounted on the loading / error /
            // not-found states so the user always has a way back to the feed.
            TopBar(
              title: context.t('opportunities.detail.title'),
              back: true,
              actions: isAuthor
                  ? <TopBarAction>[
                      TopBarAction(
                        key: const Key('opportunityDetail.kebab'),
                        icon: LucideIcons.ellipsisVertical,
                        label: context.t('common.more'),
                        onPressed: () => _DetailMenu.show(
                          context,
                          ref,
                          detail: resolved,
                        ),
                      ),
                    ]
                  : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(opportunityProvider(opportunityId));
                  await ref.read(opportunityProvider(opportunityId).future);
                },
                child: QueryState<OpportunityWithCounts>(
                  value: async,
                  onRetry: () =>
                      ref.invalidate(opportunityProvider(opportunityId)),
                  error: (Object e, _) =>
                      _DetailError(error: e, opportunityId: opportunityId),
                  data: (OpportunityWithCounts d) =>
                      _Body(detail: d, isAuthor: isAuthor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error surface for the detail screen. A [NotFoundException] (deleted /
/// expired / RLS-hidden / closed row reached via deep-link) gets a tailored
/// "no longer available" empty state with a Back-to-feed action; every other
/// failure falls back to a localized retry empty state.
class _DetailError extends ConsumerWidget {
  const _DetailError({required this.error, required this.opportunityId});

  final Object error;
  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error is NotFoundException) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          EmptyState(
            icon: LucideIcons.searchX,
            title: context.t('opportunities.detail.notFoundTitle'),
            body: context.t('opportunities.detail.notFound'),
            action: EmptyStateAction(
              label: context.t('opportunities.detail.backToFeed'),
              onPressed: () => context.go(Routes.opportunities),
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
          body: messageForError(context, error),
          action: EmptyStateAction(
            label: context.t('common.retry'),
            onPressed: () => ref.invalidate(opportunityProvider(opportunityId)),
          ),
        ),
      ],
    );
  }
}

/// Author-only kebab menu for the detail screen. Anchored to the top-right
/// of the screen (where the TopBar action lives) so the popup lines up with
/// the button instead of mis-anchoring off a stale ancestor render box.
abstract final class _DetailMenu {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required OpportunityWithCounts detail,
  }) async {
    final Size screen = MediaQuery.of(context).size;
    final double top = MediaQuery.of(context).padding.top + 52;
    final int? choice = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(screen.width - 12, top, 12, 0),
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
        context.push(Routes.opportunityEdit(detail.withAuthor.opportunity.id)),
      );
    } else if (choice == 1) {
      await _close(context, ref, detail);
    }
  }

  static Future<void> _close(
    BuildContext context,
    WidgetRef ref,
    OpportunityWithCounts detail,
  ) async {
    // confirm() handles ONLY the yes/no decision. Running the RPC inside its
    // `onConfirm` swallowed failures silently (the sheet just closed with
    // `false`); instead we run the mutation + invalidations here so we can
    // branch on success vs. failure and surface the right toast.
    final bool confirmed = await ref.read(confirmServiceProvider).confirm(
          context,
          title: context.t('opportunities.detail.closeConfirmTitle'),
          body: context.t('opportunities.detail.closeConfirmBody'),
          confirmLabel: context.t('opportunities.detail.closeConfirmCta'),
          cancelLabel: context.t('common.cancel'),
          destructive: true,
        );
    if (!confirmed || !context.mounted) return;

    final String oppId = detail.withAuthor.opportunity.id;
    try {
      await ref.read(opportunitiesServiceProvider).closeOpportunity(oppId);
      // Invalidate + await the next future so the detail screen repaints with
      // the Closed pill before the success toast fires.
      ref.invalidate(opportunityProvider(oppId));
      ref.invalidate(myOpportunitiesProvider);
      ref.invalidate(opportunitiesFeedProvider);
      await ref.read(opportunityProvider(oppId).future);
      if (!context.mounted) return;
      // Posting/closing an opportunity is a light-tick moment (not a heavy
      // confirmation) per the app's haptic vocabulary.
      Haptics.light();
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('opportunities.detail.closeSuccess'),
            intent: AppIntent.success,
          );
    } catch (e) {
      if (!context.mounted) return;
      Haptics.error();
      ref.read(toastServiceProvider.notifier).showToast(
            title: messageForError(context, e),
            intent: AppIntent.danger,
          );
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail, required this.isAuthor});

  final OpportunityWithCounts detail;
  final bool isAuthor;

  Future<void> _onExpressInterest(BuildContext context) async {
    await showExpressInterestSheet(
      context,
      opportunityId: detail.withAuthor.opportunity.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final o = detail.withAuthor.opportunity;
    final bool isClosed = o.status != OpportunityStatus.open;
    final bool isExpired = o.expiresAt.isBefore(DateTime.now().toUtc());

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
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
                            '@${detail.withAuthor.authorHandle} · ${relativeTimeAgo(context, o.createdAt)}',
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
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OpportunityKindPill(kind: o.kind),
                  if (isClosed)
                    Pill(
                      label: context.t('opportunities.detail.closedBadge'),
                      variant: PillVariant.muted,
                    )
                  // Expired-but-open: surface a warning pill so the stale
                  // state reads as caution, not as a normal open post.
                  else if (isExpired)
                    Pill(
                      label: context.t('time.expired'),
                      variant: PillVariant.warning,
                      icon: LucideIcons.clock,
                    ),
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
                          variant: PillVariant.tag,
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
                      // Foundation helper already returns `time.expired` copy
                      // for past dates; flag the row so it styles in warning.
                      text: isExpired
                          ? context.t(
                              'opportunities.detail.expiredOn',
                              vars: <String, Object>{
                                'date': _expiryDate(context, o.expiresAt),
                              },
                            )
                          : relativeTimeUntil(context, o.expiresAt),
                      warning: isExpired,
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

/// Locale-aware date for the "expired on …" meta line. Uses `DateFormat
/// .yMMMd()` (no hardcoded pattern) so month names / ordering follow locale.
String _expiryDate(BuildContext context, DateTime utc) {
  final String locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(utc.toLocal());
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.warning = false,
  });

  final IconData icon;
  final String text;

  /// Renders the row in the warning palette (used for the expired-on line).
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final Color fg = warning ? colors.warning : colors.body;
    final Color iconColor = warning ? colors.warning : colors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: typo.bodyMd.copyWith(
                color: fg,
                fontWeight: warning ? FontWeight.w600 : null,
              ),
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
    // Cross-fade between the CTA and its resolved states (e.g. the gold
    // "Express interest" button flipping to a success banner once interest
    // is registered) so the action area transitions gently, not abruptly.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: KeyedSubtree(
        key: ValueKey<String>(
          detail.viewerHasExpressedInterest
              ? 'interested'
              : isClosed
                  ? 'closed'
                  : isExpired
                      ? 'expired'
                      : 'open',
        ),
        child: _buildState(context),
      ),
    );
  }

  Widget _buildState(BuildContext context) {
    if (detail.viewerHasExpressedInterest) {
      return AppBanner(
        intent: AppIntent.success,
        title: context.t('opportunities.detail.expressedAlready'),
        child: const SizedBox.shrink(),
      );
    }
    // Closed → neutral; expired-but-open → warning (a distinct, caution
    // state, NOT the same "closed" copy). In both cases the Express interest
    // CTA is unavailable: the button collapses to its disabled visual via the
    // null `onPressed` so a stale/expired post can never accept interest.
    if (isClosed) {
      return AppBanner(
        intent: AppIntent.neutral,
        title: context.t('opportunities.detail.closedBadge'),
        child: const SizedBox.shrink(),
      );
    }
    if (isExpired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppBanner(
            intent: AppIntent.warning,
            title: context.t('opportunities.detail.expiredTitle'),
            child: Text(context.t('opportunities.detail.expiredBody')),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: context.t('opportunities.detail.expressInterestCta'),
            variant: AppButtonVariant.gold,
            onPressed: null,
          ),
        ],
      );
    }
    return AppButton(
      label: context.t('opportunities.detail.expressInterestCta'),
      variant: AppButtonVariant.gold,
      onPressed: () {
        Haptics.light();
        onExpressInterest();
      },
    );
  }
}
