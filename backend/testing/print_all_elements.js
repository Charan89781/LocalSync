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
    async function clickEl(lbl) {
      const success = await driver.executeScript((l) => {
        const els = Array.from(document.querySelectorAll('flt-semantics, span, input, button, [aria-label]'));
        const e = els.find(el => (el.getAttribute('aria-label') || '').toLowerCase().includes(l) || (el.innerText || '').toLowerCase().includes(l));
        if (e) {
          e.click();
          return true;
        }
        return false;
      }, lbl.toLowerCase());
      if (!success) console.warn("Could not click " + lbl);
    }

    await clickEl('Skip');
    await driver.sleep(4000);

    // Print details of all elements in DOM
    const allElements = await driver.executeScript(() => {
      const els = Array.from(document.querySelectorAll('*'));
      return els.map((e, idx) => ({
        idx,
        tag: e.tagName,
        id: e.id,
        className: e.className,
        ariaLabel: e.getAttribute('aria-label'),
        placeholder: e.getAttribute('placeholder'),
        role: e.getAttribute('role'),
        type: e.getAttribute('type'),
        text: (e.innerText || e.textContent || '').trim().substring(0, 100),
        value: e.value
      })).filter(info => 
        info.tag.includes('FLT-') || 
        info.tag === 'INPUT' || 
        info.tag === 'BUTTON' || 
        info.tag === 'SPAN' || 
        info.ariaLabel || 
        info.placeholder || 
        info.role
      );
    });

    console.log("=== ALL DETECTED INTERACTIVE/FLUTTER ELEMENTS ===");
    console.log(JSON.stringify(allElements, null, 2));
    console.log("=================================================");

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
