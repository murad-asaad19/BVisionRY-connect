import { useState } from 'react';
import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import { StepperLayout } from './StepperLayout';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { HandleSchema, NameSchema } from '~/features/profile/schemas';
import { checkHandleAvailable } from '~/features/profile/services/profile.service';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';

type FormValues = { name: string; handle: string };

export function IdentityStep() {
  const { t } = useTranslation();
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
      setError('name', { message: t('onboarding.identity.errorNameRequired') });
      return;
    }
    const handleParsed = HandleSchema.safeParse(values.handle);
    if (!handleParsed.success) {
      setError('handle', {
        message:
          handleParsed.error.issues[0]?.message ?? t('onboarding.identity.errorHandleInvalid'),
      });
      return;
    }
    setSubmitting(true);
    try {
      const available = await checkHandleAvailable(handleParsed.data);
      if (!available) {
        setError('handle', { message: t('onboarding.identity.errorHandleTaken') });
        return;
      }
      setField('name', nameParsed.data);
      setField('handle', handleParsed.data);
      router.push('/(onboarding)/roles');
    } catch (e) {
      setError('handle', {
        message: e instanceof Error ? e.message : t('onboarding.identity.errorHandleCheck'),
      });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <StepperLayout currentIndex={1} title={t('onboarding.identity.title')}>
      <View>
        <Controller
          control={control}
          name="name"
          rules={{ required: true }}
          render={({ field: { onChange, value } }) => (
            <Input
              testID="identity-name"
              label={t('onboarding.identity.name')}
              value={value}
              onChangeText={onChange}
              placeholder={t('onboarding.identity.namePlaceholder')}
              errorText={errors.name?.message}
            />
          )}
        />

        <Controller
          control={control}
          name="handle"
          rules={{ required: true }}
          render={({ field: { onChange, value } }) => (
            <Input
              testID="identity-handle"
              label={t('onboarding.identity.handle')}
              value={value}
              onChangeText={(text) => onChange(text.toLowerCase())}
              autoCapitalize="none"
              placeholder={t('onboarding.identity.handlePlaceholder')}
              errorText={errors.handle?.message}
            />
          )}
        />

        <Text className="font-body text-[10px] text-muted leading-snug mt-1 mb-4">
          {t('onboarding.identity.handleHint')}
        </Text>

        <Button
          testID="identity-next"
          variant="primary"
          onPress={handleSubmit(onSubmit)}
          loading={submitting}
        >
          {t('onboarding.identity.next')}
        </Button>
      </View>
    </StepperLayout>
  );
}
