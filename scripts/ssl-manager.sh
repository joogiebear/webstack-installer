#!/bin/bash

# WebStack Installer - SSL Certificate Manager
# Install, renew, and manage SSL certificates for domains

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
init_logging "ssl-manager"
check_root

# Check if certbot is installed
if ! command_exists certbot; then
    log_error "Certbot is not installed"
    echo ""
    echo "Install certbot with:"
    echo "  apt install certbot python3-certbot-apache"
    echo ""
    exit 1
fi

# Main menu
show_menu() {
    clear
    print_header "🔒 SSL Certificate Manager"

    echo "1) Install SSL Certificate for a Domain"
    echo "2) Renew SSL Certificates"
    echo "3) Check SSL Status for All Domains"
    echo "4) View SSL Certificate Details"
    echo "5) Force Renew a Certificate"
    echo "6) Set up Auto-Renewal (Cron)"
    echo "7) Remove SSL Certificate"
    echo "8) Test SSL Configuration"
    echo "0) Exit"
    echo ""
}

# Install SSL for domain
install_ssl() {
    echo ""
    log_info "Installing SSL Certificate"
    echo ""

    # Get list of domains
    local domains=($(get_all_domains))

    if [ ${#domains[@]} -eq 0 ]; then
        log_error "No domains found"
        return
    fi

    echo "Available domains:"
    for i in "${!domains[@]}"; do
        local domain="${domains[$i]}"
        local ssl_status="❌ No SSL"
        if has_ssl "$domain"; then
            ssl_status="✅ Has SSL"
        fi
        echo "  $((i+1))) $domain $ssl_status"
    done
    echo ""

    read -rp "Select domain number (or enter domain name): " selection

    local domain_to_install
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#domains[@]} ]; then
        domain_to_install="${domains[$((selection-1))]}"
    else
        domain_to_install="$selection"
    fi

    if ! validate_domain "$domain_to_install"; then
        log_error "Invalid domain"
        return
    fi

    if ! domain_exists "$domain_to_install"; then
        log_error "Domain $domain_to_install not found"
        return
    fi

    echo ""
    log_info "Installing SSL certificate for: $domain_to_install"
    echo ""

    read -rp "Include www subdomain? [Y/n]: " include_www
    
    local domains_str="-d $domain_to_install"
    if [[ ! "$include_www" =~ ^[Nn]$ ]]; then
        domains_str="$domains_str -d www.$domain_to_install"
    fi

    read -rp "Enter email address for notifications: " email_addr

    if [ -z "$email_addr" ]; then
        log_error "Email address required"
        return
    fi

    echo ""
    log_info "Running certbot..."
    echo ""

    if certbot --apache $domains_str --email "$email_addr" --agree-tos --non-interactive; then
        log_success "SSL certificate installed successfully!"
        echo ""
        echo "Your site is now accessible via HTTPS:"
        echo "  https://$domain_to_install"
        [ "$include_www" != "n" ] && echo "  https://www.$domain_to_install"
    else
        log_error "Failed to install SSL certificate"
        echo ""
        echo "Common issues:"
        echo "  - Domain DNS not pointing to this server"
        echo "  - Port 80/443 not accessible"
        echo "  - Domain not properly configured in Apache"
    fi

    echo ""
    read -rp "Press Enter to continue..."
}

# Renew SSL certificates
renew_ssl() {
    echo ""
    log_info "Renewing SSL Certificates"
    echo ""

    log_info "Checking for certificates to renew..."
    echo ""

    if certbot renew --dry-run; then
        log_success "Dry run successful. Proceeding with actual renewal..."
        echo ""
        
        if certbot renew; then
            log_success "SSL certificates renewed successfully!"
            reload_apache
        else
            log_error "Failed to renew some certificates"
        fi
    else
        log_warn "Dry run failed. Please check certbot configuration"
    fi

    echo ""
    read -rp "Press Enter to continue..."
}

# Check SSL status
check_ssl_status() {
    clear
    print_header "🔒 SSL Certificate Status"

    local domains=($(get_all_domains))

    if [ ${#domains[@]} -eq 0 ]; then
        log_info "No domains found"
        echo ""
        read -rp "Press Enter to continue..."
        return
    fi

    printf "%-35s %-15s %-15s %-12s\n" "DOMAIN" "STATUS" "EXPIRES" "DAYS LEFT"
    print_separator

    for domain in "${domains[@]}"; do
        local status="No SSL"
        local expiry="N/A"
        local days_left="N/A"
        local status_color="$RED"

        if has_ssl "$domain"; then
            status="✓ Installed"
            status_color="$GREEN"
            expiry=$(get_ssl_expiry "$domain" | awk '{print $1, $2, $4}')

            # Calculate days until expiry
            local cert_file="/etc/letsencrypt/live/$domain/cert.pem"
            if [ -f "$cert_file" ]; then
                local expiry_epoch=$(date -d "$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)" +%s 2>/dev/null || echo "0")
                local now_epoch=$(date +%s)
                days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

                if [ "$days_left" -lt 30 ]; then
                    status_color="$YELLOW"
                    status="⚠ Expiring"
                fi
            fi
        fi

        printf "%-35s ${status_color}%-23s${NC} %-15s %-12s\n" "$domain" "$status" "$expiry" "$days_left days"
    done

    echo ""
    read -rp "Press Enter to continue..."
}

# View SSL certificate details
view_ssl_details() {
    echo ""
    log_info "View SSL Certificate Details"
    echo ""

    read -rp "Enter domain name: " domain

    if ! validate_domain "$domain"; then
        log_error "Invalid domain"
        read -rp "Press Enter to continue..."
        return
    fi

    if ! has_ssl "$domain"; then
        log_error "No SSL certificate found for $domain"
        read -rp "Press Enter to continue..."
        return
    fi

    local cert_file="/etc/letsencrypt/live/$domain/cert.pem"

    clear
    print_header "🔒 SSL Certificate Details: $domain"

    echo "Certificate Information:"
    echo ""
    openssl x509 -in "$cert_file" -text -noout | grep -A 2 "Subject:"
    echo ""
    openssl x509 -in "$cert_file" -text -noout | grep -A 2 "Validity"
    echo ""
    openssl x509 -in "$cert_file" -text -noout | grep -A 3 "Subject Alternative Name"
    echo ""

    echo ""
    read -rp "Press Enter to continue..."
}

# Force renew certificate
force_renew() {
    echo ""
    log_warn "Force Renew SSL Certificate"
    echo ""

    read -rp "Enter domain name: " domain

    if ! validate_domain "$domain"; then
        log_error "Invalid domain"
        read -rp "Press Enter to continue..."
        return
    fi

    if ! has_ssl "$domain"; then
        log_error "No SSL certificate found for $domain"
        read -rp "Press Enter to continue..."
        return
    fi

    echo ""
    log_warn "This will force renew the certificate for $domain"
    if ! confirm "Continue?"; then
        return
    fi

    echo ""
    if certbot renew --cert-name "$domain" --force-renewal; then
        log_success "Certificate renewed successfully!"
        reload_apache
    else
        log_error "Failed to renew certificate"
    fi

    echo ""
    read -rp "Press Enter to continue..."
}

# Setup auto-renewal cron job
setup_auto_renewal() {
    echo ""
    log_info "Setup Auto-Renewal"
    echo ""

    local cron_cmd="0 3 * * * certbot renew --quiet && systemctl reload apache2"

    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "certbot renew"; then
        log_info "Auto-renewal cron job already exists"
        echo ""
        crontab -l | grep "certbot renew"
        echo ""

        if confirm "Update existing cron job?"; then
            # Remove old job and add new one
            crontab -l 2>/dev/null | grep -v "certbot renew" | crontab -
            (crontab -l 2>/dev/null; echo "$cron_cmd") | crontab -
            log_success "Cron job updated!"
        fi
    else
        echo "This will add a cron job to automatically renew SSL certificates"
        echo "The job will run daily at 3:00 AM"
        echo ""
        echo "Cron command:"
        echo "  $cron_cmd"
        echo ""

        if confirm "Add cron job?"; then
            (crontab -l 2>/dev/null; echo "$cron_cmd") | crontab -
            log_success "Auto-renewal cron job added successfully!"
            echo ""
            echo "Certificates will be checked daily and renewed if needed"
        fi
    fi

    echo ""
    read -rp "Press Enter to continue..."
}

# Remove SSL certificate
remove_ssl() {
    echo ""
    log_warn "Remove SSL Certificate"
    echo ""

    read -rp "Enter domain name: " domain

    if ! validate_domain "$domain"; then
        log_error "Invalid domain"
        read -rp "Press Enter to continue..."
        return
    fi

    if ! has_ssl "$domain"; then
        log_error "No SSL certificate found for $domain"
        read -rp "Press Enter to continue..."
        return
    fi

    echo ""
    log_warn "This will remove the SSL certificate for $domain"
    log_warn "The domain will no longer be accessible via HTTPS"
    echo ""

    if ! confirm "Are you sure?"; then
        return
    fi

    echo ""
    if certbot delete --cert-name "$domain"; then
        log_success "SSL certificate removed successfully"
        
        # Remove SSL configuration from Apache
        local apache_conf="/etc/apache2/sites-available/${domain}-le-ssl.conf"
        if [ -f "$apache_conf" ]; then
            a2dissite "${domain}-le-ssl" 2>/dev/null || true
            rm -f "$apache_conf"
        fi

        reload_apache
    else
        log_error "Failed to remove SSL certificate"
    fi

    echo ""
    read -rp "Press Enter to continue..."
}

# Test SSL configuration
test_ssl() {
    echo ""
    log_info "Test SSL Configuration"
    echo ""

    read -rp "Enter domain name: " domain

    if ! validate_domain "$domain"; then
        log_error "Invalid domain"
        read -rp "Press Enter to continue..."
        return
    fi

    if ! has_ssl "$domain"; then
        log_error "No SSL certificate found for $domain"
        read -rp "Press Enter to continue..."
        return
    fi

    echo ""
    log_info "Testing SSL certificate for $domain..."
    echo ""

    # Test with openssl
    echo "Testing with openssl..."
    timeout 5 openssl s_client -connect "$domain:443" -servername "$domain" </dev/null 2>/dev/null | openssl x509 -noout -dates

    echo ""
    echo "Testing certificate chain..."
    timeout 5 openssl s_client -connect "$domain:443" -servername "$domain" </dev/null 2>/dev/null | grep -A 5 "Certificate chain"

    echo ""
    log_info "For detailed SSL analysis, visit:"
    echo "  https://www.ssllabs.com/ssltest/analyze.html?d=$domain"

    echo ""
    read -rp "Press Enter to continue..."
}

# Main loop
while true; do
    show_menu
    read -rp "Select option: " choice

    case $choice in
        1) install_ssl ;;
        2) renew_ssl ;;
        3) check_ssl_status ;;
        4) view_ssl_details ;;
        5) force_renew ;;
        6) setup_auto_renewal ;;
        7) remove_ssl ;;
        8) test_ssl ;;
        0) 
            log_info "Exiting SSL Manager"
            exit 0
            ;;
        *)
            log_error "Invalid option"
            sleep 1
            ;;
    esac
done
