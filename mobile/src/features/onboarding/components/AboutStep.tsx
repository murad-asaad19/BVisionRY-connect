import { useState } from 'react';
import { View, Text, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
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

export function AboutStep() {
  const { draft, setField, reset } = useOnboardingDraft();
  const { session } = useAuthSession();
  const profileQ = useCurrentUserProfile();
  const qc = useQueryClient();

  const [city, setCity] = useState(draft.city ?? '');
  const [country, setCountry] = useState(draft.country ?? '');
  const [headline, setHeadline] = useState(draft.headline ?? '');
  const [bio, setBio] = useState(draft.bio ?? '');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const onFinish = async () => {
    const cityP = CitySchema.safeParse(city);
    const countryP = CountrySchema.safeParse(country);
    if (!cityP.success || !countryP.success) {
      setError('City and country are required.');
      return;
    }
    const headlineP = HeadlineSchema.safeParse(headline);
    const bioP = BioSchema.safeParse(bio);
    if (!headlineP.success || !bioP.success) {
      setError('Headline must be 5-120 chars; bio must be 10-1000 chars (or leave blank).');
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
      setError('Some required fields are missing. Go back and complete earlier steps.');
      return;
    }

    if (!session?.user.id) {
      setError('No active session. Please sign in again.');
      return;
    }

    setSubmitting(true);
    try {
      const updated = await submitOnboarding(session.user.id, aggregate.data);
      qc.setQueryData(['profile', session.user.id], updated);
      reset();
      router.replace('/(app)/(tabs)/home');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Submission failed');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <StepperLayout currentIndex={3} title="A bit about you">
      <ScrollView>
        <AvatarUploadButton currentPhotoUrl={profileQ.data?.photo_url ?? null} />

        <View>
          <Input
            testID="about-city"
            label="City"
            value={city}
            onChangeText={setCity}
            placeholder="San Francisco"
          />
          <Input
            testID="about-country"
            label="Country"
            value={country}
            onChangeText={setCountry}
            placeholder="USA"
          />
          <Input
            testID="about-headline"
            label="Headline (optional, 5-120 chars)"
            value={headline}
            onChangeText={setHeadline}
            placeholder="Building AI tools for makers"
            maxLength={120}
          />
          <Input
            testID="about-bio"
            label="Bio (optional, 10-1000 chars)"
            value={bio}
            onChangeText={setBio}
            placeholder="I'm a..."
            multiline
            numberOfLines={5}
            maxLength={1000}
          />

          {error && (
            <Text testID="about-error" className="text-danger-text mb-2">
              {error}
            </Text>
          )}

          <View className="mt-4">
            <Button testID="about-finish" variant="primary" onPress={onFinish} loading={submitting}>
              Finish
            </Button>
          </View>
        </View>
      </ScrollView>
    </StepperLayout>
  );
}
