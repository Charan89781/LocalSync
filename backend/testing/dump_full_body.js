const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const { spawn, execSync } = require('child_process');
const path = require('path');

const BUILD_PATH = 'D:\\AndroidFiles\\Projects\\LocalSync3\\frontend\\build\\web';
const PORT = 8095;
const BASE_URL = `http://localhost:${PORT}`;

(async () => {
  let serverProcess = null;
  let driver = null;

  // Start server
  await new Promise((resolve) => {
    const cmd = process.platform === 'win32' ? 'npx.cmd' : 'npx';
    serverProcess = spawn(cmd, ['http-server', BUILD_PATH, '-p', PORT.toString(), '-c-1'], { shell: true });
    serverProcess.stdout.on('data', d => { if (d.toString().includes('Available on:') || d.toString().includes('Hit CTRL-C')) resolve(); });
    setTimeout(resolve, 4000);
  });

  try {
    const opts = new chrome.Options();
    opts.addArguments('--headless','--no-sandbox','--disable-dev-shm-usage','--window-size=1280,800','--force-renderer-accessibility');
    driver = await new Builder().forBrowser('chrome').setChromeOptions(opts).build();

    console.log("Loading app...");
    await driver.get(BASE_URL);
    await driver.wait(until.elementLocated(By.css('flt-glass-pane')), 25000);
    await driver.sleep(3000); // Wait on onboarding screen

    console.log("Clicking Skip...");
    await driver.executeScript(() => {
      const els = Array.from(document.querySelectorAll('flt-semantics, span, input, button, [aria-label]'));
      const skip = els.find(e => (e.getAttribute('aria-label') || '').toLowerCase().includes('skip') || (e.innerText || '').toLowerCase().includes('skip'));
      if (skip) {
        skip.click();
      }
    });

    console.log("Sleeping 4 seconds...");
    await driver.sleep(4000);

    // Dump full HTML
    const html = await driver.executeScript(() => document.body.innerHTML);
    console.log("\n--- FULL BODY INNER HTML ---");
    console.log(html);
    console.log("----------------------------\n");

  } catch (e) {
    console.error("Error:", e);
  } finally {
    if (driver) await driver.quit();
    if (serverProcess) {
      if (process.platform === 'win32') {
        try { execSync(`taskkill /pid ${serverProcess.pid} /f /t`, { stdio: 'ignore' }); } catch(e) {}
      } else {
        try { serverProcess.kill('SIGKILL'); } catch(e) {}
      }
    }
    process.exit(0);
  }
})();
