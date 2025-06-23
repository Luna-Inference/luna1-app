const fs = require('fs');
const path = require('path');

const srcPath = path.join(__dirname, 'node_modules/pdfjs-dist/build/pdf.worker.mjs');

// Define destination paths for both public and build directories
const publicDir = path.join(__dirname, 'public');
const buildDir = path.join(__dirname, 'build');

const publicDestPath = path.join(publicDir, 'pdf.worker.mjs');
const buildDestPath = path.join(buildDir, 'pdf.worker.mjs');

// Ensure directories exist
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
}

if (!fs.existsSync(buildDir)) {
  fs.mkdirSync(buildDir, { recursive: true });
}

// Copy worker file if source exists
if (fs.existsSync(srcPath)) {
  // Copy to public for development
  fs.copyFileSync(srcPath, publicDestPath);
  console.log('✅ PDF.js worker copied to public directory');
  
  // Copy to build for production if build directory exists
  if (fs.existsSync(buildDir)) {
    fs.copyFileSync(srcPath, buildDestPath);
    console.log('✅ PDF.js worker copied to build directory');
  }
} else {
  console.warn('⚠️ PDF.js worker not found at:', srcPath);
  console.log('Build will continue without PDF worker...');
}