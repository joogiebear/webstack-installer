# 🚀 WebStack Installer v2.0

**Complete Multi-Domain Web Hosting Automation**

Transform your VPS into a powerful multi-domain hosting platform with Apache, MySQL, PHP, and optional email server support.

---

## ✨ Features

- 🌐 **Multi-Domain Hosting** - Host unlimited websites on one server
- 🗄️ **Automated Database Setup** - MySQL database created per domain
- 🔒 **Security First** - Isolated users, secure permissions, SSL ready
- 📧 **Email Server** - Optional Postfix/Dovecot email hosting
- 🎯 **Interactive Menu** - User-friendly management interface
- 📦 **Backup & Restore** - Protect your websites
- 🎨 **Modern Default Page** - Professional landing page

---

## 📋 Requirements

- **OS**: Ubuntu 20.04+ or Debian 11+
- **Root Access**: Required
- **Fresh VPS Recommended**: For best results

---

## 🚀 Quick Install

### Method 1: One-Line Install (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-REPO/webstack-installer/main/install.sh | sudo bash
```

### Method 2: Git Clone
```bash
git clone https://github.com/YOUR-REPO/webstack-installer.git
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
sudo ./webstack-installer.sh
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

### Install SSL Certificate
```bash
certbot --apache -d example.com -d www.example.com
```

### Backup a Domain
```bash
sudo ./backup-domain.sh
```

### View Database Credentials
```bash
sudo cat /var/www/[username]/db-credentials.txt
```

---

## 🛠️ Available Scripts

| Script | Description |
|--------|-------------|
| `webstack-menu.sh` | Interactive management menu |
| `webstack-installer.sh` | Install new domain |
| `remove-domain.sh` | Remove domain completely |
| `list-domains.sh` | List all managed domains |
| `domain-info.sh` | View domain details |
| `backup-domain.sh` | Backup domain files & database |
| `restore-domain.sh` | Restore from backup |
| `setup-email.sh` | Install email server |
| `manage-email.sh` | Manage email accounts |

---

## 📖 Example Workflow

1. **Install a domain:**
   ```bash
   sudo ./webstack-installer.sh
   # Enter: example.com
   ```

2. **Point DNS to your server:**
   - Add A record: `example.com` → `your-server-ip`
   - Add A record: `www.example.com` → `your-server-ip`

3. **Upload your website:**
   ```bash
   # Via SFTP or SCP
   scp -r ./website/* user@server:/var/www/examplecom/public_html/
   ```

4. **Install SSL:**
   ```bash
   sudo certbot --apache -d example.com -d www.example.com
   ```

5. **Done!** Visit https://example.com

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

- 📚 **Documentation**: [GitHub Wiki](#)
- 🐛 **Bug Reports**: [GitHub Issues](#)
- 💬 **Discussions**: [GitHub Discussions](#)

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
