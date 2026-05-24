import { useState } from 'react';
import { View, Text, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { StepperLayout } from './StepperLayout';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { useAuthSession } from '~/features/auth/SessionContext';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import { submitOnboarding } from '~/features/onboarding/services/onboarding.service';
import { AvatarUploadButton } from '~/features/media/components/AvatarUploadButton';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import {
  CitySchema,
  CountrySchema,
  HeadlineSchema,
  BioSchema,
  OnboardingSubmissionSchema,
} from '~/features/profile/schemas';

type FormValues = {
  city: string;
  country: string;
  headline: string;
  bio: string;
};

export function AboutStep() {
  const { t } = useTranslation();
  const { draft, setField, reset } = useOnboardingDraft();
  const { session } = useAuthSession();
  const profileQ = useCurrentUserProfile();
  const qc = useQueryClient();

  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const { control, handleSubmit } = useForm<FormValues>({
    defaultValues: {
      city: draft.city ?? '',
      country: draft.country ?? '',
      headline: draft.headline ?? '',
      bio: draft.bio ?? '',
    },
  });

  const onFinish = async (values: FormValues) => {
    setError(null);
    const cityP = CitySchema.safeParse(values.city);
    const countryP = CountrySchema.safeParse(values.country);
    if (!cityP.success || !countryP.success) {
      setError(t('onboarding.about.errorLocation'));
      return;
    }
    const headlineP = HeadlineSchema.safeParse(values.headline);
    const bioP = BioSchema.safeParse(values.bio);
    if (!headlineP.success || !bioP.success) {
      setError(t('onboarding.about.errorHeadlineBio'));
      return;
    }
    setField('city', cityP.data);
    setField('country', countryP.data);
    setField('headline', headlineP.data);
    setField('bio', bioP.data);

    const aggregate = OnboardingSubmissionSchema.safeParse({
      ...draft,
      city: cityP.data,
      country: countryP.data,
      headline: headlineP.data,
      bio: bioP.data,
    });
    if (!aggregate.success) {
      setError(t('onboarding.about.errorMissing'));
      return;
    }

    if (!session?.user.id) {
      setError(t('onboarding.about.errorSession'));
      return;
    }

    setSubmitting(true);
    try {
      const updated = await submitOnboarding(session.user.id, aggregate.data);
      qc.setQueryData(['profile', session.user.id], updated);
      reset();
      router.replace('/(app)/(tabs)/home');
    } catch (e) {
      setError(e instanceof Error ? e.message : t('onboarding.about.errorSubmit'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <StepperLayout currentIndex={3} title={t('onboarding.about.title')}>
      <ScrollView>
        <AvatarUploadButton currentPhotoUrl={profileQ.data?.photo_url ?? null} />

        <View>
          <Controller
            control={control}
            name="city"
            render={({ field: { value, onChange } }) => (
              <Input
                testID="about-city"
                label={t('onboarding.about.city')}
                value={value}
                onChangeText={onChange}
                placeholder={t('onboarding.about.cityPlaceholder')}
              />
            )}
          />
          <Controller
            control={control}
            name="country"
            render={({ field: { value, onChange } }) => (
              <Input
                testID="about-country"
                label={t('onboarding.about.country')}
                value={value}
                onChangeText={onChange}
                placeholder={t('onboarding.about.countryPlaceholder')}
              />
            )}
          />
          <Controller
            control={control}
            name="headline"
            render={({ field: { value, onChange } }) => (
              <Input
                testID="about-headline"
                label={t('onboarding.about.headline')}
                value={value}
                onChangeText={onChange}
                placeholder={t('onboarding.about.headlinePlaceholder')}
                maxLength={120}
              />
            )}
          />
          <Controller
            control={control}
            name="bio"
            render={({ field: { value, onChange } }) => (
              <Input
                testID="about-bio"
                label={t('onboarding.about.bio')}
                value={value}
                onChangeText={onChange}
                placeholder={t('onboarding.about.bioPlaceholder')}
                multiline
                numberOfLines={5}
                maxLength={1000}
              />
            )}
          />

          {error && (
            <Text testID="about-error" className="text-danger-text mb-2">
              {error}
            </Text>
          )}

          <View className="mt-4">
            <Button
              testID="about-finish"
              variant="primary"
              onPress={handleSubmit(onFinish)}
              loading={submitting}
            >
              {t('onboarding.about.finish')}
            </Button>
          </View>
        </View>
      </ScrollView>
    </StepperLayout>
  );
}
