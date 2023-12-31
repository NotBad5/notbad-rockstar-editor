TriggerEvent('chat:addSuggestion', '/record', 'Recording options', {
    { name = "type", help = "start/stop/discard" }
})

TriggerEvent('chat:addSuggestion', '/picture', 'Take a picture')

RegisterCommand('record', function(args)
	local type = args[1]
	if type == 'start' then StartRecording(1)
	if type == 'stop' then StopRecordingAndSaveClip()
	if type == 'discard' then StopRecordingAndDiscardClip()
	else return end
end)

RegisterCommand('picture', function()
	BeginTakeHighQualityPhoto();
	SaveHighQualityPhoto(-1);
	FreeMemoryForHighQualityPhoto();
end)

RegisterKeyMapping('record start', '(Rockstar) Start Recording', 'keyboard', '')
RegisterKeyMapping('record stop', '(Rockstar) Stop Recording', 'keyboard', '')
RegisterKeyMapping('record discard', '(Rockstar) Discard Recording', 'keyboard', '')
RegisterKeyMapping('picture', '(Rockstar) Take a Picture', 'keyboard', '')
