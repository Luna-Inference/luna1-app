const fs = require('fs');
const path = require('path');

const srcPath = path.join(__dirname, 'node_modules/pdfjs-dist/build/pdf.worker.mjs');
const destPath = path.join(__dirname, 'build/pdf.worker.mjs');

if (fs.existsSync(srcPath)) {
  fs.copyFileSync(srcPath, destPath);
  console.log('PDF.js worker copied to build directory');
} else {
  console.error('PDF.js worker not found at:', srcPath);
}