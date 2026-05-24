module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
  testPathIgnorePatterns: [
    '/node_modules/',
    '/playwright/',
    '/playwright-report/',
    '/test-results/',
  ],
  // pnpm stores packages under node_modules/.pnpm/<name>@<ver>/node_modules/<name>,
  // so the legacy `node_modules/(?!pkg)` pattern misses them. The leading
  // `(.*?/)?` makes the allowlist match at any depth.
  transformIgnorePatterns: [
    'node_modules/(?!(.*?/)?((jest-)?react-native|@react-native(-community)?|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@unimodules/.*|unimodules|sentry-expo|native-base|react-native-svg|nativewind))',
  ],
  moduleNameMapper: {
    '^~/(.*)$': '<rootDir>/src/$1',
  },
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts'],
};
