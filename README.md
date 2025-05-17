# WebStack Installer

A simple bash-based installer and remover for hosting individual websites on a VPS or dedicated server. Automatically sets up Apache, MariaDB, a Tailwind "Coming Soon" page, SSL with Let's Encrypt, and stores per-domain database credentials.

---

## ✅ Features

- Auto-installs **Apache** and **MariaDB**
- Creates a **unique database, user, and password** for each domain
- Deploys a **"Coming Soon" landing page** using Tailwind CSS
- Generates and configures **Apache virtual hosts**
- Optionally installs **Let's Encrypt SSL** automatically
- Saves credentials in per-domain folders:

```bash
/root/webstack-sites/
└── example.com/
├── db.txt
└── (future logs/configs)
```
- Includes a **removal script** to fully delete a domain, its site files, DB, and SSL cert

---

## 📦 Requirements

- Ubuntu/Debian or AlmaLinux (auto-detected)
- Root or `sudo` privileges
- Domain pointed to your server IP (for SSL)

---

## 🚀 Installation

### 1. Run the Installer Script

```bash
sudo bash webstack-installer.sh

    Enter your domain (e.g., example.com)

    Apache and MariaDB will be installed if not present

    A new DB + user + password will be generated

    Files saved to: /root/webstack-sites/example.com/db.txt

    Site root: /var/www/example.com

    Apache virtual host auto-enabled
```
You can optionally enable SSL via Let's Encrypt when prompted.
🧹 Removal

To completely remove a site, run:
```bash
sudo bash remove-domain.sh
```
This will:

    Disable and remove the Apache site config

    Delete /var/www/yourdomain.com

    Drop the database and user from MariaDB

    Delete /root/webstack-sites/yourdomain.com/

    Optionally remove the Let's Encrypt SSL certificate

📁 Example File Structure

/root/webstack-sites/
└── example.com/
    └── db.txt

/var/www/example.com/
└── index.html

/etc/apache2/sites-available/
└── example.com.conf

🔐 Security Note

All credentials are saved in plain text under /root/webstack-sites/. Restrict access to the /root directory and make sure only root/sudo users can access it.
