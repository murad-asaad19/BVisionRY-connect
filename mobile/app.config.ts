import { ExpoConfig } from 'expo/config';

const config: ExpoConfig = {
  name: 'BVisionRY Connect',
  slug: 'bvisionry-connect',
  version: '1.0.0',
  orientation: 'portrait',
  icon: './assets/images/icon.png',
  scheme: 'connect-mobile',
  userInterfaceStyle: 'dark',
  newArchEnabled: true,
  ios: {
    supportsTablet: false,
    bundleIdentifier: 'com.bvisionry.connect',
    googleServicesFile: './GoogleService-Info.plist',
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
    '@sentry/react-native',
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
};

export default config;
