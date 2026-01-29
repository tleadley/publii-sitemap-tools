import os
import pwd
import grp
from bs4 import BeautifulSoup

# --- CONFIGURATION ---
SITE_DIR = "/var/www/html"
PUBLIC_URL = "https://yourdomain.com"
OUTPUT_FILE = os.path.join(SITE_DIR, "sitemap.xml")
EXCLUDE_FOLDERS = {'assets', 'cgi-bin', 'tmp', '404', 'tags', 'authors'}
# ---------------------

def generate():
    items = []

    for root, dirs, files in os.walk(SITE_DIR):
        # Skip excluded folders
        dirs[:] = [d for d in dirs if d not in EXCLUDE_FOLDERS]
    for file in files:
            if file.endswith(".html"):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, SITE_DIR).replace("\\", "/")

                # Clean URL formatting
                clean_path = rel_path.replace("index.html", "")
                page_url = f"{PUBLIC_URL}/{clean_path}".rstrip("/")
                if not clean_path: page_url = f"{PUBLIC_URL}/"

                images = []
                try:
                    with open(full_path, 'r', encoding='utf-8') as f:
                        soup = BeautifulSoup(f, 'html.parser')
                        for img in soup.find_all('img'):
                            src = img.get('src')
                            if src:
                                img_url = src if src.startswith('http') else f"{PUBLIC_URL}{src if src.startswith('/') else '/' + src}"
                                images.append(img_url)
                except Exception as e:
                    print(f"Error reading {full_path}: {e}")

                items.append({'loc': page_url, 'images': list(set(images))})

             
    # This block must be aligned with the "for root..." loop
    xml = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<?xml-stylesheet type="text/xsl" href="/sitemap.xsl"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">'
    ]

    for item in items:
        xml.append('  <url>')
        xml.append(f'    <loc>{item["loc"]}</loc>')
        for img in item['images']:
            xml.append('    <image:image>')
            xml.append(f'      <image:loc>{img}</image:loc>')
            xml.append('    </image:image>')
        xml.append('  </url>')

    xml.append('</urlset>')

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write('\n'.join(xml))

    # Force ownership of the generated file to www-data
    uid = pwd.getpwnam("www-data").pw_uid
    gid = grp.getgrnam("www-data").gr_gid
    os.chown(OUTPUT_FILE, uid, gid)
    os.chmod(OUTPUT_FILE, 0o644)

 if __name__ == "__main__":
    generate()
    print(f"Sitemap successfully generated at {OUTPUT_FILE}")
