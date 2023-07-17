---------------------------------------
-- Globals
---------------------------------------
local g_bScenarioDone = false;
local handicap = Game:GetHandicapType();
local savedData = Modding.OpenSaveData();

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

local otomoPlayer = GetPlayer("CIVILIZATION_OTOMO");
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
function otomoTraitOneShotInfluence(iCityOwner, eMajorityReligion, iX, iY)
	local player = Players[iCityOwner];
	if (not player:IsMinorCiv() or not otomoPlayer:IsAlive()) then
		return;
	end

	if (eMajorityReligion ~= GameInfo.Religions["RELIGION_CHRISTIANITY"].ID) then
		return
	end

	print("We are Christianity");

	local cityPlot = Map.GetPlot(iX, iY);
	local city = cityPlot:GetPlotCity();

	local key = "OtomoFirstConvert_MinorCity_" .. tostring(city:GetID());
	local value = savedData.GetValue(key);

	if (value ~= nil) then
		return;
	end

	print("Haven't converted yet.");
	
	-- Save that this city has converted so we don't do this again.
	player:ChangeMinorCivFriendshipWithMajor(otomoPlayer:GetID(), 40);
	savedData.SetValue(key, 1);
end
GameEvents.CityConvertsReligion.Add(otomoTraitOneShotInfluence);

-- iPlayer, iUnit, iX, iY, iBuild
function canBuildTerraceFarmsAfterPolicy(iPlayer, iUnit, iX, iY, iBuild)
	local player = Players[iPlayer];
	local build = GameInfo.Builds[iBuild].Type;

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

function IkkoIkkiCannotTrainReligiousUnits(iPlayer, iUnitID, iUnitType)
	if (
		iUnitType == GameInfo.Units["UNIT_MISSIONARY"].ID or
		iUnitType == GameInfo.Units["UNIT_INQUISITOR"].ID
	) then
		local player = Players[iPlayer];
		local civ = GameInfo.Civilizations[player:GetCivilizationType()];

		if (civ.Type == GameInfo.Civilizations["CIVILIZATION_IKKO_IKKI"].Type) then
			return false;
		end
	end

	return true;
end
GameEvents.CityCanTrain.Add(IkkoIkkiCannotTrainReligiousUnits);

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
			elseif (playerType == GameInfo.Civilizations["CIVILIZATION_UESUGI"].ID) then
				uesugiPlayerId = playerIndex;
				uesugiCapitalCity = player:GetCapitalCity();
			elseif (playerType == GameInfo.Civilizations["CIVILIZATION_IKKO_IKKI"].ID) then
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
		AddUnitsPerDifficulty(playerIndex);

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

function AddUnitsPerDifficulty(playerIndex)
	-- Culture, Faith, Gold
	local humanStartingYields = {
		[0] = { 75, 100, 200 },
		[1] = { 45, 75, 150 },
		[2] = { 45, 50, 125 },
		[3] = { 30, 25, 100 },
		[4] = { 30, 20, 75 },
		[5] = { 0, 15, 50 },
		[6] = { 0, 0, 25 },
		[7] = { 0, 0, 10 }
	};
	local humanStartingUnits = {
		[0] = {
			{ "UNIT_SETTLER", UNITAI_SETTLE },
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[1] = {
			{ "UNIT_SETTLER", UNITAI_SETTLE },
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[2] = {
			{ "UNIT_SETTLER", UNITAI_SETTLE },
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[3] = {
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[4] = {
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[5] = {
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
		},
		[6] = {},
		[7] = {},
	};

	-- Culture, Faith, Gold
	local cpuStartingYields = {
		[0] = { 75, 25, 50 },
		[1] = { 75, 25, 50 },
		[2] = { 75, 25, 50 },
		[3] = { 75, 25, 50 },
		[4] = { 75, 50, 75 },
		[5] = { 75, 100, 150 },
		[6] = { 75, 175, 225 },
		[7] = { 75, 300, 500 }
	};
	local cpuStartingUnits = {
		[0] = {
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[1] = {
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[2] = {
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[3] = {
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[4] = {
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE }
		},
		[5] = {
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_BOW_ASHIGARU", UNITAI_DEFENSE }
		},
		[6] = {
			{ "UNIT_SETTLER", UNITAI_SETTLE },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_BOW_ASHIGARU", UNITAI_DEFENSE }
		},
		[7] = {
			{ "UNIT_SETTLER", UNITAI_SETTLE },
			{ "UNIT_SETTLER", UNITAI_SETTLE },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_WORKER", UNITAI_WORKER },
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_SCOUT", UNITCOMBAT_RECON },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_YARI_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_BOW_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_BOW_ASHIGARU", UNITAI_DEFENSE },
			{ "UNIT_BOW_ASHIGARU", UNITAI_DEFENSE }
		}
	};

	local player = Players[playerIndex];

	if (not player:IsAlive()) then
		return;
	end

	function SetInitialYields(player, yields, handicap)
		local culture = yields[handicap][1];
		local faith = yields[handicap][2];
		local gold = yields[handicap][3];

		player:SetJONSCulture(culture);
		player:SetFaith(faith);
		player:SetGold(gold);
	end

	function PlaceUnits(player, units, handicap)
		local capital = player:GetCapitalCity();
		local unitList = humanStartingUnits[handicap];
		for i,unit in ipairs(unitList) do
			AddUnitToPlot(player, unit[1], capital:GetX(), capital:GetY(), unit[2]);
		end
	end

	if (player:IsHuman()) then
		SetInitialYields(player, humanStartingYields, handicap);
		PlaceUnits(player, humanStartingUnits, handicap);
	else
		SetInitialYields(player, cpuStartingYields, handicap);
		PlaceUnits(player, cpuStartingUnits, handicap);
	end
end

function MakeTokugawaVassalOfImagawa()
	local imagawaTeamId = imagawaTeam:GetID();
	tokugawaTeam:Meet(imagawaTeamId);
	tokugawaTeam:DoBecomeVassal(imagawaTeamId, true);
end

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
	
	-- For final score on victory screen not to be crazy inflated
	Game.SetEstimateEndTurn(200);
	Game.SetStartYear(1500)
end