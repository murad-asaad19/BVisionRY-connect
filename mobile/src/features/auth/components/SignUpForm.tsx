import { useState } from 'react';
import { View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { z } from 'zod';
import { useTranslation } from 'react-i18next';
import {
  sendMagicLink,
  signUpWithPassword,
} from '~/features/auth/services/auth.service';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { SocialSignInButtons } from '~/features/auth/components/SocialSignInButtons';
import { AuthShell } from '~/features/auth/components/AuthShell';

const EmailSchema = z.string().email();
const PasswordSchema = z.string().min(8, 'Password must be at least 8 characters.');
type FormValues = { email: string; password: string };

/**
 * Create-account screen (mockup A2). Supports either email + password sign-up
 * or "send me a magic link" passwordless flow.
 */
export function SignUpForm() {
  const { t } = useTranslation();
  const [submitState, setSubmitState] = useState<
    'idle' | 'submitting' | 'sent' | 'signed-up' | 'error'
  >('idle');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const {
    control,
    handleSubmit,
    getValues,
    formState: { errors },
  } = useForm<FormValues>({ defaultValues: { email: '', password: '' } });

  const onCreateAccount = async ({ email, password }: FormValues) => {
    setSubmitState('submitting');
    setErrorMessage(null);
    const emailParsed = EmailSchema.safeParse(email);
    if (!emailParsed.success) {
      setErrorMessage('Enter a valid email address.');
      setSubmitState('error');
      return;
    }
    const pwParsed = PasswordSchema.safeParse(password);
    if (!pwParsed.success) {
      setErrorMessage(pwParsed.error.issues[0]?.message ?? 'Invalid password.');
      setSubmitState('error');
      return;
    }
    try {
      await signUpWithPassword(email, password);
      setSubmitState('signed-up');
      // Supabase auto-issues a session on signUp; the auth gate redirects
      // the user to /(onboarding)/goal because profile.onboarded = false.
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : 'Sign-up failed');
      setSubmitState('error');
    }
  };

  const onMagicLink = async () => {
    setSubmitState('submitting');
    setErrorMessage(null);
    const email = getValues('email');
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
      setErrorMessage(e instanceof Error ? e.message : 'Sign-up failed');
      setSubmitState('error');
    }
  };

  return (
    <AuthShell brandTestID="sign-up-brand">
      <Text testID="sign-up-title" className="font-display-bold text-[18px] text-navy mb-1">
        Create your account
      </Text>
      <Text className="font-body text-[12px] text-muted mb-3">
        Discovery for founders & builders.
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
            testID="sign-up-email"
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

      <Controller
        control={control}
        name="password"
        render={({ field: { onChange, value } }) => (
          <Input
            testID="sign-up-password"
            label="Password (min 8 characters)"
            value={value}
            onChangeText={onChange}
            placeholder="••••••••"
            secureTextEntry
            autoCapitalize="none"
            autoComplete="new-password"
          />
        )}
      />

      <Button
        testID="sign-up-submit"
        variant="primary"
        onPress={handleSubmit(onCreateAccount)}
        loading={submitState === 'submitting'}
      >
        Create account
      </Button>

      <View className="mt-2">
        <Button
          testID="sign-up-magic-link"
          variant="outline"
          onPress={onMagicLink}
          loading={submitState === 'submitting'}
        >
          Or send me a magic link
        </Button>
      </View>

      <View className="flex-row items-center justify-center mt-3 gap-1">
        <Text className="font-body text-[11px] text-muted">Have an account?</Text>
        <Pressable
          testID="sign-up-go-sign-in"
          onPress={() => router.replace('/(auth)/sign-in' as never)}
        >
          <Text className="font-display-bold text-[11px] text-navy">Sign in</Text>
        </Pressable>
      </View>

      {submitState === 'sent' && (
        <Text
          testID="sign-up-sent"
          className="text-success-text font-body text-[12px] mt-3 text-center"
        >
          {t('signIn.sent')}
        </Text>
      )}
      {submitState === 'error' && errorMessage && (
        <Text
          testID="sign-up-error"
          className="text-danger-text font-body text-[12px] mt-3 text-center"
        >
          {errorMessage}
        </Text>
      )}
    </AuthShell>
  );
}
