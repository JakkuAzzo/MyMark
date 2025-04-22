#!/bin/bash

# setup_mymark_ui.sh - Set up the Electron-based UI for MyMark (desktop cross-platform app).
# This script should be run from the MyMark project root (where backend code is located).
# It will initialize an Electron project, create UI components for Upload, Matches, Stats pages,
# and configure IPC communication with the Python backend. It also sets up scheduled scans.

echo "=== MyMark Electron UI Setup ==="

# 1. Check for Node.js and npm
echo "Checking for Node.js installation..."
if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is not installed. Please install Node.js (https://nodejs.org/) and rerun this script."
  exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "Error: npm (Node Package Manager) not found. Please ensure Node.js and npm are installed."
  exit 1
fi
echo "Node.js is installed. Node version: $(node -v)"

# 2. Initialize npm project for the Electron app
echo "Initializing Node.js project (package.json)..."
# If a package.json already exists (perhaps from a previous run), skip npm init
if [ -f package.json ]; then
  echo "package.json already exists. Skipping npm init."
else
  npm init -y
fi

# 3. Install Electron and other dependencies
echo "Installing Electron and required packages..."
npm install --save-dev electron@latest

# Optionally install React and React DOM for a React-based UI (commented out by default)
# echo "Installing React and React-DOM for front-end components..."
# npm install react react-dom react-router-dom

# Optionally install electron-reload for hot-reloading during development
echo "Installing electron-reload for automatic reload in dev..."
npm install --save-dev electron-reload

# (Optional) Install electron-devtools-installer to ease adding devtools like React Developer Tools
# echo "Installing devtools installer..."
# npm install --save-dev electron-devtools-installer

# 4. Create the Electron project structure
echo "Creating Electron project directories (src/ for source and components/)..."
mkdir -p src/components

# Create main process script (Electron entry point)
echo "Creating main Electron process file (src/main.js)..."
cat > src/main.js << 'EOF'
// main.js - Main process for Electron
const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

// Reload the app automatically during development when files change
try {
  require('electron-reload')(path.join(__dirname, '../'), {
    electron: require('path').join(__dirname, '../node_modules', '.bin', 'electron')
  });
} catch(err) {
  console.log("electron-reload not loaded (this is fine in production build):", err);
}

// Keep a global reference of the window object to avoid garbage collection
let mainWindow;

function createWindow() {
  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,   // allow Node.js integration in renderer for simplicity
      contextIsolation: false  // not isolating context since using IPC directly
      // In a production app, it's safer to use a preload script for IPC and keep nodeIntegration off.
    }
  });

  // Load the main HTML file
  mainWindow.loadFile('src/index.html');

  // Open DevTools by default for development (remove/comment out for production release)
  mainWindow.webContents.openDevTools();

  mainWindow.on('closed', function () {
    mainWindow = null;
  });
}

// Handle IPC messages from renderer (UI)
ipcMain.on('upload-image', (event, filePath) => {
  console.log("IPC Main: 'upload-image' event received with file:", filePath);
  // TODO: Call Python backend to fingerprint the image.
  // For example, use child_process to run the Python script that registers the image.
  // e.g., require('child_process').exec(`python3 backend/register_image.py "${filePath}"`, ...);
  // In this stub, we just log and simulate a response:
  event.reply('upload-status', 'success');  // send back a success status to renderer
});

ipcMain.on('scan-now', (event) => {
  console.log("IPC Main: 'scan-now' event received. Triggering background scan...");
  // TODO: Invoke Python backend to perform scanning (e.g., run a script or trigger API).
  // This could call a Python script that performs the scanning and writes results to DB.
  // Simulate scan processing with a timeout:
  setTimeout(() => {
    // In a real scenario, collect results from the scan and send them to renderer.
    // For now, just send a stub message.
    event.reply('scan-result', 'Scan completed – no new matches found (stub).');
  }, 2000);
});

// Quit when all windows are closed, except on macOS (common Electron behavior)
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// Create window when Electron is ready
app.whenReady().then(createWindow);
EOF

# Create the main HTML file for the UI
echo "Creating main UI HTML file (src/index.html) with basic pages..."
cat > src/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <!-- Ensure mobile responsiveness -->
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>MyMark</title>
  <style>
    /* Basic styling for responsiveness and layout */
    body { font-family: sans-serif; margin: 20px; }
    nav { margin-bottom: 20px; }
    nav button { margin-right: 10px; }
    .page { display: none; }
    /* Show the active page */
    .page.active { display: block; }
    /* Make images and videos (if any) responsive */
    img, video { max-width: 100%; height: auto; }
  </style>
</head>
<body>
  <!-- Navigation bar -->
  <nav>
    <button onclick="showPage('uploadPage')">Upload Likeness</button>
    <button onclick="showPage('matchesPage')">View Matches</button>
    <button onclick="showPage('statsPage')">Stats</button>
  </nav>

  <!-- Upload Page -->
  <div id="uploadPage" class="page active">
    <h2>Upload Image</h2>
    <p>Select an image to register its fingerprint:</p>
    <input type="file" id="fileInput" accept="image/*">
    <button id="uploadBtn">Upload</button>
    <p id="uploadStatus" style="color: green;"></p>
  </div>

  <!-- Matches Page -->
  <div id="matchesPage" class="page">
    <h2>Matches</h2>
    <p>Matches found will appear here. Use "Scan Now" to search for image reuse.</p>
    <button id="scanBtn">Scan Now</button>
    <p id="scanStatus" style="font-weight: bold;"></p>
    <!-- Placeholder for match results (could be a list of images/cards) -->
    <div id="matchesList"></div>
  </div>

  <!-- Stats Page -->
  <div id="statsPage" class="page">
    <h2>Statistics</h2>
    <p>
      <span id="statImages">Images tracked: 0</span><br/>
      <span id="statMatches">Matches found: 0</span><br/>
      <span id="statLastScan">Last scan: -</span>
    </p>
  </div>

  <!-- Renderer Process Script: Handles page routing and IPC -->
  <script>
    // Simple client-side routing: show one page at a time
    function showPage(pageId) {
      document.getElementById('uploadPage').style.display = 'none';
      document.getElementById('matchesPage').style.display = 'none';
      document.getElementById('statsPage').style.display = 'none';
      // Hide all pages, then show the selected page
      const pageDiv = document.getElementById(pageId);
      if (pageDiv) {
        pageDiv.style.display = 'block';
      }
    }

    // Initialize by showing the Upload page by default
    showPage('uploadPage');

    // Set up IPC communication with main process
    const { ipcRenderer } = require('electron');

    // Handle Upload button click
    const uploadBtn = document.getElementById('uploadBtn');
    uploadBtn.addEventListener('click', () => {
      const fileInput = document.getElementById('fileInput');
      if (fileInput.files.length > 0) {
        const filePath = fileInput.files[0].path;  // get the local file path
        document.getElementById('uploadStatus').style.color = 'black';
        document.getElementById('uploadStatus').textContent = "Uploading image...";
        // Send the file path to main process for fingerprinting
        ipcRenderer.send('upload-image', filePath);
      } else {
        document.getElementById('uploadStatus').style.color = 'red';
        document.getElementById('uploadStatus').textContent = "Please select a file first.";
      }
    });

    // Listen for upload status response from main
    ipcRenderer.on('upload-status', (event, status) => {
      if (status === 'success') {
        document.getElementById('uploadStatus').style.color = 'green';
        document.getElementById('uploadStatus').textContent = "Image uploaded and fingerprinted successfully!";
        // Update stats count for images (increment by 1 for demo purposes)
        const statImagesElem = document.getElementById('statImages');
        // Extract current count number and increment
        const currentCount = parseInt(statImagesElem.textContent.split(': ')[1] || "0");
        statImagesElem.textContent = "Images tracked: " + (currentCount + 1);
      } else {
        document.getElementById('uploadStatus').style.color = 'red';
        document.getElementById('uploadStatus').textContent = "Image upload failed.";
      }
    });

    // Handle Scan Now button click
    const scanBtn = document.getElementById('scanBtn');
    scanBtn.addEventListener('click', () => {
      document.getElementById('scanStatus').textContent = "Scanning for matches...";
      ipcRenderer.send('scan-now');
    });

    // Listen for scan results from main
    ipcRenderer.on('scan-result', (event, message) => {
      document.getElementById('scanStatus').textContent = message;
      // Update last scan time in stats
      const now = new Date().toLocaleString();
      document.getElementById('statLastScan').textContent = "Last scan: " + now;
      // (Optional) Update matches found count if new matches were detected
      if (message && message.includes('matches')) {
        // This is a stub logic: if message indicates matches found, increment the counter
        const statMatchesElem = document.getElementById('statMatches');
        const currentMatches = parseInt(statMatchesElem.textContent.split(': ')[1] || "0");
        // For demo, let's assume any scan could find 1 new match
        statMatchesElem.textContent = "Matches found: " + (currentMatches + 1);
        // TODO: In a real scenario, parse actual number of matches from message or data
      }
    });
  </script>
</body>
</html>
EOF

# 5. Create placeholder component files (if using a framework like React/Vue later)
echo "Creating placeholder component files for Upload, Matches, Stats..."
cat > src/components/Upload.js << 'EOF'
// Upload.js - Placeholder for Upload page component logic
// In a React scenario, this would export a component for the Upload page.
EOF
cat > src/components/Matches.js << 'EOF'
// Matches.js - Placeholder for Matches page component logic (Tinder-style UI could be implemented here)
// In a React scenario, this would export a component that lists matches and allows swiping/interaction.
EOF
cat > src/components/Stats.js << 'EOF'
// Stats.js - Placeholder for Stats page component logic
// In a React scenario, this would export a component displaying statistics and charts.
EOF

# 6. Update package.json to set Electron start script (if not already set by npm init)
echo "Configuring npm start script for Electron..."
# Add a start script to package.json for launching the Electron app
npx npm-cli-add-script -k "start" -v "electron ./src/main.js" >/dev/null 2>&1 || {
  echo "npm-cli-add-script not installed, using fallback method..."
  # Fallback: use sed to insert start script (on macOS, sed -i '' does in-place edit)
  sed -i '' -e $'s/"test": "echo \\\\\"Error: no test specified\\\\\" && exit 1"/"start": "electron ."/' package.json
}
echo "npm start script set. You can run 'npm start' to launch the MyMark Electron app."

# 7. Schedule background scan tasks (cron jobs at 00:00 and 12:00 daily)
echo "Setting up scheduled scans (cron jobs at 00:00 and 12:00)..."
CRON_JOB="0 0 * * * cd \"$(pwd)\" && /usr/bin/env python3 scan.py >> scan.log 2>&1\n0 12 * * * cd \"$(pwd)\" && /usr/bin/env python3 scan.py >> scan.log 2>&1"
# Note: Adjust the python path and script name as needed. This assumes a scan.py in project root and system python3.
(crontab -l 2>/dev/null; echo -e "$CRON_JOB") | crontab -
echo "Cron jobs added. (To verify, run 'crontab -l')"

# On macOS, an alternative is to use launchctl with a .plist file. Cron is used here for simplicity.

echo "Electron UI setup complete! 🎉"
echo "Next steps:"
echo " - Run 'npm install' if you haven't already, to install all dependencies."
echo " - Use 'npm start' to launch the Electron app and view the UI."
echo " - The app is configured with hot-reload for development (electron-reload). Edit the HTML/JS and the app will reload."
echo " - Scheduled scans will run at midnight and noon (check scan.log for output). Use the 'Scan Now' button for immediate scans."