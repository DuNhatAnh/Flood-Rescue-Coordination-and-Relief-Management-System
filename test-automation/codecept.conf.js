const { setHeadlessWhen, setCommonPlugins } = require('@codeceptjs/configure');

exports.config = {
  tests: './epic-*/*_test.js',
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
  mocha: {
    reporterOptions: {
      reportDir: './output',
      reportFilename: 'codeceptjs-report',
      reportTitle: '[KCPM] BÁO CÁO KIỂM THỬ TỰ ĐỘNG HÓA E2E API - HỆ THỐNG CỨU HỘ LŨ LỤT',
      reportPageTitle: 'KCPM - Báo Cáo Kiểm Thử Tự Động Hóa E2E API',
      charts: true,
      enableCharts: true,
      code: true,
      enableCode: true,
      overwrite: true,
      html: true,
      json: true,
      showPassed: true,
      showFailed: true,
      showPending: true,
      showSkipped: false
    }
  },
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
