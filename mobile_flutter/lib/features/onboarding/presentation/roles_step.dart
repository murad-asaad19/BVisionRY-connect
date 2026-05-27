import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/goal_type.dart';
import '../domain/onboarding_draft.dart';
import '../providers/onboarding_draft_notifier.dart';
import 'stepper_layout.dart';

/// Roles supported by the onboarding step. Mirrors the wire values stored in
/// `profiles.roles` (and used by the matching algorithm).
const List<String> _kRoles = <String>[
  'founder',
  'leader',
  'builder',
  'investor',
];

/// Maps a confirmed [GoalType] to the role the gallery's banner copy
/// surfaces ("Based on your goal, you might be a Founder").
///
/// The mapping mirrors the matching algorithm's heuristic: the goal you
/// declare is a strong prior for the role you hold (someone hiring or
/// raising is almost always a founder; someone investing is an investor;
/// etc.). Returns `null` when no obvious role applies (e.g. peer-connect).
String? _roleHintFromGoal(GoalType? gt) {
  switch (gt) {
    case GoalType.hire:
    case GoalType.coFound:
    case GoalType.takeInvestment:
      return 'founder';
    case GoalType.beHired:
      return 'builder';
    case GoalType.invest:
      return 'investor';
    case GoalType.advise:
      return 'leader';
    case GoalType.findAdvisor:
      return 'founder';
    case GoalType.peerConnect:
    case null:
      return null;
  }
}

/// Step 3 of 5 — Roles.
///
/// Multi-select chip row + primary-role pill row. Tapping a role chip
/// toggles membership in `draft.roles`; the [OnboardingDraftNotifier]
/// auto-clears `primaryRole` when the picked primary falls out of the list.
/// Next is enabled iff at least one role is selected AND a primary is
/// chosen.
class RolesStep extends ConsumerWidget {
  const RolesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OnboardingDraft> draftAsync =
        ref.watch(onboardingDraftProvider);
    final OnboardingDraft? draft = draftAsync.value;
    if (draft == null) {
      return const StepperLayout(
        stepIndex: 2,
        stepNameKey: 'onboarding.stepName.roles',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;

    final bool canProceed = draft.roles.isNotEmpty && draft.primaryRole != null;

    // Surface the role-inference banner only when the user's goal implies
    // a role they haven't already picked. Confirming the chip dismisses
    // the banner naturally.
    final String? inferredRole = _roleHintFromGoal(draft.goalType);
    final bool showInferBanner = inferredRole != null &&
        !draft.roles.contains(inferredRole);

    return StepperLayout(
      stepIndex: 2,
      stepNameKey: 'onboarding.stepName.roles',
      onBack: () => context.go(Routes.onboardingIdentity),
      footer: AppButton(
        key: const ValueKey<String>('roles-next'),
        label: context.t('onboarding.roles.next'),
        disabled: !canProceed,
        onPressed: canProceed ? () => context.go(Routes.onboardingBio) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t('onboarding.roles.title'),
            style: typo.displayLg.copyWith(color: colors.navy),
          ),
          SizedBox(height: spacing.card / 2),
          Text(
            context.t('onboarding.roles.subtitle'),
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
          if (showInferBanner) ...<Widget>[
            SizedBox(height: spacing.card),
            AppBanner(
              key: const ValueKey<String>('roles-infer-banner'),
              intent: AppIntent.info,
              child: Text(
                context.t(
                  'onboarding.roles.inferBanner',
                  vars: <String, Object>{
                    'label': context.t('onboarding.roles.$inferredRole'),
                  },
                ),
              ),
            ),
          ],
          SizedBox(height: spacing.card),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String r in _kRoles)
                AppFilterChip(
                  key: ValueKey<String>('role-chip-$r'),
                  // Render a check glyph inline next to the label when the
                  // role is selected (matches the gallery's "Founder ✓").
                  label: draft.roles.contains(r)
                      ? '${context.t('onboarding.roles.$r')} ✓'
                      : context.t('onboarding.roles.$r'),
                  active: draft.roles.contains(r),
                  onTap: () {
                    final List<String> next = List<String>.from(draft.roles);
                    if (next.contains(r)) {
                      next.remove(r);
                    } else {
                      next.add(r);
                    }
                    ref
                        .read(onboardingDraftProvider.notifier)
                        .updateRoles(next);
                  },
                ),
            ],
          ),
          SizedBox(height: spacing.card / 2),
          Text(
            context.t('onboarding.roles.footerNote'),
            style: typo.bodySm.copyWith(color: colors.muted),
          ),
          SizedBox(height: spacing.section),
          if (draft.roles.isNotEmpty) ...<Widget>[
            Text(
              context.t('onboarding.roles.primaryQuestion'),
              style: typo.displaySm.copyWith(color: colors.navy),
            ),
            SizedBox(height: spacing.card / 2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String r in draft.roles)
                  _PrimaryPill(
                    key: ValueKey<String>('primary-pill-$r'),
                    label: context.t('onboarding.roles.$r'),
                    selected: draft.primaryRole == r,
                    onTap: () => ref
                        .read(onboardingDraftProvider.notifier)
                        .updatePrimaryRole(r),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tappable wrapper around a Pill so the primary-role picker behaves like a
/// radio button row. We don't reuse the chip primitive because the visual
/// language (navy fill vs outline) is slightly different per the gallery.
class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Pill(
        label: label,
        variant: selected ? PillVariant.navy : PillVariant.outline,
        size: PillSize.md,
      ),
    );
  }
}
