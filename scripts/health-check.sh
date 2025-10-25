#!/bin/bash

# WebStack Installer - System Health Check
# Comprehensive system diagnostics and recommendations

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
init_logging "health-check"
check_root

# Health check results
declare -a WARNINGS
declare -a ERRORS
declare -a INFO_ITEMS
declare -a RECOMMENDATIONS

print_header "🏥 WebStack Health Check"

log_info "Running comprehensive system diagnostics..."
echo ""

# Check 1: System Resources
print_subsection "1. System Resources"

# Memory
TOTAL_MEM=$(get_memory_mb)
USED_MEM=$(free -m | awk 'NR==2{print $3}')
MEM_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))

echo "  Memory:"
echo "    Total: ${TOTAL_MEM}MB"
echo "    Used:  ${USED_MEM}MB ($MEM_PERCENT%)"

if [ $MEM_PERCENT -gt 90 ]; then
    ERRORS+=("Memory usage critically high: ${MEM_PERCENT}%")
    echo -e "    ${RED}✗ CRITICAL: Memory usage too high${NC}"
elif [ $MEM_PERCENT -gt 75 ]; then
    WARNINGS+=("Memory usage high: ${MEM_PERCENT}%")
    echo -e "    ${YELLOW}⚠ WARNING: Memory usage high${NC}"
else
    echo -e "    ${GREEN}✓ Memory usage OK${NC}"
fi

# Disk Space
FREE_SPACE=$(get_free_space)
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')

echo ""
echo "  Disk Space:"
echo "    Free: $FREE_SPACE"
echo "    Used: ${DISK_USAGE}%"

if [ $DISK_USAGE -gt 90 ]; then
    ERRORS+=("Disk space critically low: ${DISK_USAGE}% used")
    echo -e "    ${RED}✗ CRITICAL: Disk space low${NC}"
    RECOMMENDATIONS+=("Free up disk space immediately or expand storage")
elif [ $DISK_USAGE -gt 80 ]; then
    WARNINGS+=("Disk space running low: ${DISK_USAGE}% used")
    echo -e "    ${YELLOW}⚠ WARNING: Disk space running low${NC}"
    RECOMMENDATIONS+=("Consider cleaning up old backups and logs")
else
    echo -e "    ${GREEN}✓ Disk space OK${NC}"
fi

# CPU Load
LOAD=$(get_load_average)
CPU_CORES=$(get_cpu_cores)

echo ""
echo "  CPU:"
echo "    Cores: $CPU_CORES"
echo "    Load:  $LOAD"

LOAD_INT=$(echo "$LOAD" | cut -d'.' -f1)
if [ "$LOAD_INT" -gt "$((CPU_CORES * 2))" ]; then
    WARNINGS+=("High CPU load: $LOAD (cores: $CPU_CORES)")
    echo -e "    ${YELLOW}⚠ WARNING: High load average${NC}"
else
    echo -e "    ${GREEN}✓ CPU load OK${NC}"
fi

# Check 2: Services Status
print_subsection "2. Critical Services"

SERVICES=("apache2" "mysql")

for service in "${SERVICES[@]}"; do
    echo -n "  $service: "
    if is_service_running "$service"; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${RED}✗ Stopped${NC}"
        ERRORS+=("Service $service is not running")
        RECOMMENDATIONS+=("Start $service: systemctl start $service")
    fi
done

# Check 3: Apache Configuration
print_subsection "3. Apache Configuration"

if check_apache_config; then
    echo -e "  ${GREEN}✓ Apache configuration valid${NC}"
else
    echo -e "  ${RED}✗ Apache configuration has errors${NC}"
    ERRORS+=("Apache configuration test failed")
    RECOMMENDATIONS+=("Run 'apache2ctl configtest' to see errors")
fi

# Check enabled modules
REQUIRED_MODS=("rewrite" "ssl" "headers")
for mod in "${REQUIRED_MODS[@]}"; do
    if a2query -m "$mod" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} mod_$mod enabled"
    else
        echo -e "  ${YELLOW}⚠${NC} mod_$mod not enabled"
        WARNINGS+=("Apache module $mod not enabled")
        RECOMMENDATIONS+=("Enable mod_$mod: a2enmod $mod")
    fi
done

# Check 4: MySQL/Database Health
print_subsection "4. Database Health"

if check_mysql_connection; then
    echo -e "  ${GREEN}✓ MySQL connection OK${NC}"

    # Check database sizes
    TOTAL_DB_SIZE=0
    DOMAIN_COUNT=$(count_domains)

    if [ $DOMAIN_COUNT -gt 0 ]; then
        echo ""
        echo "  Database Sizes:"
        
        for domain in $(get_all_domains); do
            db_name=$(get_domain_database "$domain")
            if [ -n "$db_name" ] && database_exists "$db_name"; then
                db_size=$(get_database_size "$db_name")
                echo "    $db_name: ${db_size}MB"
                TOTAL_DB_SIZE=$(echo "$TOTAL_DB_SIZE + $db_size" | bc)
            fi
        done

        echo "  Total Database Size: ${TOTAL_DB_SIZE}MB"
    fi
else
    echo -e "  ${RED}✗ Cannot connect to MySQL${NC}"
    ERRORS+=("MySQL connection failed")
    RECOMMENDATIONS+=("Check MySQL service status: systemctl status mysql")
fi

# Check 5: SSL Certificates
print_subsection "5. SSL Certificates"

SSL_ISSUES=0
SSL_EXPIRING=0

for domain in $(get_all_domains); do
    if has_ssl "$domain"; then
        cert_file="/etc/letsencrypt/live/$domain/cert.pem"
        if [ -f "$cert_file" ]; then
            expiry_epoch=$(date -d "$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)" +%s 2>/dev/null || echo "0")
            now_epoch=$(date +%s)
            days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

            if [ $days_left -lt 0 ]; then
                echo -e "  ${RED}✗${NC} $domain: Certificate EXPIRED"
                ERRORS+=("SSL certificate expired for $domain")
                ((SSL_ISSUES++))
            elif [ $days_left -lt 30 ]; then
                echo -e "  ${YELLOW}⚠${NC} $domain: Expires in $days_left days"
                WARNINGS+=("SSL certificate for $domain expires soon ($days_left days)")
                ((SSL_EXPIRING++))
            else
                echo -e "  ${GREEN}✓${NC} $domain: Valid ($days_left days)"
            fi
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} $domain: No SSL"
        INFO_ITEMS+=("Domain $domain has no SSL certificate")
    fi
done

if [ $SSL_ISSUES -gt 0 ] || [ $SSL_EXPIRING -gt 0 ]; then
    RECOMMENDATIONS+=("Renew SSL certificates: certbot renew")
fi

# Check 6: Security
print_subsection "6. Security Configuration"

# Check if firewall is enabled
if command_exists ufw; then
    if ufw status | grep -q "Status: active"; then
        echo -e "  ${GREEN}✓ Firewall (UFW) enabled${NC}"
    else
        echo -e "  ${YELLOW}⚠ Firewall (UFW) disabled${NC}"
        WARNINGS+=("Firewall is not enabled")
        RECOMMENDATIONS+=("Enable firewall: ufw enable")
    fi
else
    echo -e "  ${YELLOW}⚠ UFW not installed${NC}"
    RECOMMENDATIONS+=("Install UFW: apt install ufw")
fi

# Check for security headers
if [ -f "/etc/apache2/conf-available/security-headers.conf" ]; then
    echo -e "  ${GREEN}✓ Security headers configured${NC}"
else
    echo -e "  ${YELLOW}⚠ Security headers not configured${NC}"
    RECOMMENDATIONS+=("Run security hardening: ./harden-security.sh")
fi

# Check 7: Backups
print_subsection "7. Backup Status"

BACKUP_DIR="/var/backups/webstack"
if [ -d "$BACKUP_DIR" ]; then
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "*.tar.*" -type f -mtime -7 | wc -l)
    
    if [ $BACKUP_COUNT -gt 0 ]; then
        echo -e "  ${GREEN}✓ Recent backups found ($BACKUP_COUNT in last 7 days)${NC}"
    else
        echo -e "  ${YELLOW}⚠ No recent backups found${NC}"
        WARNINGS+=("No backups found in last 7 days")
        RECOMMENDATIONS+=("Create backups: ./backup-all.sh")
    fi

    # Check backup disk usage
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
    echo "  Backup Directory Size: $BACKUP_SIZE"
else
    echo -e "  ${YELLOW}⚠ Backup directory not found${NC}"
    RECOMMENDATIONS+=("Set up regular backups with ./backup-all.sh")
fi

# Check 8: System Updates
print_subsection "8. System Updates"

if command_exists apt; then
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
    SECURITY=$(apt list --upgradable 2>/dev/null | grep -ci security || echo "0")

    echo "  Pending Updates: $UPDATES"
    echo "  Security Updates: $SECURITY"

    if [ $SECURITY -gt 0 ]; then
        WARNINGS+=("$SECURITY security updates available")
        RECOMMENDATIONS+=("Install security updates: apt update && apt upgrade")
    elif [ $UPDATES -gt 10 ]; then
        INFO_ITEMS+=("$UPDATES system updates available")
        RECOMMENDATIONS+=("Keep system updated: apt update && apt upgrade")
    else
        echo -e "  ${GREEN}✓ System relatively up to date${NC}"
    fi
fi

# Summary
echo ""
print_separator
echo ""
print_header "📊 Health Check Summary"

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}ERRORS (${#ERRORS[@]})${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for error in "${ERRORS[@]}"; do
        echo -e "  ${RED}✗${NC} $error"
    done
    echo ""
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}WARNINGS (${#WARNINGS[@]})${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for warning in "${WARNINGS[@]}"; do
        echo -e "  ${YELLOW}⚠${NC} $warning"
    done
    echo ""
fi

if [ ${#INFO_ITEMS[@]} -gt 0 ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}INFORMATION${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for info in "${INFO_ITEMS[@]}"; do
        echo -e "  ${BLUE}ℹ${NC} $info"
    done
    echo ""
fi

if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}RECOMMENDATIONS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for i in "${!RECOMMENDATIONS[@]}"; do
        echo -e "  $((i+1)). ${RECOMMENDATIONS[$i]}"
    done
    echo ""
fi

# Overall Health Score
TOTAL_CHECKS=$((${#ERRORS[@]} + ${#WARNINGS[@]} + 10))
PASSED_CHECKS=$((10 - ${#ERRORS[@]}))
HEALTH_SCORE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Overall Health Score: $HEALTH_SCORE%"

if [ $HEALTH_SCORE -ge 90 ]; then
    echo -e "${GREEN}Status: EXCELLENT${NC}"
elif [ $HEALTH_SCORE -ge 75 ]; then
    echo -e "${GREEN}Status: GOOD${NC}"
elif [ $HEALTH_SCORE -ge 60 ]; then
    echo -e "${YELLOW}Status: FAIR - Attention needed${NC}"
else
    echo -e "${RED}Status: POOR - Immediate action required${NC}"
fi

echo ""
log_info "Health check complete"
