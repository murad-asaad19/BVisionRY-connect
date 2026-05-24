import { useCallback, useMemo, useRef, useState } from 'react';
import { View, Text, Pressable, type TextInput } from 'react-native';
import { router } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { z } from 'zod';
import { useTranslation } from 'react-i18next';
import { signUpWithPassword } from '~/features/auth/services/auth.service';
import { mapAuthError } from '~/features/auth/services/errorMap';
import { useMagicLinkSubmit } from '~/features/auth/hooks/useMagicLinkSubmit';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { SocialSignInButtons } from '~/features/auth/components/SocialSignInButtons';
import { AuthShell } from '~/features/auth/components/AuthShell';

const MIN_PASSWORD = 8;

const FormSchema = z.object({
  email: z.string().trim().min(1, 'auth.errors.emailRequired').email('auth.errors.invalidEmail'),
  password: z.string().min(MIN_PASSWORD, 'auth.errors.passwordTooShort'),
});
type FormValues = z.infer<typeof FormSchema>;

/**
 * Create-account screen (mockup A2). Supports either email + password sign-up
 * or "send me a magic link" passwordless flow.
 */
export function SignUpForm() {
  const { t } = useTranslation();
  const passwordRef = useRef<TextInput>(null);

  const [passwordSubmitting, setPasswordSubmitting] = useState(false);
  const [passwordErrorKey, setPasswordErrorKey] = useState<string | null>(null);

  const {
    control,
    handleSubmit,
    getValues,
    watch,
    formState: { errors },
  } = useForm<FormValues>({
    defaultValues: { email: '', password: '' },
    mode: 'onSubmit',
  });

  const magic = useMagicLinkSubmit({
    getEmail: () => getValues('email'),
    mode: 'signUp',
  });

  const passwordValue = watch('password');
  const passwordMet = passwordValue.length >= MIN_PASSWORD;

  const onCreateAccount = useCallback(async (values: FormValues) => {
    // Run zod through safeParse to surface the i18n-key issues.
    const parsed = FormSchema.safeParse(values);
    if (!parsed.success) {
      setPasswordErrorKey(parsed.error.issues[0]?.message ?? 'auth.errors.signUpFailed');
      return;
    }
    setPasswordSubmitting(true);
    setPasswordErrorKey(null);
    try {
      await signUpWithPassword(parsed.data.email, parsed.data.password);
      // Supabase auto-issues a session on signUp; the auth gate redirects
      // the user to /(onboarding)/goal because profile.onboarded = false.
    } catch (e) {
      setPasswordErrorKey(mapAuthError(e, 'signUp'));
    } finally {
      setPasswordSubmitting(false);
    }
  }, []);

  const anySubmitting = passwordSubmitting || magic.submitting;
  const errorKey = passwordErrorKey ?? magic.errorKey;

  // Email-field error: prefer the typed zod message (key) over a generic one.
  const emailErrorKey = useMemo(() => {
    if (!errors.email) return undefined;
    const m = errors.email.message;
    return m ?? 'auth.errors.emailRequired';
  }, [errors.email]);

  const passwordFieldErrorKey = useMemo(() => {
    if (!errors.password) return undefined;
    const m = errors.password.message;
    return m ?? 'auth.errors.passwordRequired';
  }, [errors.password]);

  return (
    <AuthShell brandTestID="sign-up-brand">
      <Text testID="sign-up-title" className="font-display-bold text-display-lg text-navy mb-1">
        {t('auth.signUpTitle')}
      </Text>
      <Text className="font-body text-body-md text-muted mb-3">{t('auth.signUpTagline')}</Text>

      <SocialSignInButtons />

      <View className="flex-row items-center my-3">
        <View className="flex-1 h-px bg-border" />
        <Text className="text-muted text-display-xs font-body mx-2.5 uppercase">{t('signIn.or')}</Text>
        <View className="flex-1 h-px bg-border" />
      </View>

      <Controller
        control={control}
        name="email"
        rules={{
          required: 'auth.errors.emailRequired',
          // Zod runs at submit, but light pattern guard keeps the inline error
          // accurate when the user blurs from an obviously invalid value.
          validate: (v) =>
            z.string().email().safeParse(v.trim()).success || 'auth.errors.invalidEmail',
        }}
        render={({ field: { onChange, value, onBlur } }) => (
          <Input
            testID="sign-up-email"
            label={t('auth.email')}
            value={value}
            onChangeText={(s) => {
              onChange(s);
              if (passwordErrorKey) setPasswordErrorKey(null);
              magic.reset();
            }}
            onBlur={onBlur}
            placeholder={t('auth.emailPlaceholder')}
            autoCapitalize="none"
            autoCorrect={false}
            keyboardType="email-address"
            textContentType="emailAddress"
            autoComplete="email"
            returnKeyType="next"
            onSubmitEditing={() => passwordRef.current?.focus()}
            errorText={emailErrorKey ? t(emailErrorKey) : undefined}
          />
        )}
      />

      <Controller
        control={control}
        name="password"
        rules={{
          required: 'auth.errors.passwordRequired',
          minLength: { value: MIN_PASSWORD, message: 'auth.errors.passwordTooShort' },
        }}
        render={({ field: { onChange, value, onBlur } }) => (
          <Input
            ref={passwordRef}
            testID="sign-up-password"
            label={t('auth.password')}
            value={value}
            onChangeText={(s) => {
              onChange(s);
              if (passwordErrorKey) setPasswordErrorKey(null);
            }}
            onBlur={onBlur}
            placeholder={t('auth.passwordPlaceholder')}
            secureTextEntry
            autoCapitalize="none"
            autoCorrect={false}
            textContentType="newPassword"
            autoComplete="new-password"
            returnKeyType="done"
            onSubmitEditing={handleSubmit(onCreateAccount)}
            errorText={passwordFieldErrorKey ? t(passwordFieldErrorKey) : undefined}
          />
        )}
      />

      {/* Inline length hint — flips to success tone once the rule is met. */}
      <Text
        testID="sign-up-password-hint"
        className={`font-body text-body-xs -mt-1 mb-2 ${
          passwordMet ? 'text-success-text' : 'text-muted'
        }`}
      >
        {passwordMet ? t('auth.passwordHint8Met') : t('auth.passwordHint8')}
      </Text>

      <Button
        testID="sign-up-submit"
        variant="primary"
        onPress={handleSubmit(onCreateAccount)}
        loading={passwordSubmitting}
        disabled={anySubmitting && !passwordSubmitting}
      >
        {t('auth.submitSignUp')}
      </Button>

      <View className="mt-2">
        <Button
          testID="sign-up-magic-link"
          variant="outline"
          onPress={magic.send}
          loading={magic.submitting}
          disabled={anySubmitting && !magic.submitting}
        >
          {t('auth.magicLinkSubmitAlt')}
        </Button>
      </View>

      <View className="flex-row items-center justify-center mt-3 gap-1">
        <Text className="font-body text-display-xs text-muted">{t('auth.haveAccount')}</Text>
        <Pressable
          testID="sign-up-go-sign-in"
          onPress={() => router.replace('/(auth)/sign-in' as never)}
        >
          <Text className="font-display-bold text-display-xs text-navy">{t('auth.signInCta')}</Text>
        </Pressable>
      </View>

      {magic.sentTo && (
        <Text
          testID="sign-up-sent"
          className="text-success-text font-body text-body-md mt-3 text-center"
        >
          {t('auth.magicLinkSent')}
        </Text>
      )}
      {errorKey && (
        <Text
          testID="sign-up-error"
          accessibilityLiveRegion="polite"
          className="text-danger-text font-body text-body-md mt-3 text-center"
        >
          {t(errorKey)}
        </Text>
      )}
    </AuthShell>
  );
}
