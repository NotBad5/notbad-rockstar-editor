RegisterCommand('recordstart', function()
	StartRecording(1)
end, false)

RegisterCommand('recordstop', function()
	StopRecordingAndSaveClip()
end, false)

RegisterCommand('recorddiscard', function()
	StopRecordingAndDiscardClip()
end, false)

RegisterCommand('rockstareditor', function()
	NetworkSessionLeaveSinglePlayer()
	ActivateRockstarEditor()
end, false)