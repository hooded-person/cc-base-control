local function fnv1a(str)
    local hash = 2166136261

    for i = 1, #str do
        hash = bit32.bxor(hash, str:byte(i))
        hash = (hash * 16777619) % 2^32
    end

    return string.format("%08x", hash)
end

local args = {...}

local hashes = {}
for i, file in ipairs(args) do 

    local h = fs.open(file, "r")
    if not h then
        print("'"..file.."' does not exist")
    else
        local contents = h.readAll()
        h.close()

        local hash = fnv1a(contents)

        hashes[i] = {file, hash}
    end
end

textutils.tabulate(table.unpack(hashes))