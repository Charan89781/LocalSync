const ExcelJS = require('exceljs');
const path = require('path');

/**
 * Generates a styled Excel report for E2E tests.
 * @param {Array} testResults Array of objects { stepName, status, durationMs, details, timestamp }
 * @param {string} outputPath Output file path
 */
async function generateExcelReport(testResults, outputPath) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'LocalSync QA Automation';
  workbook.lastModifiedBy = 'LocalSync E2E Suite';
  workbook.created = new Date();
  workbook.modified = new Date();

  // 1. SUMMARY SHEET
  const summarySheet = workbook.addWorksheet('Summary', {
    views: [{ showGridLines: true }]
  });

  // Calculate stats
  const totalTests = testResults.length;
  const passedTests = testResults.filter(r => r.status === 'PASSED').length;
  const failedTests = testResults.filter(r => r.status === 'FAILED').length;
  const passRate = totalTests > 0 ? (passedTests / totalTests) * 100 : 0;
  const totalDurationMs = testResults.reduce((acc, r) => acc + r.durationMs, 0);
  const totalDurationSec = (totalDurationMs / 1000).toFixed(2);

  // Set column widths
  summarySheet.columns = [
    { header: 'Metric', key: 'metric', width: 25 },
    { header: 'Value', key: 'value', width: 20 }
  ];

  // Add data rows
  summarySheet.addRows([
    { metric: 'Project Name', value: 'LocalSync3 Web Application' },
    { metric: 'Test Execution Date', value: new Date().toLocaleString() },
    { metric: 'Total Steps Executed', value: totalTests },
    { metric: 'Steps Passed', value: passedTests },
    { metric: 'Steps Failed', value: failedTests },
    { metric: 'Pass Rate (%)', value: `${passRate.toFixed(2)}%` },
    { metric: 'Total Duration (s)', value: parseFloat(totalDurationSec) }
  ]);

  // Style Header
  summarySheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
  summarySheet.getRow(1).fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF1F4E78' } // Navy Blue
  };
  summarySheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

  // Format cells
  summarySheet.eachRow((row, rowNumber) => {
    if (rowNumber === 1) return;
    row.getCell(1).font = { bold: true };
    row.getCell(2).alignment = { horizontal: 'left' };
    
    // Status highlights in Summary
    if (row.getCell(1).value === 'Steps Passed') {
      row.getCell(2).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2EFDA' } }; // Light Green
      row.getCell(2).font = { color: { argb: 'FF375623' }, bold: true };
    }
    if (row.getCell(1).value === 'Steps Failed') {
      row.getCell(2).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFCE4D6' } }; // Light Red
      row.getCell(2).font = { color: { argb: 'FFC65911' }, bold: true };
    }
    if (row.getCell(1).value === 'Pass Rate (%)') {
      row.getCell(2).font = { bold: true };
    }
  });

  // 2. DETAILS SHEET
  const detailsSheet = workbook.addWorksheet('Test Details', {
    views: [{ showGridLines: true }]
  });

  detailsSheet.columns = [
    { header: 'Step ID', key: 'id', width: 10 },
    { header: 'Test Step Name', key: 'stepName', width: 35 },
    { header: 'Status', key: 'status', width: 15 },
    { header: 'Duration (ms)', key: 'duration', width: 15 },
    { header: 'Timestamp', key: 'timestamp', width: 25 },
    { header: 'Execution Details / Error Message', key: 'details', width: 60 }
  ];

  // Add detail rows
  testResults.forEach((result, idx) => {
    detailsSheet.addRow({
      id: idx + 1,
      stepName: result.stepName,
      status: result.status,
      duration: result.durationMs,
      timestamp: result.timestamp,
      details: result.details
    });
  });

  // Style Header
  detailsSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
  detailsSheet.getRow(1).fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF1F4E78' }
  };
  detailsSheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

  // Style Details Rows
  detailsSheet.eachRow((row, rowNumber) => {
    if (rowNumber === 1) return;
    row.getCell(1).alignment = { horizontal: 'center' };
    row.getCell(3).alignment = { horizontal: 'center' };
    row.getCell(4).alignment = { horizontal: 'right' };

    const statusCell = row.getCell(3);
    if (statusCell.value === 'PASSED') {
      statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2EFDA' } };
      statusCell.font = { color: { argb: 'FF375623' }, bold: true };
    } else if (statusCell.value === 'FAILED') {
      statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFCE4D6' } };
      statusCell.font = { color: { argb: 'FFC65911' }, bold: true };
    }
  });

  // Save report
  await workbook.xlsx.writeFile(outputPath);
  console.log(`Excel report saved successfully at: ${outputPath}`);
}

module.exports = { generateExcelReport };
