import { View, Text, Pressable, Alert, I18nManager, Platform } from 'react-native';
import { useTranslation } from 'react-i18next';
import { LANGUAGES, applyLayoutDirection, isRTLLocale } from '~/lib/i18n';

export function LanguageSection() {
  const { t, i18n: ctx } = useTranslation();
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
            onPress={() => {
              const shouldBeRTL = isRTLLocale(l.code);
              const directionChange = Platform.OS !== 'web' && I18nManager.isRTL !== shouldBeRTL;
              applyLayoutDirection(l.code);
              ctx.changeLanguage(l.code);
              if (directionChange) {
                Alert.alert(
                  'Restart required',
                  'Please reopen the app to apply the new layout direction.'
                );
              }
            }}
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
