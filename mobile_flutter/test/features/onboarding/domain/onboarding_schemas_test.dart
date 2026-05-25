import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_schemas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NameInput', () {
    test('rejects empty', () {
      expect(const NameInput.dirty('').error, NameError.required);
    });
    test('rejects whitespace-only', () {
      expect(const NameInput.dirty('   ').error, NameError.required);
    });
    test('rejects > 80', () {
      expect(NameInput.dirty('a' * 81).error, NameError.tooLong);
    });
    test('accepts an 80-char name', () {
      expect(NameInput.dirty('a' * 80).error, isNull);
    });
    test('accepts a normal name', () {
      expect(const NameInput.dirty('Ada Lovelace').error, isNull);
    });
  });

  group('HandleInput', () {
    test('rejects uppercase', () {
      expect(const HandleInput.dirty('Ada').error, HandleError.invalid);
    });
    test('rejects leading hyphen', () {
      expect(const HandleInput.dirty('-ada').error, HandleError.invalid);
    });
    test('rejects trailing hyphen', () {
      expect(const HandleInput.dirty('ada-').error, HandleError.invalid);
    });
    test('rejects 2-char (regex requires 1 OR 3+)', () {
      // The spec regex `^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$` matches a
      // single char or 3+ chars; 2-char inputs fall through the inner group.
      expect(const HandleInput.dirty('ab').error, HandleError.invalid);
    });
    test('rejects > 30 char', () {
      expect(HandleInput.dirty('a' * 31).error, HandleError.invalid);
    });
    test('accepts ada-l0velace', () {
      expect(const HandleInput.dirty('ada-l0velace').error, isNull);
    });
    test('accepts single char (per literal spec regex)', () {
      expect(const HandleInput.dirty('a').error, isNull);
    });
    test('accepts 3-char minimum', () {
      expect(const HandleInput.dirty('abc').error, isNull);
    });
    test('accepts digits + hyphen', () {
      expect(const HandleInput.dirty('42-x').error, isNull);
    });
  });

  group('GoalTextInput', () {
    test('rejects < 10', () {
      expect(const GoalTextInput.dirty('hi').error, GoalTextError.tooShort);
    });
    test('rejects > 280', () {
      expect(GoalTextInput.dirty('x' * 281).error, GoalTextError.tooLong);
    });
    test('accepts 10-char minimum', () {
      expect(GoalTextInput.dirty('a' * 10).error, isNull);
    });
    test('accepts a 50-char description', () {
      expect(
        const GoalTextInput.dirty(
          'Looking to hire a fractional design lead',
        ).error,
        isNull,
      );
    });
  });

  group('HeadlineInput', () {
    test('null is allowed', () {
      expect(const HeadlineInput.dirty().error, isNull);
    });
    test('empty is allowed', () {
      expect(const HeadlineInput.dirty('').error, isNull);
    });
    test('4 chars rejected', () {
      expect(const HeadlineInput.dirty('abcd').error, HeadlineError.range);
    });
    test('5 chars allowed', () {
      expect(const HeadlineInput.dirty('abcde').error, isNull);
    });
    test('120 chars allowed', () {
      expect(HeadlineInput.dirty('x' * 120).error, isNull);
    });
    test('121 chars rejected', () {
      expect(HeadlineInput.dirty('x' * 121).error, HeadlineError.range);
    });
  });

  group('BioInput', () {
    test('null/empty allowed', () {
      expect(const BioInput.dirty().error, isNull);
      expect(const BioInput.dirty('').error, isNull);
    });
    test('9 chars rejected, 10 allowed', () {
      expect(BioInput.dirty('a' * 9).error, BioError.range);
      expect(BioInput.dirty('a' * 10).error, isNull);
    });
    test('1001 chars rejected', () {
      expect(BioInput.dirty('a' * 1001).error, BioError.range);
    });
  });

  group('CityInput', () {
    test('rejects empty', () {
      expect(const CityInput.dirty('').error, CityCountryError.required);
    });
    test('accepts normal', () {
      expect(const CityInput.dirty('Berlin').error, isNull);
    });
    test('rejects > 80', () {
      expect(CityInput.dirty('a' * 81).error, CityCountryError.tooLong);
    });
  });

  group('CountryInput', () {
    test('rejects empty', () {
      expect(const CountryInput.dirty('').error, CityCountryError.required);
    });
    test('accepts normal', () {
      expect(const CountryInput.dirty('Germany').error, isNull);
    });
  });

  group('OnboardingSubmissionSchema', () {
    const OnboardingDraft valid = OnboardingDraft(
      goalText:
          'Looking to hire a fractional designer for our healthtech app.',
      goalType: GoalType.hire,
      name: 'Ada',
      handle: 'ada',
      roles: <String>['founder', 'leader'],
      primaryRole: 'founder',
      city: 'Berlin',
      country: 'Germany',
      headline: 'Founder',
      bio: 'A short but valid bio entry.',
    );

    test('returns null (no error) for fully valid draft', () {
      expect(OnboardingSubmissionSchema.firstError(valid), isNull);
    });
    test('flags missing goal text', () {
      final OnboardingDraft d = valid.copyWith(goalText: 'short');
      expect(
        OnboardingSubmissionSchema.firstError(d),
        'onboarding.goal.errorRange',
      );
    });
    test('flags missing goal_type', () {
      final OnboardingDraft d = valid.copyWith(goalType: null);
      expect(
        OnboardingSubmissionSchema.firstError(d),
        'onboarding.goal.pickType',
      );
    });
    test('flags missing name', () {
      final OnboardingDraft d = valid.copyWith(name: '');
      expect(
        OnboardingSubmissionSchema.firstError(d),
        'onboarding.identity.errorNameRequired',
      );
    });
    test('flags invalid handle', () {
      final OnboardingDraft d = valid.copyWith(handle: 'X');
      expect(
        OnboardingSubmissionSchema.firstError(d),
        'onboarding.identity.errorHandleInvalid',
      );
    });
    test('flags empty roles', () {
      final OnboardingDraft d =
          valid.copyWith(roles: const <String>[], primaryRole: null);
      expect(
        OnboardingSubmissionSchema.firstError(d),
        'onboarding.roles.errorPickOne',
      );
    });
    test('flags primary not in roles', () {
      final OnboardingDraft d = valid.copyWith(primaryRole: 'investor');
      expect(
        OnboardingSubmissionSchema.firstError(d),
        'onboarding.roles.errorPickPrimary',
      );
    });
    test('flags missing city', () {
      final OnboardingDraft d = valid.copyWith(city: '');
      expect(
        OnboardingSubmissionSchema.firstError(d),
        'onboarding.about.errorLocation',
      );
    });
    test('flags too-short headline', () {
      final OnboardingDraft d = valid.copyWith(headline: 'abcd');
      expect(
        OnboardingSubmissionSchema.firstError(d),
        'onboarding.about.errorHeadlineBio',
      );
    });
  });
}
