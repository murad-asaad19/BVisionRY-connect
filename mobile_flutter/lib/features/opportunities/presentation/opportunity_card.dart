import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/pill.dart';
import '../domain/opportunity_status.dart';
import '../domain/opportunity_with_author.dart';
import '_relative_time.dart';
import 'opportunity_kind_pill.dart';

/// Feed / list card for an [OpportunityWithAuthor].
///
/// Layout (top → bottom):
///   1. Author row: avatar(32) + name + relative time + kind pill.
///   2. Title (displayMd, navy, max 2 lines).
///   3. Body excerpt (bodyLg, body, max 3 lines, ellipsis).
///   4. Tags wrap (muted pills, ≤ 8 chips).
///   5. Meta row: city/country + remote pill + spacer + "N interested".
///
/// When [statusOverlay] is `true` and the opportunity is not `open`, a small
/// status pill renders next to the kind pill (used by My Opportunities to
/// flag closed / archived posts inline).
class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    super.key,
    required this.data,
    this.interestedCount,
    this.onTap,
    this.statusOverlay = false,
  });

  final OpportunityWithAuthor data;
  final int? interestedCount;
  final VoidCallback? onTap;
  final bool statusOverlay;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final o = data.opportunity;
    final int count = interestedCount ?? data.interestedCount ?? 0;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Author row ─────────────────────────────────────────────
          Row(
            children: <Widget>[
              AvatarCircle(
                name: data.authorName,
                photoUrl: data.authorPhotoUrl,
                size: 32,
                tone: AvatarTone.muted,
              ),
              SizedBox(width: spacing.card),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      data.authorName,
                      style: typo.displaySm.copyWith(color: colors.body),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      relativeShort(o.createdAt),
                      style: typo.bodyXs.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              if (statusOverlay &&
                  o.status != OpportunityStatus.open) ...<Widget>[
                Pill(
                  label: _statusLabel(context, o.status),
                  size: PillSize.sm,
                  variant: PillVariant.muted,
                ),
                const SizedBox(width: 6),
              ],
              OpportunityKindPill(kind: o.kind, size: PillSize.sm),
            ],
          ),
          SizedBox(height: spacing.card),
          // ── Title ──────────────────────────────────────────────────
          Text(
            o.title,
            style: typo.displayMd.copyWith(color: colors.navy),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing.card / 2),
          // ── Body excerpt ──────────────────────────────────────────
          Text(
            o.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: typo.bodyLg.copyWith(color: colors.body),
          ),
          if (o.tags.isNotEmpty) ...<Widget>[
            SizedBox(height: spacing.card),
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
          SizedBox(height: spacing.card),
          // ── Meta row ──────────────────────────────────────────────
          Row(
            children: <Widget>[
              if (_hasLocation(o.locationCity, o.locationCountry))
                Flexible(
                  child: Text(
                    <String?>[o.locationCity, o.locationCountry]
                        .where((String? s) => s != null && s.isNotEmpty)
                        .join(' · '),
                    style: typo.bodySm.copyWith(color: colors.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (o.remoteOk) ...<Widget>[
                if (_hasLocation(o.locationCity, o.locationCountry))
                  SizedBox(width: spacing.card / 2),
                Pill(
                  label: context.t('opportunities.filter.remoteOnly'),
                  size: PillSize.sm,
                  variant: PillVariant.outline,
                  icon: LucideIcons.globe,
                ),
              ],
              const Spacer(),
              Icon(LucideIcons.heart, size: 14, color: colors.muted),
              const SizedBox(width: 4),
              Text(
                context.t(
                  count == 1
                      ? 'opportunities.detail.viewInterested_one'
                      : 'opportunities.detail.viewInterested_other',
                  vars: <String, Object>{'count': count},
                ),
                style: typo.bodySm.copyWith(color: colors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _hasLocation(String? city, String? country) {
    final bool hasCity = city != null && city.isNotEmpty;
    final bool hasCountry = country != null && country.isNotEmpty;
    return hasCity || hasCountry;
  }

  static String _statusLabel(BuildContext context, OpportunityStatus status) {
    return switch (status) {
      OpportunityStatus.closed => context.t('opportunities.detail.closedBadge'),
      OpportunityStatus.archived =>
        context.t('opportunities.detail.closedBadge'),
      OpportunityStatus.open => '',
    };
  }
}
