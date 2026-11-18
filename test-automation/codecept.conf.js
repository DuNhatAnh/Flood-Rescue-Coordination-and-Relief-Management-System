const http = require('http');

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:8080';

// Kiểm tra backend THẬT đang chạy trước khi test. Không dùng mock server: nếu backend chưa bật thì dừng ngay.
function checkBackendAlive() {
  return new Promise((resolve, reject) => {
    const req = http.request(`${API_BASE_URL}/api/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, timeout: 5000 }, res => {
      res.resume();
      resolve();
    });
    req.on('error', () => reject(new Error(`Không kết nối được backend tại ${API_BASE_URL}. Hãy chạy "docker compose up -d" trước khi test.`)));
    req.end('{}');
  });
}

exports.config = {
  tests: process.env.TEST_PATH || './epic-*/*_test.js',
  output: './output',
  helpers: {
    REST: {
      endpoint: API_BASE_URL,
      defaultHeaders: {
        'Content-Type': 'application/json'
      },
      timeout: 10000
    },
    JSONResponse: {}
  },
  bootstrap: async () => {
    await checkBackendAlive();
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
