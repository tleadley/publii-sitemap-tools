#!/bin/bash

# Lighttpd & Debian Security Auditor - Production Build
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "====================================================="
echo "   LIGHTTPD SECURITY & LOGIC AUDIT SUITE             "
echo "====================================================="

# 1. Config Syntax
echo -e "\n${BLUE}[1] Configuration Integrity${NC}"
if lighttpd -t -f /etc/lighttpd/lighttpd.conf > /dev/null 2>&1; then
    echo -e "  [${GREEN}PASS${NC}] Configuration syntax valid."
else
    echo -e "  [${RED}FAIL${NC}] Configuration syntax error!"
    exit 1
fi

# 2. Filesystem & Ownership (The 'www-data' Check)
echo -e "\n${BLUE}[2] Filesystem Permissions${NC}"
DOC_ROOT=$(lighttpd -p -f /etc/lighttpd/lighttpd.conf | grep "server.document-root" | head -n 1 | awk -F ' *= *' '{print $2}' | tr -d '"' | xargs)
# Check for the dangerous 'chown -R www-data'
ROOT_OWNER=$(stat -c "%U" "$DOC_ROOT")
if [ "$ROOT_OWNER" == "www-data" ]; then
    echo -e "  [${RED}FAIL${NC}] Web root owned by www-data (High Risk)."
else
    echo -e "  [${GREEN}PASS${NC}] Web root owned by $ROOT_OWNER."
fi
# Check for any files writable by server
WRITABLE=$(find "$DOC_ROOT" -user www-data -type f | wc -l)
if [ "$WRITABLE" -gt 0 ]; then
    echo -e "  [${RED}FAIL${NC}] $WRITABLE files are writable by the web process."
else
    echo -e "  [${GREEN}PASS${NC}] Web root is read-only for the server."
fi

# 3. Redirect Logic Validation (301 vs 302)
echo -e "\n${BLUE}[3] Redirect & Lua Logic Validation${NC}"

# Test 1: Directory without trailing slash (Expecting 301)
# Create a dummy dir for testing if one doesn't exist
mkdir -p "$DOC_ROOT/testdir"
R301=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/testdir)

# Test 2: URL with trailing slash / no index (Expecting 302 from Lua)
R302=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/testdir/)

if [ "$R301" == "301" ]; then
    echo -e "  [${GREEN}PASS${NC}] No-slash directory request returned 301 (SEO/Canonical)."
else
    echo -e "  [${YELLOW}WARN${NC}] Expected 301 for directory, got $R301."
fi

if [ "$R302" == "302" ]; then
    echo -e "  [${GREEN}PASS${NC}] Slashed URL / No index returned 302 (Lua Security Mask)."
else
    echo -e "  [${RED}FAIL${NC}] Slashed URL did not trigger 302 Redirect. (Got $R302)."
fi

# 4. Lua Script Protection
LUA_PATH=$(lighttpd -p -f /etc/lighttpd/lighttpd.conf | grep "magnet.attract-physical-path-to" | awk -F '"' '{print $2}')
if [ -f "$LUA_PATH" ]; then
    LUA_PERM=$(stat -c "%a" "$LUA_PATH")
    if [ "$LUA_PERM" -le "644" ]; then
        echo -e "  [${GREEN}PASS${NC}] Lua script permissions are restricted ($LUA_PERM)."
    else
        echo -e "  [${RED}FAIL${NC}] Lua script is too open ($LUA_PERM)."
    fi
fi

# 5. Information Disclosure (Headers)
echo -e "\n${BLUE}[4] Header Analysis${NC}"
HEADERS=$(curl -s -I http://localhost/)
if echo "$HEADERS" | grep -qi "Server: lighttpd/"; then
    echo -e "  [${YELLOW}WARN${NC}] Server header reveals lighttpd version."
else
    echo -e "  [${GREEN}PASS${NC}] Server version is hidden."
fi
echo -e "\n--- Port Exposure Audit ---"

# --- ADAPTIVE NETWORK & FIREWALL AUDIT ---
echo -e "\n${BLUE}[5] Adaptive Network & Trust Validation${NC}"

# 1. Identify the 'Expected' trusted actors
TRUSTED_PROXY=$(lighttpd -p -f /etc/lighttpd/lighttpd.conf | grep "extforward.forwarder" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)
# Detect the local subnet dynamically
INTERNAL_NET=$(ip -o -f inet addr show $(ip route | grep default | awk '{print $5}') | awk '{print $4}' | cut -d. -f1-2) # Your internal network prefix
# Detect the server's own internal IP (for debug header testing)
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "  [${BLUE}INFO${NC}] Detected Local Subnet: ${YELLOW}$INTERNAL_NET.x.x${NC} | Internal IP: ${YELLOW}$SERVER_IP${NC}"
# 2. Check Interface Binding (0.0.0.0 vs 127.0.0.1)
LISTEN_IPS=$(ss -tulpn | grep -E ':80|:443' | awk '{print $5}' | sed 's/:[^:]*$//' | sed 's/\[//g; s/\]//g' | sort -u)

for IP in $LISTEN_IPS; do
    if [[ "$IP" == "0.0.0.0" ]] || [[ "$IP" == "::" ]]; then
        echo -e "  [${YELLOW}INFO${NC}] Global Interface found ($IP). Checking for Firewall protection..."

        # 3. Perform Adaptive Firewall Check
        if ufw status | grep -q "active"; then

            # Check for the Remote Proxy (The Front Door)
            if [ ! -z "$TRUSTED_PROXY" ]; then
                if ufw status | grep "$TRUSTED_PROXY" | grep -qE "80|443"; then
                    echo -e "  [${GREEN}PASS${NC}] Proxy IP ($TRUSTED_PROXY) whitelisted on 80/443."
                else
                    echo -e "  [${RED}FAIL${NC}] Proxy IP ($TRUSTED_PROXY) NOT whitelisted!"
                fi
            fi

            # Check for Internal Network (The Side Door)
            if ufw status | grep "$INTERNAL_NET" | grep -qE "80|443"; then
                echo -e "  [${GREEN}PASS${NC}] Internal Net ($INTERNAL_NET.x) whitelisted on 80/443."
            else
                echo -e "  [${RED}FAIL${NC}] Internal Net ($INTERNAL_NET.x) NOT whitelisted!"
            fi

            # Check for "Anywhere" Leaks (The Security Hole)
            if ufw status | grep -E "^80|^443" | grep "ALLOW" | grep -q "Anywhere"; then
                echo -e "  [${RED}CRITICAL${NC}] SECURITY LEAK: Port 80/443 is open to 'Anywhere'!"
            else
                echo -e "  [${GREEN}PASS${NC}] No global 'Anywhere' rules found."
            fi
        else
            echo -e "  [${RED}CRITICAL${NC}] Firewall is DISABLED! Global interface is fully exposed."
        fi
   fi
done
echo -e "  ${BLUE}--- IPv6 Exposure Audit ---${NC}"

# 1. Check if the server is actually listening on IPv6
IPV6_LISTEN=$(ss -tulpn | grep -E ':80|:443' | grep "\[::\]")

if [ ! -z "$IPV6_LISTEN" ]; then
    echo -e "  [${YELLOW}INFO${NC}] Server is listening on IPv6 wildcard [::]."

    # 2. Search for IPv6 'Anywhere' allow rules
    V6_LEAK=$(ufw status | grep -E "^80|^443" | grep "ALLOW" | grep "Anywhere (v6)")

    if [ ! -z "$V6_LEAK" ]; then
        echo -e "  [${RED}CRITICAL${NC}] IPv6 SECURITY LEAK: Ports 80/443 open to 'Anywhere (v6)'!"
        echo "            This bypasses your IPv4 proxy restrictions."
    else
        # 3. Verify if there are ANY IPv6 rules (Safe default is usually no IPv6 access or specific whitelist)
        V6_RULES=$(ufw status | grep "(v6)" | grep -E "80|443")
        if [ -z "$V6_RULES" ]; then
            echo -e "  [${GREEN}PASS${NC}] No IPv6 allow rules found (Default Deny active)."
        else
            echo -e "  [${GREEN}PASS${NC}] IPv6 traffic is restricted to specific rules."
        fi
    fi
else
    echo -e "  [${GREEN}PASS${NC}] Server is not listening on IPv6 (No leak possible)."
fi
echo -e "\n${BLUE}[6] MIME-Type & Content Security Audit${NC}"

# 1. Check for 'nosniff' header in a live request
NOSNIFF_CHECK=$(curl -s -I http://localhost | grep -i "X-Content-Type-Options: nosniff")

if [ ! -z "$NOSNIFF_CHECK" ]; then
    echo -e "  [${GREEN}PASS${NC}] 'X-Content-Type-Options: nosniff' header is active."
else
    echo -e "  [${RED}FAIL${NC}] Missing 'nosniff' header. Browsers may try to execute data as code."
fi
# 2. Test Default MIME-Type Handling
# Create a file with no extension
touch "$DOC_ROOT/mime_test_file"
MIME_RESPONSE=$(curl -s -I http://localhost/mime_test_file | grep -i "Content-Type")
rm "$DOC_ROOT/mime_test_file"

if [[ "$MIME_RESPONSE" == *"application/octet-stream"* ]]; then
    echo -e "  [${GREEN}PASS${NC}] Unknown files are served as safe 'octet-stream'."
elif [[ "$MIME_RESPONSE" == *"text/html"* ]]; then
    echo -e "  [${RED}FAIL${NC}] Security Risk: Unknown files are served as 'text/html'!"
else
    echo -e "  [${YELLOW}INFO${NC}] Unknown file MIME-type: $(echo $MIME_RESPONSE | awk '{print $2}')"
fi

echo -e "  Testing Internal Trust Logic... "

# We simulate a request from a trusted internal IP
TEST_IP="$SERVER_IP"
INTERNAL_CHECK=$(curl -s -I -H "X-Forwarded-For: $TEST_IP" http://localhost | grep "X-Debug")

if [[ ! -z "$INTERNAL_CHECK" ]]; then
    echo -e "  [${GREEN}PASS${NC}] Debug headers visible to Internal IP: ${YELLOW}$TEST_IP.${NC}"
else
    echo -e "  [${RED}FAIL${NC}] Debug headers HIDDEN from internal IP. (Check mod_extforward)"
fi

# --- [TEST] External Masking ---
echo -e "\n${BLUE}[TEST] Testing Internal Trust Logic${NC}"

# We simulate a request from a public IP (e.g., Google DNS)
EXTERNAL_CHECK=$(curl -s -I -H "X-Forwarded-For: 8.8.8.8" http://localhost | grep "X-Debug")

if [[ -z "$EXTERNAL_CHECK" ]]; then
    echo -e "  [${GREEN}PASS${NC}] Debug headers successfully masked from public IPs."
else
    echo -e "  [${RED}FAIL${NC}] SECURITY LEAK: Debug headers visible to public IPs!"
fi

echo -e "\n====================================================="
echo -e "${BLUE}                AUDIT COMPLETE                      ${NC} "
echo -e "====================================================="
