import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Shared chrome for every step in the onboarding wizard.
///
/// Renders, top-to-bottom:
///   1. A back button + step counter ("Step 2 of 4 · Identity") + optional
///      Skip action.
///   2. Four-segment [ProgressDots] showing the current position.
///   3. A scrollable [child] slot for the step's main content.
///   4. An optional [footer] (typically the Next / Submit button).
///
/// Step screens (`GoalStep`, `IdentityStep`, `RolesStep`, `AboutStep`) hand
/// over their `stepIndex` (0..3) and the i18n key for the step name; the
/// layout assembles the visible step label via `t('onboarding.stepLabel',
/// vars: {current, total, stepName})`.
class StepperLayout extends StatelessWidget {
  const StepperLayout({
    super.key,
    required this.stepIndex,
    required this.stepNameKey,
    required this.child,
    this.onBack,
    this.onSkip,
    this.footer,
  }) : assert(
          stepIndex >= 0 && stepIndex < totalSteps,
          'stepIndex must be in 0..${totalSteps - 1}',
        );

  /// Number of wizard steps. Fixed by the spec (goal → identity → roles →
  /// about); exposed as a constant so step screens can reference it without
  /// re-declaring the value.
  static const int totalSteps = 4;

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
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: onBack,
                    )
                  else
                    const SizedBox(width: 48),
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
                  else
                    const SizedBox(width: 48),
                ],
              ),
              SizedBox(height: spacing.card),
              ProgressDots(total: totalSteps, current: stepIndex),
              SizedBox(height: spacing.section),
              Expanded(child: SingleChildScrollView(child: child)),
              if (footer != null) ...<Widget>[
                SizedBox(height: spacing.card),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
