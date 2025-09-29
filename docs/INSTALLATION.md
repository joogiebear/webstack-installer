# 📚 Installation Guide

Complete guide to installing and configuring WebStack Installer.

---

## 🎯 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04+ or Debian 11+
- **RAM**: 1 GB (2 GB recommended)
- **Disk**: 10 GB free space
- **CPU**: 1 core (2+ recommended)
- **Root Access**: Required

### Recommended for Production
- **RAM**: 4 GB+
- **Disk**: 50 GB+ SSD
- **CPU**: 2+ cores
- **Network**: Static IP address

---

## 🚀 Installation Methods

### Method 1: Quick Install (Recommended)

One command installation:

```bash
curl -fsSL https://raw.githubusercontent.com/joogiebear/webstack-installer/main/install.sh | sudo bash
```

This will:
- Download all scripts
- Set permissions
- Create installation directory
- Launch the menu

### Method 2: Git Clone

For development or customization:

```bash
# Clone repository
git clone https://github.com/joogiebear/webstack-installer.git

# Navigate to directory
cd webstack-installer

# Make scripts executable
chmod +x scripts/*.sh

# Launch menu
sudo ./scripts/webstack-menu.sh
```

### Method 3: Manual Download

Download and extract:

```bash
# Download ZIP
wget https://github.com/joogiebear/webstack-installer/archive/refs/heads/main.zip

# Extract
unzip main.zip
cd webstack-installer-main

# Set permissions
chmod +x scripts/*.sh

# Run
sudo ./scripts/webstack-menu.sh
```

---

## 📦 What Gets Installed

The installer will set up these components:

### Core Web Stack
- **Apache 2.4+** - Web server
- **MariaDB 10.x** - Database server
- **PHP 8.0+** - Programming language
- **phpMyAdmin** - Database management GUI

### Supporting Tools
- **UFW** - Firewall
- **Certbot** - SSL certificates
- **OpenSSH** - SFTP access
- **Essential utilities** - curl, wget, git, zip, etc.

### Optional Components
- **Postfix** - SMTP mail server
- **Dovecot** - IMAP/POP3 server
- **SpamAssassin** - Spam filtering

---

## 🔧 First-Time Setup

### Step 1: Run the Installer

```bash
sudo ./scripts/webstack-menu.sh
```

Or directly:

```bash
sudo ./scripts/webstack-installer.sh
```

### Step 2: Install Your First Domain

When prompted:
1. Enter domain name (e.g., `example.com`)
2. Confirm installation
3. Wait for setup (2-5 minutes)

### Step 3: Configure DNS

Point your domain to your server:

```
A Record:
  Host: @
  Points to: YOUR_SERVER_IP

A Record:
  Host: www
  Points to: YOUR_SERVER_IP
```

Wait 5-60 minutes for DNS propagation.

### Step 4: Install SSL Certificate

```bash
sudo certbot --apache -d example.com -d www.example.com
```

Follow the prompts and select automatic HTTPS redirect.

### Step 5: Upload Your Website

Use SFTP with credentials from domain info:

```bash
# View credentials
sudo cat /root/webstack-sites/example.com/info.txt

# Or use the script
sudo ./scripts/domain-info.sh example.com
```

---

## 🌐 Adding More Domains

### Quick Add

```bash
sudo ./scripts/webstack-installer.sh
```

The installer detects existing installation and only adds the new domain.

### Multiple Domains

Each domain gets:
- ✅ Isolated system user
- ✅ Separate database
- ✅ Own credentials
- ✅ Independent SFTP access
- ✅ Unique phpMyAdmin URL

---

## 📧 Email Server Setup (Optional)

### One-Time Installation

```bash
sudo ./scripts/setup-email.sh
```

This installs email support for **ALL domains** on your server.

### Configure DNS for Email

For each domain using email:

```
MX Record:
  Host: @
  Points to: mail.yourdomain.com
  Priority: 10

A Record:
  Host: mail
  Points to: YOUR_SERVER_IP

TXT Record (SPF):
  Host: @
  Value: v=spf1 mx a ip4:YOUR_SERVER_IP ~all
```

### Install SSL for Mail Server

```bash
sudo certbot certonly --standalone -d mail.yourdomain.com
```

### Create Email Accounts

```bash
sudo ./scripts/manage-email.sh
```

Select option 1 to create accounts.

---

## 🔒 Security Configuration

### Firewall Setup

UFW is configured automatically. Verify:

```bash
sudo ufw status
```

Should show:
- Port 22 (SSH)
- Port 80 (HTTP)
- Port 443 (HTTPS)
- Ports 25, 587, 993 (if email installed)

### SSH Security

1. **Use SSH keys** instead of passwords
2. **Disable root SSH login** (after creating sudo user)
3. **Change default SSH port** (optional)

### MySQL Security

Run MySQL secure installation:

```bash
sudo mysql_secure_installation
```

Set root password and remove test databases.

### Regular Updates

Keep system updated:

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 📁 Directory Structure

After installation:

```
/root/webstack-sites/              # Domain info & credentials
├── example.com/
│   ├── info.txt                   # All domain information
│   ├── sftp-guide.txt             # SFTP instructions
│   └── email-settings.txt         # Email client settings

/var/www/                          # Website files
├── usr_abc123/                    # Domain's system user
│   ├── public_html/               # Upload files here!
│   │   ├── index.php
│   │   └── pma_xyz789/           # phpMyAdmin (random URL)
│   ├── logs/
│   │   ├── access.log
│   │   └── error.log
│   └── tmp/

/etc/apache2/
├── sites-available/               # Apache configs
│   └── example.com.conf
└── sites-enabled/                 # Active sites

/root/backups/                     # Backup storage
├── example.com_20250115_120000/
│   ├── files.tar.gz
│   ├── database.sql.gz
│   └── BACKUP_INFO.txt

/root/.email-config/               # Email server config
├── mail-server.conf
└── email-setup-guide.txt
```

---

## 🎯 Post-Installation Tasks

### 1. Test Your Setup

```bash
# Check Apache
sudo systemctl status apache2

# Check MySQL
sudo systemctl status mysql

# Check firewall
sudo ufw status

# Test website
curl -I http://your-domain.com
```

### 2. Create Regular Backups

```bash
# Backup all domains
sudo ./scripts/backup-domain.sh
```

Set up a cron job:

```bash
# Edit crontab
sudo crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/scripts/backup-domain.sh
```

### 3. Monitor Logs

```bash
# Apache error log
sudo tail -f /var/www/usr_*/logs/error.log

# Apache access log
sudo tail -f /var/www/usr_*/logs/access.log

# System log
sudo tail -f /var/log/syslog

# Mail log (if email installed)
sudo tail -f /var/log/mail.log
```

### 4. Configure Monitoring

Consider installing:
- **Netdata** - Real-time monitoring
- **Fail2ban** - Intrusion prevention
- **Logwatch** - Log analysis

---

## 🔄 Upgrading

### Update Scripts

```bash
cd webstack-installer
git pull origin main
chmod +x scripts/*.sh
```

### Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### Update PHP Version

```bash
# Install new PHP version
sudo apt install php8.2 php8.2-{cli,common,mysql,xml,curl,gd,mbstring,zip}

# Update domain to use new version
sudo ./scripts/update-domain.sh
```

---

## 🆘 Troubleshooting

### Apache Won't Start

```bash
# Check configuration
sudo apache2ctl configtest

# View error log
sudo tail -50 /var/log/apache2/error.log

# Restart Apache
sudo systemctl restart apache2
```

### Database Connection Fails

```bash
# Check MySQL is running
sudo systemctl status mysql

# Restart MySQL
sudo systemctl restart mysql

# View credentials
sudo cat /root/webstack-sites/example.com/info.txt
```

### Website Not Accessible

1. **Check DNS**: `nslookup yourdomain.com`
2. **Check Firewall**: `sudo ufw status`
3. **Check Apache**: `sudo systemctl status apache2`
4. **Check Site Enabled**: `ls -la /etc/apache2/sites-enabled/`

### SSL Certificate Issues

```bash
# Renew certificates
sudo certbot renew

# Force renewal
sudo certbot renew --force-renewal

# Check certificate status
sudo certbot certificates
```

---

## 💡 Tips & Best Practices

### 1. Regular Backups

- Backup before major changes
- Test restore procedures
- Store backups offsite
- Keep multiple backup versions

### 2. Security

- Keep system updated
- Use strong passwords
- Monitor logs regularly
- Limit SSH access
- Enable fail2ban

### 3. Performance

- Use caching (Redis/Memcached)
- Enable Gzip compression
- Optimize images
- Monitor resource usage
- Use CDN for static files

### 4. Maintenance

- Clean old logs
- Remove unused domains
- Update SSL certificates
- Monitor disk space
- Review access logs

---

## 📞 Getting Help

- **Documentation**: Check [FAQ](FAQ.md)
- **Issues**: [GitHub Issues](https://github.com/joogiebear/webstack-installer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/joogiebear/webstack-installer/discussions)
- **Logs**: Check system and application logs

---

## ✅ Installation Checklist

- [ ] System requirements met
- [ ] Scripts downloaded and executable
- [ ] First domain installed
- [ ] DNS configured and propagated
- [ ] SSL certificate installed
- [ ] Website files uploaded
- [ ] Database connection tested
- [ ] Firewall configured
- [ ] SSH secured
- [ ] Backup schedule created
- [ ] Monitoring configured
- [ ] Email server setup (if needed)

---

**Need more help? Check the [FAQ](FAQ.md) or open an issue on GitHub!**
