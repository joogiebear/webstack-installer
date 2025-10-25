# 🚀 WebStack Installer v2.0

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/joogiebear/webstack-installer.svg)](https://github.com/joogiebear/webstack-installer/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/joogiebear/webstack-installer.svg)](https://github.com/joogiebear/webstack-installer/issues)
[![GitHub forks](https://img.shields.io/github/forks/joogiebear/webstack-installer.svg)](https://github.com/joogiebear/webstack-installer/network)
[![GitHub last commit](https://img.shields.io/github/last-commit/joogiebear/webstack-installer.svg)](https://github.com/joogiebear/webstack-installer/commits/main)

**Complete Multi-Domain Web Hosting Automation**

Transform your VPS into a powerful multi-domain hosting platform with Apache, MySQL, PHP, and optional email server support.

---

## ✨ Features

### Core Features
- 🌐 **Multi-Domain Hosting** - Host unlimited websites on one server
- 🗄️ **Automated Database Setup** - MySQL database created per domain
- 🔒 **Security First** - Isolated users, secure permissions, SSL ready
- 📧 **Email Server** - Optional Postfix/Dovecot email hosting
- 🎯 **Interactive Menu** - User-friendly management interface
- 📦 **Backup & Restore** - Protect your websites
- 🎨 **Modern Default Page** - Professional landing page

### Advanced Features (v2.0+)
- 🔐 **SSL Manager** - Complete SSL certificate automation and monitoring
- 📊 **Health Monitoring** - System diagnostics with recommendations
- 📋 **JSON/CSV Export** - Export domain data for automation
- 🔄 **Domain Cloning** - Duplicate domains with one command
- 🎯 **Bulk Backups** - Backup all domains simultaneously
- 🔍 **Advanced Filtering** - Filter and sort domains by multiple criteria
- 🚀 **Parallel Processing** - Speed up bulk operations
- 📡 **Remote Backups** - Automatic rsync to backup servers
- 🏥 **Health Checks** - Comprehensive system diagnostics
- 📈 **Resource Monitoring** - Track disk, memory, SSL expiry

---

## 📋 Requirements

- **OS**: Ubuntu 20.04+ or Debian 11+
- **Root Access**: Required
- **Fresh VPS Recommended**: For best results

---

## 🚀 Quick Install

### Method 1: One-Line Install (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/joogiebear/webstack-installer/main/install.sh | sudo bash
```

### Method 2: Git Clone
```bash
git clone https://github.com/joogiebear/webstack-installer.git
cd webstack-installer
sudo ./webstack-menu.sh
```

### Method 3: Manual Download
Download the ZIP, extract it, and run:
```bash
sudo ./webstack-menu.sh
```

---

## 📚 Usage

### Interactive Menu
```bash
sudo ./webstack-menu.sh
```

### Install a New Domain
```bash
# Standard installation
sudo ./scripts/webstack-installer.sh

# Preview without making changes (dry-run)
sudo ./scripts/webstack-installer.sh --dry-run

# View help
sudo ./scripts/webstack-installer.sh --help
```

### List All Domains
```bash
sudo ./list-domains.sh
```

### Remove a Domain
```bash
sudo ./remove-domain.sh
```

---

## 🎯 What Gets Installed

For each domain, the installer creates:

- ✅ System user (isolated from other sites)
- ✅ Apache virtual host with PHP support
- ✅ MySQL database with dedicated user
- ✅ SSL-ready configuration
- ✅ Modern default landing page
- ✅ phpMyAdmin access
- ✅ Logging directory
- ✅ Backup directory

---

## 📂 Directory Structure

```
/var/www/[username]/
├── public_html/           # Website files
│   ├── index.php         # Default landing page
│   └── phpmyadmin/       # Database management
├── logs/                 # Apache logs
├── backups/              # Website backups
├── tmp/                  # PHP temporary files
└── db-credentials.txt    # Database info (secure)
```

---

## 🔐 Security Features

- Each domain runs as its own system user
- Isolated file permissions
- PHP open_basedir restrictions
- Secure database credentials storage
- SSL/TLS ready
- Optional ModSecurity support
- Security hardening script with HTTP headers
- Automatic rollback on installation failure
- Comprehensive installation logging

### Security Hardening
Apply additional security measures:
```bash
sudo ./scripts/harden-security.sh
```

Features:
- Security headers (X-Frame-Options, CSP, HSTS)
- Hide server information
- Disable dangerous PHP functions
- ModSecurity WAF (optional)
- Secure file permissions

---

## 📧 Email Server (Optional)

Setup a complete email server for your domains:

```bash
sudo ./setup-email.sh
```

Features:
- SMTP/IMAP support
- Multiple email accounts per domain
- Spam filtering with SpamAssassin
- Webmail (Roundcube)

---

## 🔄 Common Tasks

### Manage SSL Certificates
```bash
# Interactive SSL manager (recommended)
sudo ./scripts/ssl-manager.sh

# Or install directly
certbot --apache -d example.com -d www.example.com
```

### Backup Domains
```bash
# Backup single domain
sudo ./scripts/backup-domain.sh

# Backup all domains at once (new!)
sudo ./scripts/backup-all.sh

# Backup with remote copy
sudo ./scripts/backup-all.sh --remote user@backup-server --remote-path /backups
```

### List and Monitor Domains
```bash
# List all domains (table view)
sudo ./scripts/list-domains.sh

# Export to JSON
sudo ./scripts/list-domains.sh --json

# Show SSL status
sudo ./scripts/list-domains.sh --ssl --stats
```

### Check System Health
```bash
# Run comprehensive health check
sudo ./scripts/health-check.sh
```

### Clone a Domain
```bash
# Duplicate existing domain with new name
sudo ./scripts/clone-domain.sh
```

### View Domain Information
```bash
# Pretty formatted view
sudo ./scripts/domain-info.sh example.com

# JSON output
sudo ./scripts/domain-info.sh --json example.com
```

---

## 🛠️ Available Scripts

### Core Management
| Script | Description |
|--------|-------------|
| `webstack-menu.sh` | Interactive management menu |
| `webstack-installer.sh` | Install new domain (supports --dry-run, --help) |
| `remove-domain.sh` | Remove domain completely |
| `clone-domain.sh` | **NEW** Clone/duplicate existing domain with new name |

### Information & Monitoring
| Script | Description |
|--------|-------------|
| `list-domains.sh` | **Enhanced** List domains (JSON/CSV, filtering, sorting) |
| `domain-info.sh` | **Enhanced** View domain details (JSON support, SSL status) |
| `health-check.sh` | **NEW** System health diagnostics and recommendations |

### Backup & Restore
| Script | Description |
|--------|-------------|
| `backup-domain.sh` | Backup single domain files & database |
| `backup-all.sh` | **NEW** Backup all domains at once (parallel, remote) |
| `restore-domain.sh` | Restore from backup |

### SSL Management
| Script | Description |
|--------|-------------|
| `ssl-manager.sh` | **NEW** Complete SSL management suite (install, renew, monitor) |

### Email (Optional)
| Script | Description |
|--------|-------------|
| `setup-email.sh` | Install email server |
| `manage-email.sh` | Manage email accounts |

### Security & Maintenance
| Script | Description |
|--------|-------------|
| `harden-security.sh` | Apply security hardening (headers, PHP settings) |
| `test-installation.sh` | Run automated tests to verify system readiness |
| `update-domain.sh` | Update domain configuration |

---

## 🧪 Testing

Before installation, verify your system is ready:
```bash
sudo ./scripts/test-installation.sh
```

This runs automated tests to check:
- Required packages installed
- Services running
- Script syntax validation
- Domain validation logic
- Apache configuration
- MySQL connectivity

## 📖 Example Workflow

1. **Test your system:**
   ```bash
   sudo ./scripts/test-installation.sh
   ```

2. **Preview installation (optional):**
   ```bash
   sudo ./scripts/webstack-installer.sh --dry-run
   # Enter: example.com
   ```

3. **Install a domain:**
   ```bash
   sudo ./scripts/webstack-installer.sh
   # Enter: example.com
   ```

4. **Point DNS to your server:**
   - Add A record: `example.com` → `your-server-ip`
   - Add A record: `www.example.com` → `your-server-ip`

5. **Upload your website:**
   ```bash
   # Via SFTP or SCP
   scp -r ./website/* user@server:/var/www/examplecom/public_html/
   ```

6. **Install SSL:**
   ```bash
   sudo certbot --apache -d example.com -d www.example.com
   ```

7. **Apply security hardening (recommended):**
   ```bash
   sudo ./scripts/harden-security.sh
   ```

8. **Done!** Visit https://example.com

---

## ❓ Troubleshooting

### Apache won't start
```bash
# Check configuration
sudo apache2ctl configtest

# View error log
sudo tail -f /var/log/apache2/error.log
```

### Database connection fails
```bash
# Check MySQL is running
sudo systemctl status mysql

# View credentials
sudo cat /var/www/[username]/db-credentials.txt
```

### Domain not accessible
- Verify DNS is pointing to correct IP
- Check firewall allows ports 80 and 443
- Ensure Apache site is enabled: `sudo a2ensite example.com`

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🙏 Support

- 📚 **Documentation**: [GitHub Wiki](https://github.com/joogiebear/webstack-installer/wiki)
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/joogiebear/webstack-installer/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/joogiebear/webstack-installer/discussions)

---

## ⚠️ Important Notes

- **Backup regularly** - Use the backup script
- **Keep systems updated** - Run `apt update && apt upgrade`
- **Secure SSH** - Use key-based authentication
- **Monitor resources** - Check disk space and memory
- **Review logs** - Check `/var/www/[username]/logs/`

---

## 🎓 Learn More

- [Apache Documentation](https://httpd.apache.org/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Let's Encrypt](https://letsencrypt.org/getting-started/)
- [PHP Documentation](https://www.php.net/docs.php)

---

**Made with ❤️ for the self-hosting community**

⭐ Star this repo if it helped you!
