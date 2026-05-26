import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';

/// Navy/gold gradient wrapper for every auth screen.
///
/// Visual reference: gallery sections A2–A3. The full background paints a
/// `LinearGradient(navy → navyLight)` (the hero stays visible even when the
/// content scrolls). The wordmark + tagline sit at the top in white/gold,
/// and the form is rendered as a distinct white card with rounded corners
/// and a subtle shadow, inset by [AppSpacing.gutter] from each side.
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
      body: Container(
        key: const Key('auth-shell-hero'),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[colors.navy, colors.navyLight],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              spacing.gutter,
              spacing.section,
              spacing.gutter,
              spacing.section,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                SizedBox(height: spacing.section),
                Container(
                  key: const Key('auth-shell-card'),
                  decoration: BoxDecoration(
                    color: colors.white,
                    borderRadius: BorderRadius.circular(radii.card),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(spacing.gutter),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
