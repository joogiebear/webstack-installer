#!/bin/bash

# WebStack Installer - Multi-Domain Web Hosting Setup
# Creates Apache virtual hosts with PHP, MySQL, and SSL support

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

# Get domain name
read -rp "🌐 Enter domain name (e.g., example.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Domain name cannot be empty${NC}"
    exit 1
fi

# Validate domain format
if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}❌ Invalid domain format${NC}"
    exit 1
fi

# Create username from domain
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
useradd -m -s /bin/bash "$USERNAME"

# Create directory structure
echo -e "${BLUE}📂 Creating directory structure...${NC}"
SITE_ROOT="/var/www/$USERNAME/public_html"
mkdir -p "$SITE_ROOT"
mkdir -p "/var/www/$USERNAME/logs"
mkdir -p "/var/www/$USERNAME/backups"

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

# Save credentials
DB_CREDENTIALS="/var/www/$USERNAME/db-credentials.txt"
cat > "$DB_CREDENTIALS" <<EOF
Database Credentials for $DOMAIN
═══════════════════════════════════════════
Database Name: $DB_NAME
Database User: $DB_USER
Database Pass: $DB_PASS
Database Host: localhost

phpMyAdmin: http://$DOMAIN/phpmyadmin
═══════════════════════════════════════════
Created: $(date)
EOF

chmod 600 "$DB_CREDENTIALS"

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
cat > "$SITE_ROOT/index.php" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
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
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Website Active!</h1>
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
        </div>
        
        <p>Replace this file with your website content.</p>
    </div>
</body>
</html>
EOF

# Create phpMyAdmin symlink
if [ -d "/usr/share/phpmyadmin" ]; then
    ln -sf /usr/share/phpmyadmin "$SITE_ROOT/phpmyadmin"
fi

# Create tmp directory for PHP
mkdir -p "/var/www/$USERNAME/tmp"

# Set permissions
echo -e "${BLUE}🔒 Setting permissions...${NC}"
chown -R "$USERNAME:$USERNAME" "/var/www/$USERNAME"
chmod 755 "$SITE_ROOT"
chmod 700 "/var/www/$USERNAME/tmp"

# Enable site
echo -e "${BLUE}✅ Enabling site...${NC}"
a2ensite "$DOMAIN" > /dev/null 2>&1

# Reload Apache
systemctl reload apache2

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
echo "💾 Credentials saved to: $DB_CREDENTIALS"
echo ""
echo "🎯 Next Steps:"
echo "   1. Point your domain DNS to this server's IP"
echo "   2. Upload your website files to: $SITE_ROOT"
echo "   3. Install SSL: certbot --apache -d $DOMAIN -d www.$DOMAIN"
echo ""
