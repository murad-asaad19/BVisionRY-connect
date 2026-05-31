import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Shared chrome for every step in the onboarding wizard.
///
/// Renders, top-to-bottom:
///   1. A back button + step counter ("Step 2 of 5 · Goal") + optional
///      Skip action.
///   2. Five-segment [ProgressDots] showing the current position.
///   3. A scrollable [child] slot for the step's main content.
///   4. An optional [footer] (typically the Continue / Finish button).
///
/// Per the mockup the wizard proper is 4 screens (Goal → Roles → Bio →
/// Basics) but the progress rail shows 5 segments: the 5th dot is reserved
/// for the first-action / verify step that follows submission. Step screens
/// (`GoalStep`, `RolesStep`, `BioDraftStep`, `AboutStep`) hand over their
/// `stepIndex` (0..3) and the i18n key for the step name; the layout
/// assembles the visible step label via
/// `t('onboarding.stepLabel', vars: {current, total, stepName})`.
class StepperLayout extends StatelessWidget {
  const StepperLayout({
    super.key,
    required this.stepIndex,
    required this.stepNameKey,
    required this.child,
    this.onBack,
    this.onSkip,
    this.onSignOut,
    this.footer,
  }) : assert(
          stepIndex >= 0 && stepIndex < totalSteps,
          'stepIndex must be in 0..${totalSteps - 1}',
        );

  /// Number of progress segments shown in the rail. The wizard proper is 4
  /// screens (goal → roles → bio → basics); the 5th dot is reserved for the
  /// post-submission first-action / verify step, matching the mockup's
  /// 5-segment rail. Exposed as a constant so step screens can reference it
  /// without re-declaring the value.
  static const int totalSteps = 5;

  /// Zero-indexed position of the active step.
  final int stepIndex;

  /// i18n key (under `onboarding.stepName.*`) for the visible step name.
  final String stepNameKey;

  /// Step content. Scrolls vertically inside the available space.
  final Widget child;

  /// When non-null, shows a back chevron in the header that invokes this.
  /// Omitted on step 1 (Goal) since there's nowhere to go back to.
  final VoidCallback? onBack;

  /// When non-null, shows a Skip text-button in the header right slot. Not
  /// used by any step in the current spec (all four are required), but the
  /// hook is kept so future variants can opt in cheaply.
  final VoidCallback? onSkip;

  /// When non-null, shows a dedicated sign-out / exit affordance in the
  /// header's trailing slot. Gives the user an escape hatch out of the
  /// wizard (the route guard sends a session-less user back to /sign-in).
  /// Kept distinct from [onSkip] so the exit action never collides with the
  /// Skip slot/key.
  final VoidCallback? onSignOut;

  /// Optional fixed footer (Next / Submit button typically).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;

    final String stepName = context.t(stepNameKey);
    final String label = context.t(
      'onboarding.stepLabel',
      vars: <String, Object>{
        'current': stepIndex + 1,
        'total': totalSteps,
        'stepName': stepName,
      },
    );

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (onBack != null)
                    AppIconButton(
                      key: const ValueKey<String>('stepper-back'),
                      icon: Icons.chevron_left,
                      label: context.t('common.back'),
                      onPressed: onBack,
                    )
                  else
                    const SizedBox(width: 44),
                  Expanded(
                    child: Text(
                      label,
                      style: typo.bodyMd.copyWith(color: colors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (onSkip != null)
                    TextButton(
                      onPressed: onSkip,
                      child: Text(context.t('onboarding.skip')),
                    )
                  else if (onSignOut != null)
                    TextButton(
                      key: const ValueKey<String>('stepper-sign-out'),
                      onPressed: onSignOut,
                      child: Text(
                        context.t('onboarding.exit'),
                        style: typo.bodySm.copyWith(
                          color: colors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 44),
                ],
              ),
              Gap(spacing.card),
              ProgressDots(total: totalSteps, current: stepIndex),
              Gap(spacing.section),
              // Subtle fade + slide between steps. Keyed on [stepIndex] so
              // each step's content gently cross-fades/slides in as the user
              // advances or goes back, animating the transition without
              // touching the (core-owned) route builder.
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (Widget c, Animation<double> anim) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: c,
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    key: ValueKey<int>(stepIndex),
                    child: child,
                  ),
                ),
              ),
              if (footer != null) ...<Widget>[
                Gap(spacing.card),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
