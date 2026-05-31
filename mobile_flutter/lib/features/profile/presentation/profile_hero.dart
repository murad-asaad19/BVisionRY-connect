import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
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
    this.activeThisWeek = false,
  });

  final String? name;
  final String? headline;
  final String? city;
  final String? country;
  final List<String> roles;
  final String? primaryRole;
  final String? photoUrl;

  /// When `true` the hero renders the gold verified-badge halo on the avatar
  /// AND a green ✓ verified-badge pill inline beside the name, labelled with
  /// the primary role. MUST be `false` for the anon `/p/:handle` view per
  /// spec §17.2 — the badge is hidden anon to disincentivise scraping.
  final bool verified;

  /// When `true` the hero renders a small green "Active this week" recency
  /// pill alongside the location meta. Driven by [Profile.isActiveThisWeek];
  /// gracefully skipped when the data isn't available.
  final bool activeThisWeek;
}

/// Profile hero band — gallery section D1.
///
/// Visual: navyDark → navy → navyLight linear gradient (top → bottom), gold
/// radial glow at the top-center, large avatar (84dp), name (display 18px white),
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
    final String? primaryRoleLabel =
        (data.primaryRole == null || data.primaryRole!.isEmpty)
            ? null
            : _roleLabel(context, data.primaryRole!);

    return TweenAnimationBuilder<double>(
      // One-shot gentle fade-in on first build. Wraps (rather than replaces)
      // the band so the navy→navyLight gradient and gold radial glow are
      // untouched — they simply ease in with the rest of the hero.
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (BuildContext context, double t, Widget? band) =>
          Opacity(opacity: t, child: band),
      child: Container(
        key: const ValueKey<String>('profile-hero-frame'),
        width: double.infinity,
        decoration: BoxDecoration(
          // 3-stop vertical band (navyDark → navy → navyLight) for a richer
          // top-to-bottom fall-off behind the hero content.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[colors.navyDark, colors.navy, colors.navyLight],
            stops: const <double>[0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Gold radial glow tightened toward the top-center, 30% opacity.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.9),
                      radius: 0.7,
                      colors: <Color>[
                        colors.gold.withValues(alpha: 0.30),
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
                // Center-stacked to match the mockup's `.profile-hero` (avatar
                // margin:0 auto, name/head/meta/roles all centered).
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Avatar(
                    name: data.name ?? '',
                    photoUrl: data.photoUrl,
                    size: 84,
                    // Standalone hero avatar — name it for screen readers since
                    // the adjacent display name is decorative-styled text.
                    semanticLabel: (data.name ?? '').isEmpty ? null : data.name,
                    // Gold-gradient disc + double white/gold halo for the hero
                    // avatar per the mockup. Verified upgrades to `featured`
                    // explicitly; size >= 60 already resolves to the gold disc.
                    tone: data.verified
                        ? AvatarTone.featured
                        : AvatarTone.defaultTone,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    key: const ValueKey<String>('profile-hero-name-row'),
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      Text(
                        data.name ?? '',
                        textAlign: TextAlign.center,
                        style: typo.displayLg.copyWith(
                          color: colors.white,
                          fontSize: 18,
                        ),
                      ),
                      if (data.verified && primaryRoleLabel != null)
                        Semantics(
                          // The green ✓ pill conveys "verified" via colour +
                          // icon alone — label it so SR users get the meaning.
                          label: context.t(
                            'profile.a11y.verifiedRole',
                            vars: <String, Object>{'role': primaryRoleLabel},
                          ),
                          child: Pill(
                            key: const ValueKey<String>(
                              'profile-hero-verified-badge',
                            ),
                            label: primaryRoleLabel,
                            icon: Icons.check,
                            variant: PillVariant.success,
                          ),
                        ),
                    ],
                  ),
                  if (data.headline != null &&
                      data.headline!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      data.headline!,
                      textAlign: TextAlign.center,
                      style: typo.bodyMd.copyWith(color: colors.goldLight),
                    ),
                  ],
                  if (location.isNotEmpty || data.activeThisWeek) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        if (location.isNotEmpty)
                          Text(
                            location,
                            style:
                                typo.bodySm.copyWith(color: colors.goldLight),
                          ),
                        if (data.activeThisWeek)
                          Semantics(
                            // The star icon + green tint signals "recently
                            // active"; surface that meaning textually so it
                            // isn't conveyed by icon/colour alone.
                            label: context.t('profile.a11y.activeThisWeek'),
                            child: Pill(
                              key: const ValueKey<String>(
                                'profile-hero-active-pill',
                              ),
                              label: context.t('profile.activeThisWeek'),
                              icon: Icons.star,
                              variant: PillVariant.success,
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (data.roles.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final String r in data.roles)
                          Pill(
                            label: _roleLabel(context, r),
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
      ),
    );
  }

  /// Localized role label via `onboarding.roles.<role>`, falling back to a
  /// capitalized raw value for any unknown role kind.
  static String _roleLabel(BuildContext context, String role) {
    final String key = 'onboarding.roles.$role';
    final String label = context.t(key);
    if (label == key) {
      return role.isEmpty ? role : role[0].toUpperCase() + role.substring(1);
    }
    return label;
  }
}
