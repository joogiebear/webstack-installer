#!/bin/bash

# Restore Domain Script - Restore from backup

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

BACKUP_DIR="/root/backups"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          🔄 Domain Restore                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# List available backups
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    echo -e "${RED}❌ No backups found in $BACKUP_DIR${NC}"
    exit 1
fi

echo "Available backups:"
echo ""

BACKUPS=()
INDEX=1

for BACKUP in "$BACKUP_DIR"/*/ ; do
    if [ -d "$BACKUP" ]; then
        BACKUP_NAME=$(basename "$BACKUP")
        BACKUP_SIZE=$(du -sh "$BACKUP" | awk '{print $1}')
        BACKUP_DATE=$(stat -c %y "$BACKUP" | cut -d' ' -f1,2 | cut -d'.' -f1)
        
        echo "$INDEX) $BACKUP_NAME"
        echo "   Size: $BACKUP_SIZE | Date: $BACKUP_DATE"
        
        if [ -f "$BACKUP/BACKUP_INFO.txt" ]; then
            DOMAIN=$(grep "Domain:" "$BACKUP/BACKUP_INFO.txt" | cut -d' ' -f2)
            echo "   Domain: $DOMAIN"
        fi
        echo ""
        
        BACKUPS+=("$BACKUP_NAME")
        INDEX=$((INDEX + 1))
    fi
done

read -rp "Select backup number to restore: " BACKUP_NUM

if [ "$BACKUP_NUM" -lt 1 ] || [ "$BACKUP_NUM" -gt "${#BACKUPS[@]}" ]; then
    echo -e "${RED}❌ Invalid selection${NC}"
    exit 1
fi

SELECTED_BACKUP="${BACKUPS[$((BACKUP_NUM - 1))]}"
BACKUP_PATH="$BACKUP_DIR/$SELECTED_BACKUP"

echo ""
echo -e "${BLUE}Selected backup: $SELECTED_BACKUP${NC}"
echo ""

# Extract domain from backup
ORIGINAL_DOMAIN=$(grep "Domain:" "$BACKUP_PATH/BACKUP_INFO.txt" 2>/dev/null | awk '{print $2}')

if [ -z "$ORIGINAL_DOMAIN" ]; then
    # Try to extract from backup name
    ORIGINAL_DOMAIN=$(echo "$SELECTED_BACKUP" | sed 's/_[0-9]\{8\}_[0-9]\{6\}$//')
fi

echo "Original domain: $ORIGINAL_DOMAIN"
echo ""
echo "Restore options:"
echo "1) Full restore (overwrite existing $ORIGINAL_DOMAIN)"
echo "2) Restore to new domain name"
echo "3) Files only"
echo "4) Database only"
echo ""
read -rp "Select option: " RESTORE_OPTION

case $RESTORE_OPTION in
    1)
        TARGET_DOMAIN="$ORIGINAL_DOMAIN"
        RESTORE_TYPE="full"
        ;;
    2)
        read -rp "Enter new domain name: " TARGET_DOMAIN
        RESTORE_TYPE="full"
        ;;
    3)
        TARGET_DOMAIN="$ORIGINAL_DOMAIN"
        RESTORE_TYPE="files"
        ;;
    4)
        TARGET_DOMAIN="$ORIGINAL_DOMAIN"
        RESTORE_TYPE="database"
        ;;
    *)
        echo -e "${RED}❌ Invalid option${NC}"
        exit 1
        ;;
esac

USERNAME=$(echo "$TARGET_DOMAIN" | sed 's/\.//g' | cut -c1-32)
SITE_ROOT="/var/www/$USERNAME/public_html"

echo ""
echo -e "${YELLOW}⚠️  Warning: This will restore to $TARGET_DOMAIN${NC}"
echo ""
read -rp "Continue? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Restore cancelled"
    exit 0
fi

# Restore files
if [[ "$RESTORE_TYPE" == "full" ]] || [[ "$RESTORE_TYPE" == "files" ]]; then
    echo -e "${BLUE}📂 Restoring files...${NC}"
    
    if [ -f "$BACKUP_PATH/files.tar.gz" ]; then
        mkdir -p "/var/www/$USERNAME"
        tar -xzf "$BACKUP_PATH/files.tar.gz" -C "/var/www/$USERNAME"
        echo -e "${GREEN}  ✅ Files restored${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No files backup found${NC}"
    fi
fi

# Restore database
if [[ "$RESTORE_TYPE" == "full" ]] || [[ "$RESTORE_TYPE" == "database" ]]; then
    echo -e "${BLUE}🗄️  Restoring database...${NC}"
    
    if [ -f "$BACKUP_PATH/database.sql.gz" ]; then
        DB_NAME="${USERNAME}_db"
        
        # Create database if it doesn't exist
        mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
        
        # Restore database
        gunzip < "$BACKUP_PATH/database.sql.gz" | mysql "$DB_NAME"
        echo -e "${GREEN}  ✅ Database restored${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No database backup found${NC}"
    fi
fi

# Restore Apache config
if [[ "$RESTORE_TYPE" == "full" ]]; then
    echo -e "${BLUE}⚙️  Restoring Apache config...${NC}"
    
    if [ -f "$BACKUP_PATH/apache.conf" ]; then
        # If restoring to new domain, update the config
        if [ "$TARGET_DOMAIN" != "$ORIGINAL_DOMAIN" ]; then
            sed "s/$ORIGINAL_DOMAIN/$TARGET_DOMAIN/g" "$BACKUP_PATH/apache.conf" > "/etc/apache2/sites-available/$TARGET_DOMAIN.conf"
        else
            cp "$BACKUP_PATH/apache.conf" "/etc/apache2/sites-available/$TARGET_DOMAIN.conf"
        fi
        
        a2ensite "$TARGET_DOMAIN" > /dev/null 2>&1
        systemctl reload apache2
        echo -e "${GREEN}  ✅ Apache config restored${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No Apache config found${NC}"
    fi
fi

# Set permissions
chown -R www-data:www-data "/var/www/$USERNAME"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          ✅ RESTORATION COMPLETE!                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Domain: $TARGET_DOMAIN${NC}"
echo -e "${GREEN}Files: $SITE_ROOT${NC}"
echo ""

if [ "$TARGET_DOMAIN" != "$ORIGINAL_DOMAIN" ]; then
    echo -e "${YELLOW}💡 Restored to NEW domain. Remember to:${NC}"
    echo "   1. Update DNS records for $TARGET_DOMAIN"
    echo "   2. Install SSL: certbot --apache -d $TARGET_DOMAIN"
    echo "   3. Check database for old domain references"
fi

echo ""
