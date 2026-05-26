import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'avatar.dart';

/// Pressable user-cell used by discovery / search / suggested-intro lists.
///
/// Layout mirrors the gallery `.ucard` rule: 38px [Avatar] + a column of
/// name (with optional inline ✓ verified pill), a muted role-line
/// (`"Role · City · Country"`), an optional 2-line headline, and an
/// optional inline [reason] chip rendered below.
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
    this.reason,
    this.onTap,
  });

  final String name;
  final String primaryRole;
  final String? photoUrl;
  final String? headline;
  final String? city;
  final String? country;

  /// Renders the inline green ✓ pill beside the name, labelled with the
  /// capitalized [primaryRole] (gallery's `.verified-badge`). Wire to
  /// `profile.verified_github_username != null`.
  final bool verified;

  /// Promotes the card to the featured (gold-gradient) variant.
  final bool featured;

  /// Optional widget rendered inline below the headline — used by
  /// [MatchCard] to display the gallery's `.reason` chip.
  final Widget? reason;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final roleLine = _roleLine(primaryRole, city, country);

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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      const SizedBox(width: 6),
                      _VerifiedDot(color: c.success, bg: c.successBg),
                    ],
                  ],
                ),
                if (roleLine != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    roleLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodySm.copyWith(color: c.muted),
                  ),
                ],
                if (headline != null && headline!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    headline!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodyMd.copyWith(color: c.body),
                  ),
                ],
                if (reason != null) ...[
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerLeft, child: reason!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Composes the gallery's `.role` line: `"Role · City · Country"`. Empty
/// parts are skipped; returns null when every part is missing.
String? _roleLine(String primaryRole, String? city, String? country) {
  final parts = <String>[];
  if (primaryRole.isNotEmpty) parts.add(_capitalize(primaryRole));
  if (city != null && city.isNotEmpty) parts.add(city);
  if (country != null && country.isNotEmpty) parts.add(country);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

/// Compact 14px verified dot rendered inline next to the user name. The
/// role line directly below already names the role, so we drop the label
/// the gallery shows inside `.verified-badge` — bare ✓ glyph reads cleaner.
class _VerifiedDot extends StatelessWidget {
  const _VerifiedDot({required this.color, required this.bg});

  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Verified',
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(Icons.check, size: 10, color: color),
      ),
    );
  }
}
