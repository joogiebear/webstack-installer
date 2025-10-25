# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

**Phase 1: Project Infrastructure**
- GitHub issue templates for bug reports and feature requests
- Pull request template for comprehensive PR submissions
- Project badges to README (license, stars, issues, forks, last commit)
- CODE_OF_CONDUCT.md for community guidelines
- ShellCheck GitHub Actions workflow for automated code quality checks
- Comprehensive CI workflow for syntax checking, markdown linting, and security scanning
- .markdownlint.json configuration file

**Phase 2: Security, Features & Testing**
- FAQ.md with 50+ common questions and answers
- harden-security.sh script for Apache and PHP security hardening
- test-installation.sh automated test suite for system validation
- Dry-run mode for webstack-installer.sh (--dry-run flag)
- Comprehensive logging system (/var/log/webstack-installer/)
- Automatic rollback functionality for failed installations
- Enhanced domain validation with better error messages
- Intelligent username collision detection with hash-based uniqueness
- Command-line help (--help flag) for webstack-installer.sh

**Phase 3: Script Overhaul & New Utilities**
- common-functions.sh: Shared utility library with 50+ reusable functions
- ssl-manager.sh: Complete SSL certificate management suite
- backup-all.sh: Bulk backup solution with parallel processing and remote backup
- health-check.sh: System health diagnostics with recommendations
- clone-domain.sh: Domain cloning tool for duplicating existing setups
- Enhanced list-domains.sh with JSON/CSV export, filtering, and sorting
- Enhanced domain-info.sh with comprehensive statistics and SSL monitoring

### Changed
- Fixed placeholder links in README (Wiki, Issues, Discussions now point to actual URLs)
- Improved install.sh to target scripts directory specifically instead of all .sh files
- Updated README with new scripts documentation organized by category
- Enhanced Common Tasks section with examples of new features
- webstack-installer.sh now uses common-functions.sh library
- All scripts now have consistent error handling and logging
- README features section expanded to highlight v2.0 capabilities

### Security
- Added security headers configuration via harden-security.sh
- PHP security hardening (disable dangerous functions, secure settings)
- Hide server information (ServerTokens, ServerSignature)
- Optional ModSecurity WAF installation
- Enhanced validation prevents malformed input
- Rollback prevents partial installations leaving system in bad state

### Fixed
- Username collision detection now prevents conflicts with hash suffix
- Install.sh permissions handling corrected for scripts directory
- Script paths updated to reference correct locations

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
