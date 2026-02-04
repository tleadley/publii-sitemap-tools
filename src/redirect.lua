local uri  = lighty.env["uri.path"]
local path = lighty.env["physical.path"]
local attr = lighty.stat(path)
local uri_lower = uri:lower()
local client_ip = lighty.r.req_attr["request.remote-addr"] or lighty.env["request.remote-ip"] or "?"

if uri_lower:find("%.%./") or uri_lower:find("%%2e%%2e") then
    lighty.header["Location"] = "/"
    print("Traversal attempt blocked: " .. uri .. " from " .. client_ip)
    return 302
end
-- 1. THE AUDIT PRIORITY: Directory Trailing Slash (301)
-- If it's a real folder and missing the slash, we MUST return 301 first.
if (attr and attr["is_dir"] and string.sub(uri, -1) ~= "/") then
    lighty.header["Location"] = uri .. "/"
    return 301
end

-- 2. PRETTY URL LOGIC: Internal Mapping
-- If the file doesn't exist, check for a matching .html file
if (not attr) then
    local clean_path = path
    if string.sub(clean_path, -1) == "/" then clean_path = string.sub(clean_path, 1, -2) end

    if (lighty.stat(clean_path .. ".html")) then
        -- Tell Lighttpd to serve the .html version internally
        lighty.env["physical.path"] = clean_path .. ".html"
        return 0 -- Continue processing without redirecting
    else
        -- 3. THE SECURITY MASK: Redirect missing to root (302)
        lighty.header["Location"] = "/"
        return 302
    end
end
-- 3. EMPTY DIRECTORY LOGIC: Mask if no index (302)
if (attr and attr["is_dir"]) then
    if (not lighty.stat(path .. "/index.html") and not lighty.stat(path .. "/index.php")) then
        lighty.header["Location"] = "/"
        return 302
    end
end
