<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
                xmlns:html="http://www.w3.org/TR/REC-html40"
                xmlns:sitemap="http://www.sitemaps.org/schemas/sitemap/0.9"
                xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:template match="/">
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title>XML Sitemap - Professional Index</title>
                <style type="text/css">
                    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif; color: #333; margin: 0; padding: 40px; background: #f9f9fb; }
                    .container { max-width: 1000px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
                    h1 { color: #1a1a1a; font-size: 24px; margin-bottom: 10px; border-bottom: 2px solid #3498db; display: inline-block; padding-bottom: 5px; }
                    p { color: #666; margin-bottom: 30px; }
                    table { border-collapse: collapse; width: 100%; margin-top: 10px; }
                    th { background: #f8f9fa; text-align: left; padding: 12px 15px; border-bottom: 2px solid #edf2f7; font-weight: 600; color: #4a5568; }
                    td { padding: 12px 15px; border-bottom: 1px solid #edf2f7; word-break: break-all; }
                    tr:hover { background: #f7fafc; }
                    a { color: #3498db; text-decoration: none; }
                    a:hover { text-decoration: underline; }
                    .count-badge { background: #ebf8ff; color: #2b6cb0; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 600; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>XML Sitemap</h1>
                    <p>Generated for Google/Bing SEO. Total URLs indexed: <strong><xsl:value-of select="count(sitemap:urlset/sitemap:url)"/></strong></p>
                    <table>
                        <thead>
                            <tr>
                                <th width="75%">URL Location</th>
                                <th width="25%">Images Detected</th>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:for-each select="sitemap:urlset/sitemap:url">
                                <tr>
                                    <td>
                                        <a href="{sitemap:loc}"><xsl:value-of select="sitemap:loc"/></a>
                                    </td>
                                    <td>
                                        <span class="count-badge">
                                            <xsl:value-of select="count(image:image)"/> Images
                                        </span>
                                    </td>
                                </tr>
                            </xsl:for-each>
                        </tbody>
                    </table>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
