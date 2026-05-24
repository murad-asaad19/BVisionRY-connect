import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import * as Localization from 'expo-localization';
import { I18nManager, Platform } from 'react-native';
import en from '~/lib/i18n/locales/en.json';
import es from '~/lib/i18n/locales/es.json';

const RESOURCES = { en: { translation: en }, es: { translation: es } } as const;

export const LANGUAGES = [
  { code: 'en', label: 'English' },
  { code: 'es', label: 'Español' },
] as const;

const RTL_LANGUAGES = new Set(['ar', 'he', 'fa', 'ur']);

export function isRTLLocale(code: string): boolean {
  return RTL_LANGUAGES.has(code);
}

export function applyLayoutDirection(code: string): void {
  const shouldBeRTL = isRTLLocale(code);
  if (Platform.OS === 'web') {
    if (typeof document !== 'undefined') {
      document.documentElement.dir = shouldBeRTL ? 'rtl' : 'ltr';
    }
    return;
  }
  I18nManager.allowRTL(true);
  if (I18nManager.isRTL !== shouldBeRTL) {
    // Takes effect on next launch on native; no-op if already correct.
    I18nManager.forceRTL(shouldBeRTL);
  }
}

let initialized = false;
export function initI18n(): void {
  if (initialized) return;
  const deviceLocale = Localization.getLocales()[0]?.languageCode ?? 'en';
  const lng = deviceLocale && deviceLocale in RESOURCES ? deviceLocale : 'en';
  // eslint-disable-next-line import/no-named-as-default-member
  i18n.use(initReactI18next).init({
    resources: RESOURCES,
    lng,
    fallbackLng: 'en',
    interpolation: { escapeValue: false },
    compatibilityJSON: 'v4',
    debug: __DEV__,
    // Always render a string. The TS contract on `t()` is `string`, and
    // i18next's default `returnNull: true` violates that — a missing key
    // would yield `null` and propagate through to UI text props that don't
    // accept null, surfacing as crashes ("RawText 'null'") or invisible
    // labels. With `returnNull: false`, missing keys render the key path
    // string itself — visible in QA, never crashes, never a silent gap.
    returnNull: false,
    saveMissing: __DEV__,
    missingKeyHandler: (lngs, ns, key) => {
      if (__DEV__) {
        // eslint-disable-next-line no-console
        console.warn('[i18n] missing key', { lngs, ns, key });
      }
    },
  });
  applyLayoutDirection(lng);
  initialized = true;
}

export { i18n };
