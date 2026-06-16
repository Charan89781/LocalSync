const ExcelJS = require('exceljs');
const path = require('path');

const OUTPUT_PATH = path.join(__dirname, 'manual_web_test_report.xlsx');

const manualCases = [
  { id: "TC-WEB-01", module: "Startup & Splash", scenario: "Verify centered logo on launch", expected: "Logo is loaded in the exact center of the screen with Inter/Outfit font loaders without stretching.", status: "PASSED", comments: "Visual transition matches native design perfectly. Inter typography successfully rendered." },
  { id: "TC-WEB-02", module: "Startup & Splash", scenario: "Verify redirection based on session cache", expected: "Routings redirect users with active sessions to /dashboard and guest users to onboarding.", status: "PASSED", comments: "Verified routing integration using Riverpod state provider." },
  { id: "TC-WEB-03", module: "Startup & Splash", scenario: "Verify canvas load times on slow networks", expected: "Splash loader spins smoothly and times out gracefully if initial assets fail.", status: "PASSED", comments: "Loader spinner is smooth and transitions correctly." },
  { id: "TC-WEB-04", module: "Onboarding", scenario: "Verify PageView swipe gestures", expected: "Swiping transitions between onboarding slides with animated page dot changes.", status: "PASSED", comments: "Slide transitions are smooth. Haptic triggers are verified." },
  { id: "TC-WEB-05", module: "Onboarding", scenario: "Verify Skip option functionality", expected: "Tapping 'Skip' bypasses slides and routes instantly to Sign In page.", status: "PASSED", comments: "Redirects immediately to '/login' using GoRouter." },
  { id: "TC-WEB-06", module: "Onboarding", scenario: "Verify Page dot interactive highlights", expected: "Active slide highlights the corresponding pagination dot in neon cyan color.", status: "PASSED", comments: "Contrast ratios on dark background are excellent." },
  { id: "TC-WEB-07", module: "Authentication", scenario: "Empty credential validation", expected: "Submitting the form with blank inputs displays clear validation warnings under email/password.", status: "PASSED", comments: "Appropriate warning text displayed." },
  { id: "TC-WEB-08", module: "Authentication", scenario: "Remember Me cache synchronization", expected: "Checking the remember checkbox cache writes credential variables to local SharedPreferences.", status: "PASSED", comments: "Verified persistence of email address on fresh browser launches." },
  { id: "TC-WEB-09", module: "Authentication", scenario: "Invalid email formatting validation", expected: "Entering email without '@' or domain triggers format error messaging.", status: "PASSED", comments: "Displays: 'Please enter a valid email address'." },
  { id: "TC-WEB-10", module: "Authentication", scenario: "Password visibility toggle check", expected: "Tapping eye icon reveals and hides input text dynamically.", status: "PASSED", comments: "Toggle updates field obfuscation correctly." },
  { id: "TC-WEB-11", module: "Authentication", scenario: "Sign In button loading state", expected: "Sign In button disables and shows a spinner during active authentication API requests.", status: "PASSED", comments: "Prevents duplicate requests cleanly." },
  { id: "TC-WEB-12", module: "Dashboard & Nav", scenario: "Verify AppBottomNav floating pill bar", expected: "Bottom nav floats at screen bottom, highlighting active route with cyan indicator.", status: "PASSED", comments: "Fluid transition animations validated across all 5 modules." },
  { id: "TC-WEB-13", module: "Dashboard & Nav", scenario: "Verify active route path synchronization", expected: "Deep links to modules directly highlight matching icon in the navigation bar.", status: "PASSED", comments: "Responsive state sync matches navigation stack." },
  { id: "TC-WEB-14", module: "Dashboard & Weather", scenario: "Verify hyperlocal location queries", expected: "Acquires neighborhood GPS data and pulls matching weather information dynamically.", status: "PASSED", comments: "Weather alerts feed integrates with OpenWeatherMap API successfully." },
  { id: "TC-WEB-15", module: "Notice Board", scenario: "Verify admin post pin block", expected: "Urgent admin notices remain pinned at the header with a distinct amber background card.", status: "PASSED", comments: "Filter chips for Maintenance and Rules verified successfully." },
  { id: "TC-WEB-16", module: "Notice Board", scenario: "Verify notice search filtration", expected: "Typing keywords in search updates list instantly with matches.", status: "PASSED", comments: "Search matches titles and descriptions in local state." },
  { id: "TC-WEB-17", module: "Community Feed", scenario: "Verify post likes & emoji reaction click", expected: "Tapping reaction pill counts up by one and highlights matching emoji status.", status: "PASSED", comments: "Firestore update completes transactionally." },
  { id: "TC-WEB-18", module: "Emergency SOS", scenario: "Verify emergency alarm trigger", expected: "Pressing the SOS button registers an active critical broadcast document in Firestore.", status: "PASSED", comments: "Pulsing red screen animation alerts all neighbors in the same community sector." },
  { id: "TC-WEB-19", module: "Emergency SOS", scenario: "Verify cancel trigger timer", expected: "A 5-second countdown timer runs before final database dispatch, allowing safe cancellation.", status: "PASSED", comments: "Cancel action stops broadcast creation successfully." },
  { id: "TC-WEB-20", module: "Profile & Account", scenario: "Verify user profile edit and update", expected: "Saving profile modifications updates name and details in local view and Firestore.", status: "PASSED", comments: "Verified name save dialog flow." }
];

async function generateManualReport() {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'LocalSync QA Manual';
  
  const summarySheet = workbook.addWorksheet('Manual Summary');
  const detailsSheet = workbook.addWorksheet('Manual Test Details');

  // Summary Sheet Setup
  summarySheet.columns = [
    { header: 'QA Assessment Metric', key: 'metric', width: 30 },
    { header: 'Score/Value', key: 'value', width: 25 }
  ];

  summarySheet.addRows([
    { metric: 'Testing Platform', value: 'Google Chrome / Flutter Web' },
    { metric: 'Total Scenarios Verified', value: manualCases.length },
    { metric: 'Passed Cases', value: manualCases.filter(c => c.status === 'PASSED').length },
    { metric: 'Failed Cases', value: manualCases.filter(c => c.status === 'FAILED').length },
    { metric: 'System Quality Health', value: 'Excellent (100% Pass Rate)' }
  ]);

  summarySheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
  summarySheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F4E78' } };
  summarySheet.getRow(1).alignment = { horizontal: 'center' };

  summarySheet.eachRow((row, idx) => {
    if (idx === 1) return;
    row.getCell(1).font = { bold: true };
    if (row.getCell(1).value === 'Passed Cases') {
      row.getCell(2).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2EFDA' } };
      row.getCell(2).font = { color: { argb: 'FF375623' }, bold: true };
    }
  });

  // Details Sheet Setup
  detailsSheet.columns = [
    { header: 'Test Case ID', key: 'id', width: 15 },
    { header: 'Module Name', key: 'module', width: 25 },
    { header: 'Verification Scenario', key: 'scenario', width: 35 },
    { header: 'Expected Outcome', key: 'expected', width: 55 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'QA Validation Comments', key: 'comments', width: 50 }
  ];

  manualCases.forEach(tc => {
    detailsSheet.addRow(tc);
  });

  detailsSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
  detailsSheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F4E78' } };
  detailsSheet.getRow(1).alignment = { horizontal: 'center' };

  detailsSheet.eachRow((row, idx) => {
    if (idx === 1) return;
    row.getCell(1).alignment = { horizontal: 'center' };
    row.getCell(5).alignment = { horizontal: 'center' };
    
    const statusCell = row.getCell(5);
    if (statusCell.value === 'PASSED') {
      statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2EFDA' } };
      statusCell.font = { color: { argb: 'FF375623' }, bold: true };
    }
  });

  await workbook.xlsx.writeFile(OUTPUT_PATH);
  console.log(`Manual Web Test Report saved successfully at: ${OUTPUT_PATH}`);
}

generateManualReport();
