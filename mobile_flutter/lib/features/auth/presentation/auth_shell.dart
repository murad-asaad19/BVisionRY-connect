import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';

/// Navy/gold gradient wrapper for every auth screen.
///
/// Visual reference: gallery sections A1–A3. The top is a full-width hero
/// painted with `LinearGradient(navy → navyLight)`, holding the BVisionRY
/// wordmark (Dosis 700, white) above the smaller "Connect" subtitle (Dosis
/// 500, gold). Underneath, a rounded-top white card hosts the [child] —
/// usually a form scrolled inside [SingleChildScrollView].
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.tagline});

  /// Body of the screen — usually the form / call-to-action stack.
  final Widget child;

  /// Optional single-line tagline rendered beneath the wordmark.
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;

    return Scaffold(
      backgroundColor: colors.navy,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Container(
              key: const Key('auth-shell-hero'),
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: spacing.gutter,
                vertical: spacing.section,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[colors.navy, colors.navyLight],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'BVisionRY',
                    style: GoogleFonts.dosis(
                      fontSize: 32,
                      height: 36 / 32,
                      color: colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Connect',
                    style: GoogleFonts.dosis(
                      fontSize: 22,
                      height: 26 / 22,
                      color: colors.gold,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (tagline != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      tagline!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 20 / 14,
                        color: colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radii.modalTop),
                    topRight: Radius.circular(radii.modalTop),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(spacing.gutter),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
