#!/bin/bash

# WebStack Installer - One-line installation script

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

REPO="YOUR-USERNAME/webstack-installer"
BRANCH="main"
INSTALL_DIR="$HOME/webstack-installer"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          🚀 WebStack Installer                            ║"
echo "║          Quick Install                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check for git
if ! command -v git &>/dev/null; then
    echo "📦 Installing git..."
    if [ -f /etc/debian_version ]; then
        apt update && apt install -y git
    else
        echo -e "${RED}❌ Unsupported OS. Please install git manually.${NC}"
        exit 1
    fi
fi

# Clone or update repository
if [ -d "$INSTALL_DIR" ]; then
    echo "📥 Updating existing installation..."
    cd "$INSTALL_DIR" && git pull
else
    echo "📥 Downloading WebStack Installer..."
    git clone --depth 1 "https://github.com/$REPO.git" "$INSTALL_DIR"
fi

# Set permissions
cd "$INSTALL_DIR"
chmod +x *.sh

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "🚀 Get started:"
echo "   cd $INSTALL_DIR"
echo "   sudo ./webstack-menu.sh"
echo ""
