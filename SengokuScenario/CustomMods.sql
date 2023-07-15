-- Activate the PlayerCanBuild Lua GameEvent.
UPDATE CustomModOptions
	SET Value = 1
	WHERE Name = "EVENTS_PLOT";

-- Remap IDs for Improvements, as otherwise I can't modify them in autotuner
CREATE TABLE IDRemapper ( id INTEGER PRIMARY KEY AUTOINCREMENT, Type TEXT );
INSERT INTO IDRemapper (Type) SELECT Type FROM Improvements;
UPDATE Improvements SET ID =    ( SELECT IDRemapper.id-1 FROM IDRemapper WHERE Improvements.Type = IDRemapper.Type);