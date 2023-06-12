---------------------------------------
-- Globals
---------------------------------------
local g_bScenarioDone = false;
local g_iHandicap = Game:GetHandicapType();

local g_kiGameTurnLength = 200;

function GetCivID(civType)
	local civ = GameInfo.Civilizations[civType];
	if(civ) then
		return civ.ID;
	else
		return -1;
	end
end

---------------------------------------
-- UI Handlers
---------------------------------------
ContextPtr:SetUpdate(function()

	if (g_bScenarioDone) then
		ContextPtr:ClearUpdate(); 
		ContextPtr:SetHide( true );
	end

	local iTurnsRemaining = g_kiGameTurnLength - Game.GetGameTurn();
	local turnsRemainingText = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_TURNS_REMAINING", iTurnsRemaining);
	Controls.TurnsRemainingLabel:LocalizeAndSetText(turnsRemainingText);
	Controls.Grid:DoAutoSize();
	
end);

function OnBriefingButton()
	UI.AddPopup( { Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
                   Data1 = 800,
                   Data2 = 1,
                   Option1 = true,
                   Text = "TXT_KEY_SENGOKU_SCENARIO_CIV5_DAWN_TEXT" } );
end
Controls.BriefingButton:RegisterCallback( Mouse.eLClick, OnBriefingButton );

function OnEnterCityScreen()
    ContextPtr:SetHide( true );
end
Events.SerialEventEnterCityScreen.Add( OnEnterCityScreen );

function OnExitCityScreen()

	if (Game:GetGameState() ~= GameplayGameStateTypes.GAMESTATE_EXTENDED) then 
    		ContextPtr:SetHide( false );
	end
end
Events.SerialEventExitCityScreen.Add( OnExitCityScreen );

-- Grant bonuses to AI
function SetAIBonuses()
	print ("TODO: AI Bonuses not set yet!");
end


---------------------------------------
-- Game Event Handlers
---------------------------------------
function TestVictory()
	local iTurnsRemaining = g_kiGameTurnLength - Game.GetGameTurn();
	
	PreGame.SetGameOption("GAMEOPTION_NO_EXTENDED_PLAY", true);	-- No extended play allowed
	
	if (iTurnsRemaining < 1 and not g_bScenarioDone) then
		Game.SetGameState(GameplayGameStateTypes.GAMESTATE_OVER);	
		GameEvents.GameCoreTestVictory.Remove(TestVictory);
		g_bScenarioDone = true;
	end	
end
GameEvents.GameCoreTestVictory.Add(TestVictory);

---------------------------------------------------------------------
-- INITIAL INITIALIZATION
---------------------------------------------------------------------

local savedData = Modding.OpenSaveData();
local iValue = savedData.GetValue("ScenarioInitialized");

if (iValue == nil) then

	print ("In Initial Initialization");
	savedData.SetValue("ScenarioInitialized", 1);
	
	-- Grant AI bonuses
	SetAIBonuses();
	
	-- For final score on victory screen not to be crazy inflated
	Game.SetEstimateEndTurn(200);
	
	-- Game Options (some also set in WorldBuilder)
	Game.SetOption("GAMEOPTION_NO_LEAGUES", true);
	Game.SetOption("GAMEOPTION_NO_ESPIONAGE", true);
	Game.SetOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI", true);
end