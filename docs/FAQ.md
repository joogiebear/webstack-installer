# ❓ Frequently Asked Questions (FAQ)

Complete FAQ covering installation, configuration, troubleshooting, and best practices.

---

## 📚 Table of Contents

- [General Questions](#general-questions)
- [Installation](#installation)
- [Domain Management](#domain-management)
- [Email Server](#email-server)
- [Security](#security)
- [Backups](#backups)
- [Troubleshooting](#troubleshooting)
- [Performance](#performance)
- [Advanced](#advanced)

---

## General Questions

### What is WebStack Installer?

WebStack Installer is an automated solution for creating multi-domain web hosting on Ubuntu/Debian servers. It replaces expensive control panels like cPanel with open-source automation scripts.

### What does it cost?

WebStack Installer is completely free and open-source (MIT License). You only pay for your VPS/server hosting.

### What operating systems are supported?

- Ubuntu 20.04 LTS or newer
- Debian 11 (Bullseye) or newer

### Do I need technical knowledge?

Basic Linux command-line knowledge is helpful, but the interactive menu makes it beginner-friendly. If you can SSH into a server and run commands, you can use this.

### Can I use this for production websites?

Yes! The installer follows best practices for security and performance. Many users run production sites successfully.

### Is there support available?

Community support through GitHub Issues and Discussions. Check documentation first, then open an issue if needed.

---

## Installation

### How do I install WebStack Installer?

Quick install:
```bash
curl -fsSL https://raw.githubusercontent.com/joogiebear/webstack-installer/main/install.sh | sudo bash
```

See [INSTALLATION.md](INSTALLATION.md) for detailed instructions.

### How long does installation take?

- Initial system setup: 5-10 minutes
- Adding a domain: 2-3 minutes
- Email server setup: 5-7 minutes

### Can I install on an existing server?

Yes, but it's recommended to use a fresh server to avoid conflicts. The installer checks for existing services before proceeding.

### What if installation fails?

Check the error message and system logs:
```bash
sudo tail -50 /var/log/syslog
```

Common issues:
- Insufficient disk space
- Missing sudo privileges
- Network connectivity problems
- Conflicting software

### Can I uninstall WebStack Installer?

Yes, you can remove individual domains with:
```bash
sudo ./scripts/remove-domain.sh
```

To completely remove the stack, manually uninstall Apache, MySQL, and PHP.

---

## Domain Management

### How many domains can I host?

Unlimited! Limited only by your server resources (RAM, CPU, disk space).

### How do I add a second domain?

Run the installer again:
```bash
sudo ./scripts/webstack-installer.sh
```

It detects the existing installation and adds the new domain.

### Can I host subdomains?

Yes! Treat subdomains like regular domains when installing.

### How do I remove a domain?

```bash
sudo ./scripts/remove-domain.sh
```

This removes all files, databases, and configurations.

### Where are my website files located?

```
/var/www/usr_USERNAME/public_html/
```

Replace `USERNAME` with your domain's username (found in info.txt).

### How do I access phpMyAdmin?

Each domain gets a unique phpMyAdmin URL with a random path for security. Find it in:
```bash
sudo cat /root/webstack-sites/example.com/info.txt
```

### Can I use different PHP versions per domain?

Yes! Use the update script:
```bash
sudo ./scripts/update-domain.sh
```

Select option 2 to change PHP version.

### How do I view domain credentials?

```bash
sudo ./scripts/domain-info.sh example.com
```

Or directly:
```bash
sudo cat /root/webstack-sites/example.com/info.txt
```

### Can I change database passwords?

Yes, use the update script:
```bash
sudo ./scripts/update-domain.sh
```

Select option 3 to regenerate the database password.

---

## Email Server

### Do I need the email server?

No, it's completely optional. Only install if you want to send/receive emails from your domains.

### Can email work for multiple domains?

Yes! One email server installation works for ALL domains on your server.

### How do I setup email?

```bash
sudo ./scripts/setup-email.sh
```

Then configure DNS records and create email accounts.

### What email protocols are supported?

- SMTP (sending) - Port 25, 587
- IMAP (receiving) - Port 143, 993
- POP3 (receiving) - Port 110, 995

### How do I create email accounts?

```bash
sudo ./scripts/manage-email.sh
```

Select option 1 to create accounts.

### What email clients can I use?

Any standard email client:
- Gmail app
- Apple Mail
- Outlook
- Thunderbird
- K-9 Mail
- Any webmail

### Why aren't my emails being delivered?

Common issues:
1. **DNS not configured** - Add MX and SPF records
2. **Port 25 blocked** - Use port 587 instead
3. **No reverse DNS** - Contact your hosting provider
4. **Missing SPF/DKIM** - Configure anti-spam records

### How do I check mail logs?

```bash
sudo tail -f /var/log/mail.log
```

### Can I add webmail (Roundcube)?

Not included by default, but can be installed separately:
```bash
sudo apt install roundcube roundcube-mysql
```

---

## Security

### Is this setup secure?

Yes, it follows security best practices:
- Isolated system users per domain
- Restricted file permissions
- PHP open_basedir restrictions
- Random phpMyAdmin URLs
- SSL/TLS support
- Firewall configured

### How do I install SSL certificates?

```bash
sudo certbot --apache -d example.com -d www.example.com
```

Certificates auto-renew every 90 days.

### How do I secure SSH access?

1. **Use SSH keys** instead of passwords
2. **Create a sudo user** and disable root login
3. **Change SSH port** (optional)
4. **Install fail2ban** for brute-force protection

### What firewall ports are open?

Default:
- 22 (SSH)
- 80 (HTTP)
- 443 (HTTPS)

With email:
- 25, 587 (SMTP)
- 143, 993 (IMAP)
- 110, 995 (POP3)

### How often should I update?

Update weekly:
```bash
sudo apt update && sudo apt upgrade -y
```

Check for security updates daily.

### Are my database credentials safe?

Credentials are stored in `/root/webstack-sites/` with 600 permissions (root only). Never store them in web-accessible directories.

### How do I prevent SQL injection?

Use prepared statements and parameterized queries in your application code. The installer provides secure database configurations.

---

## Backups

### How do I create backups?

```bash
sudo ./scripts/backup-domain.sh
```

Choose single domain or all domains.

### Where are backups stored?

```
/root/backups/DOMAIN_TIMESTAMP/
```

Each backup includes files, database, and configs.

### How do I restore from backup?

```bash
sudo ./scripts/restore-domain.sh
```

Select the backup and restore option.

### Can I backup to remote storage?

Not built-in, but you can use rsync or rclone:

```bash
# Sync to remote server
rsync -avz /root/backups/ user@remote:/backups/

# Sync to cloud (rclone)
rclone sync /root/backups/ remote:backups/
```

### How do I automate backups?

Create a cron job:
```bash
sudo crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/scripts/backup-domain.sh
```

### How much space do backups use?

Depends on site size. Check with:
```bash
du -sh /root/backups/*
```

### Should I keep all backups?

Keep last 7 daily, 4 weekly, 3 monthly backups. Delete older ones to save space.

---

## Troubleshooting

### Website shows "Apache2 Default Page"

The site isn't enabled. Run:
```bash
sudo a2ensite example.com
sudo systemctl reload apache2
```

### "403 Forbidden" error

Permission issue. Fix with:
```bash
sudo chown -R www-data:www-data /var/www/usr_USERNAME/
sudo chmod -R 755 /var/www/usr_USERNAME/public_html/
```

### Database connection fails

1. Check MySQL is running:
```bash
sudo systemctl status mysql
```

2. Verify credentials:
```bash
sudo cat /root/webstack-sites/example.com/info.txt
```

3. Test connection:
```bash
mysql -u username -p database_name
```

### SSL certificate won't install

Common causes:
1. **DNS not pointing to server** - Wait for propagation
2. **Port 80 blocked** - Check firewall
3. **Domain not accessible** - Verify Apache is running

Test:
```bash
curl -I http://example.com
```

### "500 Internal Server Error"

Check Apache error log:
```bash
sudo tail -50 /var/www/usr_USERNAME/logs/error.log
```

Common causes:
- PHP syntax errors
- .htaccess issues
- Permission problems
- Missing PHP modules

### phpMyAdmin "Access Denied"

Use database credentials from info.txt, NOT system user password.

### Email not sending

1. Check mail logs:
```bash
sudo tail -50 /var/log/mail.log
```

2. Test mail server:
```bash
echo "Test" | mail -s "Subject" you@example.com
```

3. Check mail queue:
```bash
sudo postqueue -p
```

### High memory usage

Check processes:
```bash
top
```

Optimize:
- Disable unused Apache modules
- Tune MySQL configuration
- Enable PHP OPcache
- Use caching (Redis/Memcached)

### Disk space full

Find large files:
```bash
sudo du -sh /* | sort -hr | head -10
```

Clean up:
```bash
# Remove old logs
sudo find /var/log -type f -name "*.log.*" -delete

# Clean package cache
sudo apt clean

# Remove old backups
sudo rm -rf /root/backups/old_backup_*
```

---

## Performance

### How do I optimize performance?

1. **Enable caching** (Redis, Memcached)
2. **Use HTTP/2**
3. **Enable Gzip compression**
4. **Optimize images**
5. **Use a CDN**
6. **Enable PHP OPcache**

### Can I use Nginx instead of Apache?

The installer is built for Apache. For Nginx, you'll need to modify the scripts or use them as reference.

### How many concurrent visitors can I handle?

Depends on:
- Server resources (RAM, CPU)
- Website optimization
- Caching configuration
- Database efficiency

A typical 2GB RAM server can handle:
- 100-500 concurrent visitors (static sites)
- 50-200 concurrent visitors (dynamic sites)

### Should I use a CDN?

Yes, for production sites with traffic. CDNs improve:
- Page load speed
- Global availability
- Bandwidth costs
- Server load

Popular CDNs:
- Cloudflare (free tier available)
- Amazon CloudFront
- BunnyCDN
- StackPath

---

## Advanced

### Can I customize the installer?

Yes! All scripts are bash and easy to modify. Fork the repository and adapt to your needs.

### Can I use this with Docker?

The installer is designed for bare metal/VM installations. For Docker, consider creating containerized versions.

### How do I add custom Apache modules?

```bash
# Install module
sudo apt install libapache2-mod-NAME

# Enable module
sudo a2enmod NAME

# Restart Apache
sudo systemctl restart apache2
```

### Can I use PostgreSQL instead of MySQL?

The installer is built for MySQL/MariaDB. For PostgreSQL, you'll need to modify the database creation scripts.

### How do I enable HTTP/2?

```bash
# Enable HTTP/2 module
sudo a2enmod http2

# Add to Apache config
echo "Protocols h2 http/1.1" | sudo tee -a /etc/apache2/apache2.conf

# Restart Apache
sudo systemctl restart apache2
```

### Can I run multiple PHP versions simultaneously?

Yes, using PHP-FPM:

```bash
# Install multiple PHP versions
sudo apt install php8.1-fpm php8.2-fpm

# Configure per site in Apache conf
```

### How do I migrate from cPanel?

1. **Backup cPanel sites** using cPanel backup tool
2. **Install WebStack** on new server
3. **Create domains** with WebStack installer
4. **Upload files** via SFTP
5. **Import databases** via phpMyAdmin
6. **Update DNS** to point to new server
7. **Install SSL** certificates

### Can I automate domain provisioning?

Yes, WebStack scripts can be called from other scripts:

```bash
#!/bin/bash
DOMAIN="example.com"
echo "$DOMAIN" | sudo ./scripts/webstack-installer.sh
```

### How do I monitor server health?

Install monitoring tools:

```bash
# Netdata (real-time monitoring)
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Glances (terminal monitoring)
sudo apt install glances
```

### Can I use this for reseller hosting?

Yes, but you'll need to add:
- User management system
- Billing integration
- Resource limits (quotas)
- Client panel/dashboard

Consider WHMCS or similar for complete reseller setup.

---

## 🆘 Still Need Help?

- **Documentation**: Read [INSTALLATION.md](INSTALLATION.md)
- **Issues**: [Open a GitHub Issue](https://github.com/joogiebear/webstack-installer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/joogiebear/webstack-installer/discussions)
- **Logs**: Always check logs when troubleshooting

---

**Don't see your question? Open an issue on GitHub and we'll add it to the FAQ!**
