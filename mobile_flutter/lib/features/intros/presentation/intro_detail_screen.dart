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
import '../data/intros_service.dart';
import '../domain/intro.dart';
import '../domain/intro_enums.dart';
import '../providers/intro_by_id_provider.dart';
import '../providers/intros_providers.dart';
import 'intro_state_badge.dart';

/// Detail surface for one intro row.
///
/// Layout (per gallery E3):
/// - Top bar with back arrow + "Intro" title.
/// - Sender hero: 60px avatar + name + role + verified placeholder.
/// - Gold-bg note banner with "SENDER SAYS" caption.
/// - When the intro is `delivered` and not expired:
///   - For `kind = direct` / `warm_forward`: Accept + Decline buttons.
///   - For `kind = warm_request`: "Forward warm intro" placeholder CTA
///     (the actual forward sheet ships in Chunk B; see plan §6).
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
        child: TopBar(title: context.t('intros.detail.title'), back: true),
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
    final senderName = intro.sender?.name ?? intro.senderId;
    final senderHandle = intro.sender?.handle ?? intro.senderId;
    final senderPhoto = intro.sender?.photoUrl;
    final senderRole = intro.sender?.primaryRole;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Center(
          child: Avatar(
            name: senderName,
            photoUrl: senderPhoto,
            size: 60,
            tone: AvatarTone.featured,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            senderName,
            textAlign: TextAlign.center,
            style: typo.displayLg.copyWith(color: colors.navy, fontSize: 22),
          ),
        ),
        Center(
          child: Text(
            '@$senderHandle',
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
        ),
        if (senderRole != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              senderRole,
              style: typo.bodyMd.copyWith(color: colors.muted),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(child: IntroStateBadge(state: intro.state)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.goldPale,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.gold),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t(
                  'intros.detail.says',
                  vars: <String, Object>{'name': senderName.toUpperCase()},
                ),
                style: typo.displayXs.copyWith(color: colors.warning),
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
            onForward: () => _showForwardPlaceholder(context),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('intros.detail.declineSilent'),
            style: typo.bodyMd.copyWith(color: colors.muted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  void _showForwardPlaceholder(BuildContext context) {
    // The actual `WarmIntroForwardSheet` ships in Chunk B. Until then we
    // expose a stub so the kind-dispatch path is wired and discoverable
    // in widget tests.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              LucideIcons.share2,
              size: 40,
              color: Theme.of(context).extension<AppColors>()!.gold,
            ),
            const SizedBox(height: 12),
            Text(
              context.t('intros.warm.forwardTitle', vars: const {'targetName': '...'}),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon — full forward flow lands in the warm-intro sheet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: context.t('common.ok'),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
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
