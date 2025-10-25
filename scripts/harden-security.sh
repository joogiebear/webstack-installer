#!/bin/bash

# WebStack Installer - Security Hardening Script
# Applies security best practices to Apache and system configuration

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

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          🔒 WebStack Security Hardening                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo -e "${BLUE}This script will apply security hardening:${NC}"
echo "  • Apache security headers"
echo "  • PHP security settings"
echo "  • Disable unnecessary Apache modules"
echo "  • Hide server information"
echo "  • Configure ModSecurity (if available)"
echo "  • Set secure file permissions"
echo ""

read -rp "Continue with security hardening? [Y/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "Security hardening cancelled"
    exit 0
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. Configuring Apache Security Headers${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Create security headers configuration
SECURITY_CONF="/etc/apache2/conf-available/security-headers.conf"

cat > "$SECURITY_CONF" <<'EOFCONF'
# Security Headers Configuration
# Managed by WebStack Installer

<IfModule mod_headers.c>
    # Prevent MIME type sniffing
    Header always set X-Content-Type-Options "nosniff"
    
    # Enable XSS protection
    Header always set X-XSS-Protection "1; mode=block"
    
    # Prevent clickjacking
    Header always set X-Frame-Options "SAMEORIGIN"
    
    # Referrer policy
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    
    # Remove server signature from headers
    Header always unset X-Powered-By
    Header always unset Server
    
    # Content Security Policy (basic - customize per site)
    # Uncomment and customize for your needs:
    # Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"
    
    # HTTPS Strict Transport Security (HSTS)
    # Only enable this if you have SSL configured!
    # Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Permissions Policy (formerly Feature-Policy)
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
</IfModule>

# Disable directory listing globally
<Directory />
    Options -Indexes
</Directory>

# Limit request size to prevent DoS
LimitRequestBody 10485760

# Timeout configuration
Timeout 60
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
EOFCONF

echo -e "${GREEN}✓${NC} Security headers configuration created"

# Enable headers module
a2enmod headers > /dev/null 2>&1 || true
echo -e "${GREEN}✓${NC} Apache headers module enabled"

# Enable security headers configuration
a2enconf security-headers > /dev/null 2>&1 || true
echo -e "${GREEN}✓${NC} Security headers configuration enabled"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. Hardening Apache Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Update Apache security configuration
APACHE_SECURITY="/etc/apache2/conf-available/security.conf"

if [ -f "$APACHE_SECURITY" ]; then
    # Hide Apache version
    sed -i 's/^ServerTokens .*/ServerTokens Prod/' "$APACHE_SECURITY"
    sed -i 's/^ServerSignature .*/ServerSignature Off/' "$APACHE_SECURITY"
    echo -e "${GREEN}✓${NC} Server signature disabled"
    
    # Disable TRACE method
    if ! grep -q "TraceEnable" "$APACHE_SECURITY"; then
        echo "TraceEnable Off" >> "$APACHE_SECURITY"
    else
        sed -i 's/^TraceEnable .*/TraceEnable Off/' "$APACHE_SECURITY"
    fi
    echo -e "${GREEN}✓${NC} TRACE method disabled"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. PHP Security Hardening${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Find PHP ini file
PHP_INI=$(php -i | grep "Loaded Configuration File" | awk '{print $5}')

if [ -f "$PHP_INI" ]; then
    # Backup original PHP configuration
    cp "$PHP_INI" "$PHP_INI.backup-$(date +%Y%m%d)"
    echo -e "${GREEN}✓${NC} PHP configuration backed up"
    
    # Apply PHP security settings
    sed -i 's/^expose_php = .*/expose_php = Off/' "$PHP_INI"
    sed -i 's/^display_errors = .*/display_errors = Off/' "$PHP_INI"
    sed -i 's/^log_errors = .*/log_errors = On/' "$PHP_INI"
    sed -i 's/^allow_url_fopen = .*/allow_url_fopen = Off/' "$PHP_INI"
    sed -i 's/^allow_url_include = .*/allow_url_include = Off/' "$PHP_INI"
    
    # Disable dangerous PHP functions
    DISABLE_FUNCTIONS="exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source"
    if grep -q "^disable_functions" "$PHP_INI"; then
        sed -i "s/^disable_functions =.*/disable_functions = $DISABLE_FUNCTIONS/" "$PHP_INI"
    else
        echo "disable_functions = $DISABLE_FUNCTIONS" >> "$PHP_INI"
    fi
    
    echo -e "${GREEN}✓${NC} PHP security settings applied"
else
    echo -e "${YELLOW}⚠${NC}  PHP configuration file not found"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. Disable Unnecessary Modules${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# List of modules to disable (only if they exist and are not critical)
MODULES_TO_DISABLE="autoindex status"

for module in $MODULES_TO_DISABLE; do
    if a2query -m "$module" > /dev/null 2>&1; then
        a2dismod "$module" > /dev/null 2>&1 || true
        echo -e "${GREEN}✓${NC} Disabled module: $module"
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. ModSecurity Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if dpkg -l | grep -q libapache2-mod-security2; then
    echo -e "${GREEN}✓${NC} ModSecurity already installed"
else
    read -rp "Install ModSecurity WAF (Web Application Firewall)? [y/N]: " INSTALL_MODSEC
    if [[ "$INSTALL_MODSEC" =~ ^[Yy]$ ]]; then
        apt install -y libapache2-mod-security2
        
        # Enable ModSecurity
        a2enmod security2 > /dev/null 2>&1
        
        # Copy recommended configuration
        if [ -f /etc/modsecurity/modsecurity.conf-recommended ]; then
            cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
            sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf
        fi
        
        echo -e "${GREEN}✓${NC} ModSecurity installed and enabled"
    else
        echo -e "${YELLOW}⚠${NC}  ModSecurity installation skipped"
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}6. File Permissions Security${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Secure Apache configuration files
chmod 640 /etc/apache2/apache2.conf
echo -e "${GREEN}✓${NC} Apache configuration permissions secured"

# Secure PHP configuration
if [ -f "$PHP_INI" ]; then
    chmod 640 "$PHP_INI"
    echo -e "${GREEN}✓${NC} PHP configuration permissions secured"
fi

# Secure domain credentials
if [ -d "/root/webstack-sites" ]; then
    find /root/webstack-sites -type f -name "info.txt" -exec chmod 600 {} \;
    echo -e "${GREEN}✓${NC} Domain credentials permissions secured"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}7. Testing Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test Apache configuration
if apache2ctl configtest > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Apache configuration test passed"
else
    echo -e "${YELLOW}⚠${NC}  Apache configuration test failed. Checking..."
    apache2ctl configtest
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}8. Restarting Services${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

systemctl restart apache2
echo -e "${GREEN}✓${NC} Apache restarted"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          ✅ SECURITY HARDENING COMPLETE!                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Security improvements applied:${NC}"
echo "  ✓ Security headers configured"
echo "  ✓ Server information hidden"
echo "  ✓ PHP security settings applied"
echo "  ✓ Unnecessary modules disabled"
echo "  ✓ File permissions secured"
echo ""
echo -e "${YELLOW}📝 Additional recommendations:${NC}"
echo "  • Enable SSL/TLS for all domains"
echo "  • Configure firewall rules (UFW)"
echo "  • Keep system packages updated"
echo "  • Monitor logs regularly"
echo "  • Enable automatic security updates"
echo ""
echo -e "${BLUE}💡 To enable HSTS (after SSL is configured):${NC}"
echo "  Edit: /etc/apache2/conf-available/security-headers.conf"
echo "  Uncomment the Strict-Transport-Security header"
echo ""
