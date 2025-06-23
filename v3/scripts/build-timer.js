const { execSync } = require('child_process');

console.time('Total Build Time');

try {
  console.log('📦 Building React app...');
  console.time('React Build');
  execSync('npm run build', { stdio: 'inherit' });
  console.timeEnd('React Build');
  
  console.log('⚡ Building Electron app...');
  console.time('Electron Build');
  execSync('npx electron-builder --publish=never', { stdio: 'inherit' });
  console.timeEnd('Electron Build');
} catch (error) {
  console.error('Build failed:', error.message);
  process.exit(1);
}

console.timeEnd('Total Build Time');
