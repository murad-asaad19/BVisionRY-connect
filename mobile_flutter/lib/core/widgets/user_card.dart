import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'avatar.dart';
import 'pill.dart';

/// Pressable user-cell used by discovery / search / suggested-intro lists.
///
/// Layout: 38px [Avatar] on the left + a tight column of name (with
/// optional verified badge), primary-role [Pill], headline (max 2 lines),
/// and "city · country" meta. Wrapped in [AppCard] so it picks up the
/// gallery's 14-radius / 1px-border surface and ripples on press.
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.name,
    required this.primaryRole,
    this.photoUrl,
    this.headline,
    this.city,
    this.country,
    this.verified = false,
    this.featured = false,
    this.onTap,
  });

  final String name;
  final String primaryRole;
  final String? photoUrl;
  final String? headline;
  final String? city;
  final String? country;

  /// Renders a gold BadgeCheck beside the name. Wire to
  /// `profile.verified_github_username != null`.
  final bool verified;

  /// Promotes the card to the featured (gold-gradient) variant.
  final bool featured;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final location = _location(city, country);

    return AppCard(
      variant:
          featured ? AppCardVariant.featured : AppCardVariant.defaultVariant,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(
            name: name,
            photoUrl: photoUrl,
            size: 38,
            tone: featured ? AvatarTone.featured : AvatarTone.defaultTone,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typo.displaySm.copyWith(color: c.navy),
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: c.gold,
                        semanticLabel: 'Verified',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Pill(
                  label: primaryRole,
                  variant:
                      featured ? PillVariant.solid : PillVariant.defaultVariant,
                ),
                if (headline != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    headline!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodyMd.copyWith(color: c.body),
                  ),
                ],
                if (location != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodySm.copyWith(color: c.muted),
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

String? _location(String? city, String? country) {
  final parts = <String>[];
  if (city != null && city.isNotEmpty) parts.add(city);
  if (country != null && country.isNotEmpty) parts.add(country);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}
