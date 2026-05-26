import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/profile_provider.dart';
import '../../profile/domain/profile.dart';
import '../data/verification_service.dart';

/// Settings → Verification screen.
///
/// Mirrors spec §17.3 + §6.15: only the GitHub proof type is functional in
/// this release. The other proof types render as disabled rows with a
/// "Coming soon" pill so the surface forward-advertises the verification
/// catalog without leaking partially-built flows.
///
/// The GitHub "Verify" button opens GitHub's authorize URL in an external
/// browser via [url_launcher]. The full OAuth code-exchange flow is wired
/// in the deep-link callback (Phase 12) — for this chunk we surface the
/// entry point + a "coming in next release" toast.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  static const String _kGithubAuthorizeUrl = 'https://github.com/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AsyncValue<Profile?> async = ref.watch(profileProvider);
    final Profile? profile = async.valueOrNull;
    final String? github = profile?.verifiedGithubUsername;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('verification.title'),
          back: true,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: <Widget>[
          // The "+15% ranking boost" intro paragraph (en.json
          // `verification.rankingBoost`) was hidden until Founder/Investor
          // proof types ship — surfacing it while only Builder can verify
          // creates an unfair tilt in the discovery feed.
          SectionCard(
            title: context.t('verification.builderSection'),
            padding: EdgeInsets.zero,
            child: _GithubRow(github: github),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: context.t('verification.founderSection'),
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _ComingSoonRow(
                  rowKey: const Key('verification.row.domain'),
                  label: context.t('verification.proofs.founder.domain.label'),
                  description: context
                      .t('verification.proofs.founder.domain.description'),
                ),
                _ComingSoonRow(
                  rowKey: const Key('verification.row.team_page'),
                  label:
                      context.t('verification.proofs.founder.team_page.label'),
                  description: context
                      .t('verification.proofs.founder.team_page.description'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: context.t('verification.investorSection'),
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _ComingSoonRow(
                  rowKey: const Key('verification.row.crunchbase'),
                  label: context
                      .t('verification.proofs.investor.crunchbase.label'),
                  description: context.t(
                    'verification.proofs.investor.crunchbase.description',
                  ),
                ),
                _ComingSoonRow(
                  rowKey: const Key('verification.row.portfolio'),
                  label:
                      context.t('verification.proofs.investor.portfolio.label'),
                  description: context
                      .t('verification.proofs.investor.portfolio.description'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GithubRow extends ConsumerWidget {
  const _GithubRow({required this.github});
  final String? github;

  Future<void> _stubLaunch() async {
    final Uri uri = Uri.parse(VerificationScreen._kGithubAuthorizeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (github != null) {
      return SettingsRow(
        key: const Key('verification.row.github'),
        icon: Icons.code,
        label: context.t('verification.github'),
        description: '@$github',
        trailing: AppButton(
          key: const Key('verification.github.disconnect'),
          label: context.t('verification.disconnect'),
          variant: AppButtonVariant.outlineDanger,
          size: AppButtonSize.small,
          fullWidth: false,
          onPressed: () async {
            await ref
                .read(verificationServiceProvider)
                .clearGithubVerification();
            ref.invalidate(profileProvider);
          },
        ),
      );
    }
    return SettingsRow(
      key: const Key('verification.row.github'),
      icon: Icons.code,
      label: context.t('verification.github'),
      description: context.t('verification.githubVerifyBody'),
      trailing: AppButton(
        key: const Key('verification.github.verify'),
        label: context.t('verification.verify'),
        variant: AppButtonVariant.gold,
        size: AppButtonSize.small,
        fullWidth: false,
        onPressed: () async {
          await _stubLaunch();
          if (!context.mounted) return;
          ref.read(toastServiceProvider.notifier).showToast(
                title: context.t('verification.githubStub'),
                intent: AppIntent.info,
              );
        },
      ),
    );
  }
}

class _ComingSoonRow extends StatelessWidget {
  const _ComingSoonRow({
    required this.rowKey,
    required this.label,
    required this.description,
  });
  final Key rowKey;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: typo.displaySm.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: typo.bodySm.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(
            label: context.t('verification.comingSoon'),
            variant: PillVariant.muted,
          ),
        ],
      ),
    );
  }
}
