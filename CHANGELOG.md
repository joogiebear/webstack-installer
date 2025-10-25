# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub issue templates for bug reports and feature requests
- Pull request template for consistent PR submissions
- Project badges to README (license, stars, issues, forks, last commit)
- CODE_OF_CONDUCT.md for community guidelines
- ShellCheck GitHub Actions workflow for automated code quality checks

### Changed
- Fixed placeholder links in README (Wiki, Issues, Discussions now point to actual URLs)
- Improved install.sh to target scripts directory specifically instead of all .sh files

### Fixed
- N/A

## [2.0.0] - 2024-XX-XX

### Added
- Multi-domain hosting support
- Automated database setup per domain
- Interactive menu system (webstack-menu.sh)
- Backup and restore functionality
- Domain management scripts (list, info, update, remove)
- Email server setup script (setup-email.sh)
- Email management script (manage-email.sh)
- Modern default landing page for new domains
- phpMyAdmin integration per domain
- Secure permissions and user isolation
- SSL-ready configuration
- Firewall configuration with UFW

### Changed
- Complete rewrite from v1.x
- Improved error handling throughout all scripts
- Better user experience with colored output
- Enhanced security with isolated users per domain
- Automated web stack installation on first run

### Security
- Each domain runs as isolated system user
- PHP open_basedir restrictions
- Secure database credentials storage
- Proper file permissions

## [1.0.0] - Initial Release

### Added
- Basic web hosting setup for single domain
- Apache, MySQL, PHP installation
- Simple domain configuration

---

## Legend

- `Added` - New features
- `Changed` - Changes in existing functionality
- `Deprecated` - Soon-to-be removed features
- `Removed` - Removed features
- `Fixed` - Bug fixes
- `Security` - Security improvements

---

For detailed information about each release, see the [Releases](https://github.com/joogiebear/webstack-installer/releases) page.
