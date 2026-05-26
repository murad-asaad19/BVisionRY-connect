import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(
          title: context.t('intros.detail.title'),
          back: true,
          actions: <TopBarAction>[
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
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(context.t('intros.detail.notFound'))),
        data: (intro) => _IntroDetailBody(intro: intro),
      ),
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
      ref
        ..invalidate(receivedIntrosProvider)
        ..invalidate(sentIntrosProvider);
      if (!mounted) return;
      if (updated.conversationId != null) {
        context.go('/chats/${updated.conversationId}');
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
      ref.invalidate(receivedIntrosProvider);
      if (!mounted) return;
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SenderHero(
          name: senderName,
          photoUrl: senderPhoto,
          role: senderRole,
          verified: senderVerified,
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: IntroStateBadge(state: intro.state),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.goldPale,
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
              Text(intro.note, style: typo.bodyMd.copyWith(color: colors.navy)),
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
        if (_errorKey != null) ...[
          const SizedBox(height: 16),
          AppBanner(
            intent: AppIntent.danger,
            child: Text(context.t(_errorKey!)),
          ),
        ],
        if (intro.isActionable) ...[
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

/// Left-aligned hero: 60px avatar on the left, name + verified pill on a
/// row, role beneath. Mirrors the gallery's E3 sender block.
class _SenderHero extends StatelessWidget {
  const _SenderHero({
    required this.name,
    required this.photoUrl,
    required this.role,
    required this.verified,
  });

  final String name;
  final String? photoUrl;
  final String? role;
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
              if (role != null && !verified) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  role!,
                  style: typo.bodyMd.copyWith(color: colors.muted),
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
/// width predictable. Renders blank gold-pale circles when the signals row
/// has no user ids (the gallery shows two empty circles in the same
/// scenario — keeps the layout stable while we wait on the profile fetch).
class _MutualAvatarStack extends StatelessWidget {
  const _MutualAvatarStack({required this.userIds});

  final List<String> userIds;

  static const double _avatarSize = 24;
  static const double _overlap = 8;

  @override
  Widget build(BuildContext context) {
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
              child: Avatar(
                name: userIds.length > i ? userIds[i] : '··',
                size: _avatarSize,
              ),
            ),
        ],
      ),
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
