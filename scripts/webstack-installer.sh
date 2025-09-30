#!/bin/bash

# WebStack Installer - Multi-Domain Web Hosting Setup
# Automatically installs web stack on first run

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          🚀 WebStack Installer v2.0                       ║"
echo "║          Multi-Domain Web Hosting Setup                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install web stack
install_webstack() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  First-time setup detected!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Installing web stack components:"
    echo "  • Apache 2.4+"
    echo "  • MariaDB 10.x"
    echo "  • PHP 8.x"
    echo "  • phpMyAdmin"
    echo "  • Essential tools"
    echo ""
    read -rp "Continue with installation? [Y/n]: " INSTALL_CONFIRM
    
    if [[ "$INSTALL_CONFIRM" =~ ^[Nn]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    
    echo ""
    echo -e "${BLUE}📦 Updating package lists...${NC}"
    apt update
    
    echo ""
    echo -e "${BLUE}📦 Installing Apache web server...${NC}"
    DEBIAN_FRONTEND=noninteractive apt install -y apache2
    
    echo ""
    echo -e "${BLUE}📦 Installing MariaDB database server...${NC}"
    DEBIAN_FRONTEND=noninteractive apt install -y mariadb-server
    
    echo ""
    echo -e "${BLUE}📦 Installing PHP and extensions...${NC}"
    DEBIAN_FRONTEND=noninteractive apt install -y \
        php \
        php-mysql \
        php-cli \
        php-common \
        php-xml \
        php-curl \
        php-gd \
        php-mbstring \
        php-zip \
        libapache2-mod-php
    
    echo ""
    echo -e "${BLUE}📦 Installing phpMyAdmin...${NC}"
    DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin
    
    echo ""
    echo -e "${BLUE}📦 Installing additional tools...${NC}"
    DEBIAN_FRONTEND=noninteractive apt install -y \
        certbot \
        python3-certbot-apache \
        ufw \
        zip \
        unzip \
        curl \
        wget \
        git
    
    echo ""
    echo -e "${BLUE}⚙️  Configuring Apache...${NC}"
    a2enmod rewrite
    a2enmod ssl
    a2enmod headers
    
    echo ""
    echo -e "${BLUE}🔥 Configuring firewall...${NC}"
    if command_exists ufw; then
        ufw --force enable
        ufw allow 22/tcp   # SSH
        ufw allow 80/tcp   # HTTP
        ufw allow 443/tcp  # HTTPS
        echo "Firewall configured"
    fi
    
    echo ""
    echo -e "${BLUE}🔄 Starting services...${NC}"
    systemctl start apache2
    systemctl start mariadb
    systemctl enable apache2
    systemctl enable mariadb
    
    echo ""
    echo -e "${GREEN}✅ Web stack installation complete!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Important: Run 'mysql_secure_installation' after this script${NC}"
    echo ""
    sleep 2
}

# Check if web stack is installed
NEEDS_INSTALL=0

if ! command_exists apache2; then
    NEEDS_INSTALL=1
fi

if ! command_exists mysql; then
    NEEDS_INSTALL=1
fi

if ! command_exists php; then
    NEEDS_INSTALL=1
fi

# Install web stack if needed
if [ $NEEDS_INSTALL -eq 1 ]; then
    install_webstack
fi

# Get domain name
read -rp "🌐 Enter domain name (e.g., example.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Domain name cannot be empty${NC}"
    exit 1
fi

# Validate domain format (supports subdomains)
if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]{0,253}[a-zA-Z0-9]$ ]]; then
    echo -e "${RED}❌ Invalid domain format${NC}"
    echo "Valid examples: example.com, sub.example.com, blog.mysite.com"
    exit 1
fi

# Create username from domain (remove dots, truncate to 32 chars)
USERNAME=$(echo "$DOMAIN" | sed 's/\.//g' | cut -c1-32)

# Check if domain already exists
if [ -d "/var/www/$USERNAME" ]; then
    echo -e "${RED}❌ Domain $DOMAIN already exists${NC}"
    exit 1
fi

echo ""
echo "📝 Configuration:"
echo "   Domain: $DOMAIN"
echo "   Username: $USERNAME"
echo ""

read -rp "Continue with installation? [Y/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "Installation cancelled"
    exit 0
fi

# Create system user
echo -e "${BLUE}👤 Creating system user...${NC}"
useradd -m -s /bin/bash "$USERNAME" 2>/dev/null || true

# Create directory structure
echo -e "${BLUE}📂 Creating directory structure...${NC}"
SITE_ROOT="/var/www/$USERNAME/public_html"
mkdir -p "$SITE_ROOT"
mkdir -p "/var/www/$USERNAME/logs"
mkdir -p "/var/www/$USERNAME/backups"
mkdir -p "/var/www/$USERNAME/tmp"

# Generate database credentials
DB_NAME="${USERNAME}_db"
DB_USER="${USERNAME}_user"
DB_PASS=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)

# Create database
echo -e "${BLUE}🗄️  Creating MySQL database...${NC}"
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Create domain info directory
DOMAIN_INFO_DIR="/root/webstack-sites/$DOMAIN"
mkdir -p "$DOMAIN_INFO_DIR"

# Save credentials
INFO_FILE="$DOMAIN_INFO_DIR/info.txt"
cat > "$INFO_FILE" <<EOF
╔════════════════════════════════════════════════════════════╗
║          Domain Information: $DOMAIN
╚════════════════════════════════════════════════════════════╝

Domain: $DOMAIN
Website: http://$DOMAIN
Username: $USERNAME

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DATABASE CREDENTIALS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Database Name: $DB_NAME
Database User: $DB_USER
Database Pass: $DB_PASS
Database Host: localhost

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHPMYADMIN ACCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
URL: http://$DOMAIN/phpmyadmin
Username: $DB_USER
Password: $DB_PASS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FILE UPLOAD (SFTP)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Host: $(hostname -I | awk '{print $1}')
Port: 22
Protocol: SFTP
Username: $USERNAME
Password: [Set with: passwd $USERNAME]

Upload Directory: $SITE_ROOT

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPORTANT FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Website Files: $SITE_ROOT
Apache Config: /etc/apache2/sites-available/$DOMAIN.conf
Error Log: /var/www/$USERNAME/logs/error.log
Access Log: /var/www/$USERNAME/logs/access.log

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Point DNS A record to: $(hostname -I | awk '{print $1}')
2. Upload website files to: $SITE_ROOT
3. Install SSL: certbot --apache -d $DOMAIN
4. Set SFTP password: passwd $USERNAME

Created: $(date)
EOF

chmod 600 "$INFO_FILE"

# Create Apache virtual host
echo -e "${BLUE}⚙️  Creating Apache virtual host...${NC}"
VHOST_CONF="/etc/apache2/sites-available/$DOMAIN.conf"

cat > "$VHOST_CONF" <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    ServerAdmin webmaster@$DOMAIN

    DocumentRoot $SITE_ROOT

    <Directory $SITE_ROOT>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/www/$USERNAME/logs/error.log
    CustomLog /var/www/$USERNAME/logs/access.log combined

    php_admin_value open_basedir "$SITE_ROOT:/tmp:/var/tmp:/usr/share/php:/usr/share/phpmyadmin"
    php_admin_value upload_tmp_dir "/var/www/$USERNAME/tmp"
    php_admin_value session.save_path "/var/www/$USERNAME/tmp"
</VirtualHost>
EOF

# Create default index page
cat > "$SITE_ROOT/index.php" <<'EOFINDEX'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome - Site Active</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            padding: 60px 40px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 600px;
            text-align: center;
        }
        h1 {
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 20px;
        }
        p {
            color: #666;
            font-size: 1.2em;
            margin-bottom: 15px;
            line-height: 1.6;
        }
        .status {
            background: #f0f4ff;
            padding: 20px;
            border-radius: 10px;
            margin: 30px 0;
        }
        .status-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #ddd;
        }
        .status-item:last-child {
            border-bottom: none;
        }
        .success { color: #10b981; font-weight: bold; }
        .emoji { font-size: 3em; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">🎉</div>
        <h1>Website Active!</h1>
        <p>Your web hosting is configured and running successfully.</p>
        
        <div class="status">
            <div class="status-item">
                <span>Domain:</span>
                <span class="success"><?php echo $_SERVER['HTTP_HOST']; ?></span>
            </div>
            <div class="status-item">
                <span>PHP Version:</span>
                <span class="success"><?php echo phpversion(); ?></span>
            </div>
            <div class="status-item">
                <span>Server:</span>
                <span class="success"><?php echo $_SERVER['SERVER_SOFTWARE']; ?></span>
            </div>
            <div class="status-item">
                <span>Document Root:</span>
                <span class="success"><?php echo $_SERVER['DOCUMENT_ROOT']; ?></span>
            </div>
        </div>
        
        <p><strong>Ready to upload your website!</strong></p>
        <p style="font-size: 0.9em; color: #999;">Replace this file with your content</p>
    </div>
</body>
</html>
EOFINDEX

# Create phpMyAdmin symlink
if [ -d "/usr/share/phpmyadmin" ]; then
    ln -sf /usr/share/phpmyadmin "$SITE_ROOT/phpmyadmin"
fi

# Set permissions
echo -e "${BLUE}🔒 Setting permissions...${NC}"
chown -R www-data:www-data "/var/www/$USERNAME"
chmod 755 "$SITE_ROOT"
chmod 700 "/var/www/$USERNAME/tmp"

# Enable site
echo -e "${BLUE}✅ Enabling site...${NC}"
a2ensite "$DOMAIN" > /dev/null 2>&1

# Test Apache configuration
if apache2ctl configtest > /dev/null 2>&1; then
    # Reload Apache
    systemctl reload apache2
else
    echo -e "${YELLOW}⚠️  Apache configuration test failed. Checking...${NC}"
    apache2ctl configtest
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          ✅ INSTALLATION COMPLETE!                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Domain: $DOMAIN${NC}"
echo -e "${GREEN}Website: http://$DOMAIN${NC}"
echo -e "${GREEN}phpMyAdmin: http://$DOMAIN/phpmyadmin${NC}"
echo ""
echo "📋 Database Credentials:"
echo "   Database: $DB_NAME"
echo "   Username: $DB_USER"
echo "   Password: $DB_PASS"
echo ""
echo "💾 Complete info saved to: $INFO_FILE"
echo ""
echo "🎯 Next Steps:"
echo "   1. Point DNS A record to: $(hostname -I | awk '{print $1}')"
echo "   2. Upload files to: $SITE_ROOT"
echo "   3. Set SFTP password: passwd $USERNAME"
echo "   4. Install SSL: certbot --apache -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "📖 View info anytime: cat $INFO_FILE"
echo ""
