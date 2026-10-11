const { setHeadlessWhen, setCommonPlugins } = require('@codeceptjs/configure');

exports.config = {
  tests: './*_test.js',
  output: './output',
  helpers: {
    REST: {
      endpoint: process.env.API_BASE_URL || 'http://localhost:8080',
      defaultHeaders: {
        'Content-Type': 'application/json'
      },
      timeout: 10000
    },
    JSONResponse: {}
  },
  include: {},
  bootstrap: null,
  mocha: {},
  name: 'flood-rescue-api-tests',
  plugins: {
    retryFailedStep: {
      enabled: true
    },
    screenshotOnFail: {
      enabled: false
    }
  }
};
