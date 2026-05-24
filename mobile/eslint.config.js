// https://docs.expo.dev/guides/using-eslint/
const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');
const prettierRecommended = require('eslint-plugin-prettier/recommended');
const tsParser = require('@typescript-eslint/parser');

module.exports = defineConfig([
  expoConfig,
  prettierRecommended,
  {
    // Project-wide rules. `expoConfig` already registers
    // `@typescript-eslint`, `import`, and `react-hooks` plugins; do not
    // re-declare them here (flat-config re-registration is an error in
    // ESLint >= 9).
    rules: {
      'prettier/prettier': 'warn',
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      'react-hooks/exhaustive-deps': 'warn',
      'import/order': [
        'warn',
        {
          groups: ['builtin', 'external', 'internal', 'parent', 'sibling'],
          'newlines-between': 'always',
          alphabetize: { order: 'asc', caseInsensitive: true },
        },
      ],
    },
  },
  {
    // Type-aware rules: only apply to TS source under src/ and app/ (Expo
    // Router routes). Enabling type-checked rules requires
    // `parserOptions.project`, which is expensive — scope it tightly so
    // config/test files are unaffected.
    files: ['src/**/*.ts', 'src/**/*.tsx', 'app/**/*.ts', 'app/**/*.tsx'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        project: ['./tsconfig.json'],
        tsconfigRootDir: __dirname,
      },
    },
    rules: {
      // Subset of typescript-eslint's recommended-type-checked that pays
      // off without flooding existing code with errors.
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',
      '@typescript-eslint/no-misused-promises': 'error',
      '@typescript-eslint/no-unnecessary-type-assertion': 'warn',
    },
  },
  {
    ignores: [
      'dist/*',
      '.expo/*',
      'playwright-report/*',
      'test-results/*',
      '**/*.gen.ts',
      'ios/*',
      'android/*',
    ],
  },
]);
