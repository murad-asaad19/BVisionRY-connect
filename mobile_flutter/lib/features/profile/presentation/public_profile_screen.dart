import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/session_provider.dart';
import '../../intros/presentation/send_intro_sheet.dart';
import '../../office_hours/presentation/office_hours_section_on_profile.dart';
import '../data/public_profile_service.dart';
import '../providers/public_profile_provider.dart';
import 'profile_hero.dart';

/// Anon-accessible `/p/:handle` preview — gallery section D2.
///
/// IMPORTANT (spec §17.2): we MUST NOT render the verified badge here even
/// when the RPC returns a `verified_github_username`. The badge is reserved
/// for the authed views; surfacing it on the anon `/p/:handle` is an
/// anti-scrape consideration. We achieve this by passing `verified: false`
/// to [ProfileHero] unconditionally.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.handle});
  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AsyncValue<PublicProfile?> async =
        ref.watch(publicProfileProvider(handle));
    final bool isAuthed = ref.watch(sessionProvider).valueOrNull != null;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: 'bvisionry',
          back: Navigator.of(context).canPop(),
        ),
      ),
      body: QueryState<PublicProfile?>(
        value: async,
        onRetry: () => ref.invalidate(publicProfileProvider(handle)),
        data: (PublicProfile? profile) {
          if (profile == null) {
            return Padding(
              key: const Key('publicProfile.notFound'),
              padding: const EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.person_off_outlined,
                title: context.t('profile.notFoundTitle'),
                body: context.t('profile.notFoundBody'),
              ),
            );
          }
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
                  // Per spec §17.2 — never surface the verified badge anon.
                  verified: false,
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
              if ((profile.city ?? '').isNotEmpty ||
                  (profile.country ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: SectionCard(
                    title: context.t('profile.section.location'),
                    child: Text(
                      <String?>[profile.city, profile.country]
                          .where((String? v) => v != null && v.isNotEmpty)
                          .cast<String>()
                          .join(', '),
                      style: typo.bodyMd.copyWith(color: colors.body),
                    ),
                  ),
                ),
              if (isAuthed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: OfficeHoursSectionOnProfile(hostId: profile.id),
                ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AppButton(
                  key: const Key('publicProfile.cta'),
                  label: isAuthed
                      ? context.t('profile.sendIntro')
                      : context.t('profile.signInToConnect'),
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    if (!isAuthed) {
                      context.go(Routes.signIn);
                      return;
                    }
                    showSendIntroSheet(
                      context,
                      recipient: SendIntroRecipient(
                        id: profile.id,
                        name: profile.name ?? profile.handle,
                        handle: profile.handle,
                        photoUrl: profile.photoUrl,
                        // Per spec §17.2 we don't render the verified
                        // badge anonymously — but the sheet only opens for
                        // an authed caller, so it's safe to honour the
                        // server-provided flag here.
                        verified: profile.verifiedGithubUsername != null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
