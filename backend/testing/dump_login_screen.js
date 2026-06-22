const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const BUILD_PATH = 'D:/AndroidFiles/Projects/LocalSync3/frontend/build/web';
const PORT = 8095;
const BASE_URL = `http://localhost:${PORT}`;

(async () => {
  let serverProcess = null;
  let driver = null;

  console.log("Starting server...");
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
      console.log(`Clicking element with label: "${lbl}"...`);
      await el.click();
      await driver.sleep(1000);
    }

    async function typeEl(lbl, val) {
      const el = await waitEl(lbl, 8000);
      if (!el) throw new Error(`TextField with label "${lbl}" not found`);
      console.log(`Focusing TextField "${lbl}"...`);
      await el.click();
      await driver.sleep(500);

      const activeEl = await driver.switchTo().activeElement();
      console.log(`Typing into active element [tag: ${await activeEl.getTagName()}]: "${val}"...`);
      await activeEl.sendKeys(val);
      await driver.sleep(500);
    }

    console.log("Onboarding screen load check...");
    const welcomePng = await driver.takeScreenshot();
    fs.writeFileSync('C:/Users/PAVAN/.gemini/antigravity/brain/841462a3-eaa5-4406-b46c-58cc174581d7/welcome_screen.png', welcomePng, 'base64');
    console.log("Welcome screen screenshot saved.");

    await clickEl('Skip');
    await driver.sleep(2000);

    console.log("Login screen load check...");
    const loginPng = await driver.takeScreenshot();
    fs.writeFileSync('C:/Users/PAVAN/.gemini/antigravity/brain/841462a3-eaa5-4406-b46c-58cc174581d7/login_screen.png', loginPng, 'base64');
    console.log("Login screen screenshot saved.");

    // Let's print the visible text at this point
    let text = await driver.executeScript(() => document.body.innerText);
    console.log("Login screen text content:\n", text);

    await typeEl('email', 'test_resident@localsync.com');
    await typeEl('password', 'Resident123');

    // Take screenshot after typing to see if inputs have text
    const typedPng = await driver.takeScreenshot();
    fs.writeFileSync('C:/Users/PAVAN/.gemini/antigravity/brain/841462a3-eaa5-4406-b46c-58cc174581d7/typed_screen.png', typedPng, 'base64');
    console.log("Typed screen screenshot saved.");

    // Dump DOM at this stage to inspect elements
    const bodyHtml = await driver.executeScript(() => document.body.innerHTML);
    fs.writeFileSync('C:/Users/PAVAN/.gemini/antigravity/brain/841462a3-eaa5-4406-b46c-58cc174581d7/typed_body_dump.html', bodyHtml);
    console.log("Typed body HTML dumped.");

    // Now try to click "Sign In"
    try {
      await clickEl('Sign In');
      console.log("Sign In clicked.");
    } catch (err) {
      console.error("Sign In click failed:", err.message);
    }

    await driver.sleep(6000);

    const dashboardPng = await driver.takeScreenshot();
    fs.writeFileSync('C:/Users/PAVAN/.gemini/antigravity/brain/841462a3-eaa5-4406-b46c-58cc174581d7/dashboard_screen.png', dashboardPng, 'base64');
    console.log("Dashboard screen screenshot saved.");

    const finalUrl = await driver.getCurrentUrl();
    console.log("Final URL:", finalUrl);

  } catch (e) {
    console.error("Error occurred:", e);
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
