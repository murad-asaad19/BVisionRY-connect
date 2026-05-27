import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_draft.dart';
import '../domain/onboarding_schemas.dart';
import '../providers/handle_availability_provider.dart';
import '../providers/onboarding_draft_notifier.dart';
import 'stepper_layout.dart';

/// Step 2 of 5 — Identity.
///
/// Two fields: full name (1..80 chars) and handle (lowercase regex, 2..30
/// chars, single hyphens). The `check_handle_available` RPC runs via
/// [handleAvailabilityProvider] as soon as the handle is format-valid +
/// non-empty (the provider is keyed by handle so a unique value triggers
/// a single RPC and caches the result). The Next button is gated on
/// (name valid) ∧ (handle valid) ∧ (handle reported available).
class IdentityStep extends ConsumerStatefulWidget {
  const IdentityStep({super.key});

  @override
  ConsumerState<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends ConsumerState<IdentityStep> {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<OnboardingDraft> draftAsync =
        ref.watch(onboardingDraftProvider);
    final OnboardingDraft? draft = draftAsync.value;
    if (draft == null) {
      return const StepperLayout(
        stepIndex: 1,
        stepNameKey: 'onboarding.stepName.identity',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;

    final bool nameValid = NameInput.dirty(draft.name).error == null;
    final bool handleFormatValid =
        HandleInput.dirty(draft.handle).error == null;

    // Watch the availability provider whenever the handle is format-valid
    // + non-empty. Previously we gated this on an explicit blur, which
    // left users stuck if they tapped Next without first blurring the
    // field (no indicator, no error, button forever disabled). The
    // provider is keyed by handle string so each unique value fires
    // exactly one RPC and caches the result.
    final AsyncValue<bool?> availability =
        handleFormatValid && draft.handle.isNotEmpty
            ? ref.watch(handleAvailabilityProvider(draft.handle))
            : const AsyncValue<bool?>.data(null);

    Widget? trailing;
    String? handleError;
    availability.when(
      loading: () => trailing = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (Object _, StackTrace __) {
        trailing = Icon(Icons.error_outline, color: colors.danger, size: 20);
        handleError = context.t('onboarding.identity.errorHandleCheck');
      },
      data: (bool? available) {
        if (available == true) {
          trailing = Icon(Icons.check, color: colors.success, size: 20);
        } else if (available == false) {
          trailing = Icon(Icons.close, color: colors.danger, size: 20);
          handleError = context.t('onboarding.identity.errorHandleTaken');
        }
      },
    );
    // Format error overrides RPC state: a malformed handle should not show
    // the "taken" copy from a previous valid value.
    if (!handleFormatValid && draft.handle.isNotEmpty) {
      handleError = context.t('onboarding.identity.errorHandleInvalid');
      trailing = null;
    }

    final bool handleAvailable = availability.value == true;
    final bool canProceed = nameValid && handleFormatValid && handleAvailable;

    return StepperLayout(
      stepIndex: 1,
      stepNameKey: 'onboarding.stepName.identity',
      onBack: () => context.go(Routes.onboardingGoal),
      footer: AppButton(
        key: const ValueKey<String>('identity-next'),
        label: context.t('onboarding.identity.next'),
        onPressed: canProceed ? () => context.go(Routes.onboardingRoles) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t('onboarding.identity.title'),
            style: typo.displayLg.copyWith(color: colors.navy),
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('identity-name'),
            label: context.t('onboarding.identity.name'),
            placeholder: context.t('onboarding.identity.namePlaceholder'),
            value: draft.name,
            maxLength: NameInput.maxLength,
            onChanged: (String v) =>
                ref.read(onboardingDraftProvider.notifier).updateName(v),
            errorText: (!nameValid && draft.name.isNotEmpty)
                ? context.t('onboarding.identity.errorNameRequired')
                : null,
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('identity-handle'),
            label: context.t('onboarding.identity.handle'),
            placeholder: context.t('onboarding.identity.handlePlaceholder'),
            value: draft.handle,
            maxLength: 30,
            onChanged: (String v) {
              ref.read(onboardingDraftProvider.notifier).updateHandle(v);
            },
            trailing: trailing,
            errorText: handleError,
          ),
          SizedBox(height: spacing.card / 2),
          Text(
            context.t('onboarding.identity.handleHint'),
            style: typo.bodySm.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
