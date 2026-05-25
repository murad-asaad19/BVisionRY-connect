import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';

/// Two-button stack for the Apple + Google OAuth entry points.
///
/// Both buttons are full-width and equal-height so they read as a single
/// social-sign-in card. While [loading] is true, each renders a centred
/// spinner and is non-tappable. Callers are responsible for wiring the
/// taps to `SocialAuthService.signInWithApple` / `signInWithGoogle`.
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({
    super.key,
    required this.onApple,
    required this.onGoogle,
    this.loading = false,
  });

  /// Tap handler for the Apple entry point. Pass `null` to leave the button
  /// disabled (e.g. while another SSO request is in flight).
  final VoidCallback? onApple;

  /// Tap handler for the Google entry point.
  final VoidCallback? onGoogle;

  /// When true, both buttons render their loading visual and ignore taps.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppButton(
          key: const Key('apple-sso'),
          label: 'Continue with Apple',
          icon: CupertinoIcons.app_badge,
          variant: AppButtonVariant.apple,
          onPressed: onApple,
          loading: loading,
        ),
        const SizedBox(height: 10),
        AppButton(
          key: const Key('google-sso'),
          label: 'Continue with Google',
          icon: LucideIcons.globe,
          variant: AppButtonVariant.outline,
          onPressed: onGoogle,
          loading: loading,
        ),
      ],
    );
  }
}
