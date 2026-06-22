const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const ExcelJS = require('exceljs');

const BUILD_PATH = 'D:/AndroidFiles/Projects/LocalSync3/frontend/build/web';
const PORT = 8095;
const BASE_URL = `http://localhost:${PORT}`;
const REPORT_PATH = path.join(__dirname, 'multi_login_report.xlsx');

const testAccounts = [
  { email: 'test_resident@localsync.com', password: 'Resident123', label: 'Resident' },
  { email: 'test_shopkeeper@localsync.com', password: 'Shopkeeper123', label: 'Shop Keeper' },
  { email: 'test_admin@localsync.com', password: 'Admin123', label: 'Admin' }
];

const results = [];

async function runForAccount(email, password, label) {
  console.log(`\n==================================================`);
  console.log(`Testing Login for Role: ${label} (${email})`);
  console.log(`==================================================`);

  let driver = null;
  const t0 = Date.now();

  try {
    const opts = new chrome.Options();
    opts.addArguments('--headless','--no-sandbox','--disable-dev-shm-usage','--window-size=1280,800','--force-renderer-accessibility');
    driver = await new Builder().forBrowser('chrome').setChromeOptions(opts).build();

    console.log("[1] Loading Application URL...");
    await driver.get(BASE_URL);
    await driver.wait(until.elementLocated(By.css('flt-glass-pane')), 25000);

    // Helpers
    async function findEl(lbl) {
      return await driver.executeScript((l) => {
        const els = document.querySelectorAll('flt-semantics, span, input, button, [aria-label]');
        for (let i = els.length - 1; i >= 0; i--) {
          const e = els[i];
          const a = (e.getAttribute('aria-label') || '').toLowerCase();
          const p = (e.getAttribute('placeholder') || '').toLowerCase();
          const t = (e.innerText || e.textContent || '').trim().toLowerCase();
          if (l === 'password' && (a.includes('forgot') || t.includes('forgot'))) {
            continue;
          }
          if (l.includes('email') && (t.includes('empty') || t.includes('valid') || t.includes('enter') || a.includes('empty') || a.includes('valid') || a.includes('enter'))) {
            continue;
          }
          if (a === l || p === l || t === l) return e;
        }
        for (let i = els.length - 1; i >= 0; i--) {
          const e = els[i];
          const a = (e.getAttribute('aria-label') || '').toLowerCase();
          const p = (e.getAttribute('placeholder') || '').toLowerCase();
          const t = (e.innerText || e.textContent || '').trim().toLowerCase();
          if (l === 'password' && (a.includes('forgot') || t.includes('forgot'))) {
            continue;
          }
          if (l.includes('email') && (t.includes('empty') || t.includes('valid') || t.includes('enter') || a.includes('empty') || a.includes('valid') || a.includes('enter'))) {
            continue;
          }
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
      const el = await waitEl(lbl, 8000);
      if (!el) throw new Error(`TextField with label "${lbl}" not found`);
      await driver.executeScript((e) => {
        if (e.focus) e.focus();
        if (e.click) e.click();
      }, el);
      await driver.sleep(500);

      const activeEl = await driver.switchTo().activeElement();
      await activeEl.sendKeys(val);
      await driver.sleep(500);
    }

    console.log("[2] Waiting for onboarding welcome screen...");
    await driver.sleep(3000); // Wait for splash screen animations
    const welcome = await waitEl('Connect With Neighbors', 15000);
    if (!welcome) throw new Error("Onboarding welcome screen text not found");

    console.log("[3] Clicking Skip to navigate to Login screen...");
    await clickEl('Skip');
    await driver.sleep(2000);

    console.log("[4] Checking Login screen loaded...");
    const loginHeader = await waitEl('SIGN IN', 10000);
    if (!loginHeader) throw new Error("SIGN IN header not found");

    console.log("[5] Entering credentials...");
    await typeEl('email', email);
    await typeEl('password', password);
    
    console.log("[6] Submitting form...");
    await clickEl('Sign In');
    await driver.sleep(5000); // Wait for Firebase Auth and navigation

    console.log("[7] Checking redirect to Home/Dashboard...");
    const url = await driver.getCurrentUrl();
    console.log(`Current URL: ${url}`);
    
    // Check if we navigated past login screen
    const loginStillLoaded = await findEl('SIGN IN');
    if (loginStillLoaded) {
      throw new Error("Login page still active (authentication failed or did not transition)");
    }

    // Verify role welcome greeting on dashboard
    const userRoleText = label.toUpperCase(); // e.g. "RESIDENT", "SHOP KEEPER", "ADMIN"
    console.log(`Verifying dashboard welcome message contains: "${userRoleText}"`);
    const welcomeUser = await waitEl(userRoleText, 15000);
    if (!welcomeUser) {
      throw new Error(`Dashboard welcome message for ${userRoleText} not found`);
    }

    // If Admin, test the admin dashboard route
    if (label === 'Admin') {
      console.log("[8] Navigating to Admin Dashboard...");
      await driver.get(`${BASE_URL}/#/admin`);
      await driver.sleep(4000);
      const adminHeader = await waitEl('ADMIN CONSOLE', 15000);
      if (!adminHeader) {
        throw new Error("Admin Dashboard welcome text not found");
      }
      console.log("✅ Admin Dashboard successfully verified!");
    }

    const duration = Date.now() - t0;
    console.log(`✅ [PASSED] Successful login verification for ${label}! (${duration}ms)`);
    results.push({ email, label, status: 'PASSED', duration, details: `Successfully logged in and verified dashboard. Final URL: ${url}` });

  } catch (err) {
    const duration = Date.now() - t0;
    console.log(`❌ [FAILED] Login failed for ${label}: ${err.message} (${duration}ms)`);
    results.push({ email, label, status: 'FAILED', duration, details: err.message });
  } finally {
    if (driver) {
      try { await driver.quit(); } catch(e) {}
    }
  }
}

(async () => {
  console.log("Starting local HTTP server...");
  let serverProcess = null;
  await new Promise((resolve) => {
    const cmd = process.platform === 'win32' ? 'npx.cmd' : 'npx';
    serverProcess = spawn(cmd, ['http-server', BUILD_PATH, '-p', PORT.toString(), '-c-1'], { shell: true });
    serverProcess.stdout.on('data', d => { if (d.toString().includes('Available on:') || d.toString().includes('Hit CTRL-C')) resolve(); });
    setTimeout(resolve, 4000);
  });

  // Run sequential tests for all 3 logins
  for (const account of testAccounts) {
    await runForAccount(account.email, account.password, account.label);
  }

  // Shutdown server
  if (serverProcess) {
    if (process.platform === 'win32') {
      try { execSync(`taskkill /pid ${serverProcess.pid} /f /t`, { stdio: 'ignore' }); } catch(e) {}
    } else {
      try { serverProcess.kill('SIGKILL'); } catch(e) {}
    }
    console.log("Local HTTP server stopped.");
  }

  // Compile report
  console.log("\nGenerating Multi-Login E2E report...");
  const wb = new ExcelJS.Workbook();
  const ws = wb.addWorksheet('Multi-Login Results');
  ws.columns = [
    { header: 'Account Label', key: 'label', width: 20 },
    { header: 'Email Address', key: 'email', width: 30 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Duration (ms)', key: 'duration', width: 15 },
    { header: 'Details', key: 'details', width: 60 }
  ];

  // Header styles
  const r = ws.getRow(1);
  r.font = { bold: true, color: { argb: 'FFFFFFFF' } };
  r.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F4E78' } };
  r.alignment = { horizontal: 'center' };

  results.forEach(res => {
    const row = ws.addRow(res);
    const isPass = res.status === 'PASSED';
    const statusCell = row.getCell(3);
    statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: isPass ? 'FFE2EFDA' : 'FFFFC7CE' } };
    statusCell.font = { bold: true, color: { argb: isPass ? 'FF375623' : 'FF9C0006' } };
    statusCell.alignment = { horizontal: 'center' };
  });

  await wb.xlsx.writeFile(REPORT_PATH);
  console.log(`Report saved to: ${REPORT_PATH}`);
  process.exit(0);
})();
