#!/bin/bash

# Backup Domain Script - Backup website files and database

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

STACK_DIR="/root/webstack-sites"
BACKUP_DIR="/root/backups"

mkdir -p "$BACKUP_DIR"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          💾 Domain Backup                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "1) Backup specific domain"
echo "2) Backup all domains"
echo ""
read -rp "Select option: " BACKUP_OPTION

backup_domain() {
    local DOMAIN=$1
    local USERNAME=$(echo "$DOMAIN" | sed 's/\.//g' | cut -c1-32)
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    local BACKUP_PATH="$BACKUP_DIR/${DOMAIN}_${TIMESTAMP}"
    
    echo ""
    echo -e "${BLUE}📦 Backing up $DOMAIN...${NC}"
    
    mkdir -p "$BACKUP_PATH"
    
    # Backup website files
    echo -e "${BLUE}  • Backing up files...${NC}"
    tar -czf "$BACKUP_PATH/files.tar.gz" -C "/var/www/$USERNAME" . 2>/dev/null || true
    
    # Backup database
    if [ -f "$STACK_DIR/$DOMAIN/info.txt" ]; then
        DB_NAME=$(grep "Database:" "$STACK_DIR/$DOMAIN/info.txt" | awk '{print $2}')
        if [ -n "$DB_NAME" ]; then
            echo -e "${BLUE}  • Backing up database...${NC}"
            mysqldump "$DB_NAME" | gzip > "$BACKUP_PATH/database.sql.gz" 2>/dev/null || true
        fi
    fi
    
    # Backup Apache config
    CONF_FILE="/etc/apache2/sites-available/$DOMAIN.conf"
    if [ -f "$CONF_FILE" ]; then
        echo -e "${BLUE}  • Backing up Apache config...${NC}"
        cp "$CONF_FILE" "$BACKUP_PATH/apache.conf"
    fi
    
    # Backup domain info
    if [ -f "$STACK_DIR/$DOMAIN/info.txt" ]; then
        cp "$STACK_DIR/$DOMAIN/info.txt" "$BACKUP_PATH/domain-info.txt"
    fi
    
    # Create backup info file
    cat > "$BACKUP_PATH/BACKUP_INFO.txt" <<EOF
Backup Information
══════════════════════════════════════════
Domain: $DOMAIN
Backup Date: $(date)
Backup Path: $BACKUP_PATH

Contents:
- files.tar.gz (Website files)
- database.sql.gz (MySQL database)
- apache.conf (Apache configuration)
- domain-info.txt (Domain credentials)

Restore Instructions:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Use the restore script:
  sudo ./restore-domain.sh

Or manually:
1. Extract files: tar -xzf files.tar.gz -C /var/www/$USERNAME/
2. Import database: gunzip < database.sql.gz | mysql $DB_NAME
3. Copy Apache config: cp apache.conf /etc/apache2/sites-available/$DOMAIN.conf
4. Enable site: a2ensite $DOMAIN && systemctl reload apache2
EOF
    
    # Calculate backup size
    BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | awk '{print $1}')
    
    echo -e "${GREEN}  ✅ Backup complete: $BACKUP_PATH ($BACKUP_SIZE)${NC}"
}

case $BACKUP_OPTION in
    1)
        echo ""
        read -rp "Enter domain to backup: " DOMAIN
        
        if [ ! -d "$STACK_DIR/$DOMAIN" ]; then
            echo -e "${RED}❌ Domain not found${NC}"
            exit 1
        fi
        
        backup_domain "$DOMAIN"
        ;;
    2)
        echo ""
        echo -e "${BLUE}📦 Backing up all domains...${NC}"
        
        COUNT=0
        for DOMAIN_DIR in "$STACK_DIR"/*/; do
            if [ -d "$DOMAIN_DIR" ]; then
                DOMAIN=$(basename "$DOMAIN_DIR")
                backup_domain "$DOMAIN"
                COUNT=$((COUNT + 1))
            fi
        done
        
        echo ""
        echo -e "${GREEN}✅ Backed up $COUNT domains${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Backups stored in: $BACKUP_DIR"
echo ""
