import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/gap.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../core/widgets/variants.dart';

/// Soft email-verification gate on Home (gallery B5, lines 1356-1358).
///
/// When the signed-in user's email is not yet confirmed
/// (`auth.currentUser.emailConfirmedAt == null`) the user may still browse,
/// but a dismissible warning banner names their email and offers a "resend
/// link" action. The Send-intro CTA gating itself lives in the intro
/// composer; this banner is the surfacing affordance.
///
/// Self-collapses (renders [SizedBox.shrink]) when there is no user, when
/// the email is already confirmed, or once the user dismisses it for the
/// session.
class EmailVerifyBanner extends ConsumerStatefulWidget {
  const EmailVerifyBanner({super.key});

  @override
  ConsumerState<EmailVerifyBanner> createState() => _EmailVerifyBannerState();
}

class _EmailVerifyBannerState extends ConsumerState<EmailVerifyBanner> {
  bool _dismissed = false;
  bool _resending = false;

  Future<void> _resend(String email) async {
    if (_resending) return;
    setState(() => _resending = true);
    Haptics.light();
    final toast = ref.read(toastServiceProvider.notifier);
    try {
      await ref.read(supabaseClientProvider).auth.resend(
            type: OtpType.signup,
            email: email,
          );
      if (!mounted) return;
      toast.showToast(
        title: context.t('home.verifyEmail.resentTitle'),
        body: context.t('home.verifyEmail.resentBody'),
        intent: AppIntent.success,
      );
    } catch (_) {
      if (!mounted) return;
      toast.showToast(
        title: context.t('home.verifyEmail.resendFailed'),
        intent: AppIntent.danger,
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final User? user = ref.watch(supabaseClientProvider).auth.currentUser;
    if (user == null || user.emailConfirmedAt != null) {
      return const SizedBox.shrink();
    }
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final String email = user.email ?? '';

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, 0),
      child: AppBanner(
        key: const ValueKey<String>('home.verifyEmailBanner'),
        intent: AppIntent.warning,
        title: context.t('home.verifyEmail.title'),
        onClose: () => setState(() => _dismissed = true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              email.isEmpty
                  ? context.t('home.verifyEmail.bodyNoEmail')
                  : context.t(
                      'home.verifyEmail.body',
                      vars: <String, Object>{'email': email},
                    ),
            ),
            Gap(spacing.xs),
            TextButton(
              key: const Key('home.verifyEmail.resend'),
              onPressed:
                  (_resending || email.isEmpty) ? null : () => _resend(email),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                _resending
                    ? context.t('home.verifyEmail.resending')
                    : context.t('home.verifyEmail.resend'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
