import { useState } from 'react';
import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { StepperLayout } from './StepperLayout';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { HandleSchema, NameSchema } from '~/features/profile/schemas';
import { checkHandleAvailable } from '~/features/profile/services/profile.service';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';

type FormValues = { name: string; handle: string };

export function IdentityStep() {
  const { draft, setField } = useOnboardingDraft();
  const [submitting, setSubmitting] = useState(false);

  const {
    control,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<FormValues>({
    defaultValues: { name: draft.name ?? '', handle: draft.handle ?? '' },
  });

  const onSubmit = async (values: FormValues) => {
    const nameParsed = NameSchema.safeParse(values.name);
    if (!nameParsed.success) {
      setError('name', { message: 'Enter your name (1-80 characters).' });
      return;
    }
    const handleParsed = HandleSchema.safeParse(values.handle);
    if (!handleParsed.success) {
      setError('handle', { message: handleParsed.error.issues[0]?.message ?? 'Invalid handle' });
      return;
    }
    setSubmitting(true);
    try {
      const available = await checkHandleAvailable(handleParsed.data);
      if (!available) {
        setError('handle', { message: 'That handle is already taken.' });
        return;
      }
      setField('name', nameParsed.data);
      setField('handle', handleParsed.data);
      router.push('/(onboarding)/roles');
    } catch (e) {
      setError('handle', { message: e instanceof Error ? e.message : 'Check failed' });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <StepperLayout currentIndex={1} title="Who are you?">
      <View>
        <Controller
          control={control}
          name="name"
          rules={{ required: true }}
          render={({ field: { onChange, value } }) => (
            <View>
              <Input
                testID="identity-name"
                label="Name"
                value={value}
                onChangeText={onChange}
                placeholder="Ahmad"
              />
              {errors.name && (
                <Text testID="identity-name-error" className="text-danger-text mt-1 mb-2">
                  {errors.name.message}
                </Text>
              )}
            </View>
          )}
        />

        <Controller
          control={control}
          name="handle"
          rules={{ required: true }}
          render={({ field: { onChange, value } }) => (
            <View>
              <Input
                testID="identity-handle"
                label="Handle (lowercase, no spaces)"
                value={value}
                onChangeText={(t) => onChange(t.toLowerCase())}
                autoCapitalize="none"
                placeholder="ahmad"
              />
              {errors.handle && (
                <Text testID="identity-handle-error" className="text-danger-text mt-1 mb-2">
                  {errors.handle.message}
                </Text>
              )}
            </View>
          )}
        />

        <Text className="font-body text-[10px] text-muted leading-snug mt-1 mb-4">
          Changing your handle later creates a redirect for 90 days, then 410 Gone.
        </Text>

        <Button
          testID="identity-next"
          variant="primary"
          onPress={handleSubmit(onSubmit)}
          loading={submitting}
        >
          Next
        </Button>
      </View>
    </StepperLayout>
  );
}
