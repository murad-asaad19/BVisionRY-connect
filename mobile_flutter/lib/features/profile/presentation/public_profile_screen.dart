import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/session_provider.dart';
import '../../chat/providers/conversation_overview_provider.dart';
import '../../intros/presentation/send_intro_sheet.dart';
import '../../office_hours/presentation/office_hours_section_on_profile.dart';
import '../../privacy/privacy.dart';
import '../data/public_profile_service.dart';
import '../providers/intro_cooldown_provider.dart';
import '../providers/public_profile_provider.dart';

/// Host name used to compose the public share URL for `/p/:handle`. Keeping
/// it as a top-level constant lets Phase-12 deep-link / branding swaps
/// override it via a `--dart-define`. Mirrors the value in profile_screen.
const String _kPublicHost = 'connect.bvisionry.com';

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
          // Show the peer's @handle so the bar carries useful context.
          // Previously hard-coded to the brand name which looked like
          // stale boilerplate.
          title: '@$handle',
          back: Navigator.of(context).canPop(),
        ),
      ),
      body: QueryState<PublicProfile?>(
        value: async,
        onRetry: () => ref.invalidate(publicProfileProvider(handle)),
        data: (PublicProfile? profile) {
          if (profile == null) {
            // `get_public_profile` collapses suspended/private/missing rows
            // into a single null response — UX-wise we still want to give
            // the caller a softer signal when the handle looks valid (i.e.
            // is non-empty), so we treat that case as "private" per spec
            // §17.2's hide-rather-than-leak guidance.
            final bool looksLikeHandle =
                handle.trim().isNotEmpty && handle.trim().length >= 2;
            return Padding(
              key: looksLikeHandle
                  ? const Key('publicProfile.private')
                  : const Key('publicProfile.notFound'),
              padding: const EdgeInsets.all(24),
              child: EmptyState(
                icon: looksLikeHandle
                    ? Icons.lock_outline
                    : Icons.person_off_outlined,
                title: context.t(
                  looksLikeHandle
                      ? 'profile.privateTitle'
                      : 'profile.notFoundTitle',
                ),
                body: context.t(
                  looksLikeHandle
                      ? 'profile.privateBody'
                      : 'profile.notFoundBody',
                ),
              ),
            );
          }
          final IntroCooldownState cooldown = isAuthed
              ? ref.watch(introCooldownProvider(profile.id)).valueOrNull ??
                  const IntroCooldownState()
              : const IntroCooldownState();
          final String? cooldownDate = cooldown.availableAt == null
              ? null
              : _formatDate(cooldown.availableAt!);
          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              _PublicProfileHeader(
                profile: profile,
                host: _kPublicHost,
              ),
              if (cooldown.active)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: AppBanner(
                    key: const ValueKey<String>(
                      'publicProfile.cooldownBanner',
                    ),
                    intent: AppIntent.warning,
                    title: context.t('profile.introOnHoldTitle'),
                    child: Text(
                      context.t(
                        'profile.introOnHoldBody',
                        vars: <String, Object>{
                          'name': profile.name ?? profile.handle,
                          'date': cooldownDate ?? '',
                        },
                      ),
                    ),
                  ),
                ),
              if (isAuthed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: OfficeHoursSectionOnProfile(hostId: profile.id),
                ),
              const SizedBox(height: 24),
              // Centered primary (navy) CTA — the navy band wrapper was
              // dropped so the action floats on the light surface. The added
              // cooldown / sign-in / existing-conversation states are kept.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  key: const ValueKey<String>('publicProfile.ctaFooter'),
                  // A Consumer scopes the existing-conversation watch to this
                  // CTA (correct ref binding) and lets it take priority over
                  // the cooldown / sign-in branches: if you already chat with
                  // this person, "Open chat" is the only sensible action.
                  child: Consumer(
                    builder: (BuildContext context, WidgetRef ref, _) {
                      final String? existingConvId = isAuthed
                          ? ref.watch(
                              conversationIdForPeerProvider(profile.id),
                            )
                          : null;
                      if (existingConvId != null) {
                        return AppButton(
                          key: const Key('publicProfile.openChat'),
                          label: context.t('chat.openChat'),
                          variant: AppButtonVariant.primary,
                          fullWidth: false,
                          icon: LucideIcons.messageSquare,
                          onPressed: () {
                            Haptics.light();
                            context.push(Routes.chat(existingConvId));
                          },
                        );
                      }
                      return AppButton(
                        key: const Key('publicProfile.cta'),
                        label: !isAuthed
                            ? context.t('profile.signInToConnect')
                            : cooldown.active
                                ? context.t(
                                    cooldownDate != null
                                        ? 'profile.cooldown.buttonAvailableDate'
                                        : 'profile.cooldown.buttonAvailableSoon',
                                    vars: cooldownDate != null
                                        ? <String, Object>{'date': cooldownDate}
                                        : null,
                                  )
                                : context.t('profile.sendIntro'),
                        // Primary (navy) fill on the light surface.
                        variant: AppButtonVariant.primary,
                        fullWidth: false,
                        disabled: isAuthed && cooldown.active,
                        onPressed: cooldown.active && isAuthed
                            ? null
                            : () {
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
                                    role: profile.primaryRole,
                                    headline: profile.headline,
                                    // Per spec §17.2 we don't render the
                                    // verified badge anonymously — but the
                                    // sheet only opens for an authed caller, so
                                    // it's safe to honour the server flag here.
                                    verified:
                                        profile.verifiedGithubUsername != null,
                                  ),
                                );
                              },
                      );
                    },
                  ),
                ),
              ),
              // Safety actions — only rendered to authed viewers. Anon
              // visitors don't get a Block CTA because they have no
              // identity to bind the block to. Demoted to a compact inline
              // pairing: the existing [BlockButton] (kept intact so its
              // confirm/unblock flow is untouched) beside a muted "Report"
              // text link separated by a '·'.
              if (isAuthed) ...<Widget>[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      BlockButton(
                        userId: profile.id,
                        name: profile.name ?? profile.handle,
                        handle: profile.handle,
                        size: AppButtonSize.small,
                        fullWidth: false,
                      ),
                      Text(
                        ' · ',
                        style: typo.bodySm.copyWith(
                          color: colors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      InkWell(
                        key: const Key('publicProfile.report'),
                        onTap: () => showReportSheet(
                          context,
                          targetType: ReportTargetType.profile,
                          targetId: profile.id,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Text(
                            context.t('chat.actions.report'),
                            style: typo.bodySm.copyWith(
                              color: colors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

/// Compact short-form date for the cooldown CTA ("May 28"). [DateFormat.MMMd]
/// follows the active locale's month names + day/month ordering, so the EN
/// and ES renderings of section I4 stay correct without a hand-rolled table.
String _formatDate(DateTime dt) => DateFormat.MMMd().format(dt.toLocal());

/// Centered public-profile header — gallery section D2 (lines 1714-1724).
///
/// Layout: 96px avatar (centered), name (navy heading, centered), headline
/// (body, centered), single role pill (gold solid, centered), location
/// (muted, centered), `connect.bvisionry.com/p/<handle>` URL line below.
///
/// Per spec §17.2 the verified badge is NEVER surfaced here — the badge
/// stays inside the authed app. The standard [ProfileHero] is not reused
/// because that hero is left-aligned and dark-themed; D2 is light-mode and
/// centered.
class _PublicProfileHeader extends StatelessWidget {
  const _PublicProfileHeader({required this.profile, required this.host});

  final PublicProfile profile;
  final String host;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final String location = <String?>[profile.city, profile.country]
        .where((String? v) => v != null && v.isNotEmpty)
        .cast<String>()
        .join(', ');
    final String? roleLabel =
        (profile.primaryRole == null || profile.primaryRole!.isEmpty)
            ? null
            : _roleLabel(context, profile.primaryRole!);

    return Padding(
      key: const ValueKey<String>('public-profile-header'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Avatar(
            name: profile.name ?? profile.handle,
            photoUrl: profile.photoUrl,
            size: 96,
          ),
          const SizedBox(height: 14),
          Text(
            profile.name ?? '',
            textAlign: TextAlign.center,
            style: typo.displayLg.copyWith(color: colors.navy),
          ),
          if ((profile.headline ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              profile.headline!,
              textAlign: TextAlign.center,
              style: typo.bodyMd.copyWith(color: colors.body),
            ),
          ],
          if (roleLabel != null) ...<Widget>[
            const SizedBox(height: 10),
            Pill(label: roleLabel, variant: PillVariant.solid),
          ],
          if (location.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              // 📍 pin prefix to match mockup D2 line 1721.
              '📍 $location',
              textAlign: TextAlign.center,
              style: typo.bodySm.copyWith(color: colors.muted),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            // Must match the routable deep link (`/p/:handle`, registered as
            // the App Links path on [host]) — previously `/u/<handle>`, which
            // does not resolve.
            '$host/p/${profile.handle}',
            textAlign: TextAlign.center,
            style: typo.bodyXs.copyWith(color: colors.muted),
          ),
        ],
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
