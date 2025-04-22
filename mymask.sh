#!/bin/bash
# MyMark Setup Script
# This script sets up the MyMark project environment on macOS.
# It will install dependencies (Python, MongoDB, etc.), set up a virtual environment,
# and create the project folder structure with VS Code configuration.
# Usage: Run this script from the root of your VS Code workspace folder (e.g., ./setup_mymark.sh).

set -e

# 1. Ensure the script is running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "This script is intended for macOS (Darwin) only."
  exit 1
fi

echo "== MyMark Environment Setup (macOS) =="

# 2. Install Homebrew if not installed
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing Homebrew (you may be prompted for your password)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add Homebrew to PATH for current session (if not already in PATH)
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "Homebrew is already installed."
  echo "Updating Homebrew..."
  brew update
fi

# 3. Ensure Python3 is installed
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python3 not found. Installing Python3..."
  brew install python
else
  echo "Python3 is already installed."
fi

# 4. Create a Python virtual environment in the workspace
echo "Setting up Python virtual environment (.venv)..."
python3 -m venv .venv
# Activate the virtual environment for the remainder of the script
# shellcheck source=/dev/null
source .venv/bin/activate

# Upgrade pip inside the venv
echo "Upgrading pip..."
pip install --upgrade pip

# 5. Install required Python packages inside the virtual environment
echo "Installing required Python packages (OpenCV, NumPy, Pillow, ImageHash, PyTorch, etc.)..."
pip install numpy opencv-python Pillow ImageHash pymongo web3

# Install PyTorch (for CLIP or deep learning tasks) - this can be a large download
echo "Installing PyTorch (this may take a few minutes)..."
pip install torch torchvision torchaudio

# (Optional) If you prefer TensorFlow for CLIP/FaceNet, you could install TensorFlow instead of or in addition to PyTorch.
# e.g., pip install tensorflow tensorflow-metal (the latter is for Apple Silicon acceleration)

# 6. Install MongoDB for local use (fake user login data)
echo "Installing MongoDB Community Edition..."
brew tap mongodb/brew
brew install mongodb-community
echo "Starting MongoDB service..."
brew services start mongodb/brew/mongodb-community
echo "MongoDB is installed and running (listening on localhost:27017 by default)."

# 7. Install Node.js and Ganache CLI for a local Ethereum blockchain
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js not found. Installing Node.js (for Ganache CLI)..."
  brew install node
else
  echo "Node.js is already installed."
fi

echo "Installing Ganache CLI (local Ethereum blockchain simulator)..."
npm install -g ganache
echo "Ganache CLI installed. (You can run 'ganache' to start an Ethereum blockchain locally.)"

# 8. (Optional) Install Docker for blockchain services like Hyperledger Fabric
echo "Checking Docker installation..."
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found. If you plan to use Hyperledger Fabric or other containerized blockchain, Docker is required."
  read -p "Do you want to install Docker Desktop? (y/N): " install_docker
  if [[ "$install_docker" == "y" || "$install_docker" == "Y" ]]; then
    echo "Installing Docker Desktop (you may be prompted for your password)..."
    brew install --cask docker
    echo "Docker installed. Please launch Docker Desktop to complete setup (you may need to accept its terms)."
  else
    echo "Skipping Docker installation."
  fi
else
  echo "Docker is already installed."
fi

# Note: Hyperledger Fabric local network setup is not automated in this script due to complexity.
# If a Fabric test network is needed, ensure Docker is running and follow Fabric's official setup instructions (e.g., using Fabric samples and bootstrap script).

# 9. Create project folder structure
echo "Creating project directories..."
mkdir -p watermarking detection blockchain
# Create placeholder __init__.py files to mark these as Python packages
touch watermarking/__init__.py detection/__init__.py blockchain/__init__.py

# (Additional directories like 'frontend', 'tests', or 'data' can be created here if needed)

# 10. Configure VS Code settings for the project
echo "Configuring VS Code workspace settings..."
mkdir -p .vscode

# VS Code Settings: set Python interpreter to use the virtual environment and auto-activate it in terminal
cat > .vscode/settings.json << 'EOF'
{
    "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
    "python.terminal.activateEnvironment": true
}
EOF

# VS Code Extensions: recommend useful extensions for this project
cat > .vscode/extensions.json << 'EOF'
{
    "recommendations": [
        "ms-python.python",          // Python support
        "mongodb.mongodb-vscode",    // MongoDB integration
        "ms-azuretools.vscode-docker", // Docker integration (for container services)
        "JuanBlanco.solidity"        // Solidity language support (Ethereum smart contracts)
    ]
}
EOF

# 11. (Optional) Create a .gitignore file to exclude venv, caches, etc.
echo "Setting up .gitignore..."
cat > .gitignore << 'EOF'
# Python virtual environment
.venv/
__pycache__/
*.py[cod]

# VS Code settings
.vscode/

# macOS files
.DS_Store
EOF

# 12. Completion message
echo "MyMark project environment setup complete!"
echo "You can now open this folder in Visual Studio Code. The Python virtual environment is in '.venv' (VS Code is configured to use it)."
echo "MongoDB is running locally for user login data, and a local blockchain (Ganache Ethereum) is available."
echo "Happy coding with MyMark!"