# 🚀 GitHub Repository Setup Instructions

Complete step-by-step guide to publish your WebStack Installer to GitHub.

---

## ✅ Prerequisites

- [ ] GitHub account created
- [ ] Git installed on your computer
- [ ] Basic understanding of git commands
- [ ] All scripts tested and working

---

## 📋 Step 1: Prepare Your Repository

### 1.1 Review All Files

Make sure you have all these files in your repository:

```
webstack-installer-repo/
├── README.md ✅
├── LICENSE ✅
├── install.sh ✅
├── .gitignore ✅
├── SETUP-INSTRUCTIONS.md ✅ (this file)
├── scripts/
│   ├── webstack-installer.sh ✅
│   ├── remove-domain.sh ✅
│   ├── list-domains.sh ✅
│   ├── domain-info.sh ✅
│   ├── update-domain.sh ✅
│   ├── backup-domain.sh ✅
│   ├── restore-domain.sh ✅
│   ├── setup-email.sh ✅
│   ├── manage-email.sh ✅
│   └── webstack-menu.sh ✅
├── docs/
│   ├── INSTALLATION.md ✅
│   └── FAQ.md ✅
├── examples/ ✅
└── .github/
    └── ISSUE_TEMPLATE/ ✅
```

### 1.2 Test Locally

Before publishing, test on a fresh server:

```bash
# Test the installer
sudo ./scripts/webstack-installer.sh

# Test the menu
sudo ./scripts/webstack-menu.sh

# Test backup
sudo ./scripts/backup-domain.sh

# Test email (optional)
sudo ./scripts/setup-email.sh
```

---

## 📋 Step 2: Create GitHub Repository

### 2.1 On GitHub.com

1. Go to https://github.com/new
2. Fill in:
   - **Repository name**: `webstack-installer`
   - **Description**: `Multi-domain web hosting automation with Apache, MySQL, PHP, and email support`
   - **Visibility**: Public ✅
   - **Initialize**: Leave unchecked (we have files already)

3. Click **"Create repository"**

### 2.2 Set Repository Details

After creating, go to Settings:

1. **About section** (top right):
   - Click the gear icon ⚙️
   - Add description: `Complete multi-domain hosting solution. Replace cPanel with open-source automation.`
   - Add topics: `web-hosting`, `vps`, `apache`, `mysql`, `php`, `email-server`, `postfix`, `dovecot`, `automation`, `bash`, `ubuntu`, `debian`, `self-hosted`
   - ✅ Save changes

2. **Features**:
   - ✅ Issues
   - ✅ Discussions (optional but recommended)
   - ✅ Wiki (optional)

---

## 📋 Step 3: Push Your Code

### 3.1 Initialize Git

```bash
cd webstack-installer-repo

# Initialize repository
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial commit: Complete webstack installer suite

- 10 management scripts
- Multi-domain hosting support
- Email server integration
- Backup and restore functionality
- Complete documentation"
```

### 3.2 Connect to GitHub

Replace `YOUR-USERNAME` with your actual GitHub username:

```bash
# Add remote
git remote add origin https://github.com/YOUR-USERNAME/webstack-installer.git

# Rename branch to main
git branch -M main

# Push to GitHub
git push -u origin main
```

If prompted for credentials:
- **Username**: Your GitHub username
- **Password**: Use a Personal Access Token (not your password)

#### Creating a Personal Access Token:
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Select scopes: `repo` (full control)
4. Copy the token (you won't see it again!)

---

## 📋 Step 4: Create First Release

### 4.1 Tag Your Version

```bash
# Create version tag
git tag -a v1.0.0 -m "v1.0.0 - Initial Release

Features:
- Multi-domain hosting
- MySQL database per domain
- Email server support
- Backup and restore
- SSL ready
- 10 management scripts"

# Push tag to GitHub
git push origin v1.0.0
```

### 4.2 Create Release on GitHub

1. Go to your repository on GitHub
2. Click **"Releases"** → **"Create a new release"**
3. Fill in:
   - **Tag**: v1.0.0
   - **Release title**: `WebStack Installer v1.0.0`
   - **Description**:

```markdown
## 🎉 Initial Release

Complete multi-domain web hosting automation for Ubuntu/Debian servers.

### ✨ Features

- 🌐 Multi-domain hosting with Apache
- 🗄️ MySQL database per domain
- 📧 Email server (Postfix + Dovecot)
- 💾 Backup and restore functionality
- 🔒 SSL certificate support
- 🎯 Interactive management menu

### 📦 Installation

**Quick Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/webstack-installer/main/install.sh | sudo bash
```

**Manual Install:**
```bash
git clone https://github.com/YOUR-USERNAME/webstack-installer.git
cd webstack-installer
sudo ./scripts/webstack-menu.sh
```

### 📚 Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [FAQ](docs/FAQ.md)
- [Scripts Documentation](scripts/README.md)

### 🐛 Known Issues

None at this time. Please report issues on GitHub!

### 📝 Changelog

Initial release with all core features.
```

4. Click **"Publish release"**

---

## 📋 Step 5: Update URLs in Scripts

### 5.1 Update install.sh

Edit `/home/claude/webstack-installer-repo/install.sh`:

Find this line:
```bash
REPO="YOUR-USERNAME/webstack-installer"
```

Replace with:
```bash
REPO="your-actual-username/webstack-installer"
```

### 5.2 Commit and Push

```bash
git add install.sh
git commit -m "Update repository URL in install.sh"
git push
```

---

## 📋 Step 6: Test Installation

### 6.1 Test One-Line Install

On a fresh server:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/webstack-installer/main/install.sh | sudo bash
```

### 6.2 Test Git Clone Method

```bash
git clone https://github.com/YOUR-USERNAME/webstack-installer.git
cd webstack-installer
sudo ./scripts/webstack-menu.sh
```

---

## 📋 Step 7: Add Repository Features

### 7.1 Create Issue Templates

Create `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug Report
about: Report a bug or issue
title: '[BUG] '
labels: bug
---

**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Run '...'
2. Enter '...'
3. See error

**Expected behavior**
What you expected to happen.

**Environment:**
- OS: [e.g., Ubuntu 22.04]
- Script: [e.g., webstack-installer.sh]
- Version: [e.g., v1.0.0]

**Error messages**
```
Paste any error messages here
```

**Additional context**
Any other relevant information.
```

### 7.2 Create Feature Request Template

Create `.github/ISSUE_TEMPLATE/feature_request.md`:

```markdown
---
name: Feature Request
about: Suggest a feature or improvement
title: '[FEATURE] '
labels: enhancement
---

**Feature Description**
Clear description of the feature you'd like.

**Use Case**
Why would this feature be useful?

**Proposed Implementation**
How do you think it should work?

**Alternatives**
Have you considered alternatives?
```

### 7.3 Add Contributing Guide

Create `CONTRIBUTING.md`:

```markdown
# Contributing to WebStack Installer

Thank you for your interest!

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes thoroughly
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Code Standards

- Use bash best practices
- Add comments for complex logic
- Test on Ubuntu 20.04+ and Debian 11+
- Follow existing code style

## Testing

Test your changes on a clean VPS before submitting.

## Questions?

Open an issue for discussion!
```

---

## 📋 Step 8: Promote Your Repository

### 8.1 Add Badges to README

Add these at the top of README.md:

```markdown
![GitHub release](https://img.shields.io/github/v/release/YOUR-USERNAME/webstack-installer)
![GitHub stars](https://img.shields.io/github/stars/YOUR-USERNAME/webstack-installer)
![GitHub forks](https://img.shields.io/github/forks/YOUR-USERNAME/webstack-installer)
![GitHub issues](https://img.shields.io/github/issues/YOUR-USERNAME/webstack-installer)
![License](https://img.shields.io/github/license/YOUR-USERNAME/webstack-installer)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-orange)
![Debian](https://img.shields.io/badge/Debian-11%2B-red)
```

### 8.2 Share Your Project

- Reddit: r/selfhosted, r/homelab
- Dev.to: Write a tutorial
- Hacker News
- LinuxServer community
- Twitter/X with hashtags

---

## ✅ Checklist

Before going public, verify:

- [ ] All scripts have executable permissions
- [ ] README has correct installation commands
- [ ] install.sh has correct repository URL
- [ ] All documentation links work
- [ ] Tested on fresh Ubuntu/Debian install
- [ ] Created first release (v1.0.0)
- [ ] Added repository topics/tags
- [ ] Issue templates created
- [ ] License file present
- [ ] .gitignore configured

---

## 🎉 You're Done!

Your repository is now live and ready for users!

### Next Steps:

1. Monitor issues and pull requests
2. Respond to user questions
3. Keep documentation updated
4. Release updates regularly
5. Build a community

---

## 📞 Need Help?

- Check GitHub's documentation: https://docs.github.com
- Ask in GitHub Discussions (if enabled)
- Search existing issues

**Good luck with your project! 🚀**
