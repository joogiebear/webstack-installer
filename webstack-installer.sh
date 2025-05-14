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
DB_CREDENTIALS="/root/db-credentials.txt"

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

# Detect or prompt for web server
if command -v apache2 &>/dev/null; then
    WEBSERVER="apache2"
    log "Detected Apache installed. Using Apache."
elif command -v nginx &>/dev/null; then
    WEBSERVER="nginx"
    log "Detected Nginx installed. Using Nginx."
else
    echo "Choose a web server:"
    echo "1) Apache"
    echo "2) Nginx"
    while true; do
        read -rp "Enter choice [1-2]: " WEBSERVER_CHOICE
        case "$WEBSERVER_CHOICE" in
            1) WEBSERVER="apache2"; eval $INSTALL_CMD apache2; break ;;
            2) WEBSERVER="nginx"; eval $INSTALL_CMD nginx; break ;;
            *) echo "Invalid choice. Please enter 1 or 2." ;;
        esac
    done
fi

# Detect existing database engine
if command -v mysql &>/dev/null; then
    if mysql --version | grep -qi mariadb; then
        DB_ENGINE_INSTALLED="mariadb-server"
        DB_NAME_ENGINE="MariaDB"
    else
        DB_ENGINE_INSTALLED="mysql-server"
        DB_NAME_ENGINE="MySQL"
    fi
fi

# Database logic
if [ -n "$DB_ENGINE_INSTALLED" ]; then
    echo "💡 Detected $DB_NAME_ENGINE already installed. Using $DB_NAME_ENGINE."
    read -rp "Do you want to create a new database for this domain? [y/N]: " CREATE_DB
    if [[ "$CREATE_DB" =~ ^[Yy]$ ]]; then
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
else
    echo "Choose a database option for this domain:"
    echo "1) MariaDB"
    echo "2) MySQL"
    echo "3) Skip"
    while true; do
        read -rp "Enter choice [1-3]: " DB_CHOICE
        case "$DB_CHOICE" in
            1) DB_ENGINE="mariadb-server"; DB_NAME_ENGINE="MariaDB"; break ;;
            2) DB_ENGINE="mysql-server"; DB_NAME_ENGINE="MySQL"; break ;;
            3) DB_ENGINE=""; break ;;
            *) echo "Invalid choice. Please enter 1, 2, or 3." ;;
        esac
    done

    if [ -n "$DB_ENGINE" ]; then
        log "Installing $DB_NAME_ENGINE..."
        eval $INSTALL_CMD $DB_ENGINE

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
fi

# Install certbot if needed
if ! command -v certbot &>/dev/null; then
    log "Installing Certbot..."
    eval $INSTALL_CMD certbot python3-certbot-${WEBSERVER}
fi

# Setup site root and Coming Soon page
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

# Configure virtual host or server block
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

# Let's Encrypt SSL
read -rp "Attempt Let's Encrypt SSL install for $DOMAIN? [y/N]: " SSL_CONFIRM
if [[ "$SSL_CONFIRM" =~ ^[Yy]$ ]]; then
    read -rp "Enter your email for Let's Encrypt (used for renewal alerts): " LETSENCRYPT_EMAIL
    certbot --$WEBSERVER -d "$DOMAIN" --non-interactive --agree-tos --email "$LETSENCRYPT_EMAIL" --redirect
fi

log "✅ Setup complete for $DOMAIN!"
