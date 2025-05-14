#!/bin/bash

# Safety check for permissions
if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run with sudo or as root."
  exit 1
elif [ -z "$SUDO_USER" ]; then
  echo "⚠️  You are running this as the root user. It's safer to run with sudo instead."
fi

set -e

LOG_FILE="/opt/stack-setup.log"
DB_CREDENTIALS="/root/db-credentials.txt"

# Logging helper
log() {
    echo "$1"
    echo "$1" >> "$LOG_FILE"
}

# Detect OS
if [ -f /etc/debian_version ]; then
    OS="debian"
    UPDATE_CMD="apt update -y"
    INSTALL_CMD="apt install -y"
elif [ -f /etc/redhat-release ]; then
    OS="almalinux"
    UPDATE_CMD="dnf update -y"
    INSTALL_CMD="dnf install -y"
else
    echo "Unsupported OS."
    exit 1
fi

# Update system
eval $UPDATE_CMD

# Prompt for domain
read -rp "Enter the domain name to set up: " DOMAIN

# Prompt for web server choice
echo "Choose a web server:"
echo "1) Apache"
echo "2) Nginx"
read -rp "Enter choice [1-2]: " WEBSERVER_CHOICE

# Install web server if needed
if [[ "$WEBSERVER_CHOICE" == "1" ]]; then
    WEBSERVER="apache2"
    if ! command -v apache2 &>/dev/null; then
        log "Installing Apache..."
        eval $INSTALL_CMD apache2
    else
        log "Apache already installed."
    fi
elif [[ "$WEBSERVER_CHOICE" == "2" ]]; then
    WEBSERVER="nginx"
    if ! command -v nginx &>/dev/null; then
        log "Installing Nginx..."
        eval $INSTALL_CMD nginx
    else
        log "Nginx already installed."
    fi
else
    echo "Invalid web server selection."
    exit 1
fi

# Prompt for database choice
echo "Install database?"
echo "1) MariaDB"
echo "2) MySQL"
echo "3) Skip"
read -rp "Enter choice [1-3]: " DB_CHOICE

if [[ "$DB_CHOICE" == "1" ]]; then
    DB_ENGINE="mariadb-server"
elif [[ "$DB_CHOICE" == "2" ]]; then
    DB_ENGINE="mysql-server"
elif [[ "$DB_CHOICE" == "3" ]]; then
    DB_ENGINE=""
else
    echo "Invalid database choice."
    exit 1
fi

# Install and set up database if selected
if [ -n "$DB_ENGINE" ]; then
    if ! command -v mysql &>/dev/null; then
        log "Installing $DB_ENGINE..."
        eval $INSTALL_CMD $DB_ENGINE
    else
        log "$DB_ENGINE already installed."
    fi

    read -rp "Enter new database name: " DB_NAME
    read -rp "Enter new database user: " DB_USER
    read -rp "Enter new database password: " DB_PASS

    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

    echo -e "\n[$DOMAIN]" >> "$DB_CREDENTIALS"
    echo "DB Name: $DB_NAME" >> "$DB_CREDENTIALS"
    echo "DB User: $DB_USER" >> "$DB_CREDENTIALS"
    echo "DB Pass: $DB_PASS" >> "$DB_CREDENTIALS"
    log "Database credentials saved to $DB_CREDENTIALS"
fi

# Install certbot if not installed
if ! command -v certbot &>/dev/null; then
    log "Installing Certbot..."
    if [ "$OS" == "debian" ]; then
        eval $INSTALL_CMD certbot python3-certbot-${WEBSERVER}
    else
        eval $INSTALL_CMD certbot python3-certbot-${WEBSERVER}
    fi
fi

# Set up site directory and Coming Soon page
SITE_ROOT="/var/www/$DOMAIN"
mkdir -p "$SITE_ROOT"

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

# Create VirtualHost/Server Block
if [ "$WEBSERVER" == "apache2" ]; then
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
elif [ "$WEBSERVER" == "nginx" ]; then
    cat > "/etc/nginx/conf.d/$DOMAIN.conf" <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    root $SITE_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
    nginx -t && systemctl reload nginx
fi

# Ask for Let's Encrypt SSL
read -rp "Attempt Let's Encrypt SSL install for $DOMAIN? [y/N]: " SSL_CONFIRM
if [[ "$SSL_CONFIRM" =~ ^[Yy]$ ]]; then
    certbot --$WEBSERVER -d "$DOMAIN" --redirect
fi

log "✅ Setup complete for $DOMAIN!"
