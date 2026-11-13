Locales = Locales or {}

Locales.en = {
    title              = 'Rockstar Editor',

    rec_started        = 'Recording started.',
    rec_saved          = 'Clip saved.',
    rec_discarded      = 'Clip discarded.',
    rec_already        = 'You are already recording.',
    rec_not_running    = 'Nothing is being recorded.',
    rec_failed         = 'Recording could not start. Check your free clip storage.',
    rec_usage          = 'Usage: /%s start | stop | discard | toggle',

    replay_on          = 'Action replay is on. Save the last moments any time.',
    replay_off         = 'Action replay is off.',
    replay_saved       = 'Action replay saved.',
    replay_failed      = 'Action replay could not be saved.',
    replay_needed      = 'Turn action replay on first.',

    photo_saved        = 'Photo saved.',
    photo_failed       = 'Photo could not be saved.',

    cinematic_on       = 'Cinematic mode on.',
    cinematic_off      = 'Cinematic mode off.',

    editor_confirm     = 'The editor disconnects you from the server. Type /%s again to confirm.',
    not_allowed        = 'You cannot do that right now.',

    -- command / key binding descriptions
    desc_record        = 'Recording options',
    desc_record_arg    = 'start / stop / discard / toggle',
    desc_toggle        = 'Start or stop recording',
    desc_replay        = 'Toggle action replay',
    desc_save_replay   = 'Save action replay',
    desc_picture       = 'Take a picture',
    desc_cinematic     = 'Toggle cinematic mode',
    desc_editor        = 'Open Rockstar Editor',
    desc_menu          = 'Open the recording menu',

    -- UI
    ui_rec             = 'REC',
    ui_replay          = 'REPLAY',
    ui_record_start    = 'Start recording',
    ui_record_stop     = 'Stop and save',
    ui_discard         = 'Discard clip',
    ui_replay_on       = 'Action replay',
    ui_replay_off      = 'Action replay: on',
    ui_save_replay     = 'Save replay',
    ui_picture         = 'Take a picture',
    ui_cinematic       = 'Cinematic mode',
    ui_editor          = 'Open Rockstar Editor',
    ui_editor_confirm  = 'Click again: you will leave the server',
    ui_close           = 'Close',
    ui_hint            = 'ESC to close',

    escrow_warn        = 'This server runs %d protected resources. Clips can crash the editor until you clean them. See /%s',
    escrow_none        = 'No protected resources found on this server.',
    escrow_printed     = 'List printed to the F8 console.',
    desc_escrow        = 'Show protected resources that can crash clips',
    ui_escrow_row      = 'Clip crashes in the editor?',
    ui_escrow_title    = 'Clips that crash the editor',
    ui_escrow_text     = 'The editor cannot load protected (escrow) assets, so clips recorded near them crash. Clean the clip with one of these tools before you open it, and block the resources listed here.',
    ui_escrow_list     = 'Protected resources on this server',
    ui_escrow_legend   = 'Marked ones are maps or streamed assets. Block those first.',
    ui_escrow_copy     = 'Copy the list',
    ui_escrow_copied   = 'Copied.',
    ui_link_copied     = 'Link copied. Paste it into your browser.',
    ui_open            = 'Copy link',
    ui_back            = 'Back',
    ui_escrow_proceed  = 'Open the editor (leaves the server)',
}
