import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/invite_code.dart';
import '../providers/invite_codes_provider.dart';

/// Host used to compose the shareable invite URL. Mirrors the App Links host
/// (`connect.bvisionry.com`) registered for `/p/:handle` deep links so a
/// shared invite resolves back into the app's sign-up flow.
const String _kInviteHost = 'connect.bvisionry.com';

/// "Invite friends" — the share-my-invites surface (reachable from Settings).
///
/// Calls `ensure_invite_codes()` (via [inviteCodesProvider]) to fetch / mint
/// the caller's shareable codes, then lists each one with Copy + Share actions.
/// Sharing composes a localized message embedding the code and a deep link.
class InviteFriendsScreen extends ConsumerWidget {
  const InviteFriendsScreen({super.key});

  static String inviteUrl(String code) =>
      'https://$_kInviteHost/sign-up?invite=$code';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InviteCode>> async = ref.watch(inviteCodesProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('invite.title'), back: true),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inviteCodesProvider);
          await ref.read(inviteCodesProvider.future);
        },
        child: QueryState<List<InviteCode>>(
          value: async,
          onRetry: () => ref.invalidate(inviteCodesProvider),
          data: (List<InviteCode> codes) => _Body(codes: codes),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.codes});

  final List<InviteCode> codes;

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AppColors colors = Theme.of(context).extension<AppColors>()!;

    return ListView(
      padding: EdgeInsets.all(spacing.md),
      children: <Widget>[
        Text(
          context.t('invite.heading'),
          style: typo.displayMd.copyWith(color: colors.navy),
        ),
        const SizedBox(height: 4),
        Text(
          context.t('invite.subtitle'),
          style: typo.bodyMd.copyWith(color: colors.muted),
        ),
        SizedBox(height: spacing.md),
        if (codes.isEmpty)
          EmptyState(
            icon: LucideIcons.ticket,
            title: context.t('invite.emptyTitle'),
            body: context.t('invite.emptyBody'),
          )
        else
          for (final InviteCode code in codes) ...<Widget>[
            _InviteCodeCard(code: code),
            SizedBox(height: spacing.sm),
          ],
      ],
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code});

  final InviteCode code;

  String _shareMessage(BuildContext context) => context.t(
        'invite.shareMessage',
        vars: <String, Object>{
          'code': code.code,
          'url': InviteFriendsScreen.inviteUrl(code.code),
        },
      );

  Future<void> _copy(BuildContext context) async {
    Haptics.light();
    await Clipboard.setData(ClipboardData(text: code.code));
  }

  Future<void> _share(BuildContext context) async {
    Haptics.light();
    await Share.share(_shareMessage(context));
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final bool used = !code.isActive;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.slate100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: used ? colors.muted : colors.slate300,
                    ),
                  ),
                  child: Text(
                    code.code,
                    style: typo.displayMd.copyWith(
                      color: used ? colors.muted : colors.navy,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                      decoration: used ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
              AppIconButton(
                key: Key('invite-copy-${code.code}'),
                icon: LucideIcons.copy,
                label: context.t('invite.copy'),
                onPressed: used ? null : () => _copy(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            used
                ? context.t('invite.used')
                : context.t(
                    'invite.usesRemaining',
                    vars: <String, Object>{'count': code.remainingUses},
                  ),
            style: typo.bodySm.copyWith(color: colors.muted),
          ),
          SizedBox(height: spacing.sm),
          AppButton(
            key: Key('invite-share-${code.code}'),
            label: context.t('invite.shareCta'),
            variant: AppButtonVariant.outline,
            icon: LucideIcons.share2,
            onPressed: used ? null : () => _share(context),
          ),
        ],
      ),
    );
  }
}
