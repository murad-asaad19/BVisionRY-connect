/** @type {import('tailwindcss').Config} */
// Color tokens and base font families (`--font-display`, `--font-body`) live in `global.css`
// under `@theme` (Tailwind v4 is CSS-first). This file only declares the named font-family
// utilities (e.g. `font-display-bold`, `font-body`) that NativeWind needs at config time;
// they are NOT duplicated in the CSS theme.
module.exports = {
  content: ['./app/**/*.{js,jsx,ts,tsx}', './src/**/*.{js,jsx,ts,tsx}'],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      fontFamily: {
        'display-regular': ['Dosis_400Regular'],
        'display-medium': ['Dosis_500Medium'],
        'display-semibold': ['Dosis_600SemiBold'],
        'display-bold': ['Dosis_700Bold'],
        'display-extrabold': ['Dosis_800ExtraBold'],
        body: ['Overlock_400Regular'],
        'body-bold': ['Overlock_700Bold'],
      },
    },
  },
  plugins: [],
};
