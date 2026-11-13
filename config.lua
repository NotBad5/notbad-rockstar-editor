Config = {}

-- Language: 'en' or 'cs'. Add your own file in locales/ to translate.
Config.Locale = 'en'

-- Command names. Set one to false to disable that command.
Config.Commands = {
    record     = 'record',          -- /record start | stop | discard | toggle
    toggle     = 'recordtoggle',    -- one command to start / stop & save
    replay     = 'actionreplay',    -- turn the action replay buffer on / off
    saveReplay = 'savereplay',      -- save what just happened (needs action replay on)
    picture    = 'picture',
    cinematic  = 'cinematic',
    editor     = 'rockstareditor',
    menu       = 'recmenu',
    escrow     = 'recescrow',       -- list protected resources that can crash clips in the editor
}

-- Default keys. Players can rebind them in Settings > Key Bindings > FiveM.
-- Leave a key as '' to ship it unbound.
Config.Keys = {
    menu       = 'F10',
    toggle     = '',
    replay     = '',
    saveReplay = '',
    picture    = '',
    cinematic  = '',
}

-- Notifications: 'nui' (built in), 'native' (GTA feed), 'ox_lib', 'chat',
-- or your own function(message, kind) where kind is info/success/warning/error.
Config.Notify = 'nui'

-- On-screen REC / REPLAY badge. It is drawn by the UI, so it never ends up in your clips.
Config.Indicator = {
    enabled   = true,
    position  = 'top-right',        -- top-left | top-right | bottom-left | bottom-right
    showTimer = true,
}

-- Cinematic mode: black bars and a hidden HUD, handy for OBS and screenshots.
Config.Cinematic = {
    bars               = true,
    barHeight          = 11,        -- height of each bar in % of the screen
    hideHud            = true,      -- note: GTA also blocks the weapon wheel while the HUD is hidden
    autoWhileRecording = false,     -- switch it on automatically while recording
}

Config.Photo = {
    flash = true,                   -- white flash when the photo is taken
    sound = true,                   -- camera shutter sound
}

-- Opening the Rockstar Editor disconnects the player from the server.
Config.Editor = {
    confirm        = true,          -- ask the player to confirm first
    confirmTimeout = 10,            -- seconds to repeat the command
}

-- Clips recorded near escrow-protected assets (mostly paid maps and MLOs) often crash the
-- Rockstar Editor. That is a FiveM limitation and cannot be fixed by a script, but clips can
-- be cleaned with an external tool. This finds the protected resources on your server so
-- players know what to put on the tool's block list.
Config.Escrow = {
    enabled = true,
    warn    = true,                 -- warn the player once per session when they start recording
    showBeforeEditor = true,        -- show the list when the player opens the Rockstar Editor
    ignore  = {},                   -- resource names to leave out of the list
    tools   = {
        { name = 'clip2load', url = 'https://forum.cfx.re/t/release-clip2load-making-rockstar-editor-clips-editable-even-with-escrowed-assets/5368041' },
        { name = 'FiveM Clip Patcher', url = 'https://github.com/WaydeTheKiwi/FiveM_Clip_Patcher' },
    },
}

-- Publishes LocalPlayer.state.isRecording ('record', 'replay' or false),
-- readable on the server as Player(source).state.isRecording.
Config.StateBag = true

-- Save the running clip if the resource is stopped or restarted.
Config.SaveOnResourceStop = true

-- Return false to block an action, for example while dead or cuffed.
-- action: 'record' | 'replay' | 'picture' | 'cinematic' | 'editor' | 'menu'
Config.CanUse = function(action)
    return true
end
