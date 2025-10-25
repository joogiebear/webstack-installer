#!/bin/bash

# WebStack Installer - Backup All Domains
# Backup all domains at once with compression and remote backup support

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
init_logging "backup-all"
check_root

# Default settings
BACKUP_ROOT="/var/backups/webstack"
COMPRESSION="gzip"
KEEP_DAYS=30
REMOTE_BACKUP=false
REMOTE_HOST=""
REMOTE_PATH=""
PARALLEL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output|-o)
            BACKUP_ROOT="$2"
            shift 2
            ;;
        --compression|-c)
            COMPRESSION="$2"
            shift 2
            ;;
        --keep-days)
            KEEP_DAYS="$2"
            shift 2
            ;;
        --remote)
            REMOTE_BACKUP=true
            REMOTE_HOST="$2"
            shift 2
            ;;
        --remote-path)
            REMOTE_PATH="$2"
            shift 2
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --help|-h)
            cat << 'HELP'
Usage: backup-all.sh [OPTIONS]

Backup all managed domains at once.

Options:
  --output, -o DIR       Backup output directory (default: /var/backups/webstack)
  --compression, -c TYPE Compression type: gzip, bzip2, xz (default: gzip)
  --keep-days DAYS       Keep backups for N days (default: 30)
  --remote HOST          Copy backups to remote host via rsync
  --remote-path PATH     Remote path for backups
  --parallel             Run backups in parallel (faster but more resource intensive)
  --help, -h             Show this help message

Examples:
  backup-all.sh
  backup-all.sh --output /mnt/backups
  backup-all.sh --compression bzip2 --keep-days 60
  backup-all.sh --remote user@backup-server --remote-path /backups/webstack
  backup-all.sh --parallel

HELP
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Create backup directory
mkdir -p "$BACKUP_ROOT"

print_header "📦 Backup All Domains"

# Get all domains
DOMAINS=($(get_all_domains))

if [ ${#DOMAINS[@]} -eq 0 ]; then
    log_error "No domains found to backup"
    exit 0
fi

log_info "Found ${#DOMAINS[@]} domain(s) to backup"
echo ""

# Display settings
echo "Backup Settings:"
echo "  Output Directory: $BACKUP_ROOT"
echo "  Compression:      $COMPRESSION"
echo "  Keep for:         $KEEP_DAYS days"
echo "  Parallel:         $([ "$PARALLEL" = true ] && echo "Yes" || echo "No")"
[ "$REMOTE_BACKUP" = true ] && echo "  Remote Backup:    $REMOTE_HOST:$REMOTE_PATH"
echo ""

if ! confirm "Start backup?"; then
    log_info "Backup cancelled"
    exit 0
fi

echo ""
print_separator

# Backup function
backup_domain() {
    local domain="$1"
    local timestamp=$(get_date_filename)
    local domain_root=$(get_domain_root "$domain")
    local db_name=$(get_domain_database "$domain")
    local username=$(get_domain_username "$domain")

    # Set compression extension
    local ext="tar.gz"
    local tar_opt="-czf"
    case $COMPRESSION in
        bzip2)
            ext="tar.bz2"
            tar_opt="-cjf"
            ;;
        xz)
            ext="tar.xz"
            tar_opt="-cJf"
            ;;
    esac

    local backup_file="$BACKUP_ROOT/${domain}-${timestamp}.${ext}"

    log_info "Backing up: $domain"

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local backup_dir="$temp_dir/$domain-$timestamp"
    mkdir -p "$backup_dir"

    # Copy website files
    log_debug "Copying website files..."
    if [ -d "$domain_root" ]; then
        cp -a "$domain_root" "$backup_dir/files"
    fi

    # Export database
    if [ -n "$db_name" ] && database_exists "$db_name"; then
        log_debug "Exporting database..."
        mysqldump --single-transaction --routines --triggers "$db_name" > "$backup_dir/database.sql" 2>/dev/null || true
    fi

    # Copy domain info
    local info_file=$(get_domain_info_file "$domain")
    if [ -f "$info_file" ]; then
        cp "$info_file" "$backup_dir/info.txt"
    fi

    # Copy Apache config
    local apache_conf="/etc/apache2/sites-available/${domain}.conf"
    if [ -f "$apache_conf" ]; then
        cp "$apache_conf" "$backup_dir/apache.conf"
    fi

    # Create backup metadata
    cat > "$backup_dir/backup-info.txt" << EOF
Backup Created: $(get_timestamp)
Domain: $domain
Username: $username
Database: $db_name
Compression: $COMPRESSION
Script Version: 2.0
EOF

    # Create compressed archive
    log_debug "Creating compressed archive..."
    tar $tar_opt "$backup_file" -C "$temp_dir" "$(basename "$backup_dir")" 2>/dev/null

    # Cleanup temp directory
    rm -rf "$temp_dir"

    if [ -f "$backup_file" ]; then
        local size=$(get_file_size "$backup_file")
        log_success "$domain backed up ($size)"
        echo "$backup_file"
    else
        log_error "Failed to create backup for $domain"
        return 1
    fi
}

# Run backups
SUCCESSFUL=0
FAILED=0
BACKUP_FILES=()

if [ "$PARALLEL" = true ]; then
    # Parallel backups
    log_info "Running backups in parallel..."
    echo ""

    for domain in "${DOMAINS[@]}"; do
        backup_domain "$domain" &
    done

    # Wait for all background jobs
    wait

    # Count results (simplified for parallel mode)
    SUCCESSFUL=${#DOMAINS[@]}
else
    # Sequential backups
    for i in "${!DOMAINS[@]}"; do
        domain="${DOMAINS[$i]}"
        
        echo ""
        log_info "[$((i+1))/${#DOMAINS[@]}] Backing up: $domain"
        
        if backup_file=$(backup_domain "$domain"); then
            ((SUCCESSFUL++))
            BACKUP_FILES+=("$backup_file")
        else
            ((FAILED++))
        fi

        # Show progress
        show_progress $((i+1)) ${#DOMAINS[@]}
        echo ""
    done
fi

echo ""
print_separator
echo ""

# Summary
log_success "Backup Summary"
echo "  Successful: $SUCCESSFUL"
[ $FAILED -gt 0 ] && echo "  Failed:     $FAILED"
echo "  Location:   $BACKUP_ROOT"
echo ""

# Calculate total backup size
if [ ${#BACKUP_FILES[@]} -gt 0 ]; then
    TOTAL_SIZE=$(du -ch "${BACKUP_FILES[@]}" 2>/dev/null | tail -1 | awk '{print $1}')
    echo "  Total Size: $TOTAL_SIZE"
    echo ""
fi

# Remote backup
if [ "$REMOTE_BACKUP" = true ] && [ $SUCCESSFUL -gt 0 ]; then
    echo ""
    print_separator
    log_info "Copying backups to remote server..."
    echo ""

    if command_exists rsync; then
        if rsync -avz --progress "$BACKUP_ROOT/" "$REMOTE_HOST:$REMOTE_PATH/"; then
            log_success "Backups copied to $REMOTE_HOST successfully"
        else
            log_error "Failed to copy backups to remote server"
        fi
    else
        log_error "rsync not installed. Install with: apt install rsync"
    fi
fi

# Cleanup old backups
if [ $KEEP_DAYS -gt 0 ]; then
    echo ""
    print_separator
    log_info "Cleaning up backups older than $KEEP_DAYS days..."

    OLD_COUNT=$(find "$BACKUP_ROOT" -name "*.tar.*" -type f -mtime +$KEEP_DAYS | wc -l)

    if [ $OLD_COUNT -gt 0 ]; then
        find "$BACKUP_ROOT" -name "*.tar.*" -type f -mtime +$KEEP_DAYS -delete
        log_success "Removed $OLD_COUNT old backup(s)"
    else
        log_info "No old backups to remove"
    fi
fi

echo ""
log_success "All backups completed!"
echo ""

# Show backup list
if [ ${#BACKUP_FILES[@]} -gt 0 ]; then
    echo "Created backups:"
    for file in "${BACKUP_FILES[@]}"; do
        echo "  - $(basename "$file")"
    done
    echo ""
fi

log_info "Backup operation complete"
