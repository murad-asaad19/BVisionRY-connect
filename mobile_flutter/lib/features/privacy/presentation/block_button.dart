import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/widgets.dart';
import '../../intros/providers/intros_providers.dart';
import '../data/privacy_service.dart';
import '../providers/blocks_provider.dart';

/// Reusable block / unblock CTA for profile pages, chat menus, and intro
/// detail screens.
///
/// Label switches between "Block {name}" and "Unblock {name}" based on
/// [isBlockedProvider]. Tapping it opens a [ConfirmDialog] (destructive
/// when blocking) and on confirmation calls the matching RPC, then
/// invalidates [blocksProvider]. The block flow also invalidates
/// [receivedIntrosProvider] / [sentIntrosProvider] because the server
/// auto-declines any active `delivered` intros between the pair (spec
/// §3.8 line 1248).
class BlockButton extends ConsumerWidget {
  const BlockButton({
    super.key,
    required this.userId,
    required this.name,
    this.handle,
    this.size = AppButtonSize.defaultSize,
    this.fullWidth = true,
  });

  /// Subject of the block. Maps to `block_user(p_target := userId)`.
  final String userId;

  /// Display name interpolated into the button label.
  final String name;

  /// Optional handle used by the confirm dialog title ("Block @handle?").
  /// Falls back to [name] when null.
  final String? handle;

  final AppButtonSize size;
  final bool fullWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool blocked = ref.watch(isBlockedProvider(userId));
    return AppButton(
      label: blocked
          ? '${context.t('privacy.unblock')} $name'
          : '${context.t('privacy.block')} $name',
      variant:
          blocked ? AppButtonVariant.outline : AppButtonVariant.outlineDanger,
      size: size,
      fullWidth: fullWidth,
      onPressed: () => _onTap(context, ref, blocked),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    bool blocked,
  ) async {
    final PrivacyService svc = ref.read(privacyServiceProvider);
    final ConfirmService confirm = ref.read(confirmServiceProvider);
    if (blocked) {
      final bool ok = await confirm.confirm(
        context,
        title: context.t('privacy.unblock'),
        body: context.t('privacy.blockedListHint'),
        confirmLabel: context.t('privacy.unblock'),
      );
      if (!ok) return;
      await svc.unblockUser(userId);
    } else {
      final bool ok = await confirm.confirm(
        context,
        title: context.t(
          'privacy.blockConfirm.title',
          vars: <String, Object>{'handle': handle ?? name},
        ),
        body: context.t('privacy.blockConfirm.body'),
        confirmLabel: context.t('privacy.blockUser'),
        destructive: true,
      );
      if (!ok) return;
      await svc.blockUser(userId);
      // Server auto-declined every active delivered intro between us and
      // [userId] — refresh both lists so the caller's inbox + sent tabs
      // reflect that immediately rather than on next foreground hop.
      ref.invalidate(receivedIntrosProvider);
      ref.invalidate(sentIntrosProvider);
    }
    ref.invalidate(blocksProvider);
  }
}
