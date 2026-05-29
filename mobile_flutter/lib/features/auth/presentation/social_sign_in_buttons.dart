import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';

/// Two-button stack for the Google + Apple OAuth entry points.
///
/// Gallery reference: A2/A3 (sign-up / sign-in cards). Google is rendered
/// first (top), Apple second — both styled as light outline pills with a
/// white background, navy border, and navy label. Each button leads with a
/// brand glyph (`G` in a circle for Google, the Apple logo for Apple) and
/// the label "Continue with Google" / "Continue with Apple".
///
/// While [loading] is true, each renders a centred spinner and is
/// non-tappable. Callers are responsible for wiring the taps to
/// `SocialAuthService.signInWithGoogle` / `signInWithApple`.
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({
    super.key,
    required this.onApple,
    required this.onGoogle,
    this.appleLoading = false,
    this.googleLoading = false,
  });

  /// Tap handler for the Apple entry point. Pass `null` to leave the button
  /// disabled (e.g. while another SSO request is in flight).
  final VoidCallback? onApple;

  /// Tap handler for the Google entry point.
  final VoidCallback? onGoogle;

  /// When true, the Apple button shows its in-flight spinner and ignores
  /// taps — set only for the button whose OAuth request is running.
  final bool appleLoading;

  /// When true, the Google button shows its in-flight spinner and ignores
  /// taps.
  final bool googleLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _SsoButton(
          key: const Key('google-sso'),
          label: context.t('auth.continueGoogle'),
          leading: const _GoogleGlyph(),
          onPressed: onGoogle,
          loading: googleLoading,
        ),
        const SizedBox(height: 10),
        _SsoButton(
          key: const Key('apple-sso'),
          label: context.t('auth.continueApple'),
          leading: const _AppleGlyph(),
          onPressed: onApple,
          loading: appleLoading,
        ),
      ],
    );
  }
}

/// Outline-styled SSO button: white fill, navy border, navy label, with a
/// brand glyph on the left. Matches the gallery `.btn.outline` style.
class _SsoButton extends StatelessWidget {
  const _SsoButton({
    super.key,
    required this.label,
    required this.leading,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final bool tapBlocked = loading || onPressed == null;
    final BorderRadius br = BorderRadius.circular(radii.button);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: colors.white,
        borderRadius: br,
        child: InkWell(
          borderRadius: br,
          onTap: tapBlocked ? null : onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: br,
              border: Border.all(color: colors.navy, width: 1.5),
            ),
            child: ConstrainedBox(
              // ≥48dp tap target (WCAG 2.5.5 / Apple HIG) — the content alone
              // only reaches ~40dp.
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (loading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.navy,
                        ),
                      )
                    else ...<Widget>[
                      leading,
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: typo.displaySm.copyWith(
                        color: colors.navy,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded "G" glyph in a small circle — matches the gallery's
/// `.sso .ico` span for Google.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.white,
        border: Border.all(color: colors.navy, width: 1.5),
      ),
      child: Text(
        'G',
        style: TextStyle(
          color: colors.navy,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Apple logo glyph — uses the Material `Icons.apple` which renders the
/// stylised apple silhouette. Sized to match the Google glyph footprint.
class _AppleGlyph extends StatelessWidget {
  const _AppleGlyph();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Icon(Icons.apple, size: 20, color: colors.navy);
  }
}
