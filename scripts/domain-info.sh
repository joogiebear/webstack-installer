#!/bin/bash

# Domain Info Script - View domain credentials and settings

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

STACK_DIR="/root/webstack-sites"

# Check if domain argument provided
if [ -z "$1" ]; then
    echo ""
    echo "Usage: sudo ./domain-info.sh [domain]"
    echo ""
    echo "Example: sudo ./domain-info.sh example.com"
    echo ""
    echo "Available domains:"
    ls -1 "$STACK_DIR" 2>/dev/null || echo "No domains found"
    echo ""
    exit 1
fi

DOMAIN=$1
INFO_FILE="$STACK_DIR/$DOMAIN/info.txt"

if [ ! -f "$INFO_FILE" ]; then
    echo ""
    echo "❌ Domain '$DOMAIN' not found or info file missing."
    echo ""
    exit 1
fi

# Display the info file with nice formatting
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          📋 Domain Information: $DOMAIN"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
cat "$INFO_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📂 Additional Files:"
[ -f "$STACK_DIR/$DOMAIN/sftp-guide.txt" ] && echo "  • SFTP Guide: $STACK_DIR/$DOMAIN/sftp-guide.txt"
[ -f "$STACK_DIR/$DOMAIN/email-settings.txt" ] && echo "  • Email Settings: $STACK_DIR/$DOMAIN/email-settings.txt"
[ -f "$STACK_DIR/$DOMAIN/db-credentials.txt" ] && echo "  • Database Backup: $STACK_DIR/$DOMAIN/db-credentials.txt"
echo ""
echo "📊 Quick Stats:"
USERNAME=$(grep "Username:" "$INFO_FILE" | awk '{print $2}')
if [ -n "$USERNAME" ]; then
    DISK_USAGE=$(du -sh "/var/www/$USERNAME" 2>/dev/null | awk '{print $1}')
    echo "  • Disk Usage: $DISK_USAGE"
fi
echo ""
