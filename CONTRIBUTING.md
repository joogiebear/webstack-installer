# 🤝 Contributing to WebStack Installer

Thank you for considering contributing to WebStack Installer! This document provides guidelines for contributions.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)

---

## 📜 Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community

---

## 🚀 How to Contribute

### Reporting Bugs

1. Check if the bug already exists in [Issues](../../issues)
2. If not, create a new issue using the Bug Report template
3. Include:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details
   - Error messages

### Suggesting Features

1. Check [existing feature requests](../../issues?q=is%3Aissue+label%3Aenhancement)
2. Create a new issue using the Feature Request template
3. Explain:
   - What the feature does
   - Why it's useful
   - How it should work

### Improving Documentation

Documentation improvements are always welcome:
- Fix typos or unclear instructions
- Add examples
- Improve installation guides
- Update FAQ

---

## 💻 Development Setup

### Prerequisites

- Ubuntu 20.04+ or Debian 11+
- Root/sudo access
- Git installed
- Basic bash scripting knowledge

### Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/webstack-installer.git
cd webstack-installer
```

### Create a Branch

```bash
git checkout -b feature/your-feature-name
```

### Test Your Changes

```bash
# Test on a fresh VPS or VM
sudo ./scripts/your-modified-script.sh
```

---

## 📝 Coding Standards

### Bash Best Practices

1. **Use `set -e`** at the start of scripts to exit on errors
2. **Quote variables**: `"$VARIABLE"` not `$VARIABLE`
3. **Use meaningful variable names**: `DOMAIN` not `d`
4. **Add comments** for complex logic
5. **Check command existence**: `command -v tool &>/dev/null`

### Script Structure

```bash
#!/bin/bash

# Script description
# Purpose: What this script does

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Must run as root${NC}"
    exit 1
fi

# Main script logic here
```

### Error Handling

```bash
# Good: Check before using
if [ -f "$FILE" ]; then
    cat "$FILE"
else
    echo "File not found"
    exit 1
fi

# Good: Use || for error handling
command || { echo "Command failed"; exit 1; }
```

### Variable Naming

- **Uppercase**: For constants and environment variables
- **Lowercase**: For local variables
- **Descriptive**: Not `x`, `y`, `z`

```bash
# Good
DOMAIN="example.com"
db_name="example_db"

# Bad
D="example.com"
x="example_db"
```

---

## 🧪 Testing

### Test Environments

Test on:
- Ubuntu 20.04
- Ubuntu 22.04
- Debian 11
- Debian 12

### Testing Checklist

- [ ] Script runs without errors
- [ ] All features work as expected
- [ ] No security vulnerabilities introduced
- [ ] Doesn't break existing functionality
- [ ] Works with multiple domains
- [ ] Handles edge cases (empty input, special characters)
- [ ] Error messages are clear
- [ ] Permissions are correct

### Manual Testing

```bash
# Test installation
sudo ./scripts/webstack-installer.sh

# Test with edge cases
# - Domain with hyphens: test-site.com
# - Subdomain: sub.example.com
# - Short domain: a.co
# - Long domain: very-long-domain-name.com

# Test error handling
# - Empty input
# - Invalid domain format
# - Duplicate domain
# - Insufficient permissions
```

---

## 🔀 Pull Request Process

### Before Submitting

1. **Test thoroughly** on fresh installations
2. **Update documentation** if needed
3. **Follow coding standards**
4. **Keep commits clean** and logical
5. **Write clear commit messages**

### Commit Messages

```bash
# Good commit messages
git commit -m "Add SSL auto-renewal script"
git commit -m "Fix database creation for domains with hyphens"
git commit -m "Update documentation for email setup"

# Bad commit messages
git commit -m "Fixed stuff"
git commit -m "Update"
git commit -m "asdf"
```

### Submit Pull Request

1. Push your branch to your fork:
```bash
git push origin feature/your-feature-name
```

2. Go to GitHub and create a Pull Request

3. Fill in the PR template with:
   - Description of changes
   - Related issues
   - Testing performed
   - Screenshots (if applicable)

### PR Template

```markdown
## 📝 Description
Brief description of changes.

## 🔗 Related Issues
Fixes #123

## ✅ Testing
- [ ] Tested on Ubuntu 22.04
- [ ] Tested on Debian 11
- [ ] All existing features still work
- [ ] Added/updated documentation

## 📸 Screenshots
If applicable.

## ⚠️ Breaking Changes
None / List any breaking changes
```

### Review Process

- Maintainers will review your PR
- May request changes or ask questions
- Be responsive to feedback
- Once approved, it will be merged

---

## 🎨 Documentation Style

### Markdown Guidelines

- Use headers hierarchically (##, ###, ####)
- Include code blocks with language tags
- Add examples for clarity
- Use emojis for visual appeal (but don't overdo it)
- Keep lines under 100 characters for readability

### Example Documentation

```markdown
## 🚀 Installation

Quick install:

\`\`\`bash
curl -fsSL https://example.com/install.sh | sudo bash
\`\`\`

Manual install:

\`\`\`bash
git clone https://github.com/user/repo.git
cd repo
sudo ./install.sh
\`\`\`
```

---

## 🐛 Debugging Tips

### Enable Debug Mode

```bash
# Add to top of script
set -x  # Print commands as they execute
```

### Check Logs

```bash
# System logs
sudo tail -f /var/log/syslog

# Apache logs
sudo tail -f /var/log/apache2/error.log

# Mail logs
sudo tail -f /var/log/mail.log
```

### Test in Isolation

```bash
# Test just your function
source ./your-script.sh
your_function "test" "parameters"
```

---

## 📚 Resources

- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [ShellCheck](https://www.shellcheck.net/) - Shell script analyzer
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

---

## ❓ Questions?

- Open a [Discussion](../../discussions)
- Comment on relevant issues
- Ask in Pull Request comments

---

## 🎉 Thank You!

Your contributions make this project better for everyone!

**Happy coding! 🚀**
