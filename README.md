# notbad-rockstar-editor

Record clips, keep an action replay buffer, take photos and open the Rockstar Editor, from commands, key binds or a small menu. Standalone, no dependencies.

## Features
- **One-key recording**: start, stop and save, or discard a clip
- **Action replay**: keep a rolling buffer and save the last moments after something happens
- **Photos**: waits for the capture to finish before saving, with shutter sound and flash
- **REC / REPLAY badge** with a timer (drawn by the UI, so it is never in your clips)
- **Cinematic mode**: black bars and a hidden HUD for OBS and screenshots
- **Menu** with every action (default key `F10`)
- **Safe editor launch**: asks for confirmation and saves a running clip first
- **Escrow crash helper**: lists the protected resources on your server and warns players before their clips crash the editor (see below)
- English and Czech included, easy to translate
- Notifications through the built-in UI, GTA feed, ox_lib, chat or your own function
- Exports, events and a state bag for other resources

## Install
1. Put the `notbad-rockstar-editor` folder in your `resources` directory.
2. Add `ensure notbad-rockstar-editor` to `server.cfg`.
3. Adjust `config.lua` if you want.

## Commands
| Command | What it does |
|---|---|
| `/recmenu` | Open the menu |
| `/recordtoggle` | Start recording, or stop and save |
| `/record start \| stop \| discard \| toggle` | Same as before, kept for compatibility |
| `/actionreplay` | Turn the action replay buffer on or off |
| `/savereplay` | Save the action replay |
| `/picture` | Take a picture |
| `/cinematic` | Toggle cinematic mode |
| `/rockstareditor` | Open the Rockstar Editor (type twice to confirm) |
| `/recescrow` | Show protected resources that can crash clips |

All names can be changed or disabled in `config.lua`. Every command except `/record` and `/rockstareditor` can be bound in **Settings > Key Bindings > FiveM**.

## Clips that crash the editor (escrow)
The Rockstar Editor cannot load assets protected by Cfx.re asset escrow, mostly paid maps and MLOs. Clips recorded near them crash or hang when opened. This is a FiveM limitation and **no script can fix it**. What this resource does instead:

- The server finds every started resource that is escrow protected (it looks for the `.fxap` file) and marks the ones that are maps or streamed assets.
- Players are warned once per session when they start recording.
- Opening the Rockstar Editor (menu or `/rockstareditor`) shows the list first, with a button to continue to the editor.
- `/recescrow` (or the menu) shows the list with a copy button, plus links to tools that clean clips:
  [clip2load](https://forum.cfx.re/t/release-clip2load-making-rockstar-editor-clips-editable-even-with-escrowed-assets/5368041) and
  [FiveM Clip Patcher](https://github.com/WaydeTheKiwi/FiveM_Clip_Patcher). Players paste the list into the tool's block list instead of guessing.

Not every listed resource causes crashes, and not every crash comes from escrow. The marked maps and assets are the ones to block first. Turn the whole feature off with `Config.Escrow.enabled = false`.

## For developers
```lua
-- exports (client)
exports['notbad-rockstar-editor']:isRecording()        -- true while recording a clip
exports['notbad-rockstar-editor']:getMode()            -- 'record', 'replay' or nil
exports['notbad-rockstar-editor']:isCinematic()
exports['notbad-rockstar-editor']:startRecording()
exports['notbad-rockstar-editor']:stopRecording(save)  -- save defaults to true
exports['notbad-rockstar-editor']:toggleRecording()
exports['notbad-rockstar-editor']:toggleActionReplay()
exports['notbad-rockstar-editor']:saveActionReplay()
exports['notbad-rockstar-editor']:takePicture()
exports['notbad-rockstar-editor']:setCinematic(true)
exports['notbad-rockstar-editor']:openMenu()

-- events (client)
AddEventHandler('notbad-rockstar-editor:modeChanged', function(mode, previous) end)
AddEventHandler('notbad-rockstar-editor:cinematic', function(enabled) end)
AddEventHandler('notbad-rockstar-editor:photoTaken', function(success) end)

-- escrow list (client and server export): { { name = 'resource', assets = true }, ... }
exports['notbad-rockstar-editor']:getEscrowedResources()

-- state bag (server or client)
Player(source).state.isRecording  -- 'record', 'replay' or false
```

Use `Config.CanUse` to block actions, for example while the player is dead or cuffed.

## Upgrading from 1.0
The old key binds `record start`, `record stop` and `record discard` are replaced by one toggle bind. Players need to bind the new actions once.

## Good to know
- Opening the Rockstar Editor disconnects you from the server. That is how FiveM works.
- While the HUD is hidden in cinematic mode, GTA also blocks the weapon wheel. Set `Config.Cinematic.hideHud = false` if that bothers you.
