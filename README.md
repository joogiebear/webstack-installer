# 🛠️ General Purpose Web Server Setup Script

This bash script sets up a new domain on a VPS or dedicated server with optional database support and a mobile-optimized "Coming Soon" page. It works on Debian/Ubuntu and AlmaLinux-based systems.

## ✅ Features

- Prompts for:
  - Web server: Apache or Nginx
  - Database: MariaDB, MySQL, or none
  - Domain name
- Automatically installs required packages
- Sets up VirtualHost/Server Block
- Installs free SSL via Let's Encrypt
- Creates a Tailwind-powered mobile-first Coming Soon page
- Saves generated database credentials to `/root/db-credentials.txt`
- Re-runnable to add additional domains later without re-installing packages

---

## 📦 Requirements

- Root or `sudo` access to the server
- A domain name pointed to the server's IP address (for SSL)
- A clean Debian/Ubuntu or AlmaLinux system

---

## 🚀 Usage

### 1. Upload and Make Executable

```bash
wget https://raw.githubusercontent.com/yourusername/server-setup-script/main/setup-site.sh
chmod +x setup-site.sh
