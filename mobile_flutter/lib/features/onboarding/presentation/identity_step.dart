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

/// Step 2 of 4 — Identity.
///
/// Two fields: full name (1..80 chars) and handle (lowercase regex, 2..30
/// chars, single hyphens). On blur of the handle field we kick off the
/// `check_handle_available` RPC via [handleAvailabilityProvider], which
/// surfaces a check / X / spinner icon as the trailing widget. The Next
/// button is gated on (name valid) ∧ (handle valid) ∧ (handle reported
/// available).
class IdentityStep extends ConsumerStatefulWidget {
  const IdentityStep({super.key});

  @override
  ConsumerState<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends ConsumerState<IdentityStep> {
  /// Once the user has blurred the handle field at least once we want the
  /// availability check to be authoritative for the Next button. Tracked
  /// here so the initial render (where the provider returns idle) doesn't
  /// imply "available".
  bool _handleBlurred = false;

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

    // Only watch the availability provider for a format-valid handle —
    // otherwise we'd waste a provider subscription on every invalid keystroke.
    final AsyncValue<bool?> availability =
        handleFormatValid && _handleBlurred && draft.handle.isNotEmpty
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
            onBlur: () {
              if (!mounted) return;
              // Re-read the draft so we react to the latest handle value,
              // not the snapshot from the build that scheduled this listener.
              final String latest =
                  ref.read(onboardingDraftProvider).value?.handle ?? '';
              if (latest.isEmpty) return;
              if (HandleInput.dirty(latest).error != null) return;
              setState(() => _handleBlurred = true);
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
