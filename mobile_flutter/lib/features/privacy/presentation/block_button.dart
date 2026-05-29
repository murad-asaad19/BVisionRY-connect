import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../intros/providers/intros_providers.dart';
import '../data/privacy_service.dart';
import '../domain/blocked_user.dart';
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
    // Subscribe to the full AsyncValue rather than the derived
    // isBlockedProvider so the button can render a loading state
    // explicitly. Without this gate, the first frame after cold-open
    // shows "Block @name" (default for the AsyncLoading state) even for
    // users that ARE blocked — and a fast double-tap during the load
    // window would re-fire block_user against an already-blocked target.
    final AsyncValue<List<BlockedUser>> async = ref.watch(blocksProvider);
    final bool? blocked = async.maybeWhen(
      data: (List<BlockedUser> xs) =>
          xs.any((BlockedUser u) => u.blockedId == userId),
      orElse: () => null,
    );
    final bool resolved = blocked != null;
    final bool isBlocked = blocked ?? false;
    return AppButton(
      label: resolved
          ? (isBlocked
              ? '${context.t('privacy.unblock')} $name'
              : '${context.t('privacy.block')} $name')
          // Same baseline copy while loading so the layout doesn't
          // jump width; the visual disabled state keeps it un-tappable.
          : '${context.t('privacy.block')} $name',
      variant:
          isBlocked ? AppButtonVariant.outline : AppButtonVariant.outlineDanger,
      size: size,
      fullWidth: fullWidth,
      onPressed: resolved ? () => _onTap(context, ref, isBlocked) : null,
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    bool blocked,
  ) async {
    final PrivacyService svc = ref.read(privacyServiceProvider);
    final ConfirmService confirm = ref.read(confirmServiceProvider);
    try {
      if (blocked) {
        final bool ok = await confirm.confirm(
          context,
          title: context.t('privacy.unblock'),
          body: context.t('privacy.blockedListHint'),
          confirmLabel: context.t('privacy.unblock'),
        );
        if (!ok) return;
        Haptics.selection();
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
        Haptics.medium();
        await svc.blockUser(userId);
        // Server auto-declined every active delivered intro between us and
        // [userId] — refresh both lists so the caller's inbox + sent tabs
        // reflect that immediately rather than on next foreground hop.
        ref.invalidate(receivedIntrosProvider);
        ref.invalidate(sentIntrosProvider);
      }
      ref.invalidate(blocksProvider);
    } catch (e) {
      Haptics.error();
      if (context.mounted) {
        ref.read(toastServiceProvider.notifier).showToast(
              intent: AppIntent.danger,
              title: messageForError(context, e),
            );
      }
    }
  }
}
