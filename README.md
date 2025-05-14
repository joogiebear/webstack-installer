# 🛠️ Webstack Installer

A modular and re-runnable bash script that sets up a new domain with your choice of Apache or Nginx, optional MariaDB/MySQL support, and a responsive Tailwind CSS "Coming Soon" page — all in minutes.

Supports Debian/Ubuntu and AlmaLinux systems.

---

## ✅ Features

- Web server choice: Apache or Nginx
- Optional database setup: MariaDB, MySQL, or skip
- Generates and logs database credentials
- Sets up domain directory and virtual host
- Installs free SSL via Let's Encrypt
- Creates a mobile-optimized "Coming Soon" page
- Re-runnable for adding multiple domains
- Logs setup steps to `/opt/stack-setup.log`

---

## 📦 Requirements

- VPS or dedicated server
- Root or sudo access
- A registered domain pointed to the server IP

---

## 🚀 Quick Start

- wget https://raw.githubusercontent.com/joogiebear/webstack-installer/main/webstack-installer.sh
- chmod +x webstack-installer.sh
- sudo ./webstack-installer.sh
