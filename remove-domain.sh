#!/bin/bash

echo "🧨 Domain Removal Script"

read -rp "Enter the domain name you want to remove (e.g., example.com): " DOMAIN

CONF_PATH="/etc/apache2/sites-available/$DOMAIN.conf"
SITE_ROOT="/var/www/$DOMAIN"
CRED_FILE="/root/webstack-sites/$DOMAIN/db.txt"
DOMAIN_DIR="/root/webstack-sites/$DOMAIN"

# Apache config removal
if [ -f "$CONF_PATH" ]; then
    echo "🔧 Disabling and removing Apache config..."
    a2dissite "$DOMAIN.conf"
    rm -f "$CONF_PATH"
    systemctl reload apache2
else
    echo "❌ Apache config not found for $DOMAIN"
fi

# Site files
if [ -d "$SITE_ROOT" ]; then
    echo "🧹 Removing site files from $SITE_ROOT"
    rm -rf "$SITE_ROOT"
else
    echo "⚠️ Site folder $SITE_ROOT not found. Skipping."
fi

# Database cleanup
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
    echo "⚠️ No credentials found for $DOMAIN at $CRED_FILE"
fi

# Remove domain folder
if [ -d "$DOMAIN_DIR" ]; then
    echo "🧹 Removing domain record folder..."
    rm -rf "$DOMAIN_DIR"
fi

# Remove SSL if present
read -rp "Remove Let's Encrypt certificate for $DOMAIN? [y/N]: " SSL_REMOVE
if [[ "$SSL_REMOVE" =~ ^[Yy]$ ]]; then
    certbot delete --cert-name "$DOMAIN"
fi

echo "✅ Domain $DOMAIN cleanup complete."
