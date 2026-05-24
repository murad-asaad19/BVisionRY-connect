module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      [
        'module-resolver',
        {
          root: ['./'],
          alias: { '~': './src' },
        },
      ],
      // react-native-worklets/plugin replaces react-native-reanimated/plugin
      // in Reanimated v4. It MUST be the last plugin listed.
      'react-native-worklets/plugin',
    ],
  };
};
