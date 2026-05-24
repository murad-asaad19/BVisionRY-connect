import { useEffect } from 'react';
import { View, Text, Pressable, Alert, I18nManager, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useTranslation } from 'react-i18next';
import { LANGUAGES, applyLayoutDirection, isRTLLocale } from '~/lib/i18n';

/**
 * Storage key for the user's explicit language choice.
 *
 * Note: `lib/i18n/index.ts` (owned by the lib agent) seeds i18next from the
 * device locale at cold-start; we can't change its init order from here. We
 * patch around that by re-applying the saved choice on first mount of any
 * settings screen — i18next is synchronous to switch, so the UI updates with
 * a single render hop. The proper fix is for `initI18n()` to read this key
 * before calling `i18n.init()`; leaving that to a future lib-agent pass.
 */
const LANG_STORAGE_KEY = 'app-language';

export function LanguageSection() {
  const { t, i18n: ctx } = useTranslation();

  // On mount, honour any previously-saved choice that differs from what
  // initI18n() seeded from the device locale.
  useEffect(() => {
    let cancelled = false;
    AsyncStorage.getItem(LANG_STORAGE_KEY)
      .then((saved) => {
        if (cancelled) return;
        if (!saved) return;
        if (saved === ctx.language) return;
        if (!LANGUAGES.some((l) => l.code === saved)) return;
        ctx.changeLanguage(saved);
        applyLayoutDirection(saved);
      })
      .catch((e) => console.warn('[settings] read saved language failed', e));
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const onSelect = (code: string) => {
    const shouldBeRTL = isRTLLocale(code);
    const directionChange = Platform.OS !== 'web' && I18nManager.isRTL !== shouldBeRTL;
    applyLayoutDirection(code);
    ctx.changeLanguage(code);
    AsyncStorage.setItem(LANG_STORAGE_KEY, code).catch((e) =>
      console.warn('[settings] persist language failed', e)
    );
    if (directionChange) {
      Alert.alert(t('settings.restartRequired.title'), t('settings.restartRequired.body'));
    }
  };

  return (
    <View className="mt-6">
      <Text className="text-muted text-xs uppercase tracking-wide mb-2">
        {t('settings.language')}
      </Text>
      <View className="flex-row gap-2">
        {LANGUAGES.map((l) => (
          <Pressable
            key={l.code}
            testID={`lang-${l.code}`}
            onPress={() => onSelect(l.code)}
            accessibilityRole="button"
            accessibilityLabel={l.label}
            className={`flex-1 px-3 py-2 rounded-xl border ${
              ctx.language === l.code ? 'bg-navy border-transparent' : 'bg-white border-border'
            }`}
          >
            <Text
              className={`text-center font-semibold ${
                ctx.language === l.code ? 'text-white' : 'text-body'
              }`}
            >
              {l.label}
            </Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}
