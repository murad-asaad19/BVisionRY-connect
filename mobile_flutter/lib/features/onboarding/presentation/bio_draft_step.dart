import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_draft.dart';
import '../providers/onboarding_draft_notifier.dart';
import 'stepper_layout.dart';

/// Step 4 of 5 — AI-assisted bio drafting (UI shell, no AI call).
///
/// Mocks the gallery's B3 mini-chat: a small "AI" bubble explains what's
/// happening, a draft suggestion is shown with the proposed headline and
/// "I am" bio, and two side-by-side buttons let the user either edit
/// (clear the draft and advance) or accept (pre-fill the draft and
/// advance). The draft is composed locally from the user's roles + goal
/// — no network call.
class BioDraftStep extends ConsumerWidget {
  const BioDraftStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OnboardingDraft> draftAsync =
        ref.watch(onboardingDraftProvider);
    final OnboardingDraft? draft = draftAsync.value;
    if (draft == null) {
      return const StepperLayout(
        stepIndex: 3,
        stepNameKey: 'onboarding.stepName.bio',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;

    final _BioSuggestion suggestion = _suggestionFor(context, draft);

    void advance() => context.go(Routes.onboardingAbout);

    return StepperLayout(
      stepIndex: 3,
      stepNameKey: 'onboarding.stepName.bio',
      onBack: () => context.go(Routes.onboardingRoles),
      footer: Row(
        children: <Widget>[
          Expanded(
            child: AppButton(
              key: const ValueKey<String>('bio-edit'),
              label: context.t('onboarding.bio.edit'),
              variant: AppButtonVariant.outline,
              onPressed: () {
                // "Edit" carries the user forward without pre-filling — they
                // can hand-write the headline / bio on the final step.
                advance();
              },
            ),
          ),
          SizedBox(width: spacing.card / 2),
          Expanded(
            child: AppButton(
              key: const ValueKey<String>('bio-looks-good'),
              label: context.t('onboarding.bio.looksGood'),
              variant: AppButtonVariant.gold,
              onPressed: () async {
                // Pre-fill headline + bio with the suggested draft so the
                // About step renders them already populated.
                await ref
                    .read(onboardingDraftProvider.notifier)
                    .updateHeadline(suggestion.headline);
                await ref
                    .read(onboardingDraftProvider.notifier)
                    .updateBio(suggestion.bio);
                if (!context.mounted) return;
                advance();
              },
            ),
          ),
        ],
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
          // Chat-thread bubble explaining the draft.
          Container(
            key: const ValueKey<String>('bio-ai-bubble'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.white,
              borderRadius: BorderRadius.circular(radii.button),
              border: Border.all(color: colors.border, width: 1),
            ),
            child: RichText(
              text: TextSpan(
                style: typo.bodyMd.copyWith(color: colors.body),
                children: <InlineSpan>[
                  TextSpan(
                    text: 'AI: ',
                    style: typo.displaySm.copyWith(color: colors.navy),
                  ),
                  TextSpan(text: context.t('onboarding.bio.aiBubble')),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.card),
          // Headline suggestion.
          Text(
            context.t('onboarding.bio.headlineLabel').toUpperCase(),
            style: typo.bodyXs.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          _SuggestionTile(text: suggestion.headline),
          SizedBox(height: spacing.card),
          // Bio suggestion.
          Text(
            context.t('onboarding.bio.bioLabel').toUpperCase(),
            style: typo.bodyXs.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          _SuggestionTile(text: suggestion.bio),
        ],
      ),
    );
  }
}

/// Builds the draft suggestion from the current draft's roles + goal.
///
/// This is a deterministic template, not an AI call. Format:
///   `RoleName · <truncated goal headline>`
///   `RoleName — looking for: <full goal text>.`
///
/// Falls back to safe i18n strings if either roles or goal text is missing.
_BioSuggestion _suggestionFor(BuildContext context, OnboardingDraft draft) {
  final String roleKey = draft.primaryRole ??
      (draft.roles.isNotEmpty ? draft.roles.first : '');
  final String roleLabel = roleKey.isEmpty
      ? ''
      : context.t('onboarding.roles.$roleKey');
  final String goal = draft.goalText.trim();

  // Headline: "Founder · Looking for ..." capped to keep the visible draft
  // tight. The validator on the About step gates at 5..120 chars.
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

  // Bio: small free-form expansion of role + goal so the value passes the
  // 10..1000 char schema gate.
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
  return _BioSuggestion(headline: headline, bio: bio);
}

String _truncate(String value, int max) {
  if (value.length <= max) return value;
  if (max <= 1) return value.substring(0, max);
  return '${value.substring(0, max - 1).trimRight()}…';
}

/// Container for the two text values we suggest to the user.
class _BioSuggestion {
  const _BioSuggestion({required this.headline, required this.bio});
  final String headline;
  final String bio;
}

/// Gold-pale tile used for the suggested headline / bio strings. Matches
/// the gallery's `.bubble.them` styling for inline drafts.
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.goldPale,
        borderRadius: BorderRadius.circular(radii.button),
        border: Border.all(color: colors.gold, width: 1.5),
      ),
      child: Text(
        text,
        style: typo.bodyMd.copyWith(color: colors.navy),
      ),
    );
  }
}
