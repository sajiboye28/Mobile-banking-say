/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        'surface': '#131313',
        'surface-container': '#201f1f',
        'surface-bright': '#3a3939',
        'primary': '#4f78ff',
        'primary-container': '#0052ff',
        'secondary': '#b7c4ff',
        'tertiary': '#ffb4a1',
        'error': '#ffb4ab',
        'outline': '#8d90a2',
        'on-surface': '#e5e2e1',
        'on-primary': '#ffffff',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
    },
  },
}
