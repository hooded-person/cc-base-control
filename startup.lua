local upstream = "https://github.com/hooded-person/cc-base-control"
local branch = "main"
local instance = "basics"

local upstream_url_template = "https://raw.githubusercontent.com/<GITHUB_REPO>/refs/heads/<BRANCH>/"
local upstream_url = upstream_url_template:gsub(
    "<([^>]+)>",
    {
        GITHUB_REPO = upstream:match("[^/]+/[^/]+$"),
        BRANCH = branch,
    }
)
local upstream_config_url = upstream_url .. "instance/" .. instance .. "/"

function downloadFile(url)
    local res, err, fail_res = http.get(url)
    if not res then
        local fail_body = fail_res and fail_res.readAll() or ""
        return false, err .. ": " .. fail_body
    end
    local body = res.readAll()
    return true, body
end

local config_files = {"config.lon","peripherals.lon","programs.lon"}
local downloaded = {}
local all_downloaded = true
for _, file_name in ipairs(config_files) do
    local url = upstream_config_url .. file_name
    local ok, contents = downloadFile(url)
    if ok then
        downloaded[file_name] = contents
    else
        print(contents)
    end
    local all_downloaded = all_downloaded and ok
end
if fs.exists("inst") and not all_downloaded then
    print("Not all config files could be downloaded from upstream, continueing with local files")
    -- check partial update allowed
else -- folder inst/ does not exist or all files have been successfully downloaded
    fs.delete("inst")
    for file_name, contents in pairs(downloaded) do
        local h = fs.open("inst/"..file_name,"w")
        h.write(contents)
        h.close()
    end
end

local ok, file_list = downloadFile(upstream_url .. "installation.txt")
if not ok then error("ahh") end -- TODO: handle this normally
for file in file_list:gmatch("[^\n]+") do
    local url = upstream_url .. file
    local ok, contents = downloadFile(url)
    if not ok then
        print(("'%s' could not be downloaded"):format(file))
    else
        local h = fs.open(file, "w")
        h.write(contents)
        h.close()
    end
end