import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_service_provider.dart';
import '../../auth/providers/profile_provider.dart';
import '../domain/profile.dart';
import '../domain/profile_signals.dart';
import '../providers/profile_signals_provider.dart';
import 'goal_refresh_card.dart';
import 'profile_hero.dart';
import 'profile_signals_row.dart';

/// Host name used to compose the public share URL for `/p/:handle`. Keeping
/// it as a top-level constant lets Phase-12 deep-link / branding swaps
/// override it via a `--dart-define`.
const String _kPublicHost = 'app.bvisionry.com';

/// Own profile view — gallery section D1.
///
/// Layout: [ProfileHero] band → optional [GoalRefreshCard] when stale →
/// "I'm looking to" gold section → "I am" bio section → structured details →
/// signals row → share + edit + sign-out actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AsyncValue<Profile?> asyncProfile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('profile.title'),
          actions: <TopBarAction>[
            TopBarAction(
              icon: Icons.edit_outlined,
              label: context.t('profile.edit.title'),
              onPressed: () => context.go(Routes.profileEdit),
            ),
          ],
        ),
      ),
      body: QueryState<Profile?>(
        value: asyncProfile,
        onRetry: () => ref.invalidate(profileProvider),
        data: (Profile? profile) {
          if (profile == null) {
            return Center(
              child: Text(context.t('profile.notFound')),
            );
          }
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final Profile profile;

  Uri get _publicUri =>
      Uri.parse('https://$_kPublicHost/p/${profile.handle ?? ''}');

  Future<void> _share(BuildContext context) async {
    if ((profile.handle ?? '').isEmpty) return;
    await Share.shareUri(_publicUri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AsyncValue<ProfileSignals> asyncSignals =
        ref.watch(profileSignalsProvider(profile.id));

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        ProfileHero(
          data: ProfileHeroData(
            name: profile.name,
            headline: profile.headline,
            city: profile.city,
            country: profile.country,
            roles: profile.roles,
            primaryRole: profile.primaryRole,
            photoUrl: profile.photoUrl,
            verified: profile.isVerified,
          ),
        ),
        if (profile.isGoalStale)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: GoalRefreshCard(
              profile: profile,
              onUpdate: () => context.go(Routes.profileEdit),
            ),
          ),
        if ((profile.goalText ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _GoldSection(
              title: context.t('profile.lookingTo'),
              child: Text(
                profile.goalText!,
                style: typo.bodyLg.copyWith(color: colors.navy),
              ),
            ),
          ),
        if ((profile.bio ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SectionCard(
              title: context.t('profile.iAm'),
              child: Text(profile.bio!, style: typo.bodyLg),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SectionCard(
            title: context.t('profile.details'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _DetailRow(
                  label: context.t('profile.handle'),
                  value: '@${profile.handle ?? ''}',
                ),
                if (profile.primaryRole != null)
                  _DetailRow(
                    label: context.t('profile.primaryRoleLabel'),
                    value: _cap(profile.primaryRole!),
                  ),
                if (profile.roles.length > 1)
                  _DetailRow(
                    label: context.t('profile.allRoles'),
                    value: profile.roles.map(_cap).join(', '),
                  ),
                if ((profile.city ?? '').isNotEmpty ||
                    (profile.country ?? '').isNotEmpty)
                  _DetailRow(
                    label: context.t('profile.section.location'),
                    value: <String?>[profile.city, profile.country]
                        .where((String? v) => v != null && v.isNotEmpty)
                        .cast<String>()
                        .join(', '),
                  ),
                _DetailRow(
                  label: context.t('verification.github'),
                  value: profile.verifiedGithubUsername != null
                      ? '@${profile.verifiedGithubUsername}'
                      : context.t('profile.githubNotVerified'),
                ),
              ],
            ),
          ),
        ),
        asyncSignals.maybeWhen(
          data: (ProfileSignals signals) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ProfileSignalsRow(signals: signals),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  key: const Key('profileScreen.shareButton'),
                  label: context.t('profile.share'),
                  variant: AppButtonVariant.outline,
                  icon: Icons.share,
                  onPressed: () => _share(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  key: const Key('profileScreen.editButton'),
                  label: context.t('profile.edit.title'),
                  variant: AppButtonVariant.primary,
                  icon: Icons.edit,
                  onPressed: () => context.go(Routes.profileEdit),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AppButton(
            key: const Key('profileScreen.signOutButton'),
            label: context.t('profile.signOut'),
            variant: AppButtonVariant.outlineDanger,
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _GoldSection extends StatelessWidget {
  const _GoldSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.goldPale,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.goldLight),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: typo.displayXs.copyWith(
              color: colors.navy,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: typo.bodySm.copyWith(color: colors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: typo.bodyMd.copyWith(color: colors.body),
            ),
          ),
        ],
      ),
    );
  }
}
