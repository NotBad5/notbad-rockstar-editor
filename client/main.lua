-- notbad-rockstar-editor
-- Recording, action replay, photos, cinematic mode and a small menu.

local EVT = 'notbad-rockstar-editor'

local mode = nil            -- nil | 'record' | 'replay'
local startedAt = 0
local cinematic = false
local hudHiddenUntil = 0
local photoBusy = false
local menuOpen = false
local nuiReady = false
local editorConfirmUntil = 0
local switching = false     -- true while we change mode ourselves, pauses the sync loop
local escrow = {}            -- protected resources reported by the server
local escrowWarned = false

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function L(key, ...)
    local dict = Locales[Config.Locale] or Locales.en
    local str = dict[key] or Locales.en[key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

local function notify(msg, kind)
    kind = kind or 'info'
    local n = Config.Notify

    if type(n) == 'function' then
        n(msg, kind)
    elseif n == 'ox_lib' and GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ title = L('title'), description = msg, type = kind })
    elseif n == 'chat' then
        TriggerEvent('chat:addMessage', { args = { L('title'), msg } })
    elseif n == 'nui' and nuiReady then
        SendNUIMessage({ action = 'toast', text = msg, kind = kind })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

local function can(action)
    if Config.CanUse and Config.CanUse(action) == false then
        notify(L('not_allowed'), 'error')
        return false
    end
    return true
end

local function waitFor(check, timeout)
    local deadline = GetGameTimer() + timeout
    while GetGameTimer() < deadline do
        if check() then return true end
        Wait(50)
    end
    return check()
end

local function cinematicActive()
    return cinematic or (Config.Cinematic.autoWhileRecording and mode == 'record') or false
end

local function pushState()
    SendNUIMessage({
        action = 'state',
        mode = mode or false,
        elapsed = mode and (GetGameTimer() - startedAt) or 0,
        cinematic = cinematicActive(),
    })
end

local function setMode(new)
    if new == mode then return end
    local old = mode
    mode = new
    startedAt = GetGameTimer()

    if Config.StateBag then
        LocalPlayer.state:set('isRecording', new or false, true)
    end

    TriggerEvent(EVT .. ':modeChanged', new, old)
    pushState()
end

-- Stops whatever is running and waits until the game confirms it.
local function stopCurrent(save)
    if save then
        StopRecordingAndSaveClip()
    else
        StopRecordingAndDiscardClip()
    end
    waitFor(function() return not IsRecording() end, 2000)
    setMode(nil)
end

-- ---------------------------------------------------------------------------
-- Escrow: protected assets make clips crash in the editor
-- ---------------------------------------------------------------------------

local function escrowEnabled()
    return Config.Escrow and Config.Escrow.enabled ~= false
end

local function pushEscrow()
    SendNUIMessage({ action = 'escrow', list = escrowEnabled() and escrow or {} })
end

local function warnEscrow()
    if escrowWarned or not escrowEnabled() or not Config.Escrow.warn or #escrow == 0 then return end
    escrowWarned = true
    notify(L('escrow_warn', #escrow, Config.Commands.escrow or 'recescrow'), 'warning')
end

RegisterNetEvent(EVT .. ':escrow', function(list)
    escrow = type(list) == 'table' and list or {}
    pushEscrow()
end)

CreateThread(function()
    Wait(1500)
    if escrowEnabled() then TriggerServerEvent(EVT .. ':requestEscrow') end
end)

-- ---------------------------------------------------------------------------
-- Recording
-- ---------------------------------------------------------------------------

local function startRecording()
    if not can('record') then return end
    if mode == 'record' then
        notify(L('rec_already'), 'warning')
        return
    end

    switching = true
    if mode == 'replay' then
        stopCurrent(false)
    end

    StartRecording(1)
    if waitFor(IsRecording, 1500) then
        setMode('record')
        notify(L('rec_started'), 'success')
        warnEscrow()
    else
        notify(L('rec_failed'), 'error')
    end
    switching = false
end

local function stopRecording(save)
    if mode ~= 'record' then
        notify(L('rec_not_running'), 'warning')
        return
    end

    switching = true
    stopCurrent(save)
    switching = false
    notify(L(save and 'rec_saved' or 'rec_discarded'), save and 'success' or 'info')
end

local function toggleRecording()
    if mode == 'record' then
        stopRecording(true)
    else
        startRecording()
    end
end

-- ---------------------------------------------------------------------------
-- Action replay
-- ---------------------------------------------------------------------------

local function toggleActionReplay()
    if mode == 'replay' then
        switching = true
        stopCurrent(false)
        switching = false
        notify(L('replay_off'), 'info')
        return
    end

    if not can('replay') then return end
    if mode == 'record' then
        notify(L('rec_already'), 'warning')
        return
    end

    switching = true
    StartRecording(0)
    if waitFor(IsRecording, 1500) then
        setMode('replay')
        notify(L('replay_on'), 'success')
        warnEscrow()
    else
        notify(L('rec_failed'), 'error')
    end
    switching = false
end

local function saveActionReplay()
    if mode ~= 'replay' then
        notify(L('replay_needed'), 'warning')
        return
    end

    local ok = SaveRecordingClip()
    if ok == false or ok == 0 then
        notify(L('replay_failed'), 'error')
    else
        notify(L('replay_saved'), 'success')
    end
end

-- ---------------------------------------------------------------------------
-- Photo
-- ---------------------------------------------------------------------------

local function takePicture()
    if photoBusy or not can('picture') then return end
    photoBusy = true

    CreateThread(function()
        -- keep our own UI and the HUD out of the shot
        SendNUIMessage({ action = 'shot', phase = 'hide' })
        hudHiddenUntil = GetGameTimer() + 8000
        Wait(150)

        local success = false
        local began = BeginTakeHighQualityPhoto()

        if began ~= false and began ~= 0 then
            -- the capture is asynchronous: 1 = still working, 2 = failed
            waitFor(function() return GetStatusOfTakeHighQualityPhoto() ~= 1 end, 5000)

            if GetStatusOfTakeHighQualityPhoto() ~= 2 then
                SaveHighQualityPhoto(-1)
                waitFor(function() return GetStatusOfSaveHighQualityPhoto() ~= 1 end, 5000)
                success = GetStatusOfSaveHighQualityPhoto() ~= 2
            end
        end

        FreeMemoryForHighQualityPhoto()
        hudHiddenUntil = 0

        if success and Config.Photo.sound then
            PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', true)
        end

        SendNUIMessage({ action = 'shot', phase = 'show', flash = success and Config.Photo.flash })
        notify(L(success and 'photo_saved' or 'photo_failed'), success and 'success' or 'error')
        TriggerEvent(EVT .. ':photoTaken', success)
        photoBusy = false
    end)
end

-- ---------------------------------------------------------------------------
-- Cinematic mode
-- ---------------------------------------------------------------------------

local function setCinematic(state, silent)
    state = state and true or false
    if state == cinematic then return end
    if state and not can('cinematic') then return end

    cinematic = state
    pushState()
    TriggerEvent(EVT .. ':cinematic', state)
    if not silent then
        notify(L(state and 'cinematic_on' or 'cinematic_off'), 'info')
    end
end

CreateThread(function()
    while true do
        local hide = GetGameTimer() < hudHiddenUntil
            or (Config.Cinematic.hideHud and cinematicActive())

        if hide then
            HideHudAndRadarThisFrame()
            Wait(0)
        else
            Wait(200)
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Menu
-- ---------------------------------------------------------------------------

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'menu', open = false })
end

local function openMenu(view)
    if menuOpen or not nuiReady or not can('menu') then return end
    menuOpen = true
    pushState()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'menu', open = true, view = view or 'main' })
end

local function showEscrow()
    if #escrow == 0 then
        notify(L('escrow_none'), 'info')
        return
    end

    print(('[%s] %s:'):format(L('title'), L('ui_escrow_list')))
    for _, item in ipairs(escrow) do
        print(('  %s%s'):format(item.name, item.assets and '  (map / assets)' or ''))
    end

    if nuiReady then
        closeMenu()
        openMenu('escrow')
    else
        notify(L('escrow_printed'), 'info')
    end
end

-- ---------------------------------------------------------------------------
-- Rockstar Editor
-- ---------------------------------------------------------------------------

local function openEditor(confirmed)
    if not can('editor') then return end

    -- protected resources on the server: show the list first, the player continues from there
    if not confirmed and escrowEnabled() and Config.Escrow.showBeforeEditor ~= false and #escrow > 0 and nuiReady then
        TriggerServerEvent(EVT .. ':requestEscrow')
        closeMenu()
        openMenu('escrow-editor')
        return
    end

    if Config.Editor.confirm and not confirmed then
        if GetGameTimer() > editorConfirmUntil then
            editorConfirmUntil = GetGameTimer() + (Config.Editor.confirmTimeout * 1000)
            notify(L('editor_confirm', Config.Commands.editor or 'rockstareditor'), 'warning')
            return
        end
    end
    editorConfirmUntil = 0

    CreateThread(function()
        closeMenu()
        setCinematic(false, true)

        -- never lose a running clip
        if mode then
            switching = true
            stopCurrent(mode == 'record')
            switching = false
        end

        ActivateRockstarEditor()

        -- the native leaves the screen faded out when the editor is closed
        Wait(1000)
        while IsPauseMenuActive() do Wait(100) end
        DoScreenFadeIn(500)
    end)
end

-- ---------------------------------------------------------------------------
-- NUI
-- ---------------------------------------------------------------------------

RegisterNUICallback('ready', function(_, cb)
    local strings = {}
    for k, v in pairs(Locales.en) do strings[k] = v end
    for k, v in pairs(Locales[Config.Locale] or {}) do strings[k] = v end

    nuiReady = true
    cb({
        strings = strings,
        commands = Config.Commands,
        indicator = Config.Indicator,
        cinematic = { bars = Config.Cinematic.bars, barHeight = Config.Cinematic.barHeight },
        tools = escrowEnabled() and Config.Escrow.tools or {},
        escrowBeforeEditor = escrowEnabled() and Config.Escrow.showBeforeEditor ~= false,
    })
    pushState()
    pushEscrow()
end)

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({})
end)

RegisterNUICallback('action', function(data, cb)
    cb({})
    local name = data and data.name

    if name == 'toggle' then
        toggleRecording()
    elseif name == 'discard' then
        stopRecording(false)
    elseif name == 'replay' then
        toggleActionReplay()
    elseif name == 'saveReplay' then
        saveActionReplay()
    elseif name == 'cinematic' then
        setCinematic(not cinematic)
    elseif name == 'picture' then
        closeMenu()
        Wait(250)
        takePicture()
    elseif name == 'editor' then
        openEditor(true)
    end
end)

-- ---------------------------------------------------------------------------
-- Commands and key bindings
-- ---------------------------------------------------------------------------

local function register(id, handler, descKey, params)
    local name = Config.Commands[id]
    if not name or name == '' then return end

    RegisterCommand(name, function(_, args)
        handler(args)
    end, false)

    TriggerEvent('chat:addSuggestion', '/' .. name, L(descKey), params or {})

    local key = Config.Keys[id]
    if key ~= nil then
        RegisterKeyMapping(name, ('(%s) %s'):format(L('title'), L(descKey)), 'keyboard', key)
    end
end

register('record', function(args)
    local sub = args[1] and args[1]:lower()
    if sub == 'start' then
        startRecording()
    elseif sub == 'stop' then
        stopRecording(true)
    elseif sub == 'discard' then
        stopRecording(false)
    elseif sub == 'toggle' then
        toggleRecording()
    else
        notify(L('rec_usage', Config.Commands.record), 'info')
    end
end, 'desc_record', { { name = 'type', help = L('desc_record_arg') } })

register('toggle', toggleRecording, 'desc_toggle')
register('replay', toggleActionReplay, 'desc_replay')
register('saveReplay', saveActionReplay, 'desc_save_replay')
register('picture', takePicture, 'desc_picture')
register('cinematic', function() setCinematic(not cinematic) end, 'desc_cinematic')
register('editor', function() openEditor(false) end, 'desc_editor')
register('menu', function()
    if menuOpen then closeMenu() else openMenu() end
end, 'desc_menu')

if escrowEnabled() then
    register('escrow', showEscrow, 'desc_escrow')
end

-- ---------------------------------------------------------------------------
-- Keep our state in sync with the game
-- (recording can also be started with the default GTA keys, or end by itself)
-- ---------------------------------------------------------------------------

CreateThread(function()
    while true do
        Wait(500)
        if not switching then
            local recording = IsRecording()
            if recording and not mode then
                setMode('record')
            elseif not recording and mode then
                setMode(nil)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if menuOpen then SetNuiFocus(false, false) end
    if mode == 'record' and Config.SaveOnResourceStop then
        StopRecordingAndSaveClip()
    end
    if Config.StateBag then
        LocalPlayer.state:set('isRecording', false, true)
    end
end)

-- ---------------------------------------------------------------------------
-- Exports
-- ---------------------------------------------------------------------------

local function async(fn)
    return function(...)
        local args = { ... }
        CreateThread(function() fn(table.unpack(args)) end)
    end
end

exports('isRecording', function() return mode == 'record' end)
exports('getMode', function() return mode end)
exports('isCinematic', function() return cinematicActive() end)

exports('startRecording', async(startRecording))
exports('stopRecording', async(function(save) stopRecording(save ~= false) end))
exports('toggleRecording', async(toggleRecording))
exports('toggleActionReplay', async(toggleActionReplay))
exports('saveActionReplay', async(saveActionReplay))
exports('takePicture', takePicture)
exports('setCinematic', function(state) setCinematic(state, true) end)
exports('openMenu', function() openMenu() end)
exports('getEscrowedResources', function() return escrow end)
exports('closeMenu', closeMenu)
