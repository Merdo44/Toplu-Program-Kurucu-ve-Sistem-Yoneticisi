import { chromium } from "playwright";

async function main() {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  await page.goto("https://google.com");
  console.log("Tarayici basariyla acildi!");
  await new Promise((r) => setTimeout(r, 3000));
  await browser.close();
}

main();