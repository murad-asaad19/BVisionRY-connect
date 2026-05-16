const { getDefaultConfig } = require('expo/metro-config');
const { withNativewind } = require('nativewind/metro');

const config = getDefaultConfig(__dirname);

// Prefer the `react-native` and `require` package.json export conditions over
// `import`. Zustand's ESM build uses `import.meta.env`, which fails to parse
// when Metro serves the bundle as a classic script on web; its CJS entry uses
// `process.env.NODE_ENV`, which works. Setting these conditions explicitly
// routes Zustand (and similar packages) to their CJS build while still
// allowing packages like `react-native-web` to keep using their own subpath
// exports map.
config.resolver.unstable_conditionNames = ['react-native', 'require'];

module.exports = withNativewind(config, { input: './global.css' });
