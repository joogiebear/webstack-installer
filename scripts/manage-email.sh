#!/bin/bash

# Manage Email Script - Create and manage email accounts

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    exit 1
fi

# Check if email server is installed
if [ ! -f "/root/.email-config/mail-server.conf" ]; then
    echo -e "${RED}❌ Email server not installed${NC}"
    echo ""
    echo "Run setup-email.sh first to install the email server"
    exit 1
fi

# Get database password
MAIL_DB_PASS=$(grep "Database Password:" /root/.email-config/mail-server.conf | awk '{print $3}')

show_menu() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          📧 Email Account Management                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1) Create new email account"
    echo "2) List all email accounts"
    echo "3) Change email password"
    echo "4) Delete email account"
    echo "5) View email settings"
    echo "6) Test email sending"
    echo "0) Exit"
    echo ""
}

create_email() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}CREATE NEW EMAIL ACCOUNT${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -rp "Email address (e.g., user@domain.com): " EMAIL
    
    if [ -z "$EMAIL" ] || [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}❌ Invalid email format${NC}"
        return
    fi
    
    DOMAIN=$(echo "$EMAIL" | cut -d'@' -f2)
    
    # Add domain if it doesn't exist
    DOMAIN_ID=$(mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -sN -e "SELECT id FROM virtual_domains WHERE name='$DOMAIN';" 2>/dev/null)
    
    if [ -z "$DOMAIN_ID" ]; then
        echo -e "${BLUE}Adding domain $DOMAIN...${NC}"
        mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -e "INSERT INTO virtual_domains (name) VALUES ('$DOMAIN');" 2>/dev/null
        DOMAIN_ID=$(mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -sN -e "SELECT id FROM virtual_domains WHERE name='$DOMAIN';" 2>/dev/null)
    fi
    
    # Check if email exists
    EXISTS=$(mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -sN -e "SELECT COUNT(*) FROM virtual_users WHERE email='$EMAIL';" 2>/dev/null)
    
    if [ "$EXISTS" -gt 0 ]; then
        echo -e "${RED}❌ Email account already exists${NC}"
        return
    fi
    
    echo ""
    read -rsp "Password (min 8 characters): " PASSWORD
    echo ""
    
    if [ ${#PASSWORD} -lt 8 ]; then
        echo -e "${RED}❌ Password must be at least 8 characters${NC}"
        return
    fi
    
    # Hash password
    HASHED_PASS=$(doveadm pw -s SHA512-CRYPT -p "$PASSWORD")
    
    # Create email account
    mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -e "INSERT INTO virtual_users (domain_id, email, password) VALUES ($DOMAIN_ID, '$EMAIL', '$HASHED_PASS');" 2>/dev/null
    
    # Create maildir
    LOCAL_PART=$(echo "$EMAIL" | cut -d'@' -f1)
    MAIL_DIR="/var/mail/vhosts/$DOMAIN/$LOCAL_PART"
    
    mkdir -p "$MAIL_DIR"/{cur,new,tmp}
    chown -R vmail:vmail "$MAIL_DIR"
    chmod -R 700 "$MAIL_DIR"
    
    echo ""
    echo -e "${GREEN}✅ Email account created: $EMAIL${NC}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Email Client Settings:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "IMAP Server: mail.$DOMAIN"
    echo "IMAP Port: 993 (SSL) or 143 (STARTTLS)"
    echo ""
    echo "SMTP Server: mail.$DOMAIN"
    echo "SMTP Port: 587 (STARTTLS) or 465 (SSL)"
    echo ""
    echo "Username: $EMAIL"
    echo "Password: [your password]"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

list_emails() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}ALL EMAIL ACCOUNTS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -t -e "
        SELECT 
            vd.name AS Domain,
            vu.email AS 'Email Address',
            DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d') AS 'Created'
        FROM virtual_users vu
        JOIN virtual_domains vd ON vu.domain_id = vd.id
        ORDER BY vd.name, vu.email;
    " 2>/dev/null
    
    echo ""
}

change_password() {
    echo ""
    read -rp "Email address: " EMAIL
    
    EXISTS=$(mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -sN -e "SELECT COUNT(*) FROM virtual_users WHERE email='$EMAIL';" 2>/dev/null)
    
    if [ "$EXISTS" -eq 0 ]; then
        echo -e "${RED}❌ Email account not found${NC}"
        return
    fi
    
    echo ""
    read -rsp "New password (min 8 characters): " PASSWORD
    echo ""
    
    if [ ${#PASSWORD} -lt 8 ]; then
        echo -e "${RED}❌ Password must be at least 8 characters${NC}"
        return
    fi
    
    HASHED_PASS=$(doveadm pw -s SHA512-CRYPT -p "$PASSWORD")
    
    mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -e "UPDATE virtual_users SET password='$HASHED_PASS' WHERE email='$EMAIL';" 2>/dev/null
    
    echo -e "${GREEN}✅ Password updated for $EMAIL${NC}"
    echo ""
}

delete_email() {
    echo ""
    read -rp "Email address to delete: " EMAIL
    
    EXISTS=$(mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -sN -e "SELECT COUNT(*) FROM virtual_users WHERE email='$EMAIL';" 2>/dev/null)
    
    if [ "$EXISTS" -eq 0 ]; then
        echo -e "${RED}❌ Email account not found${NC}"
        return
    fi
    
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: This will permanently delete the email account and all messages!${NC}"
    echo ""
    read -rp "Type 'DELETE' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "DELETE" ]; then
        echo "Cancelled"
        return
    fi
    
    mysql -u mail_admin -p"$MAIL_DB_PASS" mail_server -e "DELETE FROM virtual_users WHERE email='$EMAIL';" 2>/dev/null
    
    # Delete maildir
    DOMAIN=$(echo "$EMAIL" | cut -d'@' -f2)
    LOCAL_PART=$(echo "$EMAIL" | cut -d'@' -f1)
    MAIL_DIR="/var/mail/vhosts/$DOMAIN/$LOCAL_PART"
    
    if [ -d "$MAIL_DIR" ]; then
        rm -rf "$MAIL_DIR"
    fi
    
    echo -e "${GREEN}✅ Email account deleted: $EMAIL${NC}"
    echo ""
}

view_settings() {
    echo ""
    cat /root/.email-config/email-setup-guide.txt
    echo ""
}

test_email() {
    echo ""
    read -rp "From email address: " FROM_EMAIL
    read -rp "To email address: " TO_EMAIL
    
    echo ""
    echo "Sending test email..."
    
    echo "This is a test email from your mail server." | mail -s "Test Email" -r "$FROM_EMAIL" "$TO_EMAIL"
    
    echo -e "${GREEN}✅ Test email sent${NC}"
    echo ""
    echo "Check mail log: tail -f /var/log/mail.log"
    echo ""
}

while true; do
    show_menu
    read -rp "Select option: " OPTION
    
    case $OPTION in
        1) create_email ;;
        2) list_emails ;;
        3) change_password ;;
        4) delete_email ;;
        5) view_settings ;;
        6) test_email ;;
        0) exit 0 ;;
        *) echo -e "${RED}❌ Invalid option${NC}" ; sleep 1 ;;
    esac
    
    if [ "$OPTION" != "0" ]; then
        read -rp "Press Enter to continue..."
    fi
done
