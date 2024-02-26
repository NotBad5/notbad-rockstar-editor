TriggerEvent('chat:addSuggestion', '/record', 'Recording options', {
    { name = "type", help = "start/stop/discard" }
})

TriggerEvent('chat:addSuggestion', '/picture', 'Take a picture')
TriggerEvent('chat:addSuggestion', '/rockstareditor', 'Opens rockstar editor')

RegisterCommand('record', function(args)
	local type = args[1]
	if not type then return StartRecording(1) end
	if type == 'start' then return StartRecording(1)
	elseif type == 'stop' then return StopRecordingAndSaveClip()
	elseif type == 'discard' then return StopRecordingAndDiscardClip() end
end, false)

RegisterCommand('rockstareditor', function()
	ActivateRockstarEditor()
end, false)

RegisterCommand('picture', function()
	BeginTakeHighQualityPhoto()
	SaveHighQualityPhoto(-1)
	FreeMemoryForHighQualityPhoto()
end, false)

RegisterKeyMapping('record start', '(Rockstar editor) Start Recording', 'keyboard', '')
RegisterKeyMapping('record stop', '(Rockstar editor) Stop Recording', 'keyboard', '')
RegisterKeyMapping('record discard', '(Rockstar editor) Discard Recording', 'keyboard', '')
RegisterKeyMapping('picture', '(Rockstar editor) Take a Picture', 'keyboard', '')
