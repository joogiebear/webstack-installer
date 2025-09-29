#!/bin/bash

#############################################
# WEBSTACK ONE-LINE INSTALLER
# Downloads and sets up all scripts
#############################################

REPO="joogiebear/webstack-installer"
BRANCH="main"
INSTALL_DIR="$HOME/webstack-installer"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        📥 WEBSTACK INSTALLER - QUICK SETUP                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "This will download and install all WebStack management tools."
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Warning: Running as root. Installing to /opt instead."
    INSTALL_DIR="/opt/webstack-installer"
fi

# Check for required commands
if ! command -v git &>/dev/null; then
    echo "❌ Git is not installed."
    echo ""
    
    if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
        read -rp "Install git now? [Y/n]: " INSTALL_GIT
        if [[ ! "$INSTALL_GIT" =~ ^[Nn]$ ]]; then
            echo "📦 Installing git..."
            if [ -f /etc/debian_version ]; then
                apt update && apt install -y git
            else
                echo "❌ Unsupported OS. Please install git manually."
                exit 1
            fi
        else
            echo "❌ Git is required. Please install it and try again."
            exit 1
        fi
    else
        echo "💡 Install git with: sudo apt install git"
        exit 1
    fi
fi

# Check if directory exists
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️  Directory $INSTALL_DIR already exists."
    echo ""
    read -rp "Remove and reinstall? [y/N]: " CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    else
        echo ""
        echo "💡 Using existing installation at: $INSTALL_DIR/scripts"
        echo ""
        echo "To update: cd $INSTALL_DIR && git pull"
        echo "To start: cd $INSTALL_DIR/scripts && sudo ./webstack-menu.sh"
        echo ""
        exit 0
    fi
fi

# Clone repository
echo "📥 Downloading WebStack Installer..."
if git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO.git" "$INSTALL_DIR" 2>/dev/null; then
    echo "✅ Download complete"
else
    echo "❌ Failed to clone repository"
    echo ""
    echo "💡 Possible issues:"
    echo "   • No internet connection"
    echo "   • GitHub is unreachable"
    echo "   • Repository is private or moved"
    echo ""
    echo "Try manual installation:"
    echo "  git clone https://github.com/$REPO.git"
    exit 1
fi

# Navigate to scripts directory
cd "$INSTALL_DIR/scripts" || exit 1

# Set permissions
echo "🔒 Setting permissions..."
chmod +x *.sh

# Check if successful
if [ $? -eq 0 ]; then
    SCRIPT_COUNT=$(ls -1 *.sh 2>/dev/null | wc -l)
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          ✅ INSTALLATION SUCCESSFUL!                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📂 Installation location: $INSTALL_DIR"
    echo "📜 Scripts installed: $SCRIPT_COUNT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 QUICK START OPTIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Option 1: Interactive Menu (Recommended)"
    echo "    cd $INSTALL_DIR/scripts"
    echo "    sudo ./webstack-menu.sh"
    echo ""
    echo "  Option 2: Direct Installation"
    echo "    cd $INSTALL_DIR/scripts"
    echo "    sudo ./webstack-installer.sh"
    echo ""
    echo "  Option 3: View Available Scripts"
    echo "    cd $INSTALL_DIR/scripts"
    echo "    ls -lh"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📚 DOCUMENTATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  • Main README:        cat $INSTALL_DIR/README.md"
    echo "  • Documentation:      ls $INSTALL_DIR/docs/"
    echo "  • Examples:           ls $INSTALL_DIR/examples/"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 NEXT STEPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  1. Run the interactive menu:"
    echo "     cd $INSTALL_DIR/scripts && sudo ./webstack-menu.sh"
    echo ""
    echo "  2. Or start installing your first domain:"
    echo "     cd $INSTALL_DIR/scripts && sudo ./webstack-installer.sh"
    echo ""
    echo "  3. Need help? Check the README:"
    echo "     cat $INSTALL_DIR/README.md | less"
    echo ""
    
    # Create convenient symlink if installing system-wide
    if [ "$EUID" -eq 0 ]; then
        echo "🔗 Creating system-wide commands..."
        
        # Create symlinks in /usr/local/bin
        ln -sf "$INSTALL_DIR/scripts/webstack-menu.sh" /usr/local/bin/webstack-menu 2>/dev/null
        ln -sf "$INSTALL_DIR/scripts/webstack-installer.sh" /usr/local/bin/webstack-install 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ System-wide commands created:"
            echo "   • webstack-menu      (launches menu)"
            echo "   • webstack-install   (installs domain)"
            echo ""
            echo "💡 Now you can run 'sudo webstack-menu' from anywhere!"
            echo ""
        fi
    fi
    
else
    echo "❌ Permission setting failed"
    exit 1
fi
