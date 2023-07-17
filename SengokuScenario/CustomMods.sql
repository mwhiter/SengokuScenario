-- Activate the PlayerCanBuild Lua GameEvent.
UPDATE CustomModOptions
	SET Value = 1
	WHERE Name = "EVENTS_PLOT";
