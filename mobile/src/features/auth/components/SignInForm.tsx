import { useCallback, useRef, useState } from 'react';
import { View, Text, Pressable, Alert, type TextInput } from 'react-native';
import { router } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { z } from 'zod';
import { useTranslation } from 'react-i18next';
import { signInWithIdentifier } from '~/features/auth/services/auth.service';
import { mapAuthError } from '~/features/auth/services/errorMap';
import { useMagicLinkSubmit } from '~/features/auth/hooks/useMagicLinkSubmit';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { SocialSignInButtons } from '~/features/auth/components/SocialSignInButtons';
import { AuthShell } from '~/features/auth/components/AuthShell';

const FormSchema = z.object({
  identifier: z.string().trim().min(1, 'auth.errors.identifierRequired'),
  password: z.string().min(1, 'auth.errors.passwordRequired'),
});
type FormValues = z.infer<typeof FormSchema>;

export function SignInForm() {
  const { t } = useTranslation();
  const passwordRef = useRef<TextInput>(null);

  const [passwordSubmitting, setPasswordSubmitting] = useState(false);
  const [passwordErrorKey, setPasswordErrorKey] = useState<string | null>(null);

  const {
    control,
    handleSubmit,
    getValues,
    formState: { errors },
  } = useForm<FormValues>({
    defaultValues: { identifier: '', password: '' },
    mode: 'onSubmit',
  });

  const magic = useMagicLinkSubmit({
    // Magic link works only for the email path — if the user typed a handle
    // we surface the same "needs a full email" validation error.
    getEmail: () => getValues('identifier'),
    mode: 'signIn',
  });

  const onPasswordSignIn = useCallback(
    async (values: FormValues) => {
      const parsed = FormSchema.safeParse(values);
      if (!parsed.success) {
        // rhf's Controller `required` rules already block this; defensive only.
        setPasswordErrorKey(parsed.error.issues[0]?.message ?? 'auth.errors.signInFailed');
        return;
      }
      setPasswordSubmitting(true);
      setPasswordErrorKey(null);
      try {
        await signInWithIdentifier(parsed.data.identifier, parsed.data.password);
        // Auth gate handles the redirect to /(app)/(tabs)/home or /(onboarding)/goal.
      } catch (e) {
        setPasswordErrorKey(mapAuthError(e, 'signIn'));
      } finally {
        setPasswordSubmitting(false);
      }
    },
    []
  );

  // Either path's spinner blocks the other to prevent double-submission.
  const anySubmitting = passwordSubmitting || magic.submitting;
  // Inline error band combines whichever surfaced last.
  const errorKey = passwordErrorKey ?? magic.errorKey;

  const onForgotPassword = useCallback(() => {
    Alert.alert(t('auth.forgotPassword'), t('auth.forgotPasswordBody'));
  }, [t]);

  return (
    <AuthShell brandTestID="sign-in-title">
      <Text testID="sign-in-welcome" className="font-display-bold text-[18px] text-navy mb-1">
        {t('auth.signInTitle')}
      </Text>
      <Text className="font-body text-[12px] text-muted mb-3">{t('auth.signInTagline')}</Text>

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
        render={({ field: { onChange, value, onBlur } }) => (
          <Input
            testID="sign-in-email"
            label={t('auth.emailOrUsername')}
            value={value}
            onChangeText={(s) => {
              onChange(s);
              // Reset any stale banner once the user starts editing again.
              if (passwordErrorKey) setPasswordErrorKey(null);
              magic.reset();
            }}
            onBlur={onBlur}
            placeholder={t('auth.identifierPlaceholder')}
            autoCapitalize="none"
            autoCorrect={false}
            keyboardType="email-address"
            textContentType="username"
            autoComplete="username"
            returnKeyType="next"
            onSubmitEditing={() => passwordRef.current?.focus()}
            errorText={
              errors.identifier ? t('auth.errors.identifierRequired') : undefined
            }
          />
        )}
      />

      <Controller
        control={control}
        name="password"
        rules={{ required: true }}
        render={({ field: { onChange, value, onBlur } }) => (
          <Input
            ref={passwordRef}
            testID="sign-in-password"
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
            textContentType="password"
            autoComplete="current-password"
            returnKeyType="done"
            onSubmitEditing={handleSubmit(onPasswordSignIn)}
            errorText={errors.password ? t('auth.errors.passwordRequired') : undefined}
          />
        )}
      />

      <Button
        testID="sign-in-submit"
        variant="primary"
        onPress={handleSubmit(onPasswordSignIn)}
        loading={passwordSubmitting}
        disabled={anySubmitting && !passwordSubmitting}
      >
        {t('auth.submitSignIn')}
      </Button>

      <View className="mt-2">
        <Button
          testID="sign-in-magic-link"
          variant="outline"
          onPress={magic.send}
          loading={magic.submitting}
          disabled={anySubmitting && !magic.submitting}
        >
          {t('auth.magicLinkSubmit')}
        </Button>
      </View>

      <Pressable testID="sign-in-forgot" className="mt-3 self-center" onPress={onForgotPassword}>
        <Text className="font-body text-[11px] text-muted underline">
          {t('auth.forgotPassword')}
        </Text>
      </Pressable>

      <View className="flex-row items-center justify-center mt-3 gap-1">
        <Text className="font-body text-[11px] text-muted">{t('auth.noAccount')}</Text>
        <Pressable
          testID="sign-in-go-sign-up"
          onPress={() => router.push('/(auth)/sign-up' as never)}
        >
          <Text className="font-display-bold text-[11px] text-navy">{t('auth.signUpCta')}</Text>
        </Pressable>
      </View>

      {magic.sentTo && (
        <Text
          testID="sign-in-sent"
          className="text-success-text font-body text-[12px] mt-3 text-center"
        >
          {t('auth.magicLinkSent')}
        </Text>
      )}
      {errorKey && (
        <Text
          testID="sign-in-error"
          accessibilityLiveRegion="polite"
          className="text-danger-text font-body text-[12px] mt-3 text-center"
        >
          {t(errorKey)}
        </Text>
      )}
    </AuthShell>
  );
}
