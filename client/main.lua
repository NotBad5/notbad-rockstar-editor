TriggerEvent('chat:addSuggestion', '/record', 'Recording options', {
    { name = "type", help = "start/stop/discard" }
})

TriggerEvent('chat:addSuggestion', '/picture', 'Take a picture')
TriggerEvent('chat:addSuggestion', '/rockstareditor', 'Opens rockstar editor')

RegisterCommand('record', function(source, args, rawCommand)
	local type = args[1]
	if type == 'start' then StartRecording(1) end
	if type == 'stop' then StopRecordingAndSaveClip() end
	if type == 'discard' then StopRecordingAndDiscardClip() end
end)

RegisterCommand('rockstareditor', function()
	ActivateRockstarEditor()
end)

RegisterCommand('picture', function()
	BeginTakeHighQualityPhoto()
	SaveHighQualityPhoto(-1)
	FreeMemoryForHighQualityPhoto()
end)

RegisterKeyMapping('record start', '(Rockstar editor) Start Recording', 'keyboard', '')
RegisterKeyMapping('record stop', '(Rockstar editor) Stop Recording', 'keyboard', '')
RegisterKeyMapping('record discard', '(Rockstar editor) Discard Recording', 'keyboard', '')
RegisterKeyMapping('picture', '(Rockstar editor) Take a Picture', 'keyboard', '')
