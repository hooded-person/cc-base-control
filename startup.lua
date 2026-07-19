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

-- UTIL FUNCTIONS
local function downloadFile(url)
    local res, err, fail_res = http.get(url)
    if not res then
        local fail_body = fail_res and fail_res.readAll() or ""
        return false, err .. ": " .. fail_body
    end
    local body = res.readAll()
    return true, body
end

local function fnv1a(str)
    local hash = 2166136261

    for i = 1, #str do
        hash = bit32.bxor(hash, str:byte(i))
        hash = (hash * 16777619) % 2^32
    end

    return string.format("%08x", hash)
end
-- END UTIL FUNCTIONS
-- SET SHELL THINGS OR SMTH

local path = shell.path()
path = path .. ":" .. "/bin"
shell.setPath(path)

local completion = require"cc.shell.completion"
local fnv1a_complete = completion.build{
    { completion.file, many = true }
}
shell.setCompletionFunction("bin/fnv1a.lua", fnv1a_complete)

-- END SET SHELL THINGS OR SMTH
-- DOWNLOAD FILES FROM UPSTREAM

print("Downloading from upstream:")
print(upstream_url)

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

local function install_file(file)
    -- check if locally modified
    if fs.exists(file..".hash") then
        local h = fs.open(file..".hash", "r")
        local hash = h.readAll()
        h.close()
        local h = fs.open(file, "r")
        local local_contents = h.readAll()
        h.close()
        local local_hash = fnv1a(local_contents)
        if hash ~= local_hash then
            return false, "Local contents changed (hashes dont match)"
        end
    end
    -- download file
    local url = upstream_url .. file
    local ok, contents = downloadFile(url)
    if not ok then
        return false, "Download failed"
    end
    local h = fs.open(file, "w")
    h.write(contents)
    h.close()
    -- make .hash file
    local hash = fnv1a(contents)
    local h = fs.open(file..".hash", "w")
    h.write(hash)
    h.close()

    return true
end

for file in file_list:gmatch("[^\n]+") do
    local ok, err = install_file(file)
    if not ok then
        print(file .. ": " ..err)
    end
end