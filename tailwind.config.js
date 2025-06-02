// tailwind.config.js
module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js"
  ],
  theme: {
    extend: {
      spacing: {
        '1x': '8px',
        '2x': '16px',
        '3x': '24px',
        '4x': '32px',
        '5x': '40px',
        '6x': '48px',
        '8x': '64px',
        '10x': '80px',
        '12x': '96px',
        '20x': '160px',
        '22x': '176px',
      },
      borderRadius: {
        md: '12px',
      },
      gridTemplateColumns: {
        'desktop': 'repeat(12, minmax(0, 1fr))',
        'mobile': 'repeat(4, minmax(0, 1fr))',
      },
    },
  },
  plugins: [],
}
