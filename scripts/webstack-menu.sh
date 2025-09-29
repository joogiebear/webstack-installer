#!/bin/bash

# WebStack Menu - Interactive management interface

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_menu() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          🚀 WebStack Installer v2.0                       ║"
    echo "║          Multi-Domain Hosting Management                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${CYAN}📦 DOMAIN MANAGEMENT${NC}"
    echo "  1) Install new domain"
    echo "  2) List all domains"
    echo "  3) Remove domain"
    echo "  4) Domain information"
    echo ""
    echo -e "${CYAN}🔧 MAINTENANCE${NC}"
    echo "  5) Backup domain"
    echo "  6) Restore domain"
    echo "  7) Update domain settings"
    echo ""
    echo -e "${CYAN}📧 EMAIL MANAGEMENT${NC}"
    echo "  8) Setup email server"
    echo "  9) Manage email accounts"
    echo ""
    echo -e "${CYAN}ℹ️  SYSTEM${NC}"
    echo "  10) System status"
    echo "  0) Exit"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

press_enter() {
    echo ""
    read -rp "Press Enter to continue..."
}

while true; do
    show_menu
    read -rp "Select option: " choice
    echo ""
    
    case $choice in
        1)
            if [ -f "$SCRIPT_DIR/webstack-installer.sh" ]; then
                "$SCRIPT_DIR/webstack-installer.sh"
            else
                echo -e "${RED}❌ webstack-installer.sh not found${NC}"
            fi
            press_enter
            ;;
        2)
            if [ -f "$SCRIPT_DIR/list-domains.sh" ]; then
                "$SCRIPT_DIR/list-domains.sh"
            else
                echo -e "${RED}❌ list-domains.sh not found${NC}"
            fi
            press_enter
            ;;
        3)
            if [ -f "$SCRIPT_DIR/remove-domain.sh" ]; then
                "$SCRIPT_DIR/remove-domain.sh"
            else
                echo -e "${RED}❌ remove-domain.sh not found${NC}"
            fi
            press_enter
            ;;
        4)
            if [ -f "$SCRIPT_DIR/domain-info.sh" ]; then
                "$SCRIPT_DIR/domain-info.sh"
            else
                echo -e "${YELLOW}⚠️  domain-info.sh not available${NC}"
            fi
            press_enter
            ;;
        5)
            if [ -f "$SCRIPT_DIR/backup-domain.sh" ]; then
                "$SCRIPT_DIR/backup-domain.sh"
            else
                echo -e "${YELLOW}⚠️  backup-domain.sh not available${NC}"
            fi
            press_enter
            ;;
        6)
            if [ -f "$SCRIPT_DIR/restore-domain.sh" ]; then
                "$SCRIPT_DIR/restore-domain.sh"
            else
                echo -e "${YELLOW}⚠️  restore-domain.sh not available${NC}"
            fi
            press_enter
            ;;
        7)
            if [ -f "$SCRIPT_DIR/update-domain.sh" ]; then
                "$SCRIPT_DIR/update-domain.sh"
            else
                echo -e "${YELLOW}⚠️  update-domain.sh not available${NC}"
            fi
            press_enter
            ;;
        8)
            if [ -f "$SCRIPT_DIR/setup-email.sh" ]; then
                "$SCRIPT_DIR/setup-email.sh"
            else
                echo -e "${YELLOW}⚠️  setup-email.sh not available${NC}"
            fi
            press_enter
            ;;
        9)
            if [ -f "$SCRIPT_DIR/manage-email.sh" ]; then
                "$SCRIPT_DIR/manage-email.sh"
            else
                echo -e "${YELLOW}⚠️  manage-email.sh not available${NC}"
            fi
            press_enter
            ;;
        10)
            echo "System Status:"
            echo ""
            systemctl status apache2 --no-pager -l || true
            echo ""
            systemctl status mysql --no-pager -l || true
            press_enter
            ;;
        0)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            press_enter
            ;;
    esac
done
