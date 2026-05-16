/** @type {import('tailwindcss').Config} */
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
