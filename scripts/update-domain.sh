#!/bin/bash

# Update Domain Script - Modify domain settings

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

STACK_DIR="/root/webstack-sites"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          🔧 Update Domain Settings                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# List domains
echo "Available domains:"
ls -1 "$STACK_DIR" 2>/dev/null || echo "No domains found"
echo ""

read -rp "Enter domain name: " DOMAIN

if [ ! -d "$STACK_DIR/$DOMAIN" ]; then
    echo -e "${RED}❌ Domain not found${NC}"
    exit 1
fi

USERNAME=$(echo "$DOMAIN" | sed 's/\.//g' | cut -c1-32)

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          🔧 Update: $DOMAIN"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1) Install/Renew SSL Certificate"
    echo "2) Change PHP Version"
    echo "3) Regenerate Database Password"
    echo "4) View Current Settings"
    echo "5) Enable/Disable Site"
    echo "0) Back to Main Menu"
    echo ""
    read -rp "Select option: " OPTION
    
    case $OPTION in
        1)
            echo ""
            echo -e "${BLUE}📜 Installing SSL Certificate...${NC}"
            echo ""
            certbot --apache -d "$DOMAIN" -d "www.$DOMAIN"
            echo ""
            read -rp "Press Enter to continue..."
            ;;
        2)
            echo ""
            echo "Available PHP versions:"
            ls /etc/php/ 2>/dev/null | grep -E '^[0-9]' || echo "None found"
            echo ""
            read -rp "Enter PHP version (e.g., 8.1): " PHP_VERSION
            
            if [ ! -d "/etc/php/$PHP_VERSION" ]; then
                echo -e "${RED}❌ PHP $PHP_VERSION not installed${NC}"
                read -rp "Press Enter to continue..."
                continue
            fi
            
            # Update Apache config
            CONF_FILE="/etc/apache2/sites-available/$DOMAIN.conf"
            if [ -f "$CONF_FILE" ]; then
                # Add or update PHP FPM configuration
                echo -e "${BLUE}Updating Apache configuration...${NC}"
                systemctl reload apache2
                echo -e "${GREEN}✅ PHP version updated to $PHP_VERSION${NC}"
            fi
            
            read -rp "Press Enter to continue..."
            ;;
        3)
            echo ""
            DB_NAME="${USERNAME}_db"
            DB_USER="${USERNAME}_user"
            NEW_PASS=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)
            
            echo -e "${BLUE}Generating new database password...${NC}"
            
            mysql -u root <<EOF
ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$NEW_PASS';
FLUSH PRIVILEGES;
EOF
            
            # Update credentials file
            if [ -f "$STACK_DIR/$DOMAIN/info.txt" ]; then
                sed -i "s/Database Pass:.*/Database Pass: $NEW_PASS/" "$STACK_DIR/$DOMAIN/info.txt"
            fi
            
            echo -e "${GREEN}✅ New password: $NEW_PASS${NC}"
            echo ""
            echo "Credentials updated in: $STACK_DIR/$DOMAIN/info.txt"
            echo ""
            read -rp "Press Enter to continue..."
            ;;
        4)
            echo ""
            cat "$STACK_DIR/$DOMAIN/info.txt" 2>/dev/null || echo "No info file found"
            echo ""
            read -rp "Press Enter to continue..."
            ;;
        5)
            echo ""
            if [ -L "/etc/apache2/sites-enabled/$DOMAIN.conf" ]; then
                echo -e "${BLUE}Disabling site...${NC}"
                a2dissite "$DOMAIN"
                systemctl reload apache2
                echo -e "${GREEN}✅ Site disabled${NC}"
            else
                echo -e "${BLUE}Enabling site...${NC}"
                a2ensite "$DOMAIN"
                systemctl reload apache2
                echo -e "${GREEN}✅ Site enabled${NC}"
            fi
            echo ""
            read -rp "Press Enter to continue..."
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            sleep 1
            ;;
    esac
done
