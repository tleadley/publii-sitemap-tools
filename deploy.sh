#!/bin/bash

# --- CONFIGURATION ---
WEB_ROOT="/var/www/html"
SCRIPT_DEST="/usr/local/bin/generate_sitemap.py"
SERVICE_NAME="sitemap-gen"
# ---------------------

echo "🚀 Starting deployment of Publii Sitemap Automator..."

# 1. Ensure we are running as root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Please run as root (use sudo)."
  exit
fi

# 2. Move Python script to /usr/local/bin
if [ -f "generate_sitemap.py" ]; then
    cp generate_sitemap.py $SCRIPT_DEST
    chmod +x $SCRIPT_DEST
    echo "✅ Python script installed to $SCRIPT_DEST"
else
    echo "⚠️ generate_sitemap.py not found in current folder!"
fi

# 3. Move XSLT stylesheet to Web Root
if [ -f "sitemap.xsl" ]; then
    cp sitemap.xsl "$WEB_ROOT/sitemap.xsl"
    chown www-data:www-data "$WEB_ROOT/sitemap.xsl"
    echo "✅ Stylesheet installed to $WEB_ROOT"
else
    echo "⚠️ sitemap.xsl not found!"
fi

# 4. Install Systemd Units
echo "⚙️ Configuring Systemd automation..."
cp "${SERVICE_NAME}.service" "/etc/systemd/system/"
cp "${SERVICE_NAME}.path" "/etc/systemd/system/"

# 5. Reload and Enable
systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}.path"

echo "-----------------------------------------------"
echo "🎉 Deployment Complete!"
echo "🔍 Check status with: systemctl status ${SERVICE_NAME}.path"
echo "📂 Monitor logs with: journalctl -u ${SERVICE_NAME}.service -f"
echo "-----------------------------------------------"
