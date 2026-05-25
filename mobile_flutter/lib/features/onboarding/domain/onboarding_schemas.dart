import 'package:formz/formz.dart';

import 'onboarding_draft.dart';

/// Port of `mobile/src/features/profile/schemas.ts` (Zod) into Flutter's
/// formz library. Each field input owns its own error enum so the UI can
/// localise per-error rather than mapping a generic "invalid" string.

// ─── Name ────────────────────────────────────────────────────────────────

enum NameError { required, tooLong }

class NameInput extends FormzInput<String, NameError> {
  const NameInput.pure() : super.pure('');
  const NameInput.dirty([super.value = '']) : super.dirty();

  static const int maxLength = 80;

  @override
  NameError? validator(String value) {
    if (value.trim().isEmpty) return NameError.required;
    if (value.length > maxLength) return NameError.tooLong;
    return null;
  }
}

// ─── Handle ──────────────────────────────────────────────────────────────

enum HandleError { invalid }

class HandleInput extends FormzInput<String, HandleError> {
  const HandleInput.pure() : super.pure('');
  const HandleInput.dirty([super.value = '']) : super.dirty();

  /// Same regex enforced by the `citext` CHECK constraint on
  /// `profiles.handle` (spec §3.1) — lowercase, digits, single hyphens, no
  /// leading/trailing hyphen, 2-30 chars.
  static final RegExp pattern =
      RegExp(r'^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$');

  @override
  HandleError? validator(String value) {
    if (!pattern.hasMatch(value)) return HandleError.invalid;
    return null;
  }
}

// ─── Goal text ───────────────────────────────────────────────────────────

enum GoalTextError { tooShort, tooLong }

class GoalTextInput extends FormzInput<String, GoalTextError> {
  const GoalTextInput.pure() : super.pure('');
  const GoalTextInput.dirty([super.value = '']) : super.dirty();

  static const int minLength = 10;
  static const int maxLength = 280;

  @override
  GoalTextError? validator(String value) {
    if (value.length < minLength) return GoalTextError.tooShort;
    if (value.length > maxLength) return GoalTextError.tooLong;
    return null;
  }
}

// ─── Headline (optional) ─────────────────────────────────────────────────

enum HeadlineError { range }

class HeadlineInput extends FormzInput<String?, HeadlineError> {
  const HeadlineInput.pure() : super.pure(null);
  const HeadlineInput.dirty([super.value]) : super.dirty();

  static const int minLength = 5;
  static const int maxLength = 120;

  @override
  HeadlineError? validator(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < minLength || value.length > maxLength) {
      return HeadlineError.range;
    }
    return null;
  }
}

// ─── Bio (optional) ──────────────────────────────────────────────────────

enum BioError { range }

class BioInput extends FormzInput<String?, BioError> {
  const BioInput.pure() : super.pure(null);
  const BioInput.dirty([super.value]) : super.dirty();

  static const int minLength = 10;
  static const int maxLength = 1000;

  @override
  BioError? validator(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < minLength || value.length > maxLength) {
      return BioError.range;
    }
    return null;
  }
}

// ─── City / Country (both required, ≤80) ─────────────────────────────────

enum CityCountryError { required, tooLong }

class CityInput extends FormzInput<String, CityCountryError> {
  const CityInput.pure() : super.pure('');
  const CityInput.dirty([super.value = '']) : super.dirty();

  static const int maxLength = 80;

  @override
  CityCountryError? validator(String value) {
    if (value.trim().isEmpty) return CityCountryError.required;
    if (value.length > maxLength) return CityCountryError.tooLong;
    return null;
  }
}

class CountryInput extends FormzInput<String, CityCountryError> {
  const CountryInput.pure() : super.pure('');
  const CountryInput.dirty([super.value = '']) : super.dirty();

  static const int maxLength = 80;

  @override
  CityCountryError? validator(String value) {
    if (value.trim().isEmpty) return CityCountryError.required;
    if (value.length > maxLength) return CityCountryError.tooLong;
    return null;
  }
}

// ─── Composite submission schema ─────────────────────────────────────────

/// Validates a draft top-to-bottom in wizard order. Returns the i18n key of
/// the first failure (so callers can route the user back to the offending
/// step) or null when the draft is ready to submit.
abstract final class OnboardingSubmissionSchema {
  static String? firstError(OnboardingDraft d) {
    if (GoalTextInput.dirty(d.goalText).error != null) {
      return 'onboarding.goal.errorRange';
    }
    if (d.goalType == null) return 'onboarding.goal.pickType';
    if (NameInput.dirty(d.name).error != null) {
      return 'onboarding.identity.errorNameRequired';
    }
    if (HandleInput.dirty(d.handle).error != null) {
      return 'onboarding.identity.errorHandleInvalid';
    }
    if (d.roles.isEmpty) return 'onboarding.roles.errorPickOne';
    if (d.primaryRole == null || !d.roles.contains(d.primaryRole)) {
      return 'onboarding.roles.errorPickPrimary';
    }
    if (CityInput.dirty(d.city).error != null ||
        CountryInput.dirty(d.country).error != null) {
      return 'onboarding.about.errorLocation';
    }
    if (HeadlineInput.dirty(d.headline).error != null ||
        BioInput.dirty(d.bio).error != null) {
      return 'onboarding.about.errorHeadlineBio';
    }
    return null;
  }
}
