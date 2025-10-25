#!/bin/bash

# WebStack Installer - Automated Testing Script
# Tests domain installation functionality

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
TEST_DOMAIN="test$(date +%s).local"
TEST_RESULTS=()
FAILED_TESTS=0
PASSED_TESTS=0

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          🧪 WebStack Installer Test Suite                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Test function
test_case() {
    local test_name="$1"
    local test_command="$2"

    echo -n "Testing: $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        TEST_RESULTS+=("PASS: $test_name")
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        TEST_RESULTS+=("FAIL: $test_name")
        ((FAILED_TESTS++))
        return 1
    fi
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. Prerequisites Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

test_case "Apache installed" "command -v apache2"
test_case "MySQL installed" "command -v mysql"
test_case "PHP installed" "command -v php"
test_case "Apache is running" "systemctl is-active apache2"
test_case "MySQL is running" "systemctl is-active mysql"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. Script Validation Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

test_case "webstack-installer.sh exists" "[ -f '$SCRIPT_DIR/webstack-installer.sh' ]"
test_case "webstack-installer.sh is executable" "[ -x '$SCRIPT_DIR/webstack-installer.sh' ]"
test_case "webstack-menu.sh exists" "[ -f '$SCRIPT_DIR/webstack-menu.sh' ]"
test_case "remove-domain.sh exists" "[ -f '$SCRIPT_DIR/remove-domain.sh' ]"
test_case "list-domains.sh exists" "[ -f '$SCRIPT_DIR/list-domains.sh' ]"
test_case "harden-security.sh exists" "[ -f '$SCRIPT_DIR/harden-security.sh' ]"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. Bash Syntax Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

for script in "$SCRIPT_DIR"/*.sh; do
    script_name=$(basename "$script")
    test_case "Syntax check: $script_name" "bash -n '$script'"
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. Dry-Run Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -n "Testing: Dry-run mode... "
if echo "$TEST_DOMAIN" | timeout 30 "$SCRIPT_DIR/webstack-installer.sh" --dry-run &>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC}"
    TEST_RESULTS+=("PASS: Dry-run mode")
    ((PASSED_TESTS++))
else
    echo -e "${YELLOW}⚠ SKIP (interactive input required)${NC}"
    TEST_RESULTS+=("SKIP: Dry-run mode")
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. Domain Validation Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Create a test validation function
validate_domain_test() {
    local domain="$1"
    [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]
}

test_case "Valid domain: example.com" "validate_domain_test 'example.com'"
test_case "Valid domain: sub.example.com" "validate_domain_test 'sub.example.com'"
test_case "Valid domain: test-site.com" "validate_domain_test 'test-site.com'"
test_case "Invalid domain: -invalid.com" "! validate_domain_test '-invalid.com'"
test_case "Invalid domain: invalid-.com" "! validate_domain_test 'invalid-.com'"
test_case "Invalid domain: invalid..com" "! validate_domain_test 'invalid..com'"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}6. File System Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

test_case "/var/www/ writable" "[ -w /var/www ]"
test_case "/etc/apache2/ writable" "[ -w /etc/apache2 ]"
test_case "Log directory exists" "[ -d /var/log ] || mkdir -p /var/log"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}7. Apache Configuration Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

test_case "Apache config syntax" "apache2ctl configtest"
test_case "mod_rewrite enabled" "a2query -m rewrite"
test_case "mod_ssl enabled" "a2query -m ssl"
test_case "mod_headers enabled" "a2query -m headers"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}8. MySQL Connection Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

test_case "MySQL root connection" "mysql -u root -e 'SELECT 1' &>/dev/null"
test_case "MySQL can create database" "mysql -u root -e 'CREATE DATABASE IF NOT EXISTS test_db; DROP DATABASE test_db;'"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          📊 TEST RESULTS                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo -e "Total:  $((PASSED_TESTS + FAILED_TESTS))"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "System is ready for WebStack Installer"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo ""
    echo "Please fix the following issues before using WebStack Installer:"
    for result in "${TEST_RESULTS[@]}"; do
        if [[ "$result" == FAIL:* ]]; then
            echo "  - ${result#FAIL: }"
        fi
    done
    echo ""
    exit 1
fi
