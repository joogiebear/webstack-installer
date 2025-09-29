# 📜 Scripts Documentation

Complete reference for all WebStack Installer scripts.

---

## 📋 All Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| [webstack-installer.sh](#webstack-installersh) | Install new domains | `sudo ./webstack-installer.sh` |
| [webstack-menu.sh](#webstack-menush) | Interactive menu | `sudo ./webstack-menu.sh` |
| [remove-domain.sh](#remove-domainsh) | Remove domains | `sudo ./remove-domain.sh` |
| [list-domains.sh](#list-domainssh) | List all domains | `sudo ./list-domains.sh` |
| [domain-info.sh](#domain-infosh) | View domain info | `sudo ./domain-info.sh [domain]` |
| [update-domain.sh](#update-domainsh) | Update settings | `sudo ./update-domain.sh` |
| [backup-domain.sh](#backup-domainsh) | Create backups | `sudo ./backup-domain.sh` |
| [restore-domain.sh](#restore-domainsh) | Restore backups | `sudo ./restore-domain.sh` |
| [setup-email.sh](#setup-emailsh) | Install email server | `sudo ./setup-email.sh` |
| [manage-email.sh](#manage-emailsh) | Manage emails | `sudo ./manage-email.sh` |

---

## webstack-installer.sh

**Purpose**: Main installation script for adding domains

**Usage**:
```bash
sudo ./webstack-installer.sh
```

**What it does**:
- Checks for existing installation (first-time setup or add domain)
- Installs web stack (Apache, MySQL, PHP) if needed
- Creates system user for the domain
- Configures Apache virtual host
- Creates MySQL database and user
- Generates secure credentials
- Creates default landing page
- Sets up phpMyAdmin access
- Configures firewall
- Saves all info to `/root/webstack-sites/DOMAIN/`

**Output Files**:
- `/root/webstack-sites/DOMAIN/info.txt` - Complete domain information
- `/root/webstack-sites/DOMAIN/sftp-guide.txt` - SFTP upload instructions
- `/etc/apache2/sites-available/DOMAIN.conf` - Apache configuration
- `/var/www/USERNAME/public_html/` - Website root directory

**Example**:
```bash
$ sudo ./webstack-installer.sh
Enter domain name: example.com
Installing domain example.com...
✅ Installation complete!
```

---

## webstack-menu.sh

**Purpose**: Interactive menu for all operations

**Usage**:
```bash
sudo ./webstack-menu.sh
```

**Features**:
- Access all scripts from one interface
- View system status
- Check service health
- Domain management
- Backup operations
- Email management

**Navigation**:
- Use numbers to select options
- 0 to exit
- Automatic error handling

**Example Menu**:
```
╔════════════════════════════════════════════════════════╗
║          🚀 WebStack Installer v2.0                   ║
║          Multi-Domain Hosting Management               ║
╚════════════════════════════════════════════════════════╝

📦 DOMAIN MANAGEMENT
  1) Install new domain
  2) List all domains
  3) Remove domain
  4) Domain information

🔧 MAINTENANCE
  5) Backup domain
  6) Restore domain
  7) Update domain settings

📧 EMAIL MANAGEMENT
  8) Setup email server
  9) Manage email accounts

ℹ️  SYSTEM
  10) System status
  0) Exit
```

---

## remove-domain.sh

**Purpose**: Safely remove a domain and all associated data

**Usage**:
```bash
sudo ./remove-domain.sh
```

**What it removes**:
- Website files (`/var/www/USERNAME/`)
- Database and database user
- Apache configuration
- System user
- Domain info files

**Safety**:
- Requires typing "DELETE" to confirm
- Shows exactly what will be removed
- Cannot be undone

**Example**:
```bash
$ sudo ./remove-domain.sh
Enter domain name to remove: example.com

⚠️  WARNING: This will remove:
  • Website files: /var/www/usr_examplecom
  • Database: examplecom_db
  • System user: usr_examplecom

Type 'DELETE' to confirm: DELETE
✅ Domain example.com has been completely removed
```

---

## list-domains.sh

**Purpose**: Show all installed domains with status

**Usage**:
```bash
sudo ./list-domains.sh
```

**Information Shown**:
- Domain name
- Status (Active/Disabled)
- System username
- Database name
- Disk usage
- Website root path

**Example Output**:
```
╔════════════════════════════════════════════════════════╗
║          📋 Managed Domains                            ║
╚════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Domain: example.com
Status: ✅ Active
User: usr_examplecom
Database: examplecom_db
Disk Usage: 156M
Root: /var/www/usr_examplecom/public_html

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Domain: test.net
Status: ✅ Active
User: usr_testnet
Database: testnet_db
Disk Usage: 42M
Root: /var/www/usr_testnet/public_html

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total domains: 2
```

---

## domain-info.sh

**Purpose**: Display detailed information for a specific domain

**Usage**:
```bash
sudo ./domain-info.sh [domain]
```

**Example**:
```bash
$ sudo ./domain-info.sh example.com

╔════════════════════════════════════════════════════════╗
║          📋 Domain Information: example.com            ║
╚════════════════════════════════════════════════════════╝

Domain: example.com
Website: http://example.com
Username: usr_examplecom

Database: examplecom_db
DB User: examplecom_user
DB Pass: aB12cD34eF56

phpMyAdmin: http://example.com/pma_xy789z/

SFTP Upload:
  Host: YOUR_SERVER_IP
  Port: 22
  Username: usr_examplecom
  Password: [in sftp-guide.txt]

Files Location: /var/www/usr_examplecom/public_html/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 Additional Files:
  • SFTP Guide: /root/webstack-sites/example.com/sftp-guide.txt
  • Email Settings: /root/webstack-sites/example.com/email-settings.txt

📊 Quick Stats:
  • Disk Usage: 156M
```

---

## update-domain.sh

**Purpose**: Modify domain settings and configuration

**Usage**:
```bash
sudo ./update-domain.sh
```

**Options**:
1. Install/Renew SSL Certificate
2. Change PHP Version
3. Regenerate Database Password
4. View Current Settings
5. Enable/Disable Site

**Example: Installing SSL**:
```bash
$ sudo ./update-domain.sh
Enter domain name: example.com

1) Install/Renew SSL Certificate
2) Change PHP Version
3) Regenerate Database Password
4) View Current Settings
5) Enable/Disable Site
0) Back to Main Menu

Select option: 1

📜 Installing SSL Certificate...
[Certbot process...]
✅ SSL installed successfully!
```

---

## backup-domain.sh

**Purpose**: Create backups of domains

**Usage**:
```bash
sudo ./backup-domain.sh
```

**Options**:
1. Backup specific domain
2. Backup all domains

**What's Backed Up**:
- All website files (tar.gz)
- MySQL database (sql.gz)
- Apache configuration
- Domain credentials
- Backup info file

**Backup Location**:
```
/root/backups/DOMAIN_YYYYMMDD_HHMMSS/
├── files.tar.gz
├── database.sql.gz
├── apache.conf
├── domain-info.txt
└── BACKUP_INFO.txt
```

**Example**:
```bash
$ sudo ./backup-domain.sh

1) Backup specific domain
2) Backup all domains

Select option: 1
Enter domain to backup: example.com

📦 Backing up example.com...
  • Backing up files...
  • Backing up database...
  • Backing up Apache config...
✅ Backup complete: /root/backups/example.com_20250115_120030 (158M)
```

---

## restore-domain.sh

**Purpose**: Restore domains from backups

**Usage**:
```bash
sudo ./restore-domain.sh
```

**Restore Options**:
1. Full restore (overwrite existing)
2. Restore to new domain name
3. Files only
4. Database only

**Features**:
- Lists available backups with details
- Shows backup contents before restoring
- Can restore to different domain name
- Updates configurations automatically

**Example**:
```bash
$ sudo ./restore-domain.sh

Available backups:

1) example.com_20250115_120030
   Size: 158M | Date: 2025-01-15 12:00:30
   Domain: example.com

2) test.net_20250114_020000
   Size: 42M | Date: 2025-01-14 02:00:00
   Domain: test.net

Select backup number to restore: 1

Restore options:
1) Full restore (overwrite existing example.com)
2) Restore to new domain name
3) Files only
4) Database only

Select option: 1

⚠️  Warning: This will restore to example.com
Continue? [y/N]: y

📂 Restoring files...
🗄️  Restoring database...
⚙️  Restoring Apache config...
✅ RESTORATION COMPLETE!
```

---

## setup-email.sh

**Purpose**: One-time email server installation

**Usage**:
```bash
sudo ./setup-email.sh
```

**What it installs**:
- Postfix (SMTP server)
- Dovecot (IMAP/POP3 server)
- Virtual mailbox system
- Mail database and users

**Configuration Files Created**:
- `/root/.email-config/mail-server.conf` - Server configuration
- `/root/.email-config/email-setup-guide.txt` - Complete setup guide with DNS instructions

**Features**:
- Works for ALL domains on server
- Virtual mailbox support
- Secure authentication
- Configurable ports
- Automatic firewall setup

**Post-Installation**:
1. Configure DNS records (MX, SPF)
2. Install SSL for mail server
3. Create email accounts with manage-email.sh

**Example**:
```bash
$ sudo ./setup-email.sh

╔════════════════════════════════════════════════════════╗
║          📧 Email Server Setup                         ║
╚════════════════════════════════════════════════════════╝

This will install:
  • Postfix (SMTP server)
  • Dovecot (IMAP/POP3 server)
  • Virtual mailbox support

Continue? [Y/n]: y

📦 Installing packages...
🗄️  Creating mail database...
⚙️  Configuring Postfix...
⚙️  Configuring Dovecot...
🔄 Restarting services...
🔥 Configuring firewall...

✅ Email server is now ready!

📋 Next steps:
  1. Read the setup guide: cat /root/.email-config/email-setup-guide.txt
  2. Configure DNS records for your domains
  3. Create email accounts: sudo ./manage-email.sh
```

---

## manage-email.sh

**Purpose**: Create and manage email accounts

**Usage**:
```bash
sudo ./manage-email.sh
```

**Menu Options**:
1. Create new email account
2. List all email accounts
3. Change email password
4. Delete email account
5. View email settings
6. Test email sending

**Features**:
- Works for all domains
- Secure password hashing (SHA512-CRYPT)
- Automatic mailbox creation
- Client configuration display

**Example: Creating Account**:
```bash
$ sudo ./manage-email.sh

╔════════════════════════════════════════════════════════╗
║          📧 Email Account Management                   ║
╚════════════════════════════════════════════════════════╝

1) Create new email account
2) List all email accounts
3) Change email password
4) Delete email account
5) View email settings
6) Test email sending
0) Exit

Select option: 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE NEW EMAIL ACCOUNT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Email address (e.g., user@domain.com): john@example.com
Password (min 8 characters): ********

✅ Email account created: john@example.com

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Email Client Settings:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMAP Server: mail.example.com
IMAP Port: 993 (SSL) or 143 (STARTTLS)

SMTP Server: mail.example.com
SMTP Port: 587 (STARTTLS) or 465 (SSL)

Username: john@example.com
Password: [your password]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔐 Permissions

All scripts require root/sudo access:
```bash
sudo ./script-name.sh
```

---

## 📁 File Locations

### Domain Information
```
/root/webstack-sites/DOMAIN/
├── info.txt                 # Complete domain info
├── sftp-guide.txt           # SFTP instructions
└── email-settings.txt       # Email client settings
```

### Website Files
```
/var/www/USERNAME/
├── public_html/             # Upload files here
├── logs/                    # Apache logs
├── tmp/                     # PHP temporary files
└── backups/                 # Local backups
```

### Backups
```
/root/backups/
└── DOMAIN_TIMESTAMP/
    ├── files.tar.gz
    ├── database.sql.gz
    ├── apache.conf
    └── BACKUP_INFO.txt
```

### Email Configuration
```
/root/.email-config/
├── mail-server.conf         # Server settings
└── email-setup-guide.txt    # Setup instructions
```

---

## 🆘 Common Issues

### Permission Denied

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

### Script Not Found

Run from scripts directory:
```bash
cd scripts
sudo ./script-name.sh
```

### Command Not Found

Missing dependencies. Install with:
```bash
sudo apt update
sudo apt install curl wget git
```

---

## 💡 Tips

1. **Always use sudo** when running scripts
2. **Read output messages** for important information
3. **Keep credentials safe** from `/root/webstack-sites/`
4. **Backup before making changes**
5. **Test on staging** before production changes

---

**Need more help? Check the [FAQ](../docs/FAQ.md) or [Installation Guide](../docs/INSTALLATION.md)**
