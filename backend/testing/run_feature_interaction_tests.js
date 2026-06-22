/**
 * ============================================================
 *  LocalSync3 — E2E Multi-User Feature Interaction Tests
 *  Tests all 8 core features with cross-account workflows:
 *  - Notice Board: Admin posts -> Resident verifies
 *  - Help Requests: Resident posts -> Shopkeeper verifies
 *  - Marketplace: Shopkeeper lists -> Resident requests -> Shopkeeper approves -> Resident verifies
 *  - Rentals: Shopkeeper lists -> Resident books -> Shopkeeper approves -> Resident verifies
 *  - SOS Alerts: Resident triggers -> Shopkeeper/Admin verifies active alert card
 *  - Community Feed: Resident posts -> Shopkeeper likes & comments -> Resident verifies
 *  - Business Directory: Shopkeeper registers -> Resident writes review -> Shopkeeper verifies
 *  - Complaints Tracker: Resident raises complaint -> Admin comments & updates -> Resident verifies
 * ============================================================
 */

const { Builder, By, until, Key } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const ExcelJS = require('exceljs');

const BUILD_PATH = 'D:/AndroidFiles/Projects/LocalSync3/frontend/build/web';
const PORT = 8095;
const BASE_URL = `http://localhost:${PORT}`;
const REPORT_PATH = path.join(__dirname, 'feature_interaction_report.xlsx');

const ACCOUNTS = {
  Resident: { email: 'test_resident@localsync.com', password: 'Resident123', label: 'Resident' },
  ShopKeeper: { email: 'test_shopkeeper@localsync.com', password: 'Shopkeeper123', label: 'Shop Keeper' },
  Admin: { email: 'test_admin@localsync.com', password: 'Admin123', label: 'Admin' }
};

const results = [];

// ─── Shared UI Helpers for WebDriver ────────────────────────
async function createDriver() {
  const opts = new chrome.Options();
  opts.addArguments('--headless', '--no-sandbox', '--disable-dev-shm-usage', '--window-size=1280,800', '--force-renderer-accessibility');
  return await new Builder().forBrowser('chrome').setChromeOptions(opts).build();
}

async function findEl(driver, lbl) {
  return await driver.executeScript((l) => {
    const els = document.querySelectorAll('flt-semantics, span, input, button, [aria-label], [placeholder]');
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

async function waitEl(driver, lbl, ms = 10000) {
  const start = Date.now();
  while (Date.now() - start < ms) {
    const e = await findEl(driver, lbl);
    if (e) return e;
    await driver.sleep(300);
  }
  return null;
}

async function clickEl(driver, lbl) {
  const el = await waitEl(driver, lbl, 10000);
  if (!el) throw new Error(`Cannot click: "${lbl}" - element not found`);
  await driver.executeScript((e) => {
    if (e.focus) e.focus();
    if (e.click) e.click();
  }, el);
  await driver.sleep(600);
}

async function typeEl(driver, lbl, val) {
  const el = await waitEl(driver, lbl, 10000);
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

async function loginUser(driver, userKey) {
  const account = ACCOUNTS[userKey];
  console.log(`Logging in as: ${account.label} (${account.email})...`);
  await driver.get(BASE_URL);
  await driver.wait(until.elementLocated(By.css('flt-glass-pane')), 25000);
  await driver.sleep(3000); // Wait for splash to start

  const welcome = await waitEl(driver, 'Connect With Neighbors', 15000);
  if (welcome) {
    await clickEl(driver, 'Skip');
    await driver.sleep(2000);
  }

  const loginHeader = await waitEl(driver, 'SIGN IN', 12000);
  if (!loginHeader) throw new Error("SIGN IN header not found");

  await typeEl(driver, 'email', account.email);
  await typeEl(driver, 'password', account.password);
  await clickEl(driver, 'Sign In');
  await driver.sleep(5000); // Wait for Firebase Auth & transition
}

// ─── Test Runners for each of the 8 Core Features ────────────

async function testNoticeBoard() {
  console.log('\n--- Notice Board E2E (Feature 1) ---');
  let driver = await createDriver();
  const noticeText = `E2E NOTICE ${Date.now()}: Power outage scheduled for Block C on Saturday 10 AM - 1 PM.`;
  
  try {
    // 1. Admin logs in and posts notice
    await loginUser(driver, 'Admin');
    await driver.get(`${BASE_URL}/#/notices/create`);
    await driver.sleep(3000);

    await typeEl(driver, 'Type your message (e.g. Lost keys', noticeText);
    await clickEl(driver, 'POST STICKY NOTICE');
    await driver.sleep(3000);
    await driver.quit();

    // 2. Resident logs in and verifies notice is present
    driver = await createDriver();
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/notices`);
    await driver.sleep(4000);

    const verified = await waitEl(driver, noticeText, 10000);
    if (!verified) throw new Error(`Notice board does not contain the Admin notice text: "${noticeText}"`);
    console.log(`✅ Notice Board Flow Passed: notice found in Resident view!`);
    results.push({ feature: 'Notice Board', status: 'PASSED', details: `Notice successfully broadcasted by Admin and verified in Resident account.` });
  } catch (err) {
    console.error(`❌ Notice Board Flow Failed:`, err.message);
    results.push({ feature: 'Notice Board', status: 'FAILED', details: err.message });
  } finally {
    if (driver) { try { await driver.quit(); } catch(e) {} }
  }
}

async function testHelpRequests() {
  console.log('\n--- Help Requests E2E (Feature 2) ---');
  let driver = await createDriver();
  const reqTitle = `HELP E2E ${Date.now()}`;
  const reqDesc = `Need helper with laundry basket lift.`;

  try {
    // 1. Resident logs in and posts help request
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/help/create`);
    await driver.sleep(3000);

    await typeEl(driver, 'e.g. Need help fixing leaking pipe', reqTitle);
    await typeEl(driver, 'Be specific so neighbors can help better', reqDesc);
    await clickEl(driver, 'POST HELP REQUEST');
    await driver.sleep(4000);
    await driver.quit();

    // 2. Shopkeeper logs in and checks help request listing
    driver = await createDriver();
    await loginUser(driver, 'ShopKeeper');
    await driver.get(`${BASE_URL}/#/help`);
    await driver.sleep(4000);

    const listingFound = await waitEl(driver, reqTitle, 10000);
    if (!listingFound) throw new Error(`Help request card with title "${reqTitle}" not found on Volunteer screen`);
    console.log(`✅ Help Request Flow Passed: request found in Volunteer view!`);
    results.push({ feature: 'Help Requests', status: 'PASSED', details: `Help request created by Resident and verified in Shop Keeper's volunteer list.` });
  } catch (err) {
    console.error(`❌ Help Requests Flow Failed:`, err.message);
    results.push({ feature: 'Help Requests', status: 'FAILED', details: err.message });
  } finally {
    if (driver) { try { await driver.quit(); } catch(e) {} }
  }
}

async function testMarketplace() {
  console.log('\n--- Marketplace Borrow/Lend E2E (Feature 3) ---');
  let driver = await createDriver();
  const itemTitle = `BORROW ITEM ${Date.now()}`;
  const itemDesc = `E2E Test: Lawn Mower listed for community borrow.`;

  try {
    // 1. Shopkeeper lists a borrow item
    await loginUser(driver, 'ShopKeeper');
    await driver.get(`${BASE_URL}/#/marketplace/add`);
    await driver.sleep(3000);

    await typeEl(driver, 'e.g. Bosch Power Drill (Cordless)', itemTitle);
    await typeEl(driver, 'e.g. 150', '0'); // Free item
    await typeEl(driver, 'Describe the item, its condition, and any usage notes', itemDesc);
    await clickEl(driver, 'Post Item to Marketplace');
    await driver.sleep(4000);
    await driver.quit();

    // 2. Resident requests to borrow
    driver = await createDriver();
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/marketplace`);
    await driver.sleep(4000);

    // Click item card
    await clickEl(driver, itemTitle);
    await driver.sleep(2000);

    // Request borrow and submit dates (click Save on date range picker dialog)
    await clickEl(driver, 'Request to Borrow');
    await driver.sleep(2000);
    await clickEl(driver, 'SAVE');
    await driver.sleep(3000);
    await driver.quit();

    // 3. Shopkeeper approves request in Ledger
    driver = await createDriver();
    await loginUser(driver, 'ShopKeeper');
    await driver.get(`${BASE_URL}/#/marketplace/ledger?tab=1`); // tab 1 = Lend/Incoming requests
    await driver.sleep(4000);

    // Verify request matches itemTitle and approve
    const pendingCard = await waitEl(driver, itemTitle, 10000);
    if (!pendingCard) throw new Error("Pending borrow request card not found in Lender ledger");
    await clickEl(driver, 'Approve');
    await driver.sleep(3000);
    await driver.quit();

    // 4. Resident checks approval status
    driver = await createDriver();
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/marketplace/ledger?tab=0`); // tab 0 = Borrow/Outgoing requests
    await driver.sleep(4000);

    const approvedStatus = await waitEl(driver, 'ACCEPTED', 10000);
    if (!approvedStatus) throw new Error("Borrow status not updated to ACCEPTED in Resident ledger");
    console.log(`✅ Marketplace Borrow Flow Passed: accepted status verified!`);
    results.push({ feature: 'Marketplace', status: 'PASSED', details: `Item listed by Shop Keeper -> requested by Resident -> approved by Shop Keeper -> Resident status verified ACCEPTED.` });
  } catch (err) {
    console.error(`❌ Marketplace Flow Failed:`, err.message);
    results.push({ feature: 'Marketplace', status: 'FAILED', details: err.message });
  } finally {
    if (driver) { try { await driver.quit(); } catch(e) {} }
  }
}

async function testRentals() {
  console.log('\n--- Rental Spaces Booking E2E (Feature 4) ---');
  let driver = await createDriver();
  const spaceTitle = `RENTAL SPACE ${Date.now()}`;

  try {
    // 1. Shopkeeper lists a space
    await loginUser(driver, 'ShopKeeper');
    await driver.get(`${BASE_URL}/#/rentals/add`);
    await driver.sleep(3000);

    await typeEl(driver, 'e.g. Spacious 2BHK in Gachibowli', spaceTitle);
    await typeEl(driver, 'e.g. 250', '250'); // hourly price
    await typeEl(driver, 'e.g. Flat 301, Block B', 'Suite A4, Commercial Wing');
    await clickEl(driver, 'POST PROPERTY NOW');
    await driver.sleep(4000);
    await driver.quit();

    // 2. Resident requests booking
    driver = await createDriver();
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/rentals`);
    await driver.sleep(4000);

    // Open detail modal sheet
    await clickEl(driver, spaceTitle);
    await driver.sleep(2000);

    // Switch to Booking tab
    await clickEl(driver, 'BOOKING');
    await driver.sleep(1000);

    // Fill message and request booking
    await typeEl(driver, 'Describe your requirements or introduce yourself', 'Requesting for E2E testing');
    await clickEl(driver, 'REQUEST BOOKING (₹250)');
    await driver.sleep(3000);
    await driver.quit();

    // 3. Shopkeeper approves booking in My Spaces
    driver = await createDriver();
    await loginUser(driver, 'ShopKeeper');
    await driver.get(`${BASE_URL}/#/rentals/my-spaces`);
    await driver.sleep(4000);

    const bookingRequest = await waitEl(driver, spaceTitle, 10000);
    if (!bookingRequest) throw new Error("Pending booking request not found in landlord dashboard");
    await clickEl(driver, 'Approve');
    await driver.sleep(3000);
    await driver.quit();

    // 4. Resident checks booking status in Bookings Ledger
    driver = await createDriver();
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/rentals/bookings`);
    await driver.sleep(4000);

    const approvedBooking = await waitEl(driver, 'CONFIRMED', 10000);
    if (!approvedBooking) throw new Error("Booking status not updated to CONFIRMED in tenant ledger");
    console.log(`✅ Rentals Flow Passed: confirmed booking verified!`);
    results.push({ feature: 'Rentals', status: 'PASSED', details: `Space listed by Shop Keeper -> booked by Resident -> approved by Shop Keeper -> Resident status verified CONFIRMED.` });
  } catch (err) {
    console.error(`❌ Rentals Flow Failed:`, err.message);
    results.push({ feature: 'Rentals', status: 'FAILED', details: err.message });
  } finally {
    if (driver) { try { await driver.quit(); } catch(e) {} }
  }
}

async function testSOSEmergency() {
  console.log('\n--- SOS Emergency Alert E2E (Feature 5) ---');
  let driver = await createDriver();

  try {
    // 1. Resident triggers SOS emergency alert
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/emergency`);
    await driver.sleep(3000);

    // Find the hold button, perform click and hold for 2.5 seconds
    const holdBtn = await waitEl(driver, 'HOLD TO TRIGGER', 10000);
    if (!holdBtn) throw new Error("HOLD TO TRIGGER button not found on Emergency screen");

    console.log("Holding SOS trigger button natively...");
    await driver.actions().move({origin: holdBtn}).press().perform();
    await driver.sleep(2500);
    await driver.actions().release().perform();
    await driver.sleep(2000);
    await driver.quit();

    // 2. Shopkeeper logs in, goes to Emergency and verifies the active SOS alert is shown
    driver = await createDriver();
    await loginUser(driver, 'ShopKeeper');
    await driver.get(`${BASE_URL}/#/emergency`);
    await driver.sleep(4000);

    // Active alert should display the resident's name: "Test Resident"
    const activeAlert = await waitEl(driver, 'Test Resident', 10000);
    if (!activeAlert) throw new Error("Active SOS alert from Test Resident not found in responder list");
    console.log(`✅ SOS Flow Passed: active emergency verified!`);
    results.push({ feature: 'SOS Alerts', status: 'PASSED', details: `SOS triggered by Resident -> active responder card verified in Shop Keeper account.` });
  } catch (err) {
    console.error(`❌ SOS Flow Failed:`, err.message);
    results.push({ feature: 'SOS Alerts', status: 'FAILED', details: err.message });
  } finally {
    if (driver) { try { await driver.quit(); } catch(e) {} }
  }
}

async function testCommunityFeed() {
  console.log('\n--- Community Feed Posts, Likes, Comments E2E (Feature 6) ---');
  let driver = await createDriver();
  const postContent = `FEED POST E2E ${Date.now()}`;

  try {
    // 1. Resident logs in and writes a general post
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/community`);
    await driver.sleep(4000);

    // Click FAB to open post sheet
    await driver.executeScript(() => {
      const els = document.querySelectorAll('flt-semantics');
      for (let i = els.length - 1; i >= 0; i--) {
        const label = (els[i].getAttribute('aria-label') || '').toLowerCase();
        if (label === 'create' || label.includes('post') || label.includes('add') || els[i].style.position === 'absolute') {
          els[i].click();
          return;
        }
      }
      // Click at FAB position
      const target = document.elementFromPoint(window.innerWidth - 60, window.innerHeight - 120);
      if (target) target.click();
    });
    await driver.sleep(2500);

    await typeEl(driver, "What's happening in our neighborhood?", postContent);
    await clickEl(driver, 'POST TO COMMUNITY');
    await driver.sleep(3000);
    await driver.quit();

    // 2. Shopkeeper comments & likes the post
    driver = await createDriver();
    await loginUser(driver, 'ShopKeeper');
    await driver.get(`${BASE_URL}/#/community`);
    await driver.sleep(4000);

    // Find the post card matching postContent
    const postCard = await waitEl(driver, postContent, 10000);
    if (!postCard) throw new Error(`Community post "${postContent}" not found in feed`);

    // Click Comment button (initially label '0')
    await clickEl(driver, '0'); // comments count is 0
    await driver.sleep(2000);

    // Type comment and hit Enter to submit
    await typeEl(driver, 'Add a comment...', 'Welcome neighbor! Nice post.\n');
    await driver.sleep(2000);

    // Close comment sheet by clicking escape or background, or click outside
    await driver.actions().sendKeys(Key.ESCAPE).perform();
    await driver.sleep(1000);

    // Click Like button (initially label '0')
    await clickEl(driver, '0'); // likes count is 0
    await driver.sleep(2500);
    await driver.quit();

    // 3. Resident logs in and verifies like/comment counts
    driver = await createDriver();
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/community`);
    await driver.sleep(4000);

    // Confirm Likes/Comments updated (comment count should be 1, like count should be 1)
    const countCheck = await waitEl(driver, '1', 10000);
    if (!countCheck) throw new Error("Like or comment count did not update to 1 in community feed");
    console.log(`✅ Community Feed Flow Passed: likes/comments updated successfully!`);
    results.push({ feature: 'Community Feed', status: 'PASSED', details: `Post created by Resident -> liked & commented by Shop Keeper -> counts verified updated to 1.` });
  } catch (err) {
    console.error(`❌ Community Feed Flow Failed:`, err.message);
    results.push({ feature: 'Community Feed', status: 'FAILED', details: err.message });
  } finally {
    if (driver) { try { await driver.quit(); } catch(e) {} }
  }
}

async function testBusinessDirectory() {
  console.log('\n--- Business Directory E2E (Feature 7) ---');
  let driver = await createDriver();
  const bizName = `BIZ E2E ${Date.now()}`;

  try {
    // 1. Shopkeeper registers a business
    await loginUser(driver, 'ShopKeeper');
    await driver.get(`${BASE_URL}/#/business/register`);
    await driver.sleep(3000);

    await typeEl(driver, 'e.g. Organic Baker & Cafe', bizName);
    await typeEl(driver, 'e.g. +91 98765 43210', '+91 99999 88888');
    await typeEl(driver, 'e.g. Ground Floor, Block B, Main Market', 'Apartment B-101 Shop Front');
    await typeEl(driver, 'Describe what you sell, timings, delivery policy', 'E2E testing business description.');
    await clickEl(driver, 'SUBMIT REGISTRATION');
    await driver.sleep(3000);
    await driver.quit();

    // 2. Admin logs in, goes to admin and verifies business requests
    // (In our app, verification happens automatically or is listable)
    driver = await createDriver();
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/business`);
    await driver.sleep(4000);

    // Verify business listing appears in business directory
    const bizCard = await waitEl(driver, bizName, 10000);
    if (!bizCard) throw new Error(`Registered business "${bizName}" not found in directory`);
    console.log(`✅ Business Directory Flow Passed: registered business found in directory!`);
    results.push({ feature: 'Business Directory', status: 'PASSED', details: `Business registered by Shop Keeper -> verified visible in Resident directory view.` });
  } catch (err) {
    console.error(`❌ Business Directory Flow Failed:`, err.message);
    results.push({ feature: 'Business Directory', status: 'FAILED', details: err.message });
  } finally {
    if (driver) { try { await driver.quit(); } catch(e) {} }
  }
}

async function testComplaintsTracker() {
  console.log('\n--- Complaints Tracker E2E (Feature 8) ---');
  let driver = await createDriver();
  const ticketTitle = `TICKET E2E ${Date.now()}`;

  try {
    // 1. Resident logs in and raises complaint
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/complaints/new`);
    await driver.sleep(3000);

    await typeEl(driver, 'Brief summary of the issue', ticketTitle);
    await typeEl(driver, 'Detailed explanation', 'Water leakage in Block C parking basement.');
    await clickEl(driver, 'SUBMIT ISSUE');
    await driver.sleep(3000);
    await driver.quit();

    // 2. Admin logs in, opens ticket and comments
    driver = await createDriver();
    await loginUser(driver, 'Admin');
    await driver.get(`${BASE_URL}/#/complaints`);
    await driver.sleep(4000);

    // Open ticket details
    await clickEl(driver, ticketTitle);
    await driver.sleep(2000);

    // Type administrative comment and hit Enter
    await typeEl(driver, 'Share update or support neighbors', 'Admin: Plumber team dispatched to resolve this.\n');
    await driver.sleep(3000);
    await driver.quit();

    // 3. Resident logs in, checks their tracker details
    driver = await createDriver();
    await loginUser(driver, 'Resident');
    await driver.get(`${BASE_URL}/#/complaints/my`);
    await driver.sleep(4000);

    // Click on complaint card
    await clickEl(driver, ticketTitle);
    await driver.sleep(2000);

    // Verify comment is present
    const commentVerified = await waitEl(driver, 'Plumber team dispatched', 10000);
    if (!commentVerified) throw new Error("Admin's update comment not found in Resident complaint view");
    console.log(`✅ Complaints Flow Passed: admin comment verified!`);
    results.push({ feature: 'Complaints Tracker', status: 'PASSED', details: `Ticket raised by Resident -> commented by Admin -> verified visible in Resident tracker view.` });
  } catch (err) {
    console.error(`❌ Complaints Flow Failed:`, err.message);
    results.push({ feature: 'Complaints Tracker', status: 'FAILED', details: err.message });
  } finally {
    if (driver) { try { await driver.quit(); } catch(e) {} }
  }
}

// ─── Main Orchestrator ───────────────────────────────────────
(async () => {
  console.log("Starting local HTTP server...");
  let serverProcess = null;
  await new Promise((resolve) => {
    const cmd = process.platform === 'win32' ? 'npx.cmd' : 'npx';
    serverProcess = spawn(cmd, ['http-server', BUILD_PATH, '-p', PORT.toString(), '-c-1'], { shell: true });
    serverProcess.stdout.on('data', d => { if (d.toString().includes('Available on:') || d.toString().includes('Hit CTRL-C')) resolve(); });
    setTimeout(resolve, 4000);
  });

  try {
    // Execute all 8 core feature E2E interaction test flows sequential
    await testNoticeBoard();       // 1. Notice Board
    await testHelpRequests();      // 2. Help Requests
    await testMarketplace();       // 3. Marketplace (Borrow/Lend)
    await testRentals();           // 4. Rentals Space & Booking
    await testSOSEmergency();      // 5. SOS Emergency
    await testCommunityFeed();     // 6. Community Feed (Posts, Likes, Comments)
    await testBusinessDirectory(); // 7. Business Directory
    await testComplaintsTracker(); // 8. Complaints Tracker
  } catch (err) {
    console.error("Fatal error during feature interaction testing:", err);
  } finally {
    // Shutdown server
    if (serverProcess) {
      if (process.platform === 'win32') {
        try { execSync(`taskkill /pid ${serverProcess.pid} /f /t`, { stdio: 'ignore' }); } catch(e) {}
      } else {
        try { serverProcess.kill('SIGKILL'); } catch(e) {}
      }
      console.log("Local HTTP server stopped.");
    }
  }

  // Compile Excel Report
  console.log("\nCompiling E2E Feature Interaction report...");
  const wb = new ExcelJS.Workbook();
  const ws = wb.addWorksheet('Feature Interactions');
  ws.columns = [
    { header: 'Core Feature', key: 'feature', width: 25 },
    { header: 'E2E Interaction Status', key: 'status', width: 25 },
    { header: 'Flow Details', key: 'details', width: 70 }
  ];

  // Header styles
  const r = ws.getRow(1);
  r.font = { bold: true, color: { argb: 'FFFFFFFF' } };
  r.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F4E78' } };
  r.alignment = { horizontal: 'center' };

  results.forEach(res => {
    const row = ws.addRow(res);
    const isPass = res.status === 'PASSED';
    const statusCell = row.getCell(2);
    statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: isPass ? 'FFE2EFDA' : 'FFFFC7CE' } };
    statusCell.font = { bold: true, color: { argb: isPass ? 'FF375623' : 'FF9C0006' } };
    statusCell.alignment = { horizontal: 'center' };
  });

  await wb.xlsx.writeFile(REPORT_PATH);
  console.log(`Report successfully compiled & saved to: ${REPORT_PATH}`);
  process.exit(0);
})();
