# Luna App

A React-based chat application built with TypeScript and modern web technologies.

## Prerequisites

- Node.js (version 16 or higher)
- npm (comes with Node.js)

## Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   npm install
   ```

## Running the Application

### Development Mode (Web)
```bash
npm start
```
This runs the app in development mode. Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

The page will reload automatically when you make changes, and you'll see any lint errors in the console.

### Electron App (Development)
```bash
npm run electron-dev
```
This starts the Electron desktop application with the React dev server. The app will be accessible on all network interfaces at port 3000.

### Testing
```bash
npm test
```
Launches the test runner in interactive watch mode.

### Production Build (Web)
```bash
npm run build
```
Builds the app for production to the `build` folder. The build is optimized and minified for the best performance.

### Build Electron App (Windows Installer)
```bash
npm run electron-pack
```
Creates a Windows installer for the Electron desktop application. The installer will be generated in the `dist/` folder.

## Project Structure

- `src/` - Source code
- `public/` - Public assets
- `package.json` - Dependencies and scripts
- `tsconfig.json` - TypeScript configuration

## Technologies Used

- React 19
- TypeScript
- Lucide React (icons)
- React Markdown
- Create React App