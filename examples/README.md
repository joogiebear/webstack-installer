# 📚 Examples

This directory contains example configurations and usage patterns.

## Available Examples

### Apache Configuration

**File**: `example-apache-config.conf`

Example Apache virtual host configuration that WebStack Installer creates. Shows:
- HTTP (port 80) configuration
- HTTPS (port 443) configuration with SSL
- PHP restrictions
- Logging setup

### Custom Scripts

Coming soon:
- Automated backup script
- Domain migration script
- WordPress installation script
- Database import script

## Using Examples

These examples are for reference. The installer creates these configurations automatically.

### Copy Example Config

```bash
# View example
cat examples/example-apache-config.conf

# Use as template (not recommended, use installer instead)
sudo cp examples/example-apache-config.conf /etc/apache2/sites-available/mydomain.conf
```

## Contributing Examples

Have a useful script or configuration? Add it here!

1. Create your example file
2. Add description to this README
3. Submit a pull request

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.
