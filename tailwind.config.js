module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: '#0f5fd7',
          secondary: '#08776f',
          accent: '#0f5fd7',
          neutral: '#123d92',
          'base-100': '#fcfefd',
          'base-200': '#f7f9fb',
          'base-300': '#d8e1ea',
          'base-content': '#101820',
          '--rounded-btn': '0.75rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
