import { useState } from 'react';
import { View, Text, Pressable, Alert } from 'react-native';
import { router } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { z } from 'zod';
import { useTranslation } from 'react-i18next';
import { sendMagicLink } from '~/features/auth/services/auth.service';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { SocialSignInButtons } from '~/features/auth/components/SocialSignInButtons';
import { AuthShell } from '~/features/auth/components/AuthShell';

const EmailSchema = z.string().email();
type FormValues = { email: string };

export function SignInForm() {
  const { t } = useTranslation();
  const [submitState, setSubmitState] = useState<'idle' | 'submitting' | 'sent' | 'error'>('idle');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({ defaultValues: { email: '' } });

  const onSubmit = async ({ email }: FormValues) => {
    setSubmitState('submitting');
    setErrorMessage(null);
    const parsed = EmailSchema.safeParse(email);
    if (!parsed.success) {
      setErrorMessage('Enter a valid email address.');
      setSubmitState('error');
      return;
    }
    try {
      await sendMagicLink(email);
      setSubmitState('sent');
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : 'Sign-in failed');
      setSubmitState('error');
    }
  };

  return (
    <AuthShell brandTestID="sign-in-title">
      <Text testID="sign-in-welcome" className="font-display-bold text-[18px] text-navy mb-3">
        {t('signIn.welcome')}
      </Text>

      <SocialSignInButtons />

      <View className="flex-row items-center my-3">
        <View className="flex-1 h-px bg-border" />
        <Text className="text-muted text-[11px] font-body mx-2.5 uppercase">{t('signIn.or')}</Text>
        <View className="flex-1 h-px bg-border" />
      </View>

      <Controller
        control={control}
        name="email"
        rules={{ required: true }}
        render={({ field: { onChange, value } }) => (
          <Input
            testID="sign-in-email"
            label="Email"
            value={value}
            onChangeText={onChange}
            placeholder={t('signIn.emailPlaceholder')}
            autoCapitalize="none"
            keyboardType="email-address"
            autoComplete="email"
          />
        )}
      />
      {errors.email && (
        <Text className="text-danger-text text-[11px] mb-2">Email is required.</Text>
      )}

      <Button
        testID="sign-in-submit"
        variant="primary"
        onPress={handleSubmit(onSubmit)}
        loading={submitState === 'submitting'}
      >
        {t('signIn.submit')}
      </Button>

      <Pressable
        testID="sign-in-forgot"
        className="mt-3 self-center"
        onPress={() =>
          Alert.alert(
            'Forgot password?',
            "We use magic links — just enter your email and we'll send you a one-tap sign-in."
          )
        }
      >
        <Text className="font-body text-[11px] text-muted underline">Forgot password?</Text>
      </Pressable>

      <View className="flex-row items-center justify-center mt-3 gap-1">
        <Text className="font-body text-[11px] text-muted">Don&apos;t have an account?</Text>
        <Pressable
          testID="sign-in-go-sign-up"
          onPress={() => router.push('/(auth)/sign-up' as never)}
        >
          <Text className="font-display-bold text-[11px] text-navy">Sign up</Text>
        </Pressable>
      </View>

      {submitState === 'sent' && (
        <Text
          testID="sign-in-sent"
          className="text-success-text font-body text-[12px] mt-3 text-center"
        >
          {t('signIn.sent')}
        </Text>
      )}
      {submitState === 'error' && errorMessage && (
        <Text
          testID="sign-in-error"
          className="text-danger-text font-body text-[12px] mt-3 text-center"
        >
          {errorMessage}
        </Text>
      )}
    </AuthShell>
  );
}
