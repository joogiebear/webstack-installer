#!/bin/bash

# WebStack Installer - Common Functions Library
# Shared utilities for all scripts

# ============================================================================
# COLOR CODES
# ============================================================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export NC='\033[0m' # No Color

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================
export WEBSTACK_ROOT="/var/www"
export DOMAIN_INFO_ROOT="/root/webstack-sites"
export LOG_DIR="/var/log/webstack-installer"
export APACHE_SITES_AVAILABLE="/etc/apache2/sites-available"
export APACHE_SITES_ENABLED="/etc/apache2/sites-enabled"

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Initialize logging
init_logging() {
    local script_name="${1:-webstack}"
    export LOG_FILE="$LOG_DIR/${script_name}-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$LOG_DIR"
}

# Log message with level
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi

    case $level in
        ERROR)
            echo -e "${RED}❌ $message${NC}" >&2
            ;;
        WARN)
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        SUCCESS)
            echo -e "${GREEN}✓ $message${NC}"
            ;;
        INFO)
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
        DEBUG)
            if [ "${DEBUG:-0}" = "1" ]; then
                echo -e "${MAGENTA}[DEBUG] $message${NC}"
            fi
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Quick logging shortcuts
log_error() { log "ERROR" "$@"; }
log_warn() { log "WARN" "$@"; }
log_success() { log "SUCCESS" "$@"; }
log_info() { log "INFO" "$@"; }
log_debug() { log "DEBUG" "$@"; }

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate domain format
validate_domain() {
    local domain="$1"

    # Check if empty
    if [ -z "$domain" ]; then
        log_error "Domain name cannot be empty"
        return 1
    fi

    # Length check
    if [ ${#domain} -gt 253 ]; then
        log_error "Domain name too long (max 253 characters)"
        return 1
    fi

    if [ ${#domain} -lt 3 ]; then
        log_error "Domain name too short (min 3 characters)"
        return 1
    fi

    # Format validation
    if ! [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        log_error "Invalid domain format"
        return 1
    fi

    # Check for consecutive dots or hyphens
    if [[ "$domain" =~ \.\. ]] || [[ "$domain" =~ -- ]]; then
        log_error "Domain cannot contain consecutive dots or hyphens"
        return 1
    fi

    return 0
}

# Validate IP address
validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# DOMAIN FUNCTIONS
# ============================================================================

# Get username from domain
domain_to_username() {
    local domain="$1"
    echo "$domain" | sed 's/\.//g' | tr '[:upper:]' '[:lower:]' | cut -c1-28
}

# Check if domain exists
domain_exists() {
    local domain="$1"
    [ -d "$DOMAIN_INFO_ROOT/$domain" ] && return 0 || return 1
}

# Get all installed domains
get_all_domains() {
    if [ ! -d "$DOMAIN_INFO_ROOT" ]; then
        return 1
    fi
    find "$DOMAIN_INFO_ROOT" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort
}

# Count installed domains
count_domains() {
    get_all_domains 2>/dev/null | wc -l
}

# Get domain info file path
get_domain_info_file() {
    local domain="$1"
    echo "$DOMAIN_INFO_ROOT/$domain/info.txt"
}

# Get domain username
get_domain_username() {
    local domain="$1"
    local info_file=$(get_domain_info_file "$domain")
    
    if [ -f "$info_file" ]; then
        grep "^Username:" "$info_file" | awk '{print $2}'
    else
        domain_to_username "$domain"
    fi
}

# Get domain database name
get_domain_database() {
    local domain="$1"
    local info_file=$(get_domain_info_file "$domain")
    
    if [ -f "$info_file" ]; then
        grep "^Database Name:" "$info_file" | awk '{print $3}'
    fi
}

# Get domain database user
get_domain_db_user() {
    local domain="$1"
    local info_file=$(get_domain_info_file "$domain")
    
    if [ -f "$info_file" ]; then
        grep "^Database User:" "$info_file" | awk '{print $3}'
    fi
}

# Get domain root directory
get_domain_root() {
    local domain="$1"
    local username=$(get_domain_username "$domain")
    echo "$WEBSTACK_ROOT/$username"
}

# Get domain public_html directory
get_domain_public_html() {
    local domain="$1"
    echo "$(get_domain_root "$domain")/public_html"
}

# ============================================================================
# UI FUNCTIONS
# ============================================================================

# Print header
print_header() {
    local title="$1"
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    printf "║  %-56s  ║\n" "$title"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Print section separator
print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Print subsection
print_subsection() {
    local title="$1"
    echo ""
    print_separator
    echo -e "${BLUE}$title${NC}"
    print_separator
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' ' '
    printf "] %d%%" $percentage
}

# Spinner animation
spinner() {
    local pid=$1
    local message="${2:-Processing}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${CYAN}${spin:$i:1}${NC} $message..."
        sleep 0.1
    done
    printf "\r"
}

# Confirmation prompt
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        read -rp "$prompt [Y/n]: " response
        [[ "$response" =~ ^[Nn]$ ]] && return 1 || return 0
    else
        read -rp "$prompt [y/N]: " response
        [[ "$response" =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

# Select from list
select_from_list() {
    local prompt="$1"
    shift
    local items=("$@")
    
    if [ ${#items[@]} -eq 0 ]; then
        log_error "No items to select from"
        return 1
    fi
    
    echo "$prompt"
    echo ""
    
    local i=1
    for item in "${items[@]}"; do
        echo "  $i) $item"
        ((i++))
    done
    
    echo ""
    read -rp "Enter selection [1-${#items[@]}]: " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#items[@]} ]; then
        echo "${items[$((selection-1))]}"
        return 0
    else
        log_error "Invalid selection"
        return 1
    fi
}

# ============================================================================
# SYSTEM FUNCTIONS
# ============================================================================

# Get system memory in MB
get_memory_mb() {
    free -m | awk 'NR==2{print $2}'
}

# Get disk usage for path
get_disk_usage() {
    local path="$1"
    du -sh "$path" 2>/dev/null | awk '{print $1}'
}

# Get free disk space
get_free_space() {
    df -h / | awk 'NR==2{print $4}'
}

# Get CPU cores
get_cpu_cores() {
    nproc
}

# Get load average
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ','
}

# Check if service is running
is_service_running() {
    local service="$1"
    systemctl is-active --quiet "$service"
}

# Get service status
get_service_status() {
    local service="$1"
    if is_service_running "$service"; then
        echo -e "${GREEN}Running${NC}"
    else
        echo -e "${RED}Stopped${NC}"
    fi
}

# ============================================================================
# FILE FUNCTIONS
# ============================================================================

# Create backup of file
backup_file() {
    local file="$1"
    local backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -f "$file" ]; then
        cp "$file" "$backup"
        log_debug "Backed up $file to $backup"
        echo "$backup"
        return 0
    else
        return 1
    fi
}

# Safe file write with backup
safe_write_file() {
    local file="$1"
    local content="$2"
    
    if [ -f "$file" ]; then
        backup_file "$file" >/dev/null
    fi
    
    echo "$content" > "$file"
}

# Get file size in human readable format
get_file_size() {
    local file="$1"
    if [ -f "$file" ]; then
        ls -lh "$file" | awk '{print $5}'
    fi
}

# ============================================================================
# DATABASE FUNCTIONS
# ============================================================================

# Check MySQL connection
check_mysql_connection() {
    mysql -u root -e "SELECT 1" &>/dev/null
}

# Get database size
get_database_size() {
    local db_name="$1"
    mysql -u root -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.TABLES WHERE table_schema='$db_name';" -sN 2>/dev/null
}

# Check if database exists
database_exists() {
    local db_name="$1"
    mysql -u root -e "SHOW DATABASES LIKE '$db_name'" | grep -q "$db_name"
}

# ============================================================================
# APACHE FUNCTIONS
# ============================================================================

# Check Apache configuration
check_apache_config() {
    apache2ctl configtest &>/dev/null
}

# Reload Apache
reload_apache() {
    if check_apache_config; then
        systemctl reload apache2 &>/dev/null
        return 0
    else
        log_error "Apache configuration test failed"
        return 1
    fi
}

# Check if site is enabled
is_site_enabled() {
    local domain="$1"
    [ -L "$APACHE_SITES_ENABLED/${domain}.conf" ] && return 0 || return 1
}

# Get SSL certificate expiry
get_ssl_expiry() {
    local domain="$1"
    local cert_file="/etc/letsencrypt/live/$domain/cert.pem"
    
    if [ -f "$cert_file" ]; then
        openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2
    else
        echo "No SSL certificate"
    fi
}

# Check if domain has SSL
has_ssl() {
    local domain="$1"
    [ -d "/etc/letsencrypt/live/$domain" ] && return 0 || return 1
}

# ============================================================================
# NETWORK FUNCTIONS
# ============================================================================

# Get server public IP
get_public_ip() {
    curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'
}

# Check if port is open
is_port_open() {
    local port="$1"
    netstat -tuln | grep -q ":$port "
}

# Ping host
ping_host() {
    local host="$1"
    ping -c 1 -W 2 "$host" &>/dev/null
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Generate random password
generate_password() {
    local length="${1:-16}"
    openssl rand -base64 32 | tr -d '/+=' | cut -c1-"$length"
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$((bytes / 1024))KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Get timestamp
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Get date for filenames
get_date_filename() {
    date +"%Y%m%d-%H%M%S"
}

# Calculate percentage
calculate_percentage() {
    local current=$1
    local total=$2
    echo $((current * 100 / total))
}

# ============================================================================
# CLEANUP FUNCTION
# ============================================================================

# Cleanup on exit
cleanup() {
    log_debug "Cleaning up..."
    # Add any cleanup tasks here
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Trap cleanup on exit
trap cleanup EXIT

# Export all functions for use in other scripts
export -f log log_error log_warn log_success log_info log_debug
export -f check_root command_exists validate_domain validate_ip
export -f domain_to_username domain_exists get_all_domains count_domains
export -f get_domain_info_file get_domain_username get_domain_database
export -f get_domain_db_user get_domain_root get_domain_public_html
export -f print_header print_separator print_subsection show_progress
export -f confirm select_from_list spinner
export -f get_memory_mb get_disk_usage get_free_space get_cpu_cores
export -f get_load_average is_service_running get_service_status
export -f backup_file safe_write_file get_file_size
export -f check_mysql_connection get_database_size database_exists
export -f check_apache_config reload_apache is_site_enabled
export -f get_ssl_expiry has_ssl
export -f get_public_ip is_port_open ping_host
export -f generate_password format_bytes get_timestamp get_date_filename
export -f calculate_percentage init_logging

log_debug "Common functions library loaded"
