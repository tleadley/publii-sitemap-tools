#!/bin/bash
# Updated deploy.sh – Git structure + redirect.lua support
# Must be run as root

WEB_ROOT="/var/www/html"
SCRIPT_SRC="src/generate_sitemap.py"
XSL_SRC="src/sitemap.xsl"
LUA_SRC="src/redirect.lua"                  # ← New: Lua script source
LUA_DEST="/etc/lighttpd/redirect.lua"       # ← Standard lighttpd Lua location

SCRIPT_DEST="/usr/local/bin/generate_sitemap.py"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo)."
  exit 1
fi

echo "🔄 Starting deployment..."

# Update package list and install required Python package
apt update -qq
apt install -y python3-bs4 lighttpd-mod-magnet ufw

lighttpd-enable-mod rewrite setenv

service lighttpd force-reload

echo "📦 Copying files from Git repository..."

# 1. Python sitemap generator
if [ -f "$SCRIPT_SRC" ]; then
  cp "$SCRIPT_SRC" "$SCRIPT_DEST"
  chmod +x "$SCRIPT_DEST"
  # Clean up non-breaking spaces / weird characters (common from copy-paste/editors)
  sed -i 's/\xc2\xa0/ /g' "$SCRIPT_DEST"
  echo "   ✓ Copied & cleaned: generate_sitemap.py → $SCRIPT_DEST"
else
  echo "   ⚠️ Warning: $SCRIPT_SRC not found – skipping"
fi

# 2. XSL stylesheet for sitemap
if [ -f "$XSL_SRC" ]; then
  cp "$XSL_SRC" "$WEB_ROOT/sitemap.xsl"
  chmod 644 "$WEB_ROOT/sitemap.xsl"
  echo "   ✓ Copied: sitemap.xsl → $WEB_ROOT/sitemap.xsl"
else
  echo "   ⚠️ Warning: $XSL_SRC not found – skipping"
fi

# 3. Lua redirect script for lighttpd (new)
if [ -f "$LUA_SRC" ]; then
  cp "$LUA_SRC" "$LUA_DEST"
  chmod 644 "$LUA_DEST"                   # readable by lighttpd, not writable
  echo "   ✓ Copied: redirect.lua → $LUA_DEST"
else
  echo "   ⚠️ Warning: $LUA_SRC not found – skipping Lua redirect"
fi

# 4. Systemd units for sitemap generation
if ls automation/sitemap-gen.* &>/dev/null; then
  cp automation/sitemap-gen.* /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable --now sitemap-gen.path 2>/dev/null || {
    echo "   ⚠️ Note: sitemap-gen.path enable/start failed – check unit files"
  }
  echo "   ✓ Deployed & activated systemd timer/path"
else
  echo "   ⚠️ Warning: No automation/sitemap-gen.* files found – skipping systemd"
fi

echo ""
echo "✅ Deployment finished."

# Quick summary / next steps
echo "Next steps:"
echo "  • Restart lighttpd to apply redirect.lua:   sudo systemctl restart lighttpd"
echo "  • Verify Lua is loaded:                     sudo lighttpd -tt -f /etc/lighttpd/lighttpd.conf"
echo "  • Check sitemap timer status:               systemctl status sitemap-gen.path"
echo ""
