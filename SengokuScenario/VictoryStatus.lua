----------------------------------------------------------------
----------------------------------------------------------------
-- VictoryStatus.lua
-- Script for the gameplay, UI, and some setup
-- for the Sengoku Jidai scenario
----------------------------------------------------------------
----------------------------------------------------------------

include( "IconSupport" );
include( "FLuaVector" );

--------------------------------------------------------------
-- Memoized Persistent Properties
--------------------------------------------------------------
-- Try not to use this directly for pulling values!
-- Memoize instead.
savedData = Modding.OpenSaveData();
-------------------------------------------------------------- 
function GetPersistentProperty(name)
	if(g_Properties == nil) then
		g_Properties = {};
	end
	
	if(g_Properties[name] == nil) then
		g_Properties[name] = savedData.GetValue(name);
	end
	
	return g_Properties[name];
end
--------------------------------------------------------------
function SetPersistentProperty(name, value)
	if(g_Properties == nil) then
		g_Properties = {};
	end
	
	savedData.SetValue(name, value);
	g_Properties[name] = value;
end

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------
local kyotoUIControls = nil;
local landControlUIControls = nil;

-------------------------------------------------
-- SetVictoryTypes
-------------------------------------------------
function SetVictoryTypes()
	Game.SetVictoryValid(GameInfo.Victories["VICTORY_TIME"].ID, true);
	Game.SetVictoryValid(GameInfo.Victories["VICTORY_SPACE_RACE"].ID,false);
	Game.SetVictoryValid(GameInfo.Victories["VICTORY_DOMINATION"].ID,false);
	Game.SetVictoryValid(GameInfo.Victories["VICTORY_CULTURAL"].ID,false);
	Game.SetVictoryValid(GameInfo.Victories["VICTORY_DIPLOMATIC"].ID,false);
end

-----------------------------------------------------------------
-- UI Functions (VictoryStatus)
-----------------------------------------------------------------
function UpdateKyoto()
	local kyotoPlotX = GetPersistentProperty("KyotoPlotX");
	local kyotoPlotY = GetPersistentProperty("KyotoPlotY");

	print("Kyoto is at: " .. tostring(kyotoPlotX) .. ", " .. tostring(kyotoPlotY));

	local kyotoPlot = Map.GetPlot(kyotoPlotX, kyotoPlotY);
	if (kyotoPlot:IsCity()) then
		local ownerId = kyotoPlot:GetOwner();
		local player = Players[ownerId];
		local hasMetPlayer = Teams[player:GetTeam()]:IsHasMet(Game.GetActiveTeam());

		local civName;
		if (ownerId == Game.GetActivePlayer()) then
			civName = "[COLOR_POSITIVE_TEXT]" .. Locale.Lookup("TXT_KEY_YOU") .. "[ENDCOLOR]";
		else
			if (hasMetPlayer) then
				civName = "[COLOR_NEGATIVE_TEXT]" .. Locale.Lookup(player:GetCivilizationShortDescriptionKey()) .. "[ENDCOLOR]";
			else
				civName = "[COLOR_NEGATIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_UNMET_PLAYER") .. "[ENDCOLOR]";
			end
		end
		kyotoUIControls.KyotoCivLabel:LocalizeAndSetText("TXT_KEY_SENGOKU_SCENARIO_KYOTO_CONTROLLED_CIV", civName);

		local portraitIndex = 1;
		local iconAtlas = nil;
		if (player:IsMajorCiv() and hasMetPlayer) then
			local leader = GameInfo.Leaders[player:GetLeaderType()];
			portraitIndex = leader.PortraitIndex;
			iconAtlas = leader.IconAtlas;
		else
			portraitIndex = 22;
			iconAtlas = "LEADER_ATLAS";
		end

		IconHookup(portraitIndex, 128, iconAtlas, kyotoUIControls.LeaderPortrait );
	end						
end

function isVictoryPlot(plot)
	if (plot == nil) then
		return false;
	end

	local terrainType = plot:GetTerrainType();
	if (terrainType == TerrainTypes.TERRAIN_SNOW or
		terrainType == TerrainTypes.TERRAIN_TUNDRA or
		terrainType == TerrainTypes.TERRAIN_COAST or
		terrainType == TerrainTypes.TERRAIN_OCEAN) then
		return false;
	end

	local area = plot:Area();

	if (area:GetNumTiles() < 5) then
		return false;
	end

	return true;
end

function GetPlayerVictoryLandArea(playerIndex)
	local numVictoryPlots = 0;
	local team = Players[playerIndex]:GetTeam();
	for plotIndex = 1, Map.GetNumPlots(), 1 do
		plot = Map.GetPlotByIndex(plotIndex-1);
		local plotOwner = Players[plot:GetOwner()];
		if (plotOwner ~= nil and isVictoryPlot(plot)) then
			local plotOwnerTeam = Teams[plotOwner:GetTeam()];
			if (plot:GetOwner() == playerIndex or plotOwnerTeam:IsVassal(team)) then
				numVictoryPlots = numVictoryPlots + 1;
			end
		end
	end
	return numVictoryPlots;
end

function CalculatePercent(numerator, denominator)
	local percent = numerator * 100 / denominator;
	return percent;
end

function UpdateLandControl()
	local numVictoryPlots = GetPersistentProperty("NumVictoryPlots", numVictoryPlots);

	local myNumVictoryPlots = -1;
	local highestPlayerIndex = -1;
	local highestNumVictoryPlots = -1;

	for playerIndex = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		local player = Players[playerIndex];

		local numPlayerVictoryPlots = GetPlayerVictoryLandArea(playerIndex);

		if (playerIndex == Game.GetActivePlayer()) then
			myNumVictoryPlots = numPlayerVictoryPlots;
		end
		
		if (numPlayerVictoryPlots > highestNumVictoryPlots) then
			highestNumVictoryPlots = numPlayerVictoryPlots;
			highestPlayerIndex = playerIndex;
		end
	end

	local rivalName = "";
	if (highestPlayerIndex == Game.GetActivePlayer()) then
		rivalName = "[COLOR_POSITIVE_TEXT]" .. Locale.Lookup("TXT_KEY_YOU") .. "[ENDCOLOR]";
	else
		local civName = "";
		if (Teams[Players[highestPlayerIndex]:GetTeam()]:IsHasMet(Game.GetActiveTeam())) then
			civName = Locale.Lookup(Players[highestPlayerIndex]:GetCivilizationShortDescriptionKey());
		else
			civName = Locale.ConvertTextKey("TXT_KEY_UNMET_PLAYER");
		end

		rivalName = "[COLOR_NEGATIVE_TEXT]" ..  civName .. "[ENDCOLOR]";
	end

	local yourPercent = CalculatePercent(myNumVictoryPlots, numVictoryPlots);
	local rivalPercent = CalculatePercent(highestNumVictoryPlots, numVictoryPlots);
	
	landControlUIControls.YourLandPercentLabel:LocalizeAndSetText("TXT_KEY_SENGOKU_SCENARIO_YOUR_LAND_PERCENT", string.format("%.2f", yourPercent));
	landControlUIControls.TopRivalLabel:LocalizeAndSetText("TXT_KEY_SENGOKU_SCENARIO_YOUR_RIVAL_CIV", rivalName);
	landControlUIControls.TopRivalLandPercentLabel:LocalizeAndSetText("TXT_KEY_SENGOKU_SCENARIO_YOUR_RIVAL_LAND_PERCENT", string.format("%.2f", rivalPercent));
end
-------------------------------------------------
-- BuildLayout
-- Should only be called once!!
-------------------------------------------------
function BuildKyotoVCInstance()
	local controlTable = {};
	ContextPtr:BuildInstanceForControl("KyotoVCInstance", controlTable, Controls.VCStack);
	kyotoUIControls = controlTable;
end

function BuildLandControlVCInstance()
	local controlTable = {};
	ContextPtr:BuildInstanceForControl("LandControlVCInstance", controlTable, Controls.VCStack);
	landControlUIControls = controlTable;
end

function BuildLayout()
	CivIconHookup(Game:GetActivePlayer(), 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true); -- Set the icon for player's civ

	BuildKyotoVCInstance();
	BuildLandControlVCInstance();
end

-------------------------------------------------
-- RefreshLayout
-------------------------------------------------
function RefreshLayout()
	UpdateKyoto();
	UpdateLandControl();
end

-------------------------------------------------
-- Back Button Handler
-------------------------------------------------
function OnClose()
    UIManager:DequeuePopup(ContextPtr);
end
Controls.CloseStatusButton:RegisterCallback(Mouse.eLClick, OnClose);

-------------------------------------------------
-- Input processing
-------------------------------------------------
ContextPtr:SetInputHandler( function(uiMsg, wParam, lParam)
    if(uiMsg == KeyEvents.KeyDown and wParam == Keys.VK_ESCAPE) then
		OnClose();
		return true;
    end
end);

-------------------------------------------------
-- Show/Hide Handler
-------------------------------------------------
function DoShowHidePopup(isHide)
	if (not isHide) then
		RefreshLayout();
	end
end
ContextPtr:SetShowHideHandler(DoShowHidePopup);

-- Call Initialization functions
SetVictoryTypes();
BuildLayout();