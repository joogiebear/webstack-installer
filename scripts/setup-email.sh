#!/bin/bash

# Setup Email Server - One-time email server installation

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
echo "║          📧 Email Server Setup                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if already installed
if [ -f "/root/.email-config/mail-server.conf" ]; then
    echo -e "${YELLOW}⚠️  Email server appears to be already installed${NC}"
    echo ""
    read -rp "Reinstall? [y/N]: " REINSTALL
    if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo -e "${BLUE}Installing email server components...${NC}"
echo ""
echo "This will install:"
echo "  • Postfix (SMTP server)"
echo "  • Dovecot (IMAP/POP3 server)"
echo "  • Virtual mailbox support"
echo ""
read -rp "Continue? [Y/n]: " CONFIRM

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    exit 0
fi

# Install packages
echo -e "${BLUE}📦 Installing packages...${NC}"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql

# Create mail database
echo -e "${BLUE}🗄️  Creating mail database...${NC}"

MAIL_DB_PASS=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS mail_server CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'mail_admin'@'localhost' IDENTIFIED BY '$MAIL_DB_PASS';
GRANT ALL PRIVILEGES ON mail_server.* TO 'mail_admin'@'localhost';
FLUSH PRIVILEGES;

USE mail_server;

CREATE TABLE IF NOT EXISTS virtual_domains (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS virtual_users (
    id INT NOT NULL AUTO_INCREMENT,
    domain_id INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY email (email),
    FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS virtual_aliases (
    id INT NOT NULL AUTO_INCREMENT,
    domain_id INT NOT NULL,
    source VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
EOF

# Create mail directories
mkdir -p /var/mail/vhosts
chmod -R 770 /var/mail/vhosts

# Add vmail user
groupadd -g 5000 vmail 2>/dev/null || true
useradd -g vmail -u 5000 vmail -d /var/mail 2>/dev/null || true
chown -R vmail:vmail /var/mail

# Configure Postfix
echo -e "${BLUE}⚙️  Configuring Postfix...${NC}"

postconf -e "myhostname = $(hostname -f)"
postconf -e "mydestination = localhost"
postconf -e "mynetworks = 127.0.0.0/8"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"
postconf -e "virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf"
postconf -e "virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf"
postconf -e "virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf"
postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"

# Create Postfix MySQL config files
cat > /etc/postfix/mysql-virtual-mailbox-domains.cf <<EOF
user = mail_admin
password = $MAIL_DB_PASS
hosts = 127.0.0.1
dbname = mail_server
query = SELECT 1 FROM virtual_domains WHERE name='%s'
EOF

cat > /etc/postfix/mysql-virtual-mailbox-maps.cf <<EOF
user = mail_admin
password = $MAIL_DB_PASS
hosts = 127.0.0.1
dbname = mail_server
query = SELECT 1 FROM virtual_users WHERE email='%s'
EOF

cat > /etc/postfix/mysql-virtual-alias-maps.cf <<EOF
user = mail_admin
password = $MAIL_DB_PASS
hosts = 127.0.0.1
dbname = mail_server
query = SELECT destination FROM virtual_aliases WHERE source='%s'
EOF

chmod 640 /etc/postfix/mysql-virtual-*.cf
chown root:postfix /etc/postfix/mysql-virtual-*.cf

# Configure Dovecot
echo -e "${BLUE}⚙️  Configuring Dovecot...${NC}"

# Dovecot SQL configuration
cat > /etc/dovecot/dovecot-sql.conf.ext <<EOF
driver = mysql
connect = host=127.0.0.1 dbname=mail_server user=mail_admin password=$MAIL_DB_PASS
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email as user, password FROM virtual_users WHERE email='%u';
user_query = SELECT 5000 AS uid, 5000 AS gid, '/var/mail/vhosts/%d/%n' AS home FROM virtual_users WHERE email='%u';
EOF

chmod 640 /etc/dovecot/dovecot-sql.conf.ext
chown root:dovecot /etc/dovecot/dovecot-sql.conf.ext

# Update Dovecot config
sed -i 's/#mail_location =/mail_location = maildir:~\/Maildir/' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf

# Restart services
echo -e "${BLUE}🔄 Restarting services...${NC}"
systemctl restart postfix
systemctl restart dovecot
systemctl enable postfix
systemctl enable dovecot

# Open firewall ports
if command -v ufw &> /dev/null; then
    echo -e "${BLUE}🔥 Configuring firewall...${NC}"
    ufw allow 25/tcp    # SMTP
    ufw allow 587/tcp   # Submission
    ufw allow 465/tcp   # SMTPS
    ufw allow 993/tcp   # IMAPS
    ufw allow 995/tcp   # POP3S
    ufw allow 143/tcp   # IMAP
    ufw allow 110/tcp   # POP3
fi

# Save configuration
mkdir -p /root/.email-config

cat > /root/.email-config/mail-server.conf <<EOF
Email Server Configuration
══════════════════════════════════════════
Installation Date: $(date)
Database: mail_server
Database User: mail_admin
Database Password: $MAIL_DB_PASS
Mail Directory: /var/mail/vhosts

Services:
- Postfix (SMTP): Port 25, 587
- Dovecot (IMAP): Port 143, 993
- Dovecot (POP3): Port 110, 995

Management:
Use manage-email.sh to create/manage email accounts
EOF

chmod 600 /root/.email-config/mail-server.conf

# Create email setup guide
cat > /root/.email-config/email-setup-guide.txt <<EOF
╔════════════════════════════════════════════════════════════╗
║          📧 EMAIL SERVER SETUP GUIDE                       ║"
╚════════════════════════════════════════════════════════════╝

EMAIL SERVER INSTALLED SUCCESSFULLY!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 1: DNS CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For EACH domain that will use email, add these DNS records:

MX Record:
  Host: @
  Points to: mail.yourdomain.com
  Priority: 10

A Record (for mail server):
  Host: mail
  Points to: YOUR_SERVER_IP

SPF Record (prevents spam):
  Type: TXT
  Host: @
  Value: v=spf1 mx a ip4:YOUR_SERVER_IP ~all

DKIM Record (recommended, advanced):
  Type: TXT
  Host: default._domainkey
  Value: [Generate with: opendkim-genkey]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 2: CREATE EMAIL ACCOUNTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Use the management script:
  sudo ./manage-email.sh

This allows you to:
- Create email accounts (user@domain.com)
- Change passwords
- Delete accounts
- View email settings

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 3: CONFIGURE EMAIL CLIENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

After creating an email account, use these settings:

INCOMING MAIL (IMAP):
  Server: mail.yourdomain.com
  Port: 143 (STARTTLS) or 993 (SSL/TLS)
  Username: full email address (user@domain.com)
  Password: [set when creating account]

OUTGOING MAIL (SMTP):
  Server: mail.yourdomain.com
  Port: 587 (STARTTLS) or 465 (SSL/TLS)
  Username: full email address
  Password: [same as above]
  Authentication: Required

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPORTANT NOTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. SSL Certificates:
   Install SSL for mail.yourdomain.com:
   certbot certonly --standalone -d mail.yourdomain.com

2. Port 25:
   Some ISPs block port 25. Use port 587 for sending.

3. Testing:
   Use the manage-email.sh script to send test emails.

4. Logs:
   Mail logs: /var/log/mail.log
   Check for errors: tail -f /var/log/mail.log

5. Multi-Domain:
   This email server works for ALL domains on your server.
   Just create accounts with the domain name.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MANAGEMENT COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Create email:        sudo ./manage-email.sh
View mail logs:      sudo tail -f /var/log/mail.log
Restart Postfix:     sudo systemctl restart postfix
Restart Dovecot:     sudo systemctl restart dovecot
Check mail queue:    sudo postqueue -p
Flush mail queue:    sudo postqueue -f

EOF

chmod 644 /root/.email-config/email-setup-guide.txt

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          ✅ EMAIL SERVER INSTALLED!                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✅ Email server is now ready!${NC}"
echo ""
echo "📋 Next steps:"
echo "  1. Read the setup guide: cat /root/.email-config/email-setup-guide.txt"
echo "  2. Configure DNS records for your domains"
echo "  3. Create email accounts: sudo ./manage-email.sh"
echo ""
echo "💾 Configuration saved to: /root/.email-config/"
echo ""
