/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'voidfiles': {
          navy: '#00005B',
          blue: '#3B63FB',
          white: '#FFFFFF',
          red: '#EB1100',
          black: '#161616',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
} 