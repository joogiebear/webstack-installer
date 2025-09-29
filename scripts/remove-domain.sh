#!/bin/bash

# Remove Domain Script - Clean removal of web hosting setup

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          🗑️  Remove Domain                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Get domain name
read -rp "🌐 Enter domain name to remove: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Domain name cannot be empty${NC}"
    exit 1
fi

# Create username from domain
USERNAME=$(echo "$DOMAIN" | sed 's/\.//g' | cut -c1-32)

# Check if domain exists
if [ ! -d "/var/www/$USERNAME" ]; then
    echo -e "${RED}❌ Domain $DOMAIN not found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}⚠️  WARNING: This will remove:${NC}"
echo "   • Website files: /var/www/$USERNAME"
echo "   • Apache configuration"
echo "   • Database: ${USERNAME}_db"
echo "   • System user: $USERNAME"
echo ""
echo -e "${RED}This action cannot be undone!${NC}"
echo ""

read -rp "Type 'DELETE' to confirm removal: " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "Removal cancelled"
    exit 0
fi

# Disable Apache site
echo -e "${BLUE}🔧 Disabling Apache site...${NC}"
a2dissite "$DOMAIN" > /dev/null 2>&1 || true
systemctl reload apache2

# Remove Apache config
echo -e "${BLUE}📝 Removing Apache configuration...${NC}"
rm -f "/etc/apache2/sites-available/$DOMAIN.conf"
rm -f "/etc/apache2/sites-enabled/$DOMAIN.conf"

# Remove database
echo -e "${BLUE}🗄️  Removing database...${NC}"
DB_NAME="${USERNAME}_db"
DB_USER="${USERNAME}_user"

mysql -u root <<EOF
DROP DATABASE IF EXISTS \`$DB_NAME\`;
DROP USER IF EXISTS '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Remove system user
echo -e "${BLUE}👤 Removing system user...${NC}"
userdel "$USERNAME" 2>/dev/null || true

# Remove website files
echo -e "${BLUE}🗑️  Removing website files...${NC}"
rm -rf "/var/www/$USERNAME"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          ✅ REMOVAL COMPLETE!                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Domain $DOMAIN has been completely removed${NC}"
echo ""
