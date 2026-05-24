import { ExpoConfig } from 'expo/config';

// Treat the build as production when Node is in prod mode OR when our Sentry
// env tag is set to `prod` (set by the prod EAS profile). Either condition
// gates the placeholder hard-fail below so dev shells don't trip the throw.
const isProd =
  process.env.NODE_ENV === 'production' || process.env.EXPO_PUBLIC_SENTRY_ENV === 'prod';

// The EAS project id must be set after running `eas init`. Override via the
// EXPO_PUBLIC_EAS_PROJECT_ID environment variable. Required in production —
// shipping `PROJECT_ID_PLACEHOLDER` would point EAS Update at a bogus URL.
const rawEasProjectId = process.env.EXPO_PUBLIC_EAS_PROJECT_ID;
if (isProd && !rawEasProjectId) {
  throw new Error(
    '[app.config] EXPO_PUBLIC_EAS_PROJECT_ID is required for production builds.'
  );
}
if (!rawEasProjectId) {
  console.warn(
    '[app.config] EXPO_PUBLIC_EAS_PROJECT_ID unset — falling back to placeholder for dev only.'
  );
}
const easProjectId = rawEasProjectId ?? 'PROJECT_ID_PLACEHOLDER';

// Universal/App Links host. Set via EXPO_PUBLIC_APP_LINKS_HOST. Required in
// production — shipping `DOMAIN_PLACEHOLDER` would register broken iOS
// associated domains and Android intent filters.
const rawAppLinksHost = process.env.EXPO_PUBLIC_APP_LINKS_HOST;
if (isProd && !rawAppLinksHost) {
  throw new Error(
    '[app.config] EXPO_PUBLIC_APP_LINKS_HOST is required for production builds.'
  );
}
if (!rawAppLinksHost) {
  console.warn(
    '[app.config] EXPO_PUBLIC_APP_LINKS_HOST unset — falling back to placeholder for dev only.'
  );
}
const appLinksHost = rawAppLinksHost ?? 'DOMAIN_PLACEHOLDER';

const config: ExpoConfig = {
  name: 'BVisionRY Connect',
  slug: 'bvisionry-connect',
  version: '1.0.0',
  orientation: 'portrait',
  icon: './assets/images/icon.png',
  scheme: 'connect-mobile',
  userInterfaceStyle: 'dark',
  newArchEnabled: true,
  // EAS Update — runtimeVersion uses appVersion policy so OTA updates are
  // pinned to the native binary's `version` above. Bump `version` to ship
  // a new native build; otherwise OTA can target the current runtime.
  runtimeVersion: { policy: 'appVersion' },
  updates: {
    url: `https://u.expo.dev/${easProjectId}`,
  },
  ios: {
    supportsTablet: false,
    bundleIdentifier: 'com.bvisionry.connect',
    googleServicesFile: './GoogleService-Info.plist',
    associatedDomains: [`applinks:${appLinksHost}`, `applinks:www.${appLinksHost}`],
  },
  android: {
    package: 'com.bvisionry.connect',
    adaptiveIcon: {
      backgroundColor: '#0B1220',
      foregroundImage: './assets/images/android-icon-foreground.png',
      backgroundImage: './assets/images/android-icon-background.png',
      monochromeImage: './assets/images/android-icon-monochrome.png',
    },
    edgeToEdgeEnabled: true,
    predictiveBackGestureEnabled: false,
    googleServicesFile: './google-services.json',
    intentFilters: [
      {
        action: 'VIEW',
        autoVerify: true,
        data: [{ scheme: 'https', host: appLinksHost, pathPattern: '/p/.*' }],
        category: ['BROWSABLE', 'DEFAULT'],
      },
    ],
  },
  web: {
    bundler: 'metro',
    output: 'single',
    favicon: './assets/images/favicon.png',
  },
  plugins: [
    'expo-router',
    [
      'expo-splash-screen',
      {
        image: './assets/images/splash-icon.png',
        imageWidth: 200,
        resizeMode: 'contain',
        backgroundColor: '#ffffff',
        dark: {
          backgroundColor: '#000000',
        },
      },
    ],
    // Sentry plugin tuple form. SENTRY_AUTH_TOKEN must be set in the build
    // environment (EAS secret) for source map upload to succeed.
    [
      '@sentry/react-native/expo',
      {
        organization: process.env.SENTRY_ORG,
        project: process.env.SENTRY_PROJECT,
        url: 'https://sentry.io/',
      },
    ],
    [
      'expo-build-properties',
      {
        ios: { useFrameworks: 'static' },
      },
    ],
    '@react-native-firebase/app',
    '@react-native-firebase/crashlytics',
    'expo-font',
    'expo-secure-store',
    'expo-audio',
    '@react-native-community/datetimepicker',
    'expo-localization',
  ],
  experiments: {
    typedRoutes: true,
  },
  extra: {
    eas: {
      projectId: easProjectId,
    },
  },
};

export default config;
