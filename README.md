Publii Sitemap & Image SEO Automator (Native Python)

A secure, lightweight post-processing solution for Publii sites hosted on Debian/lighttpd.

This project solves the "Relative URL" conflict in Publii: it allows you to maintain relative URLs for internal networking (Split DNS) while automatically generating a professional, absolute-URL sitemap.xml with full Google Image SEO support.
✨ Features

    Zero Dependencies (Almost): No Node.js or npm required. Uses native Python 3 and BeautifulSoup4.

    Absolute URL Mapping: Automatically prepends your public domain to relative paths.

    Full Image SEO: Maps every <image:image> location, not just a count.

    Professional Styling: Includes an XSLT stylesheet to make sitemaps human-readable.

    Linux Native Automation: Uses Systemd Path Units to trigger updates the millisecond you sync from Publii.

    Permission Auto-Fix: Automatically handles "root-owned" file issues by resetting ownership to www-data.

🚀 Installation
1. Prerequisites

Install the Python HTML parser on your Debian server:
Bash

sudo apt update && sudo apt install python3-bs4

2. Deployment

    Script: Copy generate_sitemap.py to /usr/local/bin/ and update your PUBLIC_URL.

    Styles: Drop sitemap.xsl into your web root (e.g., /var/www/html/).

    Automation: Copy the .service and .path files to /etc/systemd/system/.

3. Activation
Bash

sudo systemctl daemon-reload
sudo systemctl enable --now sitemap-gen.path

📂 Project Structure

    generate_sitemap.py: The Python 3 engine.

    sitemap.xsl: The visual stylesheet for the browser.

    sitemap-gen.service: Systemd task runner (handles permissions + execution).

    sitemap-gen.path: Systemd directory monitor.

🛠 Configuration

Inside generate_sitemap.py, you can customize:

    SITE_DIR: Path to your web files.

    PUBLIC_URL: Your live domain (FQDN).

    EXCLUDE_FOLDERS: A list of folders (e.g., tags, assets) to ignore.

🔒 Security

By avoiding npm, this workflow eliminates supply-chain vulnerabilities. The automation runs as root only for the duration of the permission reset and sitemap generation, ensuring the web root stays owned by www-data for safe serving by lighttpd.
📄 License

Public Domain / CC0 (Copyleft). Feel free to use, modify, and share.
