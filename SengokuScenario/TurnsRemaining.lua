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
	["CIVILIZATION_UESUGI"] = "POLICY_BRANCH_TRADITION",
	["CIVILIZATION_IMAGAWA"] = "POLICY_BRANCH_TRADITION"
}

local civReligions =
{
	["CIVILIZATION_CHOSOKABE"] = GameInfoTypes["RELIGION_SHINTO"],
	["CIVILIZATION_DATE"] = GameInfoTypes["RELIGION_SHINTO"],
	["CIVILIZATION_HOJO"] = GameInfoTypes["RELIGION_SHINTO"],
	["CIVILIZATION_IKKO_IKKI"] = GameInfoTypes["RELIGION_JODO_SHINSHU"],
	["CIVILIZATION_MORI"] = GameInfoTypes["RELIGION_SHINTO"],
	["CIVILIZATION_JAPAN"] = GameInfoTypes["RELIGION_SHINTO"],
	["CIVILIZATION_OTOMO"] = GameInfoTypes["RELIGION_CHRISTIANITY"],
	["CIVILIZATION_SHIMAZU"] = GameInfoTypes["RELIGION_SHINTO"],
	["CIVILIZATION_TAKEDA"] = GameInfoTypes["RELIGION_SHINTO"],
	["CIVILIZATION_TOKUGAWA"] = GameInfoTypes["RELIGION_SHINTO"],
	["CIVILIZATION_UESUGI"] = GameInfoTypes["RELIGION_SHINTO"],
	["CIVILIZATION_IMAGAWA"] = GameInfoTypes["RELIGION_SHINTO"]
}

---------------------------------------------------------------------
function CanAdoptPolicyBranch (playerId, policyBranchId)
	local player = Players[playerId];
	local civ = GameInfo.Civilizations[player:GetCivilizationType()]
	local policyBranchType = GameInfo.PolicyBranchTypes[policyBranchId].Type
	if (policyBranchType == "POLICY_BRANCH_ORGANIZATION" or
		policyBranchType == "POLICY_BRANCH_BUSHIDO" or
		policyBranchType == "POLICY_BRANCH_DIPLOMACY") then
		return true
	else
		return policyBranchType == civPolicyBranches[civ.Type]
	end
end
GameEvents.PlayerCanAdoptPolicyBranch.Add(CanAdoptPolicyBranch);

-- This is needed because all civs adopt Uprising branches as Ikko Ikki unlocks them
function CanAdoptPolicy(playerId, policyId)
	local policy = GameInfo.Policies[policyId];
	local policyBranchType = policy.PolicyBranchType;

	if (policyBranchType == "POLICY_BRANCH_UPRISING") then
		local player = Players[playerId];
		local civ = GameInfo.Civilizations[player:GetCivilizationType()]
		if (civPolicyBranches[civ.Type] ~= "POLICY_BRANCH_UPRISING") then
			return false
		end
	end

	return true
end
GameEvents.PlayerCanAdoptPolicy.Add(CanAdoptPolicy);

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
-- Ikko Ikki Religion
---------------------------------------
local ikkoIkkiBuildings = 
{
	GameInfo.Buildings["BUILDING_REBELLION_WEAK"].ID,
	GameInfo.Buildings["BUILDING_REBELLION_MODERATE"].ID,
	GameInfo.Buildings["BUILDING_REBELLION_STRONG"].ID
}

function MakeIkkoIkkiBuildingsUnbuildable(playerId, cityId, buildingType)
	for i,e in ipairs(ikkoIkkiBuildings) do
		if (e == buildingType) then
			return false;
		end
	end
	
	return true;
end

function GetJodoShinshuBuilding(city)
	for i,e in ipairs(ikkoIkkiBuildings) do
		if (city:GetNumRealBuilding(e) > 0) then
			return e;
		end
	end

	return nil
end

function ClearJodoShinshuBuildings(city)
	for i,e in ipairs(ikkoIkkiBuildings) do
		city:SetNumRealBuilding(e, 0);
	end
end

function UpdateIkkoIkkiRebellions(playerId)
	local isJodoShinshuFounder = Game.GetFounder(GameInfoTypes["RELIGION_JODO_SHINSHU"], -1) == playerId;
	if (isJodoShinshuFounder) then
		return;
	end

	local player = Players[playerId]
	for city in player:Cities() do
		local oldBuilding = GetJodoShinshuBuilding(city);
		
		ClearJodoShinshuBuildings(city);

		local numJodoShinshuFollowers = city:GetNumFollowers(GameInfoTypes["RELIGION_JODO_SHINSHU"]);
		local population = city:GetPopulation();

		if (population > 0) then
			local newBuilding = nil;
			if (numJodoShinshuFollowers == population) then
				newBuilding = GameInfo.Buildings["BUILDING_REBELLION_STRONG"].ID;
			else
				local percent = numJodoShinshuFollowers * 100 / population;
				if (percent >= 66) then
					newBuilding = GameInfo.Buildings["BUILDING_REBELLION_MODERATE"].ID;
				elseif (percent >= 33) then
					newBuilding = GameInfo.Buildings["BUILDING_REBELLION_WEAK"].ID;
				end
			end

			-- Need to add a building
			if (newBuilding ~= nil) then
				city:SetNumRealBuilding(newBuilding, 1);
			end

			-- If there's been a change, push a notification
			if (newBuilding ~= oldBuilding) then
				local strMessage = "";
				local summaryMessage = "";
				-- Rebellion started
				if (oldBuilding == nil) then
					strMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_STARTED", city:GetName());
					summaryMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_STARTED_SUMMARY", city:GetName());
				-- Rebellion ended
				elseif (newBuilding == nil) then
					strMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_ENDED", city:GetName());
					summaryMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_ENDED_SUMMARY", city:GetName());
				-- Status changed
				else
					if (newBuilding == GameInfo.Buildings["BUILDING_REBELLION_STRONG"].ID) then
						strMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_STRONGER", city:GetName());
						summaryMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_STRONGER_SUMMARY", city:GetName());
					elseif (newBuilding == GameInfo.Buildings["BUILDING_REBELLION_WEAK"].ID) then
						strMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_WEAKER", city:GetName());
						summaryMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_WEAKER_SUMMARY", city:GetName());
					else
						if (oldBuilding == GameInfo.Buildings["BUILDING_REBELLION_WEAK"].ID) then
							strMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_STRONGER", city:GetName());
							summaryMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_STRONGER_SUMMARY", city:GetName());
						else
							strMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_WEAKER", city:GetName());
							summaryMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_REBELLION_WEAKER_SUMMARY", city:GetName());
						end
					end
				end
				player:AddNotification(GameInfoTypes["NOTIFICATION_GENERIC"], strMessage, summaryMessage, city:GetX(), city:GetY(), city:GetOwner());
			end
		end
	end
end

local uprisingPolicies = {
	GameInfo.Policies["POLICY_UPRISING"].ID,
	GameInfo.Policies["POLICY_PEASANT_RULE"].ID,
	GameInfo.Policies["POLICY_POPULISM"].ID,
	GameInfo.Policies["POLICY_RELIGIOUS_FERVOR"].ID,
	GameInfo.Policies["POLICY_REVOLUTION"].ID,
	GameInfo.Policies["POLICY_SECRET_SOCIETY"].ID,
	GameInfo.Policies["POLICY_UPRISING_FINISHER"].ID,
}

function GiveUprisingPoliciesToPlayers(playerId, policyId)
	for i,e in ipairs(uprisingPolicies) do
		if (e == policyId) then
			-- award other players policy
			for playerIndex = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
				local player = Players[playerIndex];
				if (player:IsAlive() and player:GetID() ~= playerId) then
					player:GrantPolicy(policyId, true);

					local policyName = Locale.ConvertTextKey(GameInfo.Policies[policyId].Description);
					local policyHelp = Locale.ConvertTextKey(GameInfo.Policies[policyId].Help);
					local strMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_UPRISING_POLICY_ADOPTED", policyName, policyHelp);
					local summaryMessage = Locale.ConvertTextKey("TXT_KEY_SENGOKU_SCENARIO_CITY_UPRISING_POLICY_ADOPTED_SUMMARY");

					player:AddNotification(GameInfoTypes["NOTIFICATION_GENERIC"], strMessage, summaryMessage, -1, -1, -1);
				end
			end
		end
	end
end

function ConvertCityToJodoShinshu(oldOwner, isCapital, x, y, newOwner, pop, isConquest)
	local player = Players[newOwner];
	local playerType = player:GetCivilizationType();
	if (playerType == GameInfo.Civilizations["CIVILIZATION_IKKO_IKKI"].ID) then
		local plot = Map.GetPlot(x,y);
		local city = plot:GetPlotCity();
		city:AdoptReligionFully(GameInfoTypes["RELIGION_JODO_SHINSHU_BUDDHISM"]);
	end
end

GameEvents.CityCanConstruct.Add(MakeIkkoIkkiBuildingsUnbuildable);
GameEvents.PlayerDoTurn.Add(UpdateIkkoIkkiRebellions);
GameEvents.PlayerAdoptPolicy.Add(GiveUprisingPoliciesToPlayers);
GameEvents.CityCaptureComplete.Add(ConvertCityToJodoShinshu);
---------------------------------------
-- Game Event Handlers
---------------------------------------
-- iPlayer, iUnit, iX, iY, iBuild
function canBuildTerraceFarmsAfterPolicy(iPlayer, iUnit, iX, iY, iBuild)
	local player = Players[iPlayer];
	local build = GameInfo.Builds[iBuild].Type;

	print("Hi: " .. build);

	if (build ~= GameInfo.Builds["BUILD_TERRACE_FARM"].Type) then
		return true;
	end

	return player:HasPolicy(GameInfo.Policies["POLICY_EQUAL_FIELDS"].ID);
end
GameEvents.PlayerCanBuild.Add(canBuildTerraceFarmsAfterPolicy);

function canTrainBuddhistWarriorMonks(iPlayer, iUnitID, iUnitType)
	local player = Players[iPlayer];
	local stateReligion = player:GetStateReligion();

	if (iUnitType == GameInfo.Units["UNIT_WARRIOR_MONK"].ID) then
		local isBuddhistReligion = stateReligion == GameInfoTypes["RELIGION_SHINTO"] or stateReligion == GameInfoTypes["RELIGION_JODO_SHINSHU"]
		if (not isBuddhistReligion) then
			return false;
		end
	end

	return true;
end
GameEvents.CityCanTrain.Add(canTrainBuddhistWarriorMonks);

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
-- SCENARIO INITIALIZATION
---------------------------------------------------------------------
function InitReligions()
	local otomoPlayerId;
	local otomoCapitalCity;
	local ikkoIkkiPlayerId;
	local ikkoIkkiCapitalCity;
	local uesugiPlayerId;
	local uesugiCapitalCity;

	for playerIndex = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		local player = Players[playerIndex];
		if (player:IsAlive()) then
			local playerType = player:GetCivilizationType();
			if (playerType == GameInfo.Civilizations["CIVILIZATION_OTOMO"].ID) then
				otomoPlayerId = playerIndex;
				otomoCapitalCity = player:GetCapitalCity();
			elseif  (playerType == GameInfo.Civilizations["CIVILIZATION_UESUGI"].ID) then
				uesugiPlayerId = playerIndex;
				uesugiCapitalCity = player:GetCapitalCity();
			elseif  (playerType == GameInfo.Civilizations["CIVILIZATION_IKKO_IKKI"].ID) then
				ikkoIkkiPlayerId = playerIndex;
				ikkoIkkiCapitalCity = player:GetCapitalCity();
			end
		end
	end

	-- Buddhism
	Game.FoundPantheon(uesugiPlayerId, GameInfoTypes["BELIEF_ANCESTOR_WORSHIP"]);
	Game.FoundReligion(uesugiPlayerId, GameInfoTypes["RELIGION_SHINTO"], nil, GameInfoTypes["BELIEF_KAMI"], GameInfoTypes["BELIEF_PAGODAS"], -1, -1, uesugiCapitalCity);
	Game.EnhanceReligion(uesugiPlayerId, GameInfoTypes["RELIGION_SHINTO"], GameInfoTypes["BELIEF_RELIGIOUS_COMMUNITY"], GameInfoTypes["BELIEF_DEFENDER_FAITH"]);

	-- Christianity
	Game.FoundPantheon(otomoPlayerId, GameInfoTypes["BELIEF_PAPAL_PRIMACY"]);
	Game.FoundReligion(otomoPlayerId, GameInfoTypes["RELIGION_CHRISTIANITY"], nil, GameInfoTypes["BELIEF_TITHE"], GameInfoTypes["BELIEF_CATHEDRALS"], -1, -1, otomoCapitalCity);
	Game.EnhanceReligion(otomoPlayerId, GameInfoTypes["RELIGION_CHRISTIANITY"], GameInfoTypes["BELIEF_MISSIONARY_ZEAL"], GameInfoTypes["BELIEF_HOLY_ORDER"]);

	-- Jodo Shinshu
	Game.FoundPantheon(ikkoIkkiPlayerId, GameInfoTypes["BELIEF_POPULISM"]);
	Game.FoundReligion(ikkoIkkiPlayerId, GameInfoTypes["RELIGION_JODO_SHINSHU"], nil, GameInfoTypes["BELIEF_TRUE_PURE_LAND"], GameInfoTypes["BELIEF_MONASTERIES"], -1, -1, ikkoIkkiCapitalCity);
	Game.EnhanceReligion(ikkoIkkiPlayerId, GameInfoTypes["RELIGION_JODO_SHINSHU"], GameInfoTypes["BELIEF_HOLY_WARRIORS"], GameInfoTypes["BELIEF_JUST_WAR"]);

	for playerIndex = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		local player = Players[playerIndex];
		if (player:IsAlive()) then
			local civType = GameInfo.Civilizations[player:GetCivilizationType()].Type;
			capital = player:GetCapitalCity();
			if (capital ~= nil) then
				local religion = civReligions[civType]

				capital:AdoptReligionFully(religion);
				player:SetStateReligion(religion)
			end
		end
	end
end

function InitPlayers()
	for playerIndex = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		AddInitialUnits(playerIndex);

		local player = Players[playerIndex]
		-- Ikko Ikki starts with Uprising branch unlocked
		if (player:GetCivilizationType() == GameInfo.Civilizations["CIVILIZATION_IKKO_IKKI"].Type) then
			player:SetPolicyBranchUnlocked(GameInfo.PolicyBranchTypes["POLICY_BRANCH_UPRISING"], true, false);
		end
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
	InitReligions();
	MakeTokugawaVassalOfImagawa();

	-- Grant AI bonuses
	SetAIBonuses();
	
	-- For final score on victory screen not to be crazy inflated
	Game.SetEstimateEndTurn(200);
end