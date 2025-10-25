#!/bin/bash

# WebStack Installer - Clone Domain
# Duplicate an existing domain with a new name

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
if [ -f "$SCRIPT_DIR/common-functions.sh" ]; then
    source "$SCRIPT_DIR/common-functions.sh"
else
    echo "Error: common-functions.sh not found"
    exit 1
fi

# Initialize
init_logging "clone-domain"
check_root

print_header "📋 Clone Domain"

# Get source domain
echo "Available domains to clone:"
DOMAINS=($(get_all_domains))

if [ ${#DOMAINS[@]} -eq 0 ]; then
    log_error "No domains found to clone"
    exit 1
fi

for i in "${!DOMAINS[@]}"; do
    echo "  $((i+1))) ${DOMAINS[$i]}"
done
echo ""

read -rp "Select source domain (number or name): " selection

SOURCE_DOMAIN=""
if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#DOMAINS[@]} ]; then
    SOURCE_DOMAIN="${DOMAINS[$((selection-1))]}"
else
    SOURCE_DOMAIN="$selection"
fi

# Validate source
if ! validate_domain "$SOURCE_DOMAIN"; then
    log_error "Invalid domain"
    exit 1
fi

if ! domain_exists "$SOURCE_DOMAIN"; then
    log_error "Source domain not found"
    exit 1
fi

# Get target domain
echo ""
read -rp "Enter new domain name: " TARGET_DOMAIN

if ! validate_domain "$TARGET_DOMAIN"; then
    exit 1
fi

if domain_exists "$TARGET_DOMAIN"; then
    log_error "Target domain already exists"
    exit 1
fi

# Summary
echo ""
log_info "Clone Summary:"
echo "  Source: $SOURCE_DOMAIN"
echo "  Target: $TARGET_DOMAIN"
echo ""
echo "This will copy:"
echo "  ✓ Website files"
echo "  ✓ Database (with new credentials)"
echo "  ✓ Apache configuration"
echo "  ✓ File permissions"
echo ""

if ! confirm "Proceed with cloning?"; then
    log_info "Cloning cancelled"
    exit 0
fi

# Get source info
SOURCE_USERNAME=$(get_domain_username "$SOURCE_DOMAIN")
SOURCE_ROOT=$(get_domain_root "$SOURCE_DOMAIN")
SOURCE_DB=$(get_domain_database "$SOURCE_DOMAIN")

# Generate target info
TARGET_USERNAME=$(domain_to_username "$TARGET_DOMAIN")
TARGET_ROOT="$WEBSTACK_ROOT/$TARGET_USERNAME"
TARGET_DB="${TARGET_USERNAME}_db"
TARGET_DB_USER="${TARGET_USERNAME}_user"
TARGET_DB_PASS=$(generate_password 16)

echo ""
log_info "Starting domain cloning..."

# Create target user
print_subsection "Creating System User"
if useradd -m -s /bin/bash "$TARGET_USERNAME" 2>/dev/null; then
    log_success "User created: $TARGET_USERNAME"
else
    log_error "Failed to create user"
    exit 1
fi

# Create directory structure
print_subsection "Creating Directory Structure"
mkdir -p "$TARGET_ROOT/public_html"
mkdir -p "$TARGET_ROOT/logs"
mkdir -p "$TARGET_ROOT/backups"
mkdir -p "$TARGET_ROOT/tmp"
log_success "Directories created"

# Copy website files
print_subsection "Copying Website Files"
if [ -d "$SOURCE_ROOT/public_html" ]; then
    cp -a "$SOURCE_ROOT/public_html/." "$TARGET_ROOT/public_html/"
    
    # Remove phpMyAdmin symlink if present
    rm -f "$TARGET_ROOT/public_html/phpmyadmin"
    
    log_success "Files copied"
else
    log_warn "No source files found"
fi

# Clone database
print_subsection "Cloning Database"
if [ -n "$SOURCE_DB" ] && database_exists "$SOURCE_DB"; then
    # Create new database
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`$TARGET_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$TARGET_DB_USER'@'localhost' IDENTIFIED BY '$TARGET_DB_PASS';
GRANT ALL PRIVILEGES ON \`$TARGET_DB\`.* TO '$TARGET_DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

    # Copy database data
    mysqldump --single-transaction --routines --triggers "$SOURCE_DB" | mysql "$TARGET_DB"
    
    log_success "Database cloned"
else
    log_warn "No source database to clone"
fi

# Create Apache config
print_subsection "Creating Apache Configuration"
cat > "/etc/apache2/sites-available/$TARGET_DOMAIN.conf" <<EOF
<VirtualHost *:80>
    ServerName $TARGET_DOMAIN
    ServerAlias www.$TARGET_DOMAIN
    ServerAdmin webmaster@$TARGET_DOMAIN

    DocumentRoot $TARGET_ROOT/public_html

    <Directory $TARGET_ROOT/public_html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog $TARGET_ROOT/logs/error.log
    CustomLog $TARGET_ROOT/logs/access.log combined

    php_admin_value open_basedir "$TARGET_ROOT/public_html:/tmp:/var/tmp:/usr/share/php:/usr/share/phpmyadmin"
    php_admin_value upload_tmp_dir "$TARGET_ROOT/tmp"
    php_admin_value session.save_path "$TARGET_ROOT/tmp"
</VirtualHost>
EOF

# Enable site
a2ensite "$TARGET_DOMAIN" > /dev/null 2>&1
log_success "Apache configuration created"

# Set permissions
print_subsection "Setting Permissions"
chown -R www-data:www-data "$TARGET_ROOT"
chmod 755 "$TARGET_ROOT/public_html"
chmod 700 "$TARGET_ROOT/tmp"
log_success "Permissions set"

# Create domain info
print_subsection "Saving Domain Information"
mkdir -p "$DOMAIN_INFO_ROOT/$TARGET_DOMAIN"
cat > "$DOMAIN_INFO_ROOT/$TARGET_DOMAIN/info.txt" <<EOF
Domain: $TARGET_DOMAIN
Username: $TARGET_USERNAME
Created: $(get_timestamp)

Database Name: $TARGET_DB
Database User: $TARGET_DB_USER
Database Pass: $TARGET_DB_PASS

Website Root: $TARGET_ROOT/public_html
phpMyAdmin: http://$TARGET_DOMAIN/phpmyadmin

Cloned from: $SOURCE_DOMAIN
EOF
chmod 600 "$DOMAIN_INFO_ROOT/$TARGET_DOMAIN/info.txt"
log_success "Domain information saved"

# Reload Apache
if reload_apache; then
    log_success "Apache reloaded"
else
    log_error "Failed to reload Apache"
    exit 1
fi

echo ""
print_separator
echo ""
log_success "Domain cloned successfully!"
echo ""
echo "New Domain: $TARGET_DOMAIN"
echo "  Username:   $TARGET_USERNAME"
echo "  Database:   $TARGET_DB"
echo "  DB User:    $TARGET_DB_USER"
echo "  DB Pass:    $TARGET_DB_PASS"
echo ""
echo "Next Steps:"
echo "  1. Point DNS A record to: $(get_public_ip)"
echo "  2. Update database connection in your code (if needed)"
echo "  3. Set SFTP password: passwd $TARGET_USERNAME"
echo "  4. Install SSL: certbot --apache -d $TARGET_DOMAIN"
echo ""
echo "Info file: $DOMAIN_INFO_ROOT/$TARGET_DOMAIN/info.txt"
echo ""
