---------------------------------------
-- Globals
---------------------------------------
local g_bScenarioDone = false;
local g_iHandicap = Game:GetHandicapType();

local g_kiGameTurnLength = 200;

function AddUnitToPlot(player, unitType, plotX, plotY, unitAi)
	iUnitID = GameInfoTypes[unitType];
	unit = player:InitUnit(iUnitID, plotX, plotY, unitAi, DirectionTypes.DIRECTION_EAST);
	unit:JumpToNearestValidPlot();
end

function GetCivID(civType)
	local civ = GameInfo.Civilizations[civType];
	if(civ) then
		return civ.ID;
	else
		return -1;
	end
end

function GetPlayer(civType)
	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		player = Players[iPlayerLoop];
		local playerCiv = player:GetCivilizationType();
		if (playerCiv == GetCivID(civType)) then
			return Players[iPlayerLoop]
		end
	end

	println("Player " .. civType .. " was not found");

	return nil
end

local tokugawaPlayer = GetPlayer("CIVILIZATION_TOKUGAWA");
local tokugawaTeam = Teams[tokugawaPlayer:GetTeam()];
local imagawaPlayer = GetPlayer("CIVILIZATION_IMAGAWA");
local imagawaTeam = Teams[imagawaPlayer:GetTeam()];

local civPolicyBranches =
{
	["CIVILIZATION_CHOSOKABE"] = "POLICY_BRANCH_TRADITION",
	["CIVILIZATION_DATE"] = "POLICY_BRANCH_TRADITION",
	["CIVILIZATION_HOJO"] = "POLICY_BRANCH_TRADITION",
	["CIVILIZATION_IKKO_IKKI"] = "POLICY_BRANCH_UPRISING",
	["CIVILIZATION_MORI"] = "POLICY_BRANCH_TRADITION",
	["CIVILIZATION_JAPAN"] = "POLICY_BRANCH_TRADITION",
	["CIVILIZATION_OTOMO"] = "POLICY_BRANCH_DEVOTION",
	["CIVILIZATION_SHIMAZU"] = "POLICY_BRANCH_TRADITION",
	["CIVILIZATION_TAKEDA"] = "POLICY_BRANCH_TRADITION",
	["CIVILIZATION_TOKUGAWA"] = "POLICY_BRANCH_TRADITION",
	["CIVILIZATION_UESUGI"] = "POLICY_BRANCH_TRADITION"
}

---------------------------------------------------------------------
function CanAdoptPolicyBranch (iPlayerID, iPolicyBranch)
	local player = Players[iPlayerID];
	local civ = GameInfo.Civilizations[player:GetCivilizationType()]
	local policyBranchType = GameInfo.PolicyBranchTypes[iPolicyBranch].Type
	if (policyBranchType == "POLICY_BRANCH_ORGANIZATION" or
		policyBranchType == "POLICY_BRANCH_BUSHIDO" or
		policyBranchType == "POLICY_BRANCH_DIPLOMACY") then
		return true
	else
		return policyBranchType == civPolicyBranches[civ.Type]
	end
end
GameEvents.PlayerCanAdoptPolicyBranch.Add(CanAdoptPolicyBranch);

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

function InitPlayers()
	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		AddInitialUnits(iPlayerLoop);
	end
end

function AddInitialUnits(playerIndex)
	local player = Players[playerIndex];
	if (not player:IsAlive()) then
		return
	end

	local capital = player:GetCapitalCity();
	if (capital == nil) then
		return
	end

	AddUnitToPlot(player, "UNIT_WORKER", capital:GetX(), capital:GetY(), UNITAI_WORKER);
	AddUnitToPlot(player, "UNIT_YARI_ASHIGARU", capital:GetX(), capital:GetY(), UNITAI_DEFENSE);
end

-- Grant bonuses to AI
function SetAIBonuses()
	print ("TODO: AI Bonuses not set yet!");
end

function MakeTokugawaVassalOfImagawa()
	local imagawaTeamId = imagawaTeam:GetID();
	tokugawaTeam:Meet(imagawaTeamId);
	tokugawaTeam:DoBecomeVassal(imagawaTeamId, true);
end

local savedData = Modding.OpenSaveData();
local iValue = savedData.GetValue("ScenarioInitialized");

if (iValue == nil) then

	print ("In Initial Initialization");
	savedData.SetValue("ScenarioInitialized", 1);

	-- Game Options (some also set in WorldBuilder)
	Game.SetOption("GAMEOPTION_NO_BARBARIANS", true);
	Game.SetOption("GAMEOPTION_EVENTS", false);
	Game.SetOption("GAMEOPTION_NO_LEAGUES", true);
	Game.SetOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI", true);
	Game.SetOption("GAMEOPTION_HUMAN_VASSALS", true);
	
	InitPlayers();
	MakeTokugawaVassalOfImagawa();

	-- Grant AI bonuses
	SetAIBonuses();
	
	-- For final score on victory screen not to be crazy inflated
	Game.SetEstimateEndTurn(200);
end