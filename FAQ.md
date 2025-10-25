# Frequently Asked Questions (FAQ)

## General Questions

### What is WebStack Installer?

WebStack Installer is an automated tool that transforms your VPS into a multi-domain web hosting platform. It installs and configures Apache, MySQL/MariaDB, PHP, and provides optional email server support with a focus on security through user isolation.

### What operating systems are supported?

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Debian 11 (Bullseye)
- Debian 12 (Bookworm)

### Can I use this on a production server?

Yes, but we recommend testing on a staging environment first. Always backup your data before running any installation scripts.

### Is this free to use?

Yes! WebStack Installer is open-source software released under the MIT License. It's completely free to use, modify, and distribute.

---

## Installation Questions

### Do I need a fresh VPS?

While not strictly required, a fresh VPS is recommended for best results. If you have existing web services, they may conflict with the installation.

### Can I install this without root access?

No, root access is required as the installer needs to create system users, install packages, and configure system services.

### What if I already have Apache/MySQL/PHP installed?

The installer will detect existing installations and skip those components. However, ensure your existing setup is compatible to avoid conflicts.

### How much disk space do I need?

Minimum requirements:
- **2GB** for base installation
- **5GB+** recommended for multiple domains and databases
- Additional space for website files and backups

### How much RAM is required?

- **Minimum:** 1GB RAM
- **Recommended:** 2GB+ RAM for better performance with multiple domains

---

## Domain Management Questions

### How many domains can I host?

There's no hard limit imposed by the installer. The number of domains you can host depends on your server resources (CPU, RAM, disk space) and traffic levels.

### Can I use subdomains?

Yes! The installer supports subdomains. Simply enter the full subdomain when installing (e.g., `blog.example.com`).

### What happens if I try to install the same domain twice?

The installer checks for existing domains and will prevent duplicate installations. Each domain must be unique.

### Can I have multiple domains point to the same files?

Not directly through the installer. Each domain gets its own isolated directory. However, you can manually create symbolic links or modify Apache configurations after installation.

### How do I transfer a domain to another server?

1. Backup the domain: `sudo ./scripts/backup-domain.sh`
2. Copy the backup file to the new server
3. Install the domain on the new server
4. Restore from backup: `sudo ./scripts/restore-domain.sh`
5. Update DNS records

---

## Security Questions

### How secure is this setup?

WebStack Installer implements several security best practices:
- Each domain runs as an isolated system user
- PHP open_basedir restrictions prevent cross-site access
- Secure file permissions
- Database credentials stored with restricted access
- Firewall configuration (UFW)
- SSL/TLS ready

### Where are database passwords stored?

Database credentials are stored in `/root/webstack-sites/[domain]/info.txt` with `600` permissions (readable only by root).

### Should I run mysql_secure_installation?

Yes! The installer prompts you to run `mysql_secure_installation` after first-time setup to secure your MySQL installation.

### How do I install SSL certificates?

After your domain's DNS is pointing to your server:

```bash
sudo certbot --apache -d example.com -d www.example.com
```

Certbot will automatically configure Apache and set up auto-renewal.

### Can I use custom SSL certificates?

Yes. You can manually configure Apache to use custom SSL certificates by editing `/etc/apache2/sites-available/[domain].conf`.

---

## Database Questions

### What database is created for each domain?

Each domain gets:
- Database name: `[username]_db`
- Database user: `[username]_user`
- Unique random password

### Can I create additional databases for a domain?

Yes. You can manually create additional databases using phpMyAdmin or MySQL CLI:

```bash
sudo mysql -u root
CREATE DATABASE newdb;
GRANT ALL ON newdb.* TO 'username_user'@'localhost';
```

### How do I access phpMyAdmin?

Access phpMyAdmin at: `http://yourdomain.com/phpmyadmin`

Use the database credentials found in `/root/webstack-sites/[domain]/info.txt`

### Can I access databases remotely?

By default, MySQL only accepts local connections. To enable remote access, you need to:
1. Configure MySQL to bind to external IP
2. Create remote user permissions
3. Configure firewall rules

**Warning:** Remote database access can be a security risk.

---

## File Management Questions

### How do I upload files to my website?

**Option 1: SFTP** (Recommended)
```
Host: your-server-ip
Port: 22
Protocol: SFTP
Username: [domain username]
Path: /var/www/[username]/public_html/
```

**Option 2: SCP**
```bash
scp -r ./files/* username@server:/var/www/username/public_html/
```

**Option 3: Git** (for developers)
```bash
ssh username@server
cd /var/www/username/public_html
git clone your-repo.git .
```

### What are the file permissions?

- Website files: owned by `www-data:www-data`
- Permissions: `755` for directories, `644` for files
- Upload via SFTP with domain user, files are accessible to Apache

### Where should I put my website files?

Place all website files in: `/var/www/[username]/public_html/`

This directory is your document root. Your `index.php` or `index.html` goes here.

### Can I modify Apache configuration?

Yes. The configuration file is located at:
```
/etc/apache2/sites-available/[domain].conf
```

After making changes:
```bash
sudo apache2ctl configtest
sudo systemctl reload apache2
```

---

## Email Server Questions

### Do I need to install the email server?

No, it's optional. Only install if you want to host email for your domains.

### What email features are included?

- SMTP/IMAP support
- Multiple email accounts per domain
- Spam filtering (SpamAssassin)
- Webmail access (Roundcube)

### Can I use external email services?

Yes! You can use services like Gmail, Office 365, or any other email provider. Just configure your domain's MX records accordingly.

### How do I create email accounts?

```bash
sudo ./scripts/manage-email.sh
```

Follow the interactive prompts to add, remove, or manage email accounts.

---

## Backup & Restore Questions

### How do I backup a domain?

```bash
sudo ./scripts/backup-domain.sh
```

This creates a compressed archive containing:
- All website files
- Database dump
- Apache configuration
- Domain credentials

### Where are backups stored?

Backups are stored in: `/var/www/[username]/backups/`

Each backup is timestamped: `domain-YYYY-MM-DD-HHMMSS.tar.gz`

### How do I restore from backup?

```bash
sudo ./scripts/restore-domain.sh
```

Follow the prompts to select a backup file and restore.

### Should I backup to another location?

**Yes!** Always keep backups on a separate server or storage service:

```bash
# Copy to remote server
scp /var/www/username/backups/*.tar.gz user@backup-server:/backups/

# Or use rsync
rsync -av /var/www/*/backups/ user@backup-server:/backups/
```

### Can I automate backups?

Yes! Set up a cron job:

```bash
sudo crontab -e
```

Add daily backup at 2 AM:
```
0 2 * * * /path/to/webstack-installer/scripts/backup-domain.sh domain.com
```

---

## Troubleshooting

### Apache won't start

Check configuration syntax:
```bash
sudo apache2ctl configtest
```

View error logs:
```bash
sudo tail -f /var/log/apache2/error.log
```

### Website shows 403 Forbidden

Check file permissions:
```bash
sudo chown -R www-data:www-data /var/www/username/public_html
sudo chmod -R 755 /var/www/username/public_html
```

### Database connection fails

1. Verify MySQL is running:
```bash
sudo systemctl status mysql
```

2. Check credentials:
```bash
sudo cat /root/webstack-sites/domain/info.txt
```

3. Test connection:
```bash
mysql -u username_user -p database_name
```

### Domain not accessible

1. **Check DNS:** Ensure A record points to your server IP
   ```bash
   dig yourdomain.com
   ```

2. **Check firewall:** Ensure ports 80/443 are open
   ```bash
   sudo ufw status
   ```

3. **Check Apache:** Ensure site is enabled
   ```bash
   sudo a2ensite yourdomain.com
   sudo systemctl reload apache2
   ```

4. **Check logs:**
   ```bash
   sudo tail -f /var/www/username/logs/error.log
   ```

### PHP not working

1. Check PHP module is enabled:
```bash
sudo a2enmod php8.x
sudo systemctl restart apache2
```

2. Create test file:
```bash
echo "<?php phpinfo(); ?>" > /var/www/username/public_html/info.php
```

Visit: `http://yourdomain.com/info.php`

### Out of disk space

Check disk usage:
```bash
df -h
```

Find large files:
```bash
sudo du -sh /var/www/*/
sudo du -sh /var/www/*/backups/
```

Clean old backups:
```bash
sudo find /var/www/*/backups/ -mtime +30 -delete
```

---

## Performance Questions

### How can I improve website performance?

1. **Enable caching:** Install and configure OPcache
2. **Use CDN:** Services like Cloudflare
3. **Optimize images:** Compress and serve WebP
4. **Enable gzip:** Already enabled by default
5. **Use HTTP/2:** Enable SSL and mod_http2

### Can I use Nginx instead of Apache?

The current version uses Apache. Nginx support may be added in future releases. You can manually configure Nginx, but you'll need to modify the scripts.

### How do I monitor resource usage?

```bash
# CPU and Memory
htop

# Disk usage
df -h

# Per-domain disk usage
sudo du -sh /var/www/*/

# Apache processes
ps aux | grep apache

# MySQL processes
ps aux | grep mysql
```

---

## Update & Maintenance Questions

### How do I update WebStack Installer?

```bash
cd webstack-installer
git pull origin main
chmod +x scripts/*.sh
```

### How do I update PHP/Apache/MySQL?

Use your system's package manager:
```bash
sudo apt update
sudo apt upgrade
```

### Do I need to maintain anything?

Regular maintenance tasks:
- Keep system packages updated
- Monitor disk space
- Review logs periodically
- Test backups regularly
- Renew SSL certificates (automatic with Certbot)

### How do I remove a domain?

```bash
sudo ./scripts/remove-domain.sh
```

This will:
- Remove website files
- Drop database
- Remove Apache configuration
- Delete system user
- Clean up all domain files

---

## Advanced Questions

### Can I use custom PHP versions per domain?

Yes, but requires additional configuration:
1. Install multiple PHP versions
2. Configure PHP-FPM pools per domain
3. Modify Apache vhost to use specific PHP-FPM socket

### Can I run Node.js applications?

Yes. Install Node.js and use a reverse proxy:
1. Install Node.js
2. Configure Apache as reverse proxy
3. Run Node.js app on different port
4. Proxy requests through Apache

### Can I use this with Docker?

Yes, but the scripts are designed for bare-metal installations. For Docker, consider using Docker Compose with separate containers for Apache, MySQL, and PHP.

### Can I integrate with CI/CD?

Yes! You can automate deployments:
```bash
# Example GitHub Actions workflow
- name: Deploy to server
  run: |
    scp -r ./build/* user@server:/var/www/username/public_html/
```

---

## Getting Help

### Where can I get support?

- **Documentation:** [GitHub Wiki](https://github.com/joogiebear/webstack-installer/wiki)
- **Bug Reports:** [GitHub Issues](https://github.com/joogiebear/webstack-installer/issues)
- **Discussions:** [GitHub Discussions](https://github.com/joogiebear/webstack-installer/discussions)

### How do I report a bug?

1. Go to [GitHub Issues](https://github.com/joogiebear/webstack-installer/issues)
2. Click "New Issue"
3. Choose "Bug Report" template
4. Fill in all required information
5. Submit

### Can I contribute?

Yes! Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

**Still have questions?** Open a [Discussion](https://github.com/joogiebear/webstack-installer/discussions) and we'll help you out!
