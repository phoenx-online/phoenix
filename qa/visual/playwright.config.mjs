import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env.BASE_URL;
if (!baseURL) {
  throw new Error('BASE_URL is required');
}

export default defineConfig({
  testDir: './tests',
  outputDir: process.env.PW_OUTPUT_DIR || './test-results',
  fullyParallel: false,
  forbidOnly: true,
  retries: 0,
  workers: 1,
  timeout: 60_000,
  reporter: [
    ['list'],
    ['html', {
      outputFolder: process.env.PW_HTML_REPORT || './playwright-report',
      open: 'never'
    }]
  ],
  use: {
    baseURL,
    actionTimeout: 12_000,
    navigationTimeout: 35_000,
    screenshot: 'only-on-failure',
    video: 'on',
    trace: 'on',
    ignoreHTTPSErrors: false
  },
  projects: [
    {
      name: 'desktop-chromium',
      use: { ...devices['Desktop Chrome'] }
    },
    {
      name: 'android-chromium',
      use: { ...devices['Pixel 7'] }
    },
    {
      name: 'mobile-webview-emulation',
      use: {
        ...devices['Pixel 7'],
        userAgent:
          'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/153.0 Mobile Safari/537.36 FBAN/MessengerForAndroid'
      }
    }
  ]
});
