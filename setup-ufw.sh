#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Quick UFW Setup Script – Exact rules match for your web/proxy server
# Run as root or with sudo
# ------------------------------------------------------------------------------

set -euo pipefail

# Optional: Reset UFW to defaults first (uncomment if you want a clean slate)
# echo "Resetting UFW to defaults..."
# ufw --force reset
# ufw default deny incoming
# ufw default allow outgoing
# ufw limit from 10.150.16.0/24 to any port 22 proto tcp comment 'Rate-limited internal SSH'

echo "Enabling UFW if not already active..."
ufw --force enable >/dev/null || true

# 1. Internal services (SSH + custom port) – restricted to your subnet
echo "Adding internal-only rules..."
ufw allow from 10.150.16.0/24 to any port 22 proto tcp comment 'Internal SSH'
ufw allow from 10.150.16.0/24 to any port 61209 proto tcp comment 'Internal custom service (61209)'

# 2. Loopback (harmless/default, but explicit for completeness)
ufw allow in on lo to any comment 'Loopback IPv4'
# IPv6 loopback is handled separately below

# 3. Public web ports – only on eth0 interface (prevents binding to other interfaces)
echo "Adding public web rules on eth0..."
ufw allow in on eth0 to any port 80 proto tcp comment 'HTTP public on eth0'
ufw allow in on eth0 to any port 443 proto tcp comment 'HTTPS public on eth0'

# 4. IPv6 equivalents
# (UFW automatically handles ::1 loopback in many cases, but make explicit)
ufw allow in on lo proto ipv6 comment 'Loopback IPv6'

# IPv6 public web – same interface restriction
ufw allow in on eth0 to any port 80 proto tcp comment 'HTTP public on eth0 (v6)'
ufw allow in on eth0 to any port 443 proto tcp comment 'HTTPS public on eth0 (v6)'

echo ""
echo "Reloading UFW..."
ufw reload

echo ""
echo "Done. Current status:"
ufw status numbered

echo ""
echo "IPv6 status (if enabled):"
ufw status numbered | grep -i "(v6)" || echo "  (no IPv6 rules shown – check /etc/default/ufw if IPv6 is disabled)"
