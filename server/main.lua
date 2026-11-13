-- Finds resources protected by Cfx.re asset escrow. Clips that reference them
-- cannot be opened in the Rockstar Editor, so players get a list to clean their clips with.

local EVT = 'notbad-rockstar-editor'
local cfg = Config.Escrow or {}
local list = {}
local scanQueued = false

local ignored = {}
for _, name in ipairs(cfg.ignore or {}) do ignored[name] = true end

-- every escrowed resource ships with a .fxap file in its root
local function hasFxap(name)
    local ok, data = pcall(LoadResourceFile, name, '.fxap')
    if ok and data then return true end

    local path = GetResourcePath(name)
    if path and io and io.open then
        local file = io.open(path .. '/.fxap', 'rb')
        if file then
            file:close()
            return true
        end
    end
    return false
end

-- maps and other streamed assets are the usual cause of editor crashes
local function looksLikeAssets(name)
    return GetResourceMetadata(name, 'this_is_a_map', 0) == 'yes'
        or GetNumResourceMetadata(name, 'data_file') > 0
end

local function scan()
    local found = {}
    for i = 0, GetNumResources() - 1 do
        local name = GetResourceByFindIndex(i)
        if name and not ignored[name] and GetResourceState(name) == 'started' and hasFxap(name) then
            found[#found + 1] = { name = name, assets = looksLikeAssets(name) }
        end
    end

    table.sort(found, function(a, b)
        if a.assets ~= b.assets then return a.assets end
        return a.name < b.name
    end)
    return found
end

local function queueScan()
    if scanQueued or cfg.enabled == false then return end
    scanQueued = true
    SetTimeout(3000, function()
        scanQueued = false
        list = scan()
        TriggerClientEvent(EVT .. ':escrow', -1, list)
    end)
end

RegisterNetEvent(EVT .. ':requestEscrow', function()
    TriggerClientEvent(EVT .. ':escrow', source, list)
end)

AddEventHandler('onResourceStart', queueScan)
AddEventHandler('onResourceStop', queueScan)

exports('getEscrowedResources', function() return list end)
