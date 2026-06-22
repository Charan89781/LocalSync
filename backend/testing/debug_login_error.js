const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const { spawn, execSync } = require('child_process');
const path = require('path');

const BUILD_PATH = 'D:/AndroidFiles/Projects/LocalSync3/frontend/build/web';
const PORT = 8095;
const BASE_URL = `http://localhost:${PORT}`;

(async () => {
  let serverProcess = null;
  let driver = null;

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

    await driver.get(BASE_URL);
    await driver.wait(until.elementLocated(By.css('flt-glass-pane')), 25000);
    await driver.sleep(3000);

    // Helpers
    async function findEl(lbl) {
      return await driver.executeScript((l) => {
        const els = document.querySelectorAll('flt-semantics, span, input, button, [aria-label]');
        for (let i = els.length - 1; i >= 0; i--) {
          const e = els[i];
          const a = (e.getAttribute('aria-label') || '').toLowerCase();
          const p = (e.getAttribute('placeholder') || '').toLowerCase();
          const t = (e.innerText || e.textContent || '').trim().toLowerCase();
          if (a === l || p === l || t === l) return e;
        }
        for (let i = els.length - 1; i >= 0; i--) {
          const e = els[i];
          const a = (e.getAttribute('aria-label') || '').toLowerCase();
          const p = (e.getAttribute('placeholder') || '').toLowerCase();
          const t = (e.innerText || e.textContent || '').trim().toLowerCase();
          if (a.includes(l) || p.includes(l) || (t.includes(l) && e.tagName !== 'FLT-SEMANTICS-HOST')) return e;
        }
        return null;
      }, lbl.toLowerCase());
    }

    async function waitEl(lbl, ms = 10000) {
      const start = Date.now();
      while (Date.now() - start < ms) {
        const e = await findEl(lbl);
        if (e) return e;
        await driver.sleep(300);
      }
      return null;
    }

    async function clickEl(lbl) {
      const el = await waitEl(lbl, 8000);
      if (!el) throw new Error(`Cannot click: "${lbl}" - element not found`);
      await el.click();
    }

    async function typeEl(lbl, val) {
      await driver.executeScript((l, v) => {
        const els = document.querySelectorAll('input, [contenteditable], flt-semantics');
        for (let i = els.length - 1; i >= 0; i--) {
          const e = els[i];
          const a = (e.getAttribute('aria-label') || '').toLowerCase();
          const p = (e.getAttribute('placeholder') || '').toLowerCase();
          if (a.includes(l) || p.includes(l)) {
            if (e.tagName === 'INPUT') {
              e.value = v;
              e.dispatchEvent(new Event('input', { bubbles: true }));
              e.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            }
            e.innerText = v;
            e.dispatchEvent(new Event('input', { bubbles: true }));
            return true;
          }
        }
      }, lbl.toLowerCase(), val);
    }

    await clickEl('Skip');
    await driver.sleep(2000);

    // Enter Resident credentials
    await typeEl('email', 'test_resident@localsync.com');
    await typeEl('password', 'Resident123');
    await clickEl('Sign In');

    console.log("Submitted form. Sleeping 6 seconds...");
    await driver.sleep(6000);

    // Dump page content
    const text = await driver.executeScript(() => document.body.innerText);
    console.log("\n--- BODY TEXT CONTENT ---");
    console.log(text);
    console.log("-------------------------\n");

    // Print all logs in browser console
    const logs = await driver.manage().logs().get('browser');
    console.log("--- BROWSER CONSOLE LOGS ---");
    logs.forEach(l => console.log(`[${l.level.name}] ${l.message}`));
    console.log("----------------------------");

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
