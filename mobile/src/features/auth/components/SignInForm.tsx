import { useState } from 'react';
import { View, Text, Pressable, Alert } from 'react-native';
import { router } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { z } from 'zod';
import { useTranslation } from 'react-i18next';
import {
  sendMagicLink,
  signInWithIdentifier,
} from '~/features/auth/services/auth.service';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { SocialSignInButtons } from '~/features/auth/components/SocialSignInButtons';
import { AuthShell } from '~/features/auth/components/AuthShell';

const EmailSchema = z.string().email();
type FormValues = { identifier: string; password: string };

export function SignInForm() {
  const { t } = useTranslation();
  const [submitState, setSubmitState] = useState<
    'idle' | 'submitting' | 'sent' | 'signed-in' | 'error'
  >('idle');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const {
    control,
    handleSubmit,
    getValues,
    formState: { errors },
  } = useForm<FormValues>({ defaultValues: { identifier: '', password: '' } });

  const onPasswordSignIn = async ({ identifier, password }: FormValues) => {
    setSubmitState('submitting');
    setErrorMessage(null);
    if (!identifier.trim()) {
      setErrorMessage('Enter your email or username.');
      setSubmitState('error');
      return;
    }
    if (!password) {
      setErrorMessage('Enter your password.');
      setSubmitState('error');
      return;
    }
    try {
      await signInWithIdentifier(identifier, password);
      setSubmitState('signed-in');
      // Auth gate handles the redirect to /(app)/(tabs)/home or /(onboarding)/goal.
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : 'Sign-in failed');
      setSubmitState('error');
    }
  };

  const onMagicLink = async () => {
    setSubmitState('submitting');
    setErrorMessage(null);
    const identifier = getValues('identifier').trim();
    const parsed = EmailSchema.safeParse(identifier);
    if (!parsed.success) {
      setErrorMessage('Magic link needs a full email address.');
      setSubmitState('error');
      return;
    }
    try {
      await sendMagicLink(identifier);
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
        name="identifier"
        rules={{ required: true }}
        render={({ field: { onChange, value } }) => (
          <Input
            testID="sign-in-email"
            label="Email or username"
            value={value}
            onChangeText={onChange}
            placeholder="you@example.com or @handle"
            autoCapitalize="none"
            keyboardType="email-address"
            autoComplete="username"
          />
        )}
      />
      {errors.identifier && (
        <Text className="text-danger-text text-[11px] mb-2">Email or username is required.</Text>
      )}

      <Controller
        control={control}
        name="password"
        render={({ field: { onChange, value } }) => (
          <Input
            testID="sign-in-password"
            label="Password"
            value={value}
            onChangeText={onChange}
            placeholder="••••••••"
            secureTextEntry
            autoCapitalize="none"
            autoComplete="current-password"
          />
        )}
      />

      <Button
        testID="sign-in-submit"
        variant="primary"
        onPress={handleSubmit(onPasswordSignIn)}
        loading={submitState === 'submitting'}
      >
        {t('signIn.submit')}
      </Button>

      <View className="mt-2">
        <Button
          testID="sign-in-magic-link"
          variant="outline"
          onPress={onMagicLink}
          loading={submitState === 'submitting'}
        >
          Send magic link instead
        </Button>
      </View>

      <Pressable
        testID="sign-in-forgot"
        className="mt-3 self-center"
        onPress={() =>
          Alert.alert(
            'Forgot password?',
            'Use "Send magic link" — enter your email and tap the one-time link we send.'
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
