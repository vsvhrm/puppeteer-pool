import { Cluster } from 'puppeteer-cluster';
import puppeteer from 'puppeteer-extra';
import { executablePath } from 'puppeteer';
import Stealth from 'puppeteer-extra-plugin-stealth';
import { cpus } from 'node:os';

puppeteer.use(Stealth());

export const cluster = await Cluster.launch({
  puppeteer,
  puppeteerOptions: {
    headless: false,
    executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || executablePath()
  },
  timeout: 60 * 10000, // Максимальное время выполнения одной задачи (1 минута)
  maxConcurrency: cpus().length,
  concurrency: Cluster.CONCURRENCY_CONTEXT,
  monitor: true
});

export async function generalTask({ page, data }) {
  const { url, timeout, selector } = data;
  page.setDefaultNavigationTimeout(timeout ?? 3 * 10000);
  const response = await page.goto(url);
  if (selector) await page.waitForSelector(selector);
  const status = response.status();
  const content = await page.content();
  const cookies = await page.cookies();
  return { status, content, cookies };
}

export async function htmlTask({ page, data }) {
  const { url, timeout, selector } = data;
  page.setDefaultNavigationTimeout(timeout ?? 3 * 10000);
  await page.goto(url);
  await page.waitForSelector(selector);
  return page.content();
}
