import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/confirm_dialog.dart';

/// Wraps a composer screen body in a [PopScope] that blocks the back gesture
/// while [isDirty] is `true` and prompts the user (via [ConfirmService]) to
/// confirm discarding unsaved edits before popping.
///
/// Reuses the shared `profile.confirmDiscard.*` copy so the discard prompt
/// reads identically across the app. Both [NewOpportunityScreen] and
/// [EditOpportunityScreen] mount this so the guard stays in one place.
class UnsavedChangesGuard extends ConsumerWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.isDirty,
    required this.child,
  });

  /// Whether the wrapped form currently has unsaved edits.
  final bool isDirty;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop || !isDirty) return;
        final bool discard = await ref.read(confirmServiceProvider).confirm(
              context,
              title: context.t('profile.confirmDiscard.title'),
              body: context.t('profile.confirmDiscard.body'),
              confirmLabel: context.t('profile.confirmDiscard.discard'),
              cancelLabel: context.t('profile.confirmDiscard.keepEditing'),
              destructive: true,
            );
        if (discard && context.mounted) {
          // The pop was blocked by `canPop: false`; perform it explicitly now
          // that the user has confirmed.
          if (context.canPop()) context.pop();
        }
      },
      child: child,
    );
  }
}
