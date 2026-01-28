![Python Version](https://img.shields.io/badge/python-3.x-blue.svg)
![Platform](https://img.shields.io/badge/platform-debian%20%7C%20ubuntu-lightgrey.svg)
![License](https://img.shields.io/badge/license-CC0-green.svg)

# Publii Sitemap & Image SEO Automator (Native Python)

A secure, lightweight post-processing solution for Publii sites hosted on Debian/lighttpd.

This project solves the "Relative URL" conflict in Publii: it allows you to maintain relative URLs for internal networking (Split DNS) while automatically generating a professional, absolute-URL sitemap.xml with full Google Image SEO support.

## ✨ Features

- Zero Dependencies (Almost): No Node.js or npm required. Uses native Python 3 and BeautifulSoup4.
- Absolute URL Mapping: Automatically prepends your public domain to relative paths.
- Full Image SEO: Maps every <image:image> location, not just a count.
- Professional Styling: Includes an XSLT stylesheet to make sitemaps human-readable.
- Linux Native Automation: Uses Systemd Path Units to trigger updates the millisecond you sync from Publii.
- Permission Auto-Fix: Automatically handles "root-owned" file issues by resetting ownership to www-data.

## 🚀 Installation
### 1. Prerequisites

Install the Python HTML parser on your Debian server:
Bash

```sudo apt update && sudo apt install python3-bs4```

### 2. Deployment

- Script: Copy generate_sitemap.py to /usr/local/bin/ and update your PUBLIC_URL.
- Styles: Drop sitemap.xsl into your web root (e.g., /var/www/html/).
- Automation: Copy the .service and .path files to /etc/systemd/system/.

### 3. Activation
Bash
```
sudo systemctl daemon-reload
sudo systemctl enable --now sitemap-gen.path
```

## 📂 Project Structure

- generate_sitemap.py: The Python 3 engine.
- sitemap.xsl: The visual stylesheet for the browser.
- sitemap-gen.service: Systemd task runner (handles permissions + execution).
- sitemap-gen.path: Systemd directory monitor.

## 🛠 Configuration

Inside generate_sitemap.py, you can customize:

- SITE_DIR: Path to your web files.
- PUBLIC_URL: Your live domain (FQDN).
- EXCLUDE_FOLDERS: A list of folders (e.g., tags, assets) to ignore.

## 🔒 Security

By avoiding npm, this workflow eliminates supply-chain vulnerabilities. The automation runs as root only for the duration of the permission reset and sitemap generation, ensuring the web root stays owned by www-data for safe serving by lighttpd.
📄 License
Public Domain / CC0 (Copyleft). Feel free to use, modify, and share.

## 📖 How to Use
### 1. Configure Publii

To ensure this tool works correctly with your Publii setup:

- URLs: Set your Publii site to use Relative URLs (found in Site Settings).
- SEO: Disable the internal sitemap generation in Publii (SEO -> Sitemap).
- Sync: Configure your sync method (SFTP/SSH) to target your Debian server's web root (e.g., /var/www/html).

### 2. First-Time Setup on Server

Clone this repository to your user's home directory on the server:
Bash
```
git clone https://github.com/yourusername/publii-sitemap-tools.git ~/sitemap-tools
cd ~/sitemap-tools
```
Edit src/generate_sitemap.py and set your PUBLIC_URL to your live domain:
Python

PUBLIC_URL = "https://yourdomain.com"

Run the installer:
Bash

```sudo ./deploy.sh```

### 3. The Workflow

Once installed, you never need to run the script manually again:

- Create/Edit content in the Publii Desktop App.
- Hit "Sync" in Publii.
- The files arrive on your Debian server via SSH/SFTP.
- Systemd detects the new files, instantly resets permissions to www-data, and regenerates your sitemap.xml.

### 4. Verification

You can verify the automation is running by checking the Systemd logs:
Bash

```journalctl -u sitemap-gen.service -f```

Or by visiting your sitemap in a browser: https://yourdomain.com/sitemap.xml. You should see a styled, human-readable table containing all your pages and image locations.

## 🛠 Troubleshooting

| Issue | Cause | Fix |
| --- | --- | --- |
| Sitemap not updating | sitemap-gen.path not running | sudo systemctl status sitemap-gen.path |
| Permission Denied | Publii synced as root | The service handles this, but ensure deploy.sh was run with sudo.|
| No images in sitemap | Script didn't find <img> tags | Ensure your images are not loaded via external JavaScript (lazy-loading is fine if src is present).|

## 🔄 Updating the Tools

If you pull updates from this repository to your server:
Bash
```
git pull
sudo ./deploy.sh
```
This will automatically refresh the Python logic and restart the path watcher.
