#!/bin/bash
# Updated deploy.sh for Git structure

WEB_ROOT="/var/www/html"
SCRIPT_SRC="src/generate_sitemap.py"
XSL_SRC="src/sitemap.xsl"
SCRIPT_DEST="/usr/local/bin/generate_sitemap.py"

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Please run as root."
  exit
fi

apt update

apt install python3-bs4 -y

echo "📦 Deploying from Git repository..."

# Copy Python Logic
cp $SCRIPT_SRC $SCRIPT_DEST
chmod +x $SCRIPT_DEST
sed -i 's/\xc2\xa0/ /g' /usr/local/bin/generate_sitemap.py

# Copy Stylesheet
cp $XSL_SRC "$WEB_ROOT/sitemap.xsl"
chown www-data:www-data "$WEB_ROOT/sitemap.xsl"

# Copy Systemd Units
cp automation/sitemap-gen.* /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now sitemap-gen.path

echo "✅ Git deployment complete."
