/** @type {import('tailwindcss').Config} */
// Color tokens, typography scale, and spacing scale live in `global.css` under `@theme`
// (Tailwind v4 is CSS-first). This file declares the named font-family utilities that
// NativeWind needs at config time so classes like `font-body` / `font-display-bold`
// resolve to the right family name; weights/sizes/spacings come from CSS.
module.exports = {
  content: ['./app/**/*.{js,jsx,ts,tsx}', './src/**/*.{js,jsx,ts,tsx}'],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      fontFamily: {
        // Display (Dosis) — kept for screen titles, eyebrows, brand wordmarks.
        'display-regular': ['Dosis_400Regular'],
        'display-medium': ['Dosis_500Medium'],
        'display-semibold': ['Dosis_600SemiBold'],
        'display-bold': ['Dosis_700Bold'],
        'display-extrabold': ['Dosis_800ExtraBold'],
        // Body (Inter) — replaces Overlock. Used for paragraphs + UI text.
        body: ['Inter_400Regular'],
        'body-medium': ['Inter_500Medium'],
        'body-semibold': ['Inter_600SemiBold'],
        'body-bold': ['Inter_700Bold'],
      },
    },
  },
  plugins: [],
};
