#!/bin/bash

# WebStack Installer - Domain Information Viewer
# Enhanced version with JSON output, resource stats, and SSL status

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
if [ -f "$SCRIPT_DIR/common-functions.sh" ]; then
    source "$SCRIPT_DIR/common-functions.sh"
else
    echo "Error: common-functions.sh not found"
    exit 1
fi

# Initialize
init_logging "domain-info"

# Parse arguments
OUTPUT_FORMAT="pretty"
SHOW_CREDENTIALS=false
DOMAIN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --credentials)
            SHOW_CREDENTIALS=true
            shift
            ;;
        --help|-h)
            cat << 'HELP'
Usage: domain-info.sh [OPTIONS] DOMAIN

Display comprehensive information about a domain.

Arguments:
  DOMAIN                Domain name to query

Options:
  --json                Output in JSON format
  --credentials         Show full credentials (default: hidden)
  --help, -h            Show this help message

Examples:
  domain-info.sh example.com
  domain-info.sh --json example.com
  domain-info.sh --credentials example.com

HELP
            exit 0
            ;;
        *)
            if [ -z "$DOMAIN" ]; then
                DOMAIN="$1"
            else
                log_error "Unknown option: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if domain provided
if [ -z "$DOMAIN" ]; then
    log_error "Domain name required"
    echo ""
    echo "Usage: domain-info.sh [OPTIONS] DOMAIN"
    echo "Try 'domain-info.sh --help' for more information"
    echo ""
    echo "Available domains:"
    get_all_domains 2>/dev/null || echo "  No domains found"
    echo ""
    exit 1
fi

# Validate domain
if ! validate_domain "$DOMAIN"; then
    exit 1
fi

# Check if domain exists
if ! domain_exists "$DOMAIN"; then
    log_error "Domain '$DOMAIN' not found"
    echo ""
    echo "Available domains:"
    get_all_domains
    echo ""
    exit 1
fi

# Collect domain information
collect_info() {
    local info_file=$(get_domain_info_file "$DOMAIN")
    local username=$(get_domain_username "$DOMAIN")
    local db_name=$(get_domain_database "$DOMAIN")
    local db_user=$(get_domain_db_user "$DOMAIN")
    local domain_root=$(get_domain_root "$DOMAIN")
    local public_html=$(get_domain_public_html "$DOMAIN")

    # Basic info
    INFO["domain"]="$DOMAIN"
    INFO["username"]="$username"
    INFO["database"]="$db_name"
    INFO["db_user"]="$db_user"
    INFO["domain_root"]="$domain_root"
    INFO["public_html"]="$public_html"

    # Get database password if showing credentials
    if [ "$SHOW_CREDENTIALS" = true ] && [ -f "$info_file" ]; then
        local db_pass=$(grep "Database Pass:" "$info_file" | awk '{print $3}')
        INFO["db_password"]="$db_pass"
    else
        INFO["db_password"]="***hidden***"
    fi

    # Server info
    INFO["server_ip"]=$(get_public_ip)

    # Status info
    if is_site_enabled "$DOMAIN"; then
        INFO["status"]="active"
    else
        INFO["status"]="disabled"
    fi

    # SSL info
    if has_ssl "$DOMAIN"; then
        INFO["ssl_status"]="installed"
        INFO["ssl_expiry"]=$(get_ssl_expiry "$DOMAIN")

        # Check if SSL is expiring soon (within 30 days)
        local cert_file="/etc/letsencrypt/live/$DOMAIN/cert.pem"
        if [ -f "$cert_file" ]; then
            local expiry_epoch=$(date -d "$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)" +%s 2>/dev/null || echo "0")
            local now_epoch=$(date +%s)
            local days_until_expiry=$(( (expiry_epoch - now_epoch) / 86400 ))
            INFO["ssl_days_remaining"]="$days_until_expiry"

            if [ "$days_until_expiry" -lt 30 ]; then
                INFO["ssl_warning"]="expires_soon"
            else
                INFO["ssl_warning"]="ok"
            fi
        fi
    else
        INFO["ssl_status"]="not_installed"
        INFO["ssl_expiry"]="N/A"
        INFO["ssl_days_remaining"]="0"
        INFO["ssl_warning"]="no_ssl"
    fi

    # Resource usage
    INFO["disk_usage"]=$(get_disk_usage "$domain_root")

    # Database size
    if [ -n "$db_name" ] && database_exists "$db_name"; then
        local db_size=$(get_database_size "$db_name")
        INFO["db_size"]="${db_size}MB"
    else
        INFO["db_size"]="N/A"
    fi

    # File counts
    if [ -d "$public_html" ]; then
        INFO["file_count"]=$(find "$public_html" -type f 2>/dev/null | wc -l)
        INFO["dir_count"]=$(find "$public_html" -type d 2>/dev/null | wc -l)
    else
        INFO["file_count"]="0"
        INFO["dir_count"]="0"
    fi

    # Apache config
    INFO["apache_config"]="/etc/apache2/sites-available/${DOMAIN}.conf"

    # Logs
    INFO["error_log"]="${domain_root}/logs/error.log"
    INFO["access_log"]="${domain_root}/logs/access.log"

    # Recent log entries
    if [ -f "${INFO[error_log]}" ]; then
        INFO["recent_errors"]=$(wc -l < "${INFO[error_log]}" 2>/dev/null || echo "0")
    else
        INFO["recent_errors"]="0"
    fi

    # Last modified
    if [ -f "$info_file" ]; then
        INFO["created"]=$(stat -c %y "$info_file" 2>/dev/null | cut -d'.' -f1 || echo "Unknown")
    fi

    # PHP version
    if command_exists php; then
        INFO["php_version"]=$(php -v | head -n 1 | awk '{print $2}')
    else
        INFO["php_version"]="Unknown"
    fi
}

declare -A INFO
collect_info

# Output in pretty format
output_pretty() {
    clear
    print_header "📋 Domain Information: $DOMAIN"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}DOMAIN DETAILS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  Domain:           ${INFO[domain]}"
    echo "  Status:           $([ "${INFO[status]}" = "active" ] && echo -e "${GREEN}✓ Active${NC}" || echo -e "${YELLOW}⏸ Disabled${NC}")"
    echo "  Username:         ${INFO[username]}"
    echo "  Server IP:        ${INFO[server_ip]}"
    echo "  Created:          ${INFO[created]}"
    echo ""

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}DATABASE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  Database Name:    ${INFO[database]}"
    echo "  Database User:    ${INFO[db_user]}"
    echo "  Database Pass:    ${INFO[db_password]}"
    echo "  Database Size:    ${INFO[db_size]}"
    echo "  phpMyAdmin:       http://${INFO[domain]}/phpmyadmin"
    echo ""

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}SSL CERTIFICATE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ "${INFO[ssl_status]}" = "installed" ]; then
        echo -e "  Status:           ${GREEN}✓ Installed${NC}"
        echo "  Expires:          ${INFO[ssl_expiry]}"
        echo "  Days Remaining:   ${INFO[ssl_days_remaining]} days"

        if [ "${INFO[ssl_warning]}" = "expires_soon" ]; then
            echo -e "  ${YELLOW}⚠ Warning: Certificate expires soon! Renew with: certbot renew${NC}"
        fi
    else
        echo -e "  Status:           ${YELLOW}⚠ Not Installed${NC}"
        echo "  Install SSL:      certbot --apache -d ${INFO[domain]} -d www.${INFO[domain]}"
    fi
    echo ""

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}RESOURCE USAGE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  Disk Usage:       ${INFO[disk_usage]}"
    echo "  File Count:       ${INFO[file_count]} files"
    echo "  Directory Count:  ${INFO[dir_count]} directories"
    echo "  PHP Version:      ${INFO[php_version]}"
    echo ""

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}FILE LOCATIONS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  Website Root:     ${INFO[public_html]}"
    echo "  Domain Root:      ${INFO[domain_root]}"
    echo "  Apache Config:    ${INFO[apache_config]}"
    echo "  Error Log:        ${INFO[error_log]}"
    echo "  Access Log:       ${INFO[access_log]}"
    echo ""

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}QUICK ACTIONS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  View Errors:      tail -f ${INFO[error_log]}"
    echo "  View Access:      tail -f ${INFO[access_log]}"
    echo "  Edit Config:      nano ${INFO[apache_config]}"
    echo "  Backup Domain:    ./backup-domain.sh ${INFO[domain]}"
    echo "  Remove Domain:    ./remove-domain.sh ${INFO[domain]}"
    echo ""
}

# Output in JSON format
output_json() {
    cat << EOF
{
  "domain": "${INFO[domain]}",
  "status": "${INFO[status]}",
  "username": "${INFO[username]}",
  "server_ip": "${INFO[server_ip]}",
  "created": "${INFO[created]}",
  "database": {
    "name": "${INFO[database]}",
    "user": "${INFO[db_user]}",
    "password": "${INFO[db_password]}",
    "size": "${INFO[db_size]}"
  },
  "ssl": {
    "status": "${INFO[ssl_status]}",
    "expiry": "${INFO[ssl_expiry]}",
    "days_remaining": ${INFO[ssl_days_remaining]},
    "warning": "${INFO[ssl_warning]}"
  },
  "resources": {
    "disk_usage": "${INFO[disk_usage]}",
    "file_count": ${INFO[file_count]},
    "dir_count": ${INFO[dir_count]},
    "php_version": "${INFO[php_version]}"
  },
  "paths": {
    "domain_root": "${INFO[domain_root]}",
    "public_html": "${INFO[public_html]}",
    "apache_config": "${INFO[apache_config]}",
    "error_log": "${INFO[error_log]}",
    "access_log": "${INFO[access_log]}"
  }
}
EOF
}

# Main execution
check_root

case $OUTPUT_FORMAT in
    json)
        output_json
        ;;
    pretty|*)
        output_pretty
        ;;
esac

log_info "Domain info displayed for $DOMAIN"
