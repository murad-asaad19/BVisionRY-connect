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

/// Step 5 of 5 — A few last details.
///
/// Photo upload (UI shell), full name, location (combined city + country),
/// handle (with live URL preview + redirect note), then optional headline
/// and bio. On Submit we run the composite schema, call
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

  /// Splits a combined "City, Country" value on the FIRST comma and persists
  /// each half independently. Keeps the underlying schema (separate columns)
  /// untouched while the UI presents a single field.
  void _onLocationChanged(String value) {
    final int idx = value.indexOf(',');
    if (idx == -1) {
      // No comma yet — treat the whole value as the city, clear the country
      // so the schema doesn't accept half-typed input.
      ref.read(onboardingDraftProvider.notifier).updateCity(value.trim());
      ref.read(onboardingDraftProvider.notifier).updateCountry('');
      return;
    }
    final String city = value.substring(0, idx).trim();
    final String country = value.substring(idx + 1).trim();
    ref.read(onboardingDraftProvider.notifier).updateCity(city);
    ref.read(onboardingDraftProvider.notifier).updateCountry(country);
  }

  /// Reconstructs the "City, Country" string from the two persisted fields.
  String _composeLocation(OnboardingDraft draft) {
    final String city = draft.city.trim();
    final String country = draft.country.trim();
    if (city.isEmpty && country.isEmpty) return '';
    if (country.isEmpty) return city;
    if (city.isEmpty) return country;
    return '$city, $country';
  }

  void _onTapPhoto() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: Text(context.t('onboarding.about.photoComingSoonTitle')),
          content: Text(context.t('onboarding.about.photoComingSoonBody')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(context.t('common.ok')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OnboardingDraft> draftAsync =
        ref.watch(onboardingDraftProvider);
    final OnboardingDraft? draft = draftAsync.value;
    if (draft == null) {
      return const StepperLayout(
        stepIndex: 4,
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
    final bool handleFormatValid =
        HandleInput.dirty(draft.handle).error == null;
    final String handlePreview =
        '${context.t('onboarding.about.handlePreviewPrefix')}'
        '${draft.handle.isEmpty ? '…' : draft.handle}';

    return StepperLayout(
      stepIndex: 4,
      stepNameKey: 'onboarding.stepName.about',
      onBack: () => context.go(Routes.onboardingBio),
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
          SizedBox(height: spacing.card / 2),
          Text(
            context.t('onboarding.about.subtitle'),
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
          SizedBox(height: spacing.card),
          // Photo upload field — dashed-gold 64px circle + helper text.
          Text(
            context.t('onboarding.about.photoLabel').toUpperCase(),
            style: typo.bodyXs.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              _DashedGoldAvatar(
                key: const ValueKey<String>('about-photo'),
                onTap: _onTapPhoto,
              ),
              SizedBox(width: spacing.card / 2),
              Expanded(
                child: Text(
                  context.t('onboarding.about.photoHint'),
                  style: typo.bodySm.copyWith(color: colors.muted),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('about-name'),
            label: context.t('onboarding.identity.name'),
            placeholder: context.t('onboarding.identity.namePlaceholder'),
            value: draft.name,
            maxLength: NameInput.maxLength,
            onChanged: (String v) =>
                ref.read(onboardingDraftProvider.notifier).updateName(v),
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('about-location'),
            label: context.t('onboarding.about.location'),
            placeholder: context.t('onboarding.about.locationPlaceholder'),
            value: _composeLocation(draft),
            onChanged: _onLocationChanged,
            // Always surface the location error when either half is
            // invalid. Previously the error only showed when the user
            // had typed something into the (hidden) city/country fields
            // — empty Location stayed silent and Submit no-op'd.
            errorText:
                (cityErr != null || countryErr != null)
                    ? context.t('onboarding.about.errorLocation')
                    : null,
          ),
          SizedBox(height: spacing.card),
          AppInput(
            key: const ValueKey<String>('about-handle'),
            label: context.t('onboarding.about.handle'),
            placeholder: context.t('onboarding.about.handlePlaceholder'),
            value: draft.handle,
            maxLength: 30,
            onChanged: (String v) =>
                ref.read(onboardingDraftProvider.notifier).updateHandle(v),
            errorText: (!handleFormatValid && draft.handle.isNotEmpty)
                ? context.t('onboarding.identity.errorHandleInvalid')
                : null,
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: context.t('onboarding.about.handlePreviewPrefix'),
                  style: typo.bodySm.copyWith(color: colors.muted),
                ),
                TextSpan(
                  text: draft.handle.isEmpty ? '…' : draft.handle,
                  style: typo.bodySm.copyWith(
                    color: colors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            // a11y: the rendered preview reads as one continuous URL.
            semanticsLabel: handlePreview,
          ),
          const SizedBox(height: 4),
          Text(
            context.t('onboarding.about.handleRedirectNote'),
            style: typo.bodyXs.copyWith(color: colors.muted),
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

/// 64px dashed-gold circle uploader. Tapping opens a "coming soon" dialog —
/// the visual is the load-bearing artifact for the gallery alignment audit;
/// the actual upload pipeline ships later.
class _DashedGoldAvatar extends StatelessWidget {
  const _DashedGoldAvatar({super.key, required this.onTap});
  final VoidCallback onTap;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      button: true,
      label: 'Add photo',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: CustomPaint(
          painter: _DashedCirclePainter(color: colors.gold),
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: colors.goldPale,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.add, color: colors.navy, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Draws a dashed circular stroke around the avatar uploader. Flutter has no
/// built-in dashed border, so we render one with a tight CustomPainter.
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = (size.shortestSide - 2) / 2;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const int dashes = 18;
    const double sweepFraction = 0.6; // 60% stroke / 40% gap
    const double dashAngle = (2 * 3.141592653589793) / dashes;
    for (int i = 0; i < dashes; i++) {
      final double start = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        dashAngle * sweepFraction,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.color != color;
}
