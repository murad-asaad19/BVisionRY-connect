import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_draft.dart';
import '../domain/onboarding_schemas.dart';
import '../providers/onboarding_draft_notifier.dart';
import 'onboarding_exit.dart';
import 'stepper_layout.dart';

/// Step 3 of 4 — headline + "I am" bio.
///
/// A simple, deterministic, editable form: two fields the user fills in
/// themselves. On first seed the fields are prefilled either from a previously
/// chosen headline+bio (back-navigation) or from a deterministic local
/// template derived from the user's role + goal — so the user always lands on
/// an editable starting point. No AI, no network, no spinners.
class BioDraftStep extends ConsumerStatefulWidget {
  const BioDraftStep({super.key});

  @override
  ConsumerState<BioDraftStep> createState() => _BioDraftStepState();
}

class _BioDraftStepState extends ConsumerState<BioDraftStep> {
  /// `true` once we've performed the one-time prefill from the persisted draft
  /// (or the deterministic template). Guards against re-seeding on rebuild.
  bool _seeded = false;

  String _headline = '';
  String _bio = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OnboardingDraft> draftAsync =
        ref.watch(onboardingDraftProvider);
    final OnboardingDraft? draft = draftAsync.value;
    if (draft == null) {
      return const StepperLayout(
        stepIndex: 2,
        stepNameKey: 'onboarding.stepName.bio',
        child: _BioStepSkeleton(),
      );
    }

    // One-time prefill on the first build that sees a hydrated draft.
    //
    // If the user already chose a headline+bio earlier (e.g. they're
    // navigating Back into this step), rehydrate from the persisted draft.
    // Otherwise seed the deterministic template so the user always lands on an
    // editable starting point.
    if (!_seeded) {
      _seeded = true;
      final String existingHeadline = draft.headline?.trim() ?? '';
      final String existingBio = draft.bio?.trim() ?? '';
      if (existingHeadline.isNotEmpty && existingBio.isNotEmpty) {
        _headline = existingHeadline;
        _bio = existingBio;
      } else {
        final _BioTemplate template = _templateVariantFor(context, draft);
        _headline = template.headline;
        _bio = template.bio;
      }
    }

    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;

    final HeadlineError? headlineErr = HeadlineInput.dirty(_headline).error;
    final BioError? bioErr = BioInput.dirty(_bio).error;
    final bool valid = headlineErr == null &&
        bioErr == null &&
        _headline.trim().length >= HeadlineInput.minLength &&
        _bio.trim().length >= BioInput.minLength;

    Future<void> save() async {
      if (!valid) return;
      Haptics.medium();
      final OnboardingDraftNotifier notifier =
          ref.read(onboardingDraftProvider.notifier);
      await notifier.updateHeadline(_headline.trim());
      await notifier.updateBio(_bio.trim());
      Analytics.log(
        AppEvent.onboardingStepCompleted,
        const <String, Object>{'step': 'bio'},
      );
      if (!context.mounted) return;
      context.go(Routes.onboardingAbout);
    }

    return StepperLayout(
      stepIndex: 2,
      stepNameKey: 'onboarding.stepName.bio',
      onBack: () => context.go(Routes.onboardingRoles),
      onSignOut: () => confirmAndSignOut(context, ref),
      footer: AppButton(
        key: const ValueKey<String>('bio-looks-good'),
        label: context.t('onboarding.bio.looksGood'),
        variant: AppButtonVariant.gold,
        onPressed: valid ? save : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t('onboarding.bio.title'),
            style: typo.displayLg.copyWith(color: colors.navy),
          ),
          SizedBox(height: spacing.card / 2),
          Text(
            context.t('onboarding.bio.subtitle'),
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('bio-custom-headline'),
            label: context.t('onboarding.bio.headlineLabel'),
            value: _headline,
            maxLength: HeadlineInput.maxLength,
            onChanged: (String v) => setState(() => _headline = v),
            errorText: headlineErr != null
                ? context.t('onboarding.about.errorHeadlineBio')
                : null,
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('bio-custom-bio'),
            label: context.t('onboarding.bio.bioLabel'),
            value: _bio,
            multiline: true,
            minLines: 3,
            maxLines: 6,
            maxLength: BioInput.maxLength,
            onChanged: (String v) => setState(() => _bio = v),
            errorText: bioErr != null
                ? context.t('onboarding.about.errorHeadlineBio')
                : null,
          ),
        ],
      ),
    );
  }
}

/// Resolves the user-facing label for the draft's primary role. Falls back to
/// the raw key if no translation is available so the prompt context is never
/// silently dropped.
String _roleLabel(BuildContext context, OnboardingDraft draft) {
  final String roleKey =
      draft.primaryRole ?? (draft.roles.isNotEmpty ? draft.roles.first : '');
  if (roleKey.isEmpty) return '';
  return context.t('onboarding.roles.$roleKey');
}

/// A deterministic (headline, bio) starting point for the editable form.
class _BioTemplate {
  const _BioTemplate({required this.headline, required this.bio});

  final String headline;
  final String bio;
}

/// Builds the deterministic template used as the initial prefill. Format:
///   headline: `RoleName · <truncated goal>`
///   bio:      `RoleName (<goalLabel>) — <full goal text>`
///
/// Falls back to safe i18n strings if either roles or goal text is missing.
_BioTemplate _templateVariantFor(
  BuildContext context,
  OnboardingDraft draft,
) {
  final String roleLabel = _roleLabel(context, draft);
  final String goal = draft.goalText.trim();

  String headline;
  if (roleLabel.isEmpty && goal.isEmpty) {
    headline = context.t('onboarding.bio.fallbackHeadline');
  } else if (goal.isEmpty) {
    headline = roleLabel;
  } else if (roleLabel.isEmpty) {
    headline = _truncate(goal, 80);
  } else {
    headline = '$roleLabel · ${_truncate(goal, 80 - roleLabel.length - 3)}';
  }
  headline = _truncate(headline, 120);

  String bio;
  if (roleLabel.isEmpty && goal.isEmpty) {
    bio = context.t('onboarding.bio.fallbackBio');
  } else if (goal.isEmpty) {
    bio = '$roleLabel on BVisionRY Connect.';
  } else if (roleLabel.isEmpty) {
    bio = 'Looking for: $goal';
  } else {
    bio = '$roleLabel — looking for: $goal';
    if (draft.goalType != null) {
      final String goalLabel =
          context.t(draft.goalType!.i18nLabelKey).toLowerCase();
      bio = '$roleLabel ($goalLabel) — $goal';
    }
  }
  return _BioTemplate(headline: headline, bio: bio);
}

String _truncate(String value, int max) {
  if (value.length <= max) return value;
  if (max <= 1) return value.substring(0, max);
  return '${value.substring(0, max - 1).trimRight()}…';
}

/// Shape-matching placeholder shown while the persisted draft hydrates, in
/// place of a bare centered spinner. Mirrors the Bio step (title → subtitle →
/// two fields) so the layout doesn't jump when content arrives.
class _BioStepSkeleton extends StatelessWidget {
  const _BioStepSkeleton();

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Skeleton(width: 220, height: 24),
        Gap(spacing.sm),
        const Skeleton(width: 280, height: 14),
        Gap(spacing.card),
        const Skeleton(width: double.infinity, height: 56, rounded: 10),
        Gap(spacing.card),
        const Skeleton(width: double.infinity, height: 120, rounded: 10),
      ],
    );
  }
}
