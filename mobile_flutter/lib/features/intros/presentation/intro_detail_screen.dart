import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/session_provider.dart';
import '../../privacy/privacy.dart';
import '../../profile/domain/profile.dart';
import '../../profile/domain/profile_signals.dart';
import '../../profile/providers/peer_profile_provider.dart';
import '../../profile/providers/profile_signals_provider.dart';
import '../data/intros_service.dart';
import '../domain/intro.dart';
import '../domain/intro_enums.dart';
import '../providers/intro_by_id_provider.dart';
import '../providers/intros_providers.dart';
import 'intro_accepted_celebration.dart';
import 'intro_state_badge.dart';
import 'warm_intro_forward_sheet.dart';

/// Detail surface for one intro row.
///
/// Layout (per gallery E3):
/// - Top bar with back arrow + "Intro request" title + Report action.
/// - Sender hero: 60px avatar + name + verified pill on a row, role line
///   under name (left-aligned, matches E3 mockup).
/// - Gold-pale note banner with "NAME SAYS" caption (navy).
/// - Mutual-connections footer with a mini avatar stack.
/// - When the intro is `delivered` and not expired:
///   - For `kind = direct` / `warm_forward`: Accept + Decline buttons.
///   - For `kind = warm_request`: "Forward warm intro" placeholder CTA.
/// - When the intro is `expired`: an inline `expiredHint` line.
/// - When the intro is `declined`: both action buttons are hidden.
class IntroDetailScreen extends ConsumerWidget {
  const IntroDetailScreen({super.key, required this.introId});

  final String introId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(introByIdProvider(introId));
    final viewerId = ref.watch(currentSessionProvider)?.user.id;
    final intro = async.valueOrNull;
    // Sender can't report their own intro — only show the flag when the
    // viewer is the recipient (or any third party that happens to land
    // here through deep-link). Mirrors the conditional on the chat
    // 3-dot Block row.
    final showReport =
        intro != null && viewerId != null && intro.senderId != viewerId;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('intros.detail.title'),
          back: true,
          actions: <TopBarAction>[
            if (showReport)
              TopBarAction(
                key: const ValueKey('intro-detail-report'),
                icon: LucideIcons.flag,
                label: context.t('intros.detail.report'),
                onPressed: () => unawaited(
                  showReportSheet(
                    context,
                    targetType: ReportTargetType.intro,
                    targetId: introId,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: QueryState<Intro>(
        value: async,
        loading: const SkeletonProfile(),
        // The cached-list lookup either has the row or it doesn't, so a bare
        // retry can't recover a genuinely-missing intro. Give the user a real
        // way out: an "Open inbox" recovery action alongside the localized
        // error copy (NotFoundException -> errors.notFound).
        error: (e, _) => _IntroNotFound(error: e),
        data: (intro) => _IntroDetailBody(intro: intro),
      ),
    );
  }
}

/// Recovery surface shown when [introByIdProvider] can't resolve the intro
/// (deep-link to a deleted / expired / RLS-hidden row, or a cold start with
/// no cached lists). Routes back to the Inbox rather than dead-ending on a
/// bare "not found" line.
class _IntroNotFound extends StatelessWidget {
  const _IntroNotFound({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    // ListView keeps the surface scrollable so it composes cleanly inside the
    // Scaffold body and matches the other inbox error states.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        EmptyState(
          icon: LucideIcons.mailQuestion,
          title: context.t('intros.detail.notFound'),
          body: messageForError(context, error),
          action: EmptyStateAction(
            label: context.t('intros.detail.backToInbox'),
            onPressed: () => context.go(Routes.inbox),
          ),
        ),
      ],
    );
  }
}

class _IntroDetailBody extends ConsumerStatefulWidget {
  const _IntroDetailBody({required this.intro});

  final Intro intro;

  @override
  ConsumerState<_IntroDetailBody> createState() => _IntroDetailBodyState();
}

class _IntroDetailBodyState extends ConsumerState<_IntroDetailBody> {
  bool _busy = false;
  String? _errorKey;

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      final IntrosService svc = ref.read(introsServiceProvider);
      final updated = await svc.acceptIntro(widget.intro.id);
      Analytics.log(AppEvent.introAccepted);
      ref
        ..invalidate(receivedIntrosProvider)
        ..invalidate(sentIntrosProvider);
      if (!mounted) return;
      // SIGNATURE MOMENT — the intro is accepted (the app's core payoff).
      // Heavy impact + a brief celebration that floats on the ROOT overlay
      // so it keeps playing over the chat screen we push to below; it never
      // blocks navigation.
      Haptics.heavy();
      IntroAcceptedCelebration.play(context);
      final String? conversationId = updated.conversationId;
      if (conversationId != null) {
        // Mirror the "Open chat" CTA below — same push semantics + Routes
        // constant so accepting and re-opening land on the chat identically.
        unawaited(context.push(Routes.chat(conversationId)));
      } else {
        unawaited(Navigator.of(context).maybePop());
      }
    } on AppException catch (e) {
      setState(() => _errorKey = e.i18nKey);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      await ref.read(introsServiceProvider).declineIntro(widget.intro.id);
      Analytics.log(AppEvent.introDeclined);
      ref.invalidate(receivedIntrosProvider);
      if (!mounted) return;
      // Medium impact — confirms the decision without celebrating it.
      Haptics.medium();
      unawaited(Navigator.of(context).maybePop());
    } on AppException catch (e) {
      setState(() => _errorKey = e.i18nKey);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final intro = widget.intro;
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    // Resolve the peer (the *sender* for an incoming intro is the person
    // the recipient is deciding about; for an outgoing intro we still
    // surface the sender hero as a deterministic "who started this thread"
    // anchor — matches the gallery's E3 layout).
    final AsyncValue<Profile?> peerAsync =
        ref.watch(peerProfileProvider(intro.senderId));
    final Profile? peer = peerAsync.asData?.value;
    final senderName = peer?.name ?? intro.sender?.name ?? intro.senderId;
    final senderPhoto = peer?.photoUrl ?? intro.sender?.photoUrl;
    final senderRole = peer?.primaryRole ?? intro.sender?.primaryRole;
    final bool senderVerified =
        peer?.isVerified ?? intro.sender?.isVerified ?? false;
    // Two-line sender meta per gallery E3 (lines 1842-1843): a muted
    // "Role · Stage · Location" line plus the headline/tagline beneath —
    // both shown independent of verified state.
    final String? senderMeta = _composeSenderMeta(peer ?? intro.sender);
    final String? senderHeadline = peer?.headline ?? intro.sender?.headline;
    // Accept/Decline buttons are recipient-only — `intro.isActionable`
    // checks state+expiry but not viewer role, so without this gate the
    // sender of a still-delivered intro would see Accept/Decline on their
    // own outbound row and hit a 42501 ("only the recipient can accept")
    // mapped to the misleading 'auth.errors.signInFailed' copy.
    final String? viewerId = ref.watch(currentUserIdProvider);
    final bool viewerIsRecipient =
        viewerId != null && viewerId == intro.recipientId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SenderHero(
          name: senderName,
          photoUrl: senderPhoto,
          role: senderRole,
          metaLine: senderMeta,
          headline: senderHeadline,
          verified: senderVerified,
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: IntroStateBadge(
            state: intro.state,
            // Mirror IntroListRow: when the viewer is the sender, route
            // the badge through its sender-POV labels so a declined row
            // surfaces as "Delivered, awaiting response" (spec §12
            // silent-decline) instead of leaking a "Declined" pill.
            fromSender: !viewerIsRecipient,
            connectedAt: intro.createdAt,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Gallery E3 (line 1846) uses `.banner.muted` (#f1f5f9 + border)
            // for the "{NAME} SAYS" note — not the gold-pale of the E1
            // composer card. slate100 is the dark-mode-aware muted-surface
            // token that resolves to #f1f5f9 in light mode.
            color: colors.slate100,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t(
                  'intros.detail.says',
                  vars: <String, Object>{'name': senderName.toUpperCase()},
                ),
                style: typo.displayXs.copyWith(
                  color: colors.navy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(intro.note, style: typo.bodyMd.copyWith(color: colors.body)),
            ],
          ),
        ),
        if (intro.state == IntroState.expired) ...[
          const SizedBox(height: 16),
          Text(
            context.t('intros.detail.expiredHint'),
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
        ],
        // Connected intros land here once the chat thread has been
        // created. Surface an "Open chat" CTA so the next step (replying)
        // is one tap away instead of forcing the user to hunt for the
        // peer in the Chats tab.
        if (intro.state == IntroState.connected &&
            intro.conversationId != null) ...[
          const SizedBox(height: 20),
          AppButton(
            key: const Key('intro-detail-open-chat'),
            label: context.t('intros.detail.openChat'),
            variant: AppButtonVariant.gold,
            icon: LucideIcons.messageSquare,
            onPressed: () => context.push(Routes.chat(intro.conversationId!)),
          ),
        ],
        if (_errorKey != null) ...[
          const SizedBox(height: 16),
          AppBanner(
            intent: AppIntent.danger,
            child: Text(context.t(_errorKey!)),
          ),
        ],
        if (intro.isActionable && viewerIsRecipient) ...[
          const SizedBox(height: 20),
          _ActionRow(
            intro: intro,
            busy: _busy,
            onAccept: _accept,
            onDecline: _decline,
            onForward: _openForwardSheet,
          ),
          const SizedBox(height: 8),
          Text(
            context.t('intros.detail.declineSilent'),
            style: typo.bodyMd.copyWith(color: colors.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        _MutualConnectionsFooter(targetUserId: intro.senderId),
        // Block CTA — only when viewer is the recipient (i.e. someone
        // they don't know reached out). The sender can't block themselves;
        // mirrors the conditional on the Report flag in the top bar.
        if (viewerIsRecipient) ...[
          const SizedBox(height: 24),
          BlockButton(
            userId: intro.senderId,
            name: senderName,
            handle: peer?.handle,
          ),
        ],
      ],
    );
  }

  Future<void> _openForwardSheet() async {
    final intro = widget.intro;
    assert(
      intro.kind == IntroKind.warmRequest,
      'WarmIntroForwardSheet may only be opened for warm_request rows; '
      'got ${intro.kind}',
    );
    await showWarmIntroForwardSheet(context, intro: intro);
  }
}

/// Composes the gallery's E3 meta line "Role · Stage · Location" from a
/// [Profile]'s role, stage (founder/investor), and city/country. Each part
/// is dropped when empty; returns `null` when nothing resolves so the hero
/// can collapse the line entirely.
String? _composeSenderMeta(Profile? profile) {
  if (profile == null) return null;
  final List<String> parts = <String>[
    if ((profile.primaryRole ?? '').isNotEmpty) profile.primaryRole!,
    if ((profile.founderStage ?? '').isNotEmpty)
      profile.founderStage!
    else if ((profile.investorStage ?? '').isNotEmpty)
      profile.investorStage!,
    if ((profile.city ?? '').isNotEmpty)
      profile.city!
    else if ((profile.country ?? '').isNotEmpty)
      profile.country!,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Left-aligned hero: 60px avatar on the left, name + verified pill on a
/// row, and two muted meta lines beneath — a "Role · Stage · Location" line
/// and the headline/tagline. Mirrors the gallery's E3 sender block (lines
/// 1841-1843): the verified pill and the role meta line coexist.
class _SenderHero extends StatelessWidget {
  const _SenderHero({
    required this.name,
    required this.photoUrl,
    required this.role,
    required this.metaLine,
    required this.headline,
    required this.verified,
  });

  final String name;
  final String? photoUrl;

  /// Short role word folded into the verified badge label.
  final String? role;

  /// Composed "Role · Stage · Location" line shown under the name.
  final String? metaLine;

  /// Headline / tagline shown as the second meta line.
  final String? headline;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Avatar(
          name: name,
          photoUrl: photoUrl,
          size: 60,
          tone: AvatarTone.featured,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typo.displayLg.copyWith(
                        color: colors.navy,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  if (verified) ...<Widget>[
                    const SizedBox(width: 8),
                    Pill(
                      key: const ValueKey<String>('intro-sender-verified'),
                      label: role ?? context.t('verification.verifiedPill'),
                      variant: PillVariant.success,
                      icon: Icons.check,
                    ),
                  ],
                ],
              ),
              if (metaLine != null && metaLine!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  metaLine!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodyMd.copyWith(color: colors.muted),
                ),
              ],
              if (headline != null && headline!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  headline!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodyMd.copyWith(color: colors.body),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Mutual-connections footer rendered at the bottom of the detail body.
///
/// Watches [profileSignalsProvider] for the sender and renders a small
/// avatar stack + count line. Collapses to a zero-height SizedBox when the
/// signal returns 0 mutuals (or is still loading), so the surface never
/// flashes a "0 mutual connections" line.
class _MutualConnectionsFooter extends ConsumerWidget {
  const _MutualConnectionsFooter({required this.targetUserId});

  final String targetUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final AsyncValue<ProfileSignals> async =
        ref.watch(profileSignalsProvider(targetUserId));
    final ProfileSignals signals = async.asData?.value ?? ProfileSignals.empty;
    if (signals.mutualConnectionCount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: <Widget>[
            _MutualAvatarStack(userIds: signals.mutualTopUserIds),
            const SizedBox(width: 8),
            Text(
              context.t(
                'intros.detail.mutualConnections',
                vars: <String, Object>{
                  'count': signals.mutualConnectionCount,
                },
              ),
              style: typo.bodyMd.copyWith(color: colors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlapping mini-avatar stack, capped at 3 avatars to keep the footer
/// width predictable. Resolves each user id to a [Profile] via
/// [peerProfileProvider] so we render proper initials / photos — not the
/// raw UUID (which would otherwise produce hex-prefix "initials"). Renders
/// blank gold-pale circles when the signals row has no user ids.
class _MutualAvatarStack extends ConsumerWidget {
  const _MutualAvatarStack({required this.userIds});

  final List<String> userIds;

  static const double _avatarSize = 24;
  static const double _overlap = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = userIds.isEmpty ? 2 : userIds.take(3).length;
    final double width = _avatarSize + (count - 1) * (_avatarSize - _overlap);
    return SizedBox(
      width: width,
      height: _avatarSize,
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < count; i++)
            Positioned(
              left: i * (_avatarSize - _overlap),
              child: _MutualAvatar(
                userId: userIds.length > i ? userIds[i] : null,
                size: _avatarSize,
              ),
            ),
        ],
      ),
    );
  }
}

class _MutualAvatar extends ConsumerWidget {
  const _MutualAvatar({required this.userId, required this.size});

  final String? userId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return Avatar(name: '··', size: size);
    }
    final profile = ref.watch(peerProfileProvider(userId!)).valueOrNull;
    return Avatar(
      name: profile?.name ?? '··',
      photoUrl: profile?.photoUrl,
      size: size,
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.intro,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onForward,
  });

  final Intro intro;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    if (intro.isWarmRequest) {
      // accept_intro server-side raises 22023 wrong-intro-kind against a
      // warm_request — surface the Forward path instead and route to the
      // (Chunk B) WarmIntroForwardSheet.
      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: context.t('intros.detail.declineCta'),
              variant: AppButtonVariant.outline,
              onPressed: busy ? null : onDecline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: context.t('intros.detail.forwardCta'),
              onPressed: busy ? null : onForward,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: context.t('intros.detail.declineCta'),
            variant: AppButtonVariant.outline,
            onPressed: busy ? null : onDecline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: context.t('intros.detail.acceptCta'),
            onPressed: busy ? null : onAccept,
          ),
        ),
      ],
    );
  }
}
