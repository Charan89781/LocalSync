const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

const OUTPUT_PATH = path.join(__dirname, 'consolidated_real_test_report.xlsx');

const FILES_TO_MERGE = [
  {
    name: 'Selenium Web E2E (Silicon)',
    path: path.join(__dirname, 'selenium-tests/test_report.xlsx'),
    prefix: 'Web_Sel_'
  },
  {
    name: 'Appium Mobile E2E',
    path: path.join(__dirname, 'appium-testing/appium_test_report.xlsx'),
    prefix: 'Mob_App_'
  },
  {
    name: 'Manual Web QA',
    path: path.join(__dirname, 'selenium-tests/manual_web_test_report.xlsx'),
    prefix: 'Man_Web_'
  },
  {
    name: 'Backend Security Rules',
    path: path.join(__dirname, 'automated-testing/automated.xlsx'),
    prefix: 'Sec_Rules_'
  }
];

async function mergeReports() {
  console.log('🏁 Starting report consolidation...\n');
  const masterWorkbook = new ExcelJS.Workbook();
  masterWorkbook.creator = 'LocalSync Consolidated QA System';
  masterWorkbook.created = new Date();

  for (const item of FILES_TO_MERGE) {
    if (!fs.existsSync(item.path)) {
      console.log(`⚠️  File not found (skipping): ${item.path}`);
      continue;
    }

    console.log(`📦 Reading ${item.name} from: ${path.basename(item.path)}`);
    const tempWorkbook = new ExcelJS.Workbook();
    await tempWorkbook.xlsx.readFile(item.path);

    tempWorkbook.eachSheet((srcSheet) => {
      // Create a unique sheet name within 31 characters limit for Excel
      let sheetName = srcSheet.name;
      if (sheetName.length > 20) {
        sheetName = sheetName.substring(0, 20);
      }
      const newSheetName = `${item.prefix}${sheetName}`.substring(0, 31);
      
      console.log(`   └─ Copying sheet "${srcSheet.name}" as "${newSheetName}"`);
      const destSheet = masterWorkbook.addWorksheet(newSheetName, { views: [{ showGridLines: true }] });

      // Copy column layouts
      if (srcSheet.columns) {
        destSheet.columns = srcSheet.columns.map(col => ({
          header: col.header,
          key: col.key,
          width: col.width,
          style: col.style
        }));
      }

      // Copy rows and cell styles
      srcSheet.eachRow({ includeEmpty: true }, (row, rowNumber) => {
        const destRow = destSheet.getRow(rowNumber);
        destRow.height = row.height;

        row.eachCell({ includeEmpty: true }, (cell, colNumber) => {
          const destCell = destRow.getCell(colNumber);
          destCell.value = cell.value;
          
          // Deep copy styling
          if (cell.style) {
            destCell.style = JSON.parse(JSON.stringify(cell.style));
          }
        });
      });

      // Copy merged cells
      if (srcSheet.model && srcSheet.model.merges) {
        srcSheet.model.merges.forEach(mergeRange => {
          try {
            destSheet.mergeCells(mergeRange);
          } catch (e) {
            // Ignore potential merge boundary errors
          }
        });
      }

      // Copy views (gridlines, etc)
      if (srcSheet.views) {
        destSheet.views = srcSheet.views;
      }
    });
  }

  console.log(`\n💾 Saving consolidated report to: ${OUTPUT_PATH}`);
  await masterWorkbook.xlsx.writeFile(OUTPUT_PATH);
  console.log('✅ Consolidation completed successfully!');
}

mergeReports().catch(err => {
  console.error('❌ Error consolidating reports:', err);
  process.exit(1);
});
