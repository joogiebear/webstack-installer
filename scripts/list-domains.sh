#!/bin/bash

# WebStack Installer - List All Domains
# Enhanced version with filtering, sorting, and multiple output formats

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
init_logging "list-domains"

# Parse arguments
OUTPUT_FORMAT="table"
SORT_BY="domain"
FILTER=""
SHOW_SSL=false
SHOW_STATS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --format|-f)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --sort|-s)
            SORT_BY="$2"
            shift 2
            ;;
        --filter)
            FILTER="$2"
            shift 2
            ;;
        --ssl)
            SHOW_SSL=true
            shift
            ;;
        --stats)
            SHOW_STATS=true
            shift
            ;;
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --csv)
            OUTPUT_FORMAT="csv"
            shift
            ;;
        --help|-h)
            cat << 'HELP'
Usage: list-domains.sh [OPTIONS]

List all managed domains with various display options.

Options:
  --format, -f FORMAT   Output format: table, json, csv, simple (default: table)
  --sort, -s FIELD      Sort by: domain, size, status (default: domain)
  --filter PATTERN      Filter domains by pattern
  --ssl                 Show SSL certificate status
  --stats               Show detailed statistics
  --json                Output as JSON (shortcut for --format json)
  --csv                 Output as CSV (shortcut for --format csv)
  --help, -h            Show this help message

Examples:
  list-domains.sh                    # Default table view
  list-domains.sh --format json      # JSON output
  list-domains.sh --sort size        # Sort by disk usage
  list-domains.sh --filter example   # Filter domains containing 'example'
  list-domains.sh --ssl --stats      # Show SSL and detailed stats

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

# Collect domain information
declare -a DOMAINS
declare -A DOMAIN_INFO

collect_domain_info() {
    local domain_list=$(get_all_domains)

    if [ -z "$domain_list" ]; then
        return 1
    fi

    while IFS= read -r domain; do
        # Apply filter if specified
        if [ -n "$FILTER" ] && [[ ! "$domain" =~ $FILTER ]]; then
            continue
        fi

        DOMAINS+=("$domain")

        local username=$(get_domain_username "$domain")
        local db_name=$(get_domain_database "$domain")
        local domain_root=$(get_domain_root "$domain")
        local public_html=$(get_domain_public_html "$domain")

        # Get disk usage
        local disk_usage=$(get_disk_usage "$domain_root")

        # Check status
        local status="disabled"
        if is_site_enabled "$domain"; then
            status="active"
        fi

        # SSL status
        local ssl_status="none"
        local ssl_expiry="N/A"
        if has_ssl "$domain"; then
            ssl_status="installed"
            ssl_expiry=$(get_ssl_expiry "$domain")
        fi

        # Database size
        local db_size="N/A"
        if [ -n "$db_name" ] && database_exists "$db_name"; then
            db_size=$(get_database_size "$db_name")
            [ -n "$db_size" ] && db_size="${db_size}MB" || db_size="0MB"
        fi

        # Store info
        DOMAIN_INFO["${domain}:username"]="$username"
        DOMAIN_INFO["${domain}:database"]="$db_name"
        DOMAIN_INFO["${domain}:db_size"]="$db_size"
        DOMAIN_INFO["${domain}:disk_usage"]="$disk_usage"
        DOMAIN_INFO["${domain}:status"]="$status"
        DOMAIN_INFO["${domain}:ssl"]="$ssl_status"
        DOMAIN_INFO["${domain}:ssl_expiry"]="$ssl_expiry"
        DOMAIN_INFO["${domain}:root"]="$domain_root"
        DOMAIN_INFO["${domain}:public_html"]="$public_html"
    done <<< "$domain_list"

    return 0
}

# Sort domains
sort_domains() {
    case $SORT_BY in
        size)
            # Sort by disk usage (approximate)
            printf '%s\n' "${DOMAINS[@]}" | while read -r d; do
                local size_str="${DOMAIN_INFO[${d}:disk_usage]}"
                # Convert to sortable number (rough approximation)
                local size_num=0
                if [[ $size_str =~ ([0-9.]+)([KMGT])? ]]; then
                    size_num=${BASH_REMATCH[1]}
                    case ${BASH_REMATCH[2]} in
                        K) size_num=$(echo "$size_num * 1" | bc);;
                        M) size_num=$(echo "$size_num * 1000" | bc);;
                        G) size_num=$(echo "$size_num * 1000000" | bc);;
                        T) size_num=$(echo "$size_num * 1000000000" | bc);;
                    esac
                fi
                printf '%020d %s\n' "$size_num" "$d"
            done | sort -rn | awk '{print $2}'
            ;;
        status)
            printf '%s\n' "${DOMAINS[@]}" | while read -r d; do
                echo "${DOMAIN_INFO[${d}:status]} $d"
            done | sort | awk '{print $2}'
            ;;
        domain|*)
            printf '%s\n' "${DOMAINS[@]}" | sort
            ;;
    esac
}

# Output in table format
output_table() {
    print_header "📋 Managed Domains"

    if [ ${#DOMAINS[@]} -eq 0 ]; then
        log_info "No domains found"
        return
    fi

    # Table header
    printf "%-30s %-10s %-15s %-10s" "DOMAIN" "STATUS" "USERNAME" "DISK"
    [ "$SHOW_SSL" = true ] && printf " %-12s" "SSL"
    printf "\n"

    printf "%-30s %-10s %-15s %-10s" "$(printf '%.0s-' {1..30})" "$(printf '%.0s-' {1..10})" "$(printf '%.0s-' {1..15})" "$(printf '%.0s-' {1..10})"
    [ "$SHOW_SSL" = true ] && printf " %-12s" "$(printf '%.0s-' {1..12})"
    printf "\n"

    # Table rows
    local sorted_domains=$(sort_domains)
    while IFS= read -r domain; do
        local username="${DOMAIN_INFO[${domain}:username]}"
        local disk="${DOMAIN_INFO[${domain}:disk_usage]}"
        local status="${DOMAIN_INFO[${domain}:status]}"

        # Color code status
        local status_display
        if [ "$status" = "active" ]; then
            status_display="${GREEN}✓ Active${NC}"
        else
            status_display="${YELLOW}⏸ Disabled${NC}"
        fi

        printf "%-30s %-18s %-15s %-10s" "$domain" "$(echo -e "$status_display")" "$username" "$disk"

        if [ "$SHOW_SSL" = true ]; then
            local ssl="${DOMAIN_INFO[${domain}:ssl]}"
            if [ "$ssl" = "installed" ]; then
                printf " ${GREEN}%-12s${NC}" "✓ SSL"
            else
                printf " ${YELLOW}%-12s${NC}" "⚠ No SSL"
            fi
        fi

        printf "\n"

        # Show detailed stats if requested
        if [ "$SHOW_STATS" = true ]; then
            local db_name="${DOMAIN_INFO[${domain}:database]}"
            local db_size="${DOMAIN_INFO[${domain}:db_size]}"
            local public_html="${DOMAIN_INFO[${domain}:public_html]}"

            echo "  └─ Database: $db_name ($db_size)"
            echo "  └─ Path: $public_html"

            if [ "$SHOW_SSL" = true ] && [ "${DOMAIN_INFO[${domain}:ssl]}" = "installed" ]; then
                local expiry="${DOMAIN_INFO[${domain}:ssl_expiry]}"
                echo "  └─ SSL Expiry: $expiry"
            fi
            echo ""
        fi
    done <<< "$sorted_domains"

    print_separator
    echo ""
    echo "Total domains: ${#DOMAINS[@]}"

    # Calculate total disk usage
    local total_size=0
    for domain in "${DOMAINS[@]}"; do
        local size_str="${DOMAIN_INFO[${domain}:disk_usage]}"
        # This is approximate
        if [[ $size_str =~ ([0-9.]+)M ]]; then
            total_size=$(echo "$total_size + ${BASH_REMATCH[1]}" | bc)
        elif [[ $size_str =~ ([0-9.]+)G ]]; then
            total_size=$(echo "$total_size + ${BASH_REMATCH[1]} * 1024" | bc)
        fi
    done

    if [ $(echo "$total_size > 0" | bc) -eq 1 ]; then
        if [ $(echo "$total_size > 1024" | bc) -eq 1 ]; then
            echo "Total disk usage: $(echo "scale=2; $total_size / 1024" | bc)GB"
        else
            echo "Total disk usage: $(echo "scale=2; $total_size" | bc)MB"
        fi
    fi

    echo ""
}

# Output in JSON format
output_json() {
    echo "{"
    echo '  "domains": ['

    local first=true
    local sorted_domains=$(sort_domains)

    while IFS= read -r domain; do
        [ "$first" = false ] && echo ","
        first=false

        cat << EOF
    {
      "domain": "$domain",
      "username": "${DOMAIN_INFO[${domain}:username]}",
      "database": "${DOMAIN_INFO[${domain}:database]}",
      "db_size": "${DOMAIN_INFO[${domain}:db_size]}",
      "disk_usage": "${DOMAIN_INFO[${domain}:disk_usage]}",
      "status": "${DOMAIN_INFO[${domain}:status]}",
      "ssl": "${DOMAIN_INFO[${domain}:ssl]}",
      "ssl_expiry": "${DOMAIN_INFO[${domain}:ssl_expiry]}",
      "root": "${DOMAIN_INFO[${domain}:root]}",
      "public_html": "${DOMAIN_INFO[${domain}:public_html]}"
    }
EOF
    done <<< "$sorted_domains"

    echo ""
    echo "  ],"
    echo '  "summary": {'
    echo "    \"total_domains\": ${#DOMAINS[@]}"
    echo "  }"
    echo "}"
}

# Output in CSV format
output_csv() {
    echo "Domain,Username,Database,DB Size,Disk Usage,Status,SSL,SSL Expiry,Root Path"

    local sorted_domains=$(sort_domains)
    while IFS= read -r domain; do
        echo "$domain,${DOMAIN_INFO[${domain}:username]},${DOMAIN_INFO[${domain}:database]},${DOMAIN_INFO[${domain}:db_size]},${DOMAIN_INFO[${domain}:disk_usage]},${DOMAIN_INFO[${domain}:status]},${DOMAIN_INFO[${domain}:ssl]},${DOMAIN_INFO[${domain}:ssl_expiry]},${DOMAIN_INFO[${domain}:public_html]}"
    done <<< "$sorted_domains"
}

# Output in simple format
output_simple() {
    local sorted_domains=$(sort_domains)
    while IFS= read -r domain; do
        echo "$domain"
    done <<< "$sorted_domains"
}

# Main execution
if ! collect_domain_info; then
    print_header "📋 Managed Domains"
    log_info "No domains found"
    echo ""
    exit 0
fi

case $OUTPUT_FORMAT in
    json)
        output_json
        ;;
    csv)
        output_csv
        ;;
    simple)
        output_simple
        ;;
    table|*)
        output_table
        ;;
esac

log_info "Domain list complete"
