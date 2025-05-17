#!/bin/bash

echo "🧨 Domain Removal Script"

read -rp "Enter the domain name you want to remove (e.g., example.com): " DOMAIN

CONF_PATH="/etc/apache2/sites-available/$DOMAIN.conf"
LE_SSL_CONF="/etc/apache2/sites-available/${DOMAIN}-le-ssl.conf"
SITE_ROOT="/var/www/$DOMAIN"
CRED_FILE="/root/webstack-sites/$DOMAIN/db.txt"
DOMAIN_DIR="/root/webstack-sites/$DOMAIN"

# Disable and delete Apache configs
if [ -f "$CONF_PATH" ]; then
    echo "🔧 Disabling and removing Apache config: $CONF_PATH"
    a2dissite "$DOMAIN.conf"
    rm -f "$CONF_PATH"
else
    echo "⚠️ No Apache config found at $CONF_PATH"
fi

if [ -f "$LE_SSL_CONF" ]; then
    echo "🔧 Disabling and removing SSL config: $LE_SSL_CONF"
    a2dissite "${DOMAIN}-le-ssl.conf"
    rm -f "$LE_SSL_CONF"
else
    echo "⚠️ No Let's Encrypt SSL config found at $LE_SSL_CONF"
fi

systemctl reload apache2

# Remove site files
if [ -d "$SITE_ROOT" ]; then
    echo "🧹 Removing site files from $SITE_ROOT"
    rm -rf "$SITE_ROOT"
else
    echo "⚠️ Site directory not found: $SITE_ROOT"
fi

# Drop database and user
if [ -f "$CRED_FILE" ]; then
    DB_NAME=$(awk '/DB Name:/ {print $3}' "$CRED_FILE")
    DB_USER=$(awk '/DB User:/ {print $3}' "$CRED_FILE")

    echo "🗑 Dropping database and user..."
    mysql -u root <<EOF
DROP DATABASE IF EXISTS \`$DB_NAME\`;
DROP USER IF EXISTS '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
else
    echo "⚠️ No database credentials found for $DOMAIN at $CRED_FILE"
fi

# Delete per-domain credentials folder
if [ -d "$DOMAIN_DIR" ]; then
    echo "🧹 Removing domain credential folder: $DOMAIN_DIR"
    rm -rf "$DOMAIN_DIR"
fi

# Remove Let's Encrypt certificate files
LETSENCRYPT_LIVE="/etc/letsencrypt/live/$DOMAIN"
LETSENCRYPT_ARCHIVE="/etc/letsencrypt/archive/$DOMAIN"
LETSENCRYPT_RENEWAL="/etc/letsencrypt/renewal/$DOMAIN.conf"

if [ -d "$LETSENCRYPT_LIVE" ] || [ -d "$LETSENCRYPT_ARCHIVE" ] || [ -f "$LETSENCRYPT_RENEWAL" ]; then
    echo "🧨 Removing Let's Encrypt certificate files..."
    rm -rf "$LETSENCRYPT_LIVE"
    rm -rf "$LETSENCRYPT_ARCHIVE"
    rm -f "$LETSENCRYPT_RENEWAL"
else
    echo "✅ No Let's Encrypt files found for $DOMAIN"
fi

echo "✅ Domain $DOMAIN fully removed!"
