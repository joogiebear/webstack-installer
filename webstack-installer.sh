#!/bin/bash

# Safety check
if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run with sudo or as root."
  exit 1
elif [ -z "$SUDO_USER" ]; then
  echo "⚠️  You are running this as the root user. It's safer to run with sudo instead."
fi

set -e

LOG_FILE="/opt/stack-setup.log"

log() {
    echo "$1"
    echo "$1" >> "$LOG_FILE"
}

# Detect OS
if [ -f /etc/debian_version ]; then
    OS="debian"
    UPDATE_CMD="apt update -y"
    INSTALL_CMD="apt install -y"
else
    echo "Unsupported OS."
    exit 1
fi

eval $UPDATE_CMD

# Prompt for domain
read -rp "Enter the domain name to set up: " DOMAIN
DOMAIN_DIR="/root/webstack-sites/$DOMAIN"
mkdir -p "$DOMAIN_DIR"
DB_CREDENTIALS="$DOMAIN_DIR/db.txt"

# Install Apache
log "Installing Apache..."
eval $INSTALL_CMD apache2

# Install MariaDB
log "Installing MariaDB..."
eval $INSTALL_CMD mariadb-server
systemctl enable mariadb
systemctl start mariadb

# Set default PHP version
PHP_VERSION="8.4"

# Add Sury PHP repo for Debian
if ! grep -q "packages.sury.org" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  log "Adding Sury PHP repository for Debian..."
  apt install -y apt-transport-https lsb-release ca-certificates curl gnupg2
  curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/sury.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
  eval $UPDATE_CMD
fi

# Remove any conflicting PHP modules
a2dismod php7.4 php8.0 php8.1 php8.2 php8.3 php8.4 &>/dev/null || true

# Install full PHP 8.4 + Apache module
PHP_PACKAGES="php${PHP_VERSION} php${PHP_VERSION}-cli php${PHP_VERSION}-mysql libapache2-mod-php${PHP_VERSION} \
php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml \
php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath"

log "Installing PHP ${PHP_VERSION} with full extensions..."
eval $INSTALL_CMD $PHP_PACKAGES

# Enable PHP module
a2enmod php${PHP_VERSION}
systemctl restart apache2


# Generate database credentials
DB_NAME="db_${RANDOM}"
DB_USER="user_${RANDOM}"
DB_PASS=$(openssl rand -base64 16)

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "DB Name: $DB_NAME" > "$DB_CREDENTIALS"
echo "DB User: $DB_USER" >> "$DB_CREDENTIALS"
echo "DB Pass: $DB_PASS" >> "$DB_CREDENTIALS"
log "Database credentials saved to $DB_CREDENTIALS"

# Certbot
if ! command -v certbot &>/dev/null; then
    log "Installing Certbot..."
    eval $INSTALL_CMD certbot python3-certbot-apache
fi

# Site root
SITE_ROOT="/var/www/$DOMAIN"
mkdir -p "$SITE_ROOT"

# Coming soon page + phpinfo
cat > "$SITE_ROOT/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Coming Soon</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-900 text-white h-screen flex items-center justify-center">
  <div class="text-center">
    <h1 class="text-4xl md:text-6xl font-bold mb-4">Coming Soon</h1>
    <p class="text-lg md:text-xl text-gray-400">Our website is under construction. Stay tuned!</p>
  </div>
</body>
</html>
EOF

cat > "$SITE_ROOT/phpinfo.php" <<EOF
<?php phpinfo(); ?>
EOF

# Apache vhost
cat > "/etc/apache2/sites-available/$DOMAIN.conf" <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot $SITE_ROOT
    <Directory $SITE_ROOT>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

a2ensite "$DOMAIN.conf"
systemctl reload apache2

# SSL
read -rp "Attempt Let's Encrypt SSL install for $DOMAIN? [y/N]: " SSL_CONFIRM
if [[ "$SSL_CONFIRM" =~ ^[Yy]$ ]]; then
    read -rp "Enter your email for Let's Encrypt (used for renewal alerts): " LETSENCRYPT_EMAIL
    certbot --apache -d "$DOMAIN" --non-interactive --agree-tos --email "$LETSENCRYPT_EMAIL" --redirect
fi

log "✅ Setup complete for $DOMAIN!"
