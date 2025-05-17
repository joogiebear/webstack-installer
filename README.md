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
wget https://raw.githubusercontent.com/joogiebear/webstack-installer/main/webstack-installer.sh
chmod +x webstack-installer.sh
sudo ./webstack-installer.sh
```
You can optionally enable SSL via Let's Encrypt when prompted.
🧹 Removal

To completely remove a site, run:
```bash
wget https://raw.githubusercontent.com/joogiebear/webstack-installer/main/remove-domain.sh
chmod +x remove-domain.sh
sudo ./remove-domain.sh

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
