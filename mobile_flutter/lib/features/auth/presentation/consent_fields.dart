import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';

/// Minimum age (in years) required to use the service. Kept in sync with the
/// server-side `record_signup_consent` RPC, which is the source of truth.
const int kMinSignupAge = 18;

/// Whole-years age for [dob] as of today, in local time.
int ageFromDob(DateTime dob, {DateTime? now}) {
  final DateTime today = now ?? DateTime.now();
  int age = today.year - dob.year;
  final bool hadBirthdayThisYear =
      today.month > dob.month ||
          (today.month == dob.month && today.day >= dob.day);
  if (!hadBirthdayThisYear) age -= 1;
  return age;
}

/// Tappable, read-only date-of-birth field for the sign-up gate.
///
/// Renders like an [AppInput] (same label / frame / inline-error treatment)
/// but opens a [showDatePicker] on tap instead of accepting keystrokes. The
/// picker is bounded so a user can only choose a plausible birth date.
class DateOfBirthField extends StatelessWidget {
  const DateOfBirthField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final DateTime now = DateTime.now();
    // Default the picker to the minimum-age cutoff so the wheel lands on a
    // sensible year rather than today.
    final DateTime initial =
        value ?? DateTime(now.year - kMinSignupAge, now.month, now.day);
    final DateTime picked = (await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year - 120),
          lastDate: now,
          initialEntryMode: DatePickerEntryMode.calendar,
        )) ??
        initial;
    if (picked != initial || value == null) {
      Haptics.light();
      onChanged(picked);
    }
  }

  String _format(DateTime d) {
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final bool hasError = errorText != null;
    final bool hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.t('auth.consent.dobLabel').toUpperCase(),
          style: typo.bodyXs.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          key: const Key('dob-input'),
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => _pick(context) : null,
          child: Container(
            decoration: BoxDecoration(
              color: colors.white,
              borderRadius: BorderRadius.circular(radii.input),
              border: Border.all(
                color: hasError ? colors.dangerBorder : colors.border,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    hasValue
                        ? _format(value!)
                        : context.t('auth.consent.dobPlaceholder'),
                    style: typo.bodyLg.copyWith(
                      color: hasValue ? colors.body : colors.muted,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: colors.muted,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              errorText!,
              style: typo.bodyXs.copyWith(color: colors.danger),
            ),
          ),
        ] else ...<Widget>[
          const SizedBox(height: 4),
          Text(
            context.t('auth.consent.dobHelper'),
            style: typo.bodyXs.copyWith(color: colors.muted),
          ),
        ],
      ],
    );
  }
}

/// Consent checkbox + inline-tappable legal links ("I agree to the Terms of
/// Service and Privacy Policy"). The two link spans push the [Routes.legalTerms]
/// / [Routes.legalPrivacy] screens so the user can read each document inline.
class ConsentCheckbox extends StatelessWidget {
  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final TextStyle base = typo.bodyMd.copyWith(color: colors.body);
    final TextStyle link = typo.bodyMd.copyWith(
      color: colors.navy,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    Widget linkText(String labelKey, String route) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => context.push(route) : null,
          child: Text(context.t(labelKey), style: link),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                key: const Key('consent-checkbox'),
                value: value,
                onChanged: enabled
                    ? (bool? v) {
                        Haptics.light();
                        onChanged(v ?? false);
                      }
                    : null,
                activeColor: colors.navy,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              // Tapping anywhere on the body text (outside the links) toggles
              // the checkbox, so the whole row is an obvious affordance.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled
                    ? () {
                        Haptics.light();
                        onChanged(!value);
                      }
                    : null,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(context.t('auth.consent.agreePrefix'), style: base),
                    linkText('auth.consent.terms', Routes.legalTerms),
                    Text(context.t('auth.consent.agreeJoin'), style: base),
                    linkText('auth.consent.privacy', Routes.legalPrivacy),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              errorText!,
              style: typo.bodyXs.copyWith(color: colors.danger),
            ),
          ),
        ],
      ],
    );
  }
}
