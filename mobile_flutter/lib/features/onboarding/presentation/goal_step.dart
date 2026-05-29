import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../data/infer_goal_service.dart';
import '../domain/goal_type.dart';
import '../domain/onboarding_draft.dart';
import '../domain/onboarding_schemas.dart';
import '../providers/infer_goal_provider.dart';
import '../providers/onboarding_draft_notifier.dart';
import 'onboarding_exit.dart';
import 'stepper_layout.dart';

/// Step 1 of 4 — Goal.
///
/// Captures the user's free-text goal (10..280 chars), runs an 800ms-debounced
/// inference call (gated at 20 chars) to suggest a [GoalType], and lets the
/// user confirm with a chip selector. When the inference returns with
/// `high` confidence the matching chip is auto-selected (the user can still
/// override). On valid text + a non-null `goalType`, the Continue button
/// advances to the Roles step (name + handle are captured later, on the
/// final Basics step, per the mockup's 4-step flow).
class GoalStep extends ConsumerStatefulWidget {
  const GoalStep({super.key});

  @override
  ConsumerState<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends ConsumerState<GoalStep> {
  /// Remembers the most recent inferred [GoalType] we already pushed into the
  /// draft. Prevents the `ref.listen` callback from re-applying the same
  /// auto-select on every rebuild after the user manually overrides.
  GoalType? _lastAutoApplied;

  @override
  void initState() {
    super.initState();
    // Goal is step 1 of the wizard — reaching it marks the funnel start.
    Analytics.log(AppEvent.onboardingStarted);
  }

  @override
  Widget build(BuildContext context) {
    // Auto-apply high-confidence inference results into the draft once per
    // result. Uses ref.listen so the side-effect runs after the build that
    // surfaces the new state, never during build.
    ref.listen<InferGoalState>(inferGoalProvider, (
      InferGoalState? prev,
      InferGoalState next,
    ) {
      if (next is! Inferred) return;
      final InferGoalResult r = next.result;
      if (r.confidence != InferConfidence.high) return;
      final GoalType? inferred = r.goalType;
      if (inferred == null) return;
      if (_lastAutoApplied == inferred) return;
      _lastAutoApplied = inferred;
      ref.read(onboardingDraftProvider.notifier).updateGoalType(inferred);
    });

    final AsyncValue<OnboardingDraft> draftAsync =
        ref.watch(onboardingDraftProvider);
    final InferGoalState inferState = ref.watch(inferGoalProvider);
    final OnboardingDraft? draft = draftAsync.value;

    if (draft == null) {
      return const StepperLayout(
        stepIndex: 0,
        stepNameKey: 'onboarding.stepName.goal',
        child: _GoalStepSkeleton(),
      );
    }

    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;

    final bool goalValid = GoalTextInput.dirty(draft.goalText).error == null;
    final bool canProceed = goalValid && draft.goalType != null;

    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;

    return StepperLayout(
      stepIndex: 0,
      stepNameKey: 'onboarding.stepName.goal',
      onSignOut: () => confirmAndSignOut(context, ref),
      footer: AppButton(
        key: const ValueKey<String>('goal-next'),
        label: context.t('onboarding.goal.continue'),
        onPressed: canProceed
            ? () {
                Analytics.log(
                  AppEvent.onboardingStepCompleted,
                  const <String, Object>{'step': 'goal'},
                );
                context.go(Routes.onboardingRoles);
              }
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // First-run welcome / framing so the user isn't dropped cold into
          // a bare text field.
          Container(
            key: const ValueKey<String>('goal-welcome'),
            width: double.infinity,
            padding: EdgeInsets.all(spacing.card),
            decoration: BoxDecoration(
              color: colors.goldPale,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t('onboarding.goal.welcomeTitle'),
                  style: typo.displaySm.copyWith(color: colors.navy),
                ),
                Gap(spacing.xs),
                Text(
                  context.t('onboarding.goal.welcomeBody'),
                  style: typo.bodyMd.copyWith(color: colors.body),
                ),
              ],
            ),
          ),
          Gap(spacing.section),
          Text(
            context.t('onboarding.goal.title'),
            style: typo.displayLg.copyWith(color: colors.navy),
          ),
          Gap(spacing.sm),
          Text(
            context.t('onboarding.goal.helper'),
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
          Gap(spacing.card),
          AppInput(
            label: context.t('onboarding.goal.label'),
            placeholder: context.t('onboarding.goal.placeholder'),
            value: draft.goalText,
            multiline: true,
            minLines: 3,
            maxLength: GoalTextInput.maxLength,
            onChanged: (String v) {
              ref.read(onboardingDraftProvider.notifier).updateGoalText(v);
              ref.read(inferGoalProvider.notifier).requestInference(
                    text: v,
                    primaryRole: draft.primaryRole,
                    roles: draft.roles.isEmpty ? null : draft.roles,
                  );
            },
            errorText: (!goalValid && draft.goalText.isNotEmpty)
                ? context.t('onboarding.goal.errorRange')
                : null,
          ),
          Gap(spacing.sm),
          Text(
            context.t('onboarding.goal.examplesNote'),
            style: typo.bodySm.copyWith(color: colors.muted),
          ),
          Gap(spacing.card),
          _InferStatus(state: inferState),
          Gap(spacing.card),
          Text(
            context.t('onboarding.goal.typeLabel'),
            style: typo.displaySm.copyWith(color: colors.navy),
          ),
          Gap(spacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final GoalType gt in GoalType.values)
                AppFilterChip(
                  key: ValueKey<String>('goal-chip-${gt.wire}'),
                  label: context.t(gt.i18nLabelKey),
                  active: draft.goalType == gt,
                  onTap: () {
                    Haptics.selection();
                    // Manual tap counts as a user override — record it as
                    // the "applied" type so the inference listener doesn't
                    // immediately overwrite it on the next rebuild.
                    _lastAutoApplied = gt;
                    ref
                        .read(onboardingDraftProvider.notifier)
                        .updateGoalType(gt);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renders the inference banner directly above the chip grid.
///
/// Idle → nothing. Inferring → info banner. High-confidence inferred → success
/// banner naming the chosen label. Low-confidence or failed → warning banner
/// asking the user to pick manually.
class _InferStatus extends StatelessWidget {
  const _InferStatus({required this.state});
  final InferGoalState state;

  @override
  Widget build(BuildContext context) {
    final InferGoalState s = state;
    if (s is InferIdle) return const SizedBox.shrink();
    if (s is Inferring) {
      return AppBanner(
        intent: AppIntent.info,
        leadingIcon: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        child: Text(context.t('onboarding.goal.inferring')),
      );
    }
    if (s is Inferred) {
      final InferGoalResult r = s.result;
      if (r.confidence == InferConfidence.high && r.goalType != null) {
        final String label = context.t(r.goalType!.i18nLabelKey);
        return AppBanner(
          intent: AppIntent.success,
          child: Text(
            context.t(
              'onboarding.goal.inferred',
              vars: <String, Object>{'label': label},
            ),
          ),
        );
      }
      return AppBanner(
        intent: AppIntent.warning,
        child: Text(context.t('onboarding.goal.inferFailed')),
      );
    }
    // InferFailed.
    return AppBanner(
      intent: AppIntent.warning,
      child: Text(context.t('onboarding.goal.inferFailed')),
    );
  }
}

/// Shape-matching placeholder shown while the persisted draft hydrates, in
/// place of a bare centered spinner. Mirrors the Goal step's vertical rhythm
/// (welcome block → title → text box → chip row) so nothing jumps when the
/// real content arrives.
class _GoalStepSkeleton extends StatelessWidget {
  const _GoalStepSkeleton();

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Skeleton(width: double.infinity, height: 64, rounded: 14),
        Gap(spacing.section),
        const Skeleton(width: 220, height: 24),
        Gap(spacing.sm),
        const Skeleton(width: 280, height: 14),
        Gap(spacing.card),
        const Skeleton(width: double.infinity, height: 96, rounded: 10),
        Gap(spacing.card),
        const Skeleton(width: 120, height: 18),
        Gap(spacing.sm),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            Skeleton(width: 90, height: 32, rounded: 999),
            Skeleton(width: 110, height: 32, rounded: 999),
            Skeleton(width: 80, height: 32, rounded: 999),
          ],
        ),
      ],
    );
  }
}
