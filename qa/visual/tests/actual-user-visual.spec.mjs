import fs from 'node:fs';
import path from 'node:path';
import { test, expect } from '@playwright/test';

const manifest = JSON.parse(
  fs.readFileSync(new URL('../journeys.json', import.meta.url), 'utf8')
);

function selectedJourneys() {
  const override = (process.env.VISUAL_PATHS || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);

  if (override.length > 0) {
    return override.map((route, index) => ({
      name: `override-${String(index + 1).padStart(2, '0')}`,
      path: route,
      mode: 'read-only'
    }));
  }

  return manifest.journeys.filter((journey) => journey.enabled !== false);
}

function slug(value) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 80) || 'page';
}

test('actual-user read-only visual evidence', async ({ page }, testInfo) => {
  const diagnostics = {
    project: manifest.project,
    targetEnvironment: process.env.TARGET_ENVIRONMENT || 'unspecified',
    commitSha: process.env.GITHUB_SHA || 'local',
    baseUrl: process.env.BASE_URL,
    startedAt: new Date().toISOString(),
    journeys: [],
    consoleErrors: [],
    pageErrors: [],
    failedRequests: []
  };

  page.on('console', (message) => {
    if (message.type() === 'error') {
      diagnostics.consoleErrors.push({
        url: page.url(),
        text: message.text()
      });
    }
  });

  page.on('pageerror', (error) => {
    diagnostics.pageErrors.push({
      url: page.url(),
      message: error.message
    });
  });

  page.on('requestfailed', (request) => {
    diagnostics.failedRequests.push({
      url: request.url(),
      method: request.method(),
      failure: request.failure()?.errorText || 'unknown'
    });
  });

  const journeys = selectedJourneys();
  expect(journeys.length, 'At least one journey must be configured').toBeGreaterThan(0);

  for (const [index, journey] of journeys.entries()) {
    expect(journey.mode || 'read-only').toBe('read-only');

    const response = await page.goto(journey.path, { waitUntil: 'domcontentloaded' });
    const status = response?.status() ?? 0;

    expect(status, `${journey.name} returned no HTTP response`).toBeGreaterThan(0);
    expect(status, `${journey.name} returned server error ${status}`).toBeLessThan(500);
    await expect(page.locator('body')).toBeVisible();

    const screenshotName =
      `${String(index + 1).padStart(2, '0')}-${slug(journey.name)}-${slug(testInfo.project.name)}.png`;

    await page.screenshot({
      path: testInfo.outputPath(screenshotName),
      fullPage: true
    });

    diagnostics.journeys.push({
      name: journey.name,
      requestedPath: journey.path,
      finalUrl: page.url(),
      status,
      title: await page.title(),
      screenshot: screenshotName
    });
  }

  diagnostics.finishedAt = new Date().toISOString();

  await testInfo.attach('diagnostics.json', {
    body: Buffer.from(JSON.stringify(diagnostics, null, 2)),
    contentType: 'application/json'
  });

  expect(
    diagnostics.pageErrors,
    `Uncaught page errors: ${JSON.stringify(diagnostics.pageErrors, null, 2)}`
  ).toEqual([]);
});
