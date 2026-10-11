/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx,html}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        ground: 'var(--ground)',
        surface: 'var(--surface)',
        ink: 'var(--ink)',
        muted: 'var(--muted)',
        signal: 'var(--signal)',
        selected: 'var(--selected)',
        error: 'var(--error)',
      },
      fontFamily: {
        sans: ['Manrope', 'ui-sans-serif', 'sans-serif'],
        mono: ['Cascadia Code', 'SFMono-Regular', 'Consolas', 'monospace'],
      }
    },
  },
  plugins: [],
}
