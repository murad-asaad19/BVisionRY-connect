import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_service_provider.dart';

/// Shared sign-out / exit affordance for the onboarding wizard.
///
/// Confirms intent, then runs the canonical [AuthService.signOut] path. We
/// don't navigate manually — the route guard sees the now session-less user
/// and redirects to `/sign-in` on the next tick. On failure we surface a
/// localized toast rather than leaving the user wondering why nothing
/// happened.
///
/// Wired into [StepperLayout.onSignOut] so any step can offer the escape
/// hatch with one call.
Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  Haptics.medium();
  final bool ok = await ref.read(confirmServiceProvider).confirm(
        context,
        title: context.t('onboarding.exitConfirm.title'),
        body: context.t('onboarding.exitConfirm.body'),
        confirmLabel: context.t('onboarding.exit'),
        cancelLabel: context.t('common.cancel'),
        destructive: true,
      );
  if (!ok) return;
  try {
    await ref.read(authServiceProvider).signOut();
    // No explicit navigation: the route guard redirects the session-less
    // user to /sign-in automatically.
  } on Object catch (e) {
    if (!context.mounted) return;
    ref.read(toastServiceProvider.notifier).showToast(
          title: messageForError(context, e),
          intent: AppIntent.danger,
        );
  }
}
