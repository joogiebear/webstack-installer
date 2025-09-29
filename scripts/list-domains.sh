#!/bin/bash

# List all managed domains

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          📋 Managed Domains                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -d "/var/www" ]; then
    echo "No domains found"
    exit 0
fi

COUNT=0

for USER_DIR in /var/www/*/; do
    if [ -d "$USER_DIR" ] && [ "$USER_DIR" != "/var/www/html/" ]; then
        USERNAME=$(basename "$USER_DIR")
        
        # Find domain from Apache config
        CONF_FILE=$(find /etc/apache2/sites-available/ -name "*.conf" -exec grep -l "DocumentRoot.*$USERNAME" {} \; 2>/dev/null | head -n 1)
        
        if [ -n "$CONF_FILE" ]; then
            DOMAIN=$(grep "ServerName" "$CONF_FILE" | head -n 1 | awk '{print $2}')
            
            # Get site info
            SITE_ROOT="/var/www/$USERNAME/public_html"
            DB_CREDS="/var/www/$USERNAME/db-credentials.txt"
            
            if [ -f "$DB_CREDS" ]; then
                DB_NAME=$(grep "Database Name:" "$DB_CREDS" | awk '{print $3}')
            else
                DB_NAME="N/A"
            fi
            
            # Check if site is enabled
            if [ -L "/etc/apache2/sites-enabled/$(basename "$CONF_FILE")" ]; then
                STATUS="${GREEN}✅ Active${NC}"
            else
                STATUS="${YELLOW}⏸️  Disabled${NC}"
            fi
            
            # Get disk usage
            DISK_USAGE=$(du -sh "$USER_DIR" 2>/dev/null | awk '{print $1}')
            
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GREEN}Domain:${NC} $DOMAIN"
            echo -e "Status: $STATUS"
            echo -e "User: $USERNAME"
            echo -e "Database: $DB_NAME"
            echo -e "Disk Usage: $DISK_USAGE"
            echo -e "Root: $SITE_ROOT"
            
            COUNT=$((COUNT + 1))
        fi
    fi
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Total domains: $COUNT"
echo ""
