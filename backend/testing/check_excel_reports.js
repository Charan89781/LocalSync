const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

const multiLoginPath = "D:/AndroidFiles/Projects/LocalSync3/backend/testing/multi_login_report.xlsx";
const unifiedPath = "D:/AndroidFiles/Projects/LocalSync3/backend/testing/unified_test_report.xlsx";

(async () => {
  console.log("--- Multi-Login Excel Report Check ---");
  if (fs.existsSync(multiLoginPath)) {
    console.log("File exists. Size:", fs.statSync(multiLoginPath).size, "bytes");
    const wb = new ExcelJS.Workbook();
    await wb.xlsx.readFile(multiLoginPath);
    console.log("Worksheets in file:");
    wb.eachSheet((sheet) => {
      console.log(`  Sheet: "${sheet.name}" (${sheet.rowCount} rows, ${sheet.columnCount} columns)`);
      for (let r = 1; r <= Math.min(sheet.rowCount, 5); r++) {
        const row = sheet.getRow(r);
        const vals = [];
        row.eachCell((cell) => vals.push(cell.value));
        console.log(`    Row ${r}: ${JSON.stringify(vals)}`);
      }
    });
  } else {
    console.log("Multi-login file does not exist!");
  }

  console.log("\n--- Unified Excel Report Check ---");
  if (fs.existsSync(unifiedPath)) {
    console.log("File exists. Size:", fs.statSync(unifiedPath).size, "bytes");
    const wb = new ExcelJS.Workbook();
    await wb.xlsx.readFile(unifiedPath);
    console.log("Worksheets in file:");
    wb.eachSheet((sheet) => {
      console.log(`  Sheet: "${sheet.name}" (${sheet.rowCount} rows, ${sheet.columnCount} columns)`);
      for (let r = 1; r <= Math.min(sheet.rowCount, 4); r++) {
        const row = sheet.getRow(r);
        const vals = [];
        row.eachCell((cell) => vals.push(cell.value));
        console.log(`    Row ${r}: ${JSON.stringify(vals)}`);
      }
    });
  } else {
    console.log("Unified file does not exist!");
  }
})();
