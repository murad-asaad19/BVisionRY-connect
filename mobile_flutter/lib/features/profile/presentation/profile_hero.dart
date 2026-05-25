import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Read-only DTO consumed by [ProfileHero]. We unify the surface so the hero
/// can render both [Profile] (own view) and [PublicProfile] (anon `/p/:handle`
/// view) without leaking either class up here.
@immutable
class ProfileHeroData {
  const ProfileHeroData({
    required this.name,
    required this.headline,
    required this.city,
    required this.country,
    required this.roles,
    required this.primaryRole,
    required this.photoUrl,
    required this.verified,
  });

  final String? name;
  final String? headline;
  final String? city;
  final String? country;
  final List<String> roles;
  final String? primaryRole;
  final String? photoUrl;

  /// When `true` the hero renders the gold verified-badge halo on the avatar.
  /// MUST be `false` for the anon `/p/:handle` view per spec §17.2.
  final bool verified;
}

/// Profile hero band — gallery section D1.
///
/// Visual: navy → navyLight linear gradient (top → bottom), gold radial glow
/// at the top-center, large avatar (76dp), name (display 18px white),
/// headline (12px gold-light), `city · country` meta, then a wrapped row of
/// role [Pill]s (one solid for the primary role, outlines for the rest).
class ProfileHero extends StatelessWidget {
  const ProfileHero({super.key, required this.data});

  final ProfileHeroData data;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final String location = <String?>[data.city, data.country]
        .where((String? v) => v != null && v.isNotEmpty)
        .cast<String>()
        .join(' · ');

    return Container(
      key: const ValueKey<String>('profile-hero-frame'),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // 135deg ≈ topLeft → bottomRight in Flutter terms.
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.navy, colors.navyLight],
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Gold radial glow at top-center, 18% opacity per spec.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1.2),
                    radius: 0.9,
                    colors: <Color>[
                      colors.gold.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Avatar(
                  name: data.name ?? '',
                  photoUrl: data.photoUrl,
                  size: 76,
                  tone: data.verified
                      ? AvatarTone.featured
                      : AvatarTone.defaultTone,
                ),
                const SizedBox(height: 14),
                Text(
                  data.name ?? '',
                  style: typo.displayLg.copyWith(
                    color: colors.white,
                    fontSize: 18,
                  ),
                ),
                if (data.headline != null &&
                    data.headline!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    data.headline!,
                    style: typo.bodyMd.copyWith(color: colors.goldLight),
                  ),
                ],
                if (location.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    location,
                    style: typo.bodySm.copyWith(color: colors.goldLight),
                  ),
                ],
                if (data.roles.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final String r in data.roles)
                        Pill(
                          label: _capitalize(r),
                          variant: r == data.primaryRole
                              ? PillVariant.solid
                              : PillVariant.outline,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
