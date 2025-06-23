const fs = require('fs');
const path = require('path');

const srcPath = path.join(__dirname, 'node_modules/pdfjs-dist/build/pdf.worker.mjs');
const destDir = path.join(__dirname, 'build');
const destPath = path.join(destDir, 'pdf.worker.mjs');

// Ensure build directory exists
if (!fs.existsSync(destDir)) {
  fs.mkdirSync(destDir, { recursive: true });
}

if (fs.existsSync(srcPath)) {
  fs.copyFileSync(srcPath, destPath);
  console.log(' PDF.js worker copied to build directory');
} else {
  console.warn('  PDF.js worker not found at:', srcPath);
  console.log('Build will continue without PDF worker...');
}