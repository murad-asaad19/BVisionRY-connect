import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/profile_provider.dart';
import '../../auth/providers/session_provider.dart';
import '../data/onboarding_service.dart';
import '../domain/onboarding_draft.dart';
import '../domain/onboarding_schemas.dart';
import '../providers/onboarding_draft_notifier.dart';
import 'stepper_layout.dart';

/// Step 4 of 4 — About.
///
/// City + country are required; headline + bio are optional (with min-length
/// constraints when non-empty). On Submit we run the composite schema, call
/// [OnboardingService.submitOnboarding], reset the draft store, and
/// invalidate [profileProvider] so the route guard advances the user to
/// `/home` automatically — we don't navigate manually.
class AboutStep extends ConsumerStatefulWidget {
  const AboutStep({super.key});

  @override
  ConsumerState<AboutStep> createState() => _AboutStepState();
}

class _AboutStepState extends ConsumerState<AboutStep> {
  bool _submitting = false;

  Future<void> _submit() async {
    final OnboardingDraft? draft = ref.read(onboardingDraftProvider).value;
    if (draft == null) return;
    final String? err = OnboardingSubmissionSchema.firstError(draft);
    if (err != null) {
      _toast(context.t(err), AppIntent.danger);
      return;
    }
    final Session? session = ref.read(currentSessionProvider);
    if (session == null) {
      _toast(
        context.t('onboarding.about.errorSession'),
        AppIntent.danger,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(onboardingServiceProvider).submitOnboarding(
            userId: session.user.id,
            draft: draft,
          );
      await ref.read(onboardingDraftProvider.notifier).reset();
      ref.invalidate(profileProvider);
      // The route guard re-evaluates on profile invalidation and advances
      // the user to /home; no explicit navigation needed here.
    } on AppException catch (e) {
      if (!mounted) return;
      _toast(context.t(e.i18nKey), AppIntent.danger);
    } catch (_) {
      if (!mounted) return;
      _toast(
        context.t('onboarding.about.errorSubmit'),
        AppIntent.danger,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String title, AppIntent intent) {
    ref.read(toastServiceProvider.notifier).showToast(
          title: title,
          intent: intent,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OnboardingDraft> draftAsync =
        ref.watch(onboardingDraftProvider);
    final OnboardingDraft? draft = draftAsync.value;
    if (draft == null) {
      return const StepperLayout(
        stepIndex: 3,
        stepNameKey: 'onboarding.stepName.about',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;

    final bool canSubmit = OnboardingSubmissionSchema.firstError(draft) == null;

    final HeadlineError? headlineErr =
        HeadlineInput.dirty(draft.headline).error;
    final BioError? bioErr = BioInput.dirty(draft.bio).error;
    final CityCountryError? cityErr = CityInput.dirty(draft.city).error;
    final CityCountryError? countryErr =
        CountryInput.dirty(draft.country).error;

    return StepperLayout(
      stepIndex: 3,
      stepNameKey: 'onboarding.stepName.about',
      onBack: () => context.go(Routes.onboardingRoles),
      footer: AppButton(
        key: const ValueKey<String>('about-submit'),
        label: context.t('onboarding.about.finish'),
        loading: _submitting,
        onPressed: canSubmit && !_submitting ? _submit : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t('onboarding.about.title'),
            style: typo.displayLg.copyWith(color: colors.navy),
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('about-city'),
            label: context.t('onboarding.about.city'),
            placeholder: context.t('onboarding.about.cityPlaceholder'),
            value: draft.city,
            maxLength: CityInput.maxLength,
            onChanged: (String v) =>
                ref.read(onboardingDraftProvider.notifier).updateCity(v),
            errorText: (cityErr != null && draft.city.isNotEmpty)
                ? context.t('onboarding.about.errorLocation')
                : null,
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('about-country'),
            label: context.t('onboarding.about.country'),
            placeholder: context.t('onboarding.about.countryPlaceholder'),
            value: draft.country,
            maxLength: CountryInput.maxLength,
            onChanged: (String v) =>
                ref.read(onboardingDraftProvider.notifier).updateCountry(v),
            errorText: (countryErr != null && draft.country.isNotEmpty)
                ? context.t('onboarding.about.errorLocation')
                : null,
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('about-headline'),
            label: context.t('onboarding.about.headline'),
            placeholder: context.t('onboarding.about.headlinePlaceholder'),
            value: draft.headline ?? '',
            maxLength: HeadlineInput.maxLength,
            onChanged: (String v) => ref
                .read(onboardingDraftProvider.notifier)
                .updateHeadline(v.isEmpty ? null : v),
            errorText: headlineErr != null
                ? context.t('onboarding.about.errorHeadlineBio')
                : null,
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('about-bio'),
            label: context.t('onboarding.about.bio'),
            placeholder: context.t('onboarding.about.bioPlaceholder'),
            value: draft.bio ?? '',
            maxLength: BioInput.maxLength,
            multiline: true,
            minLines: 4,
            onChanged: (String v) => ref
                .read(onboardingDraftProvider.notifier)
                .updateBio(v.isEmpty ? null : v),
            errorText: bioErr != null
                ? context.t('onboarding.about.errorHeadlineBio')
                : null,
          ),
        ],
      ),
    );
  }
}
