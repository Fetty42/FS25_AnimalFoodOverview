-- Author: Fetty42
-- Date: 09.12.2024
-- Version: 1.0.0.0

local dbPrintfOn = true
local dbInfoPrintfOn = true

local function dbInfoPrintf(...)
	if dbInfoPrintfOn then
    	print(string.format(...))
	end
end

local function dbPrintf(...)
	if dbPrintfOn then
    	print(string.format(...))
	end
end

local function dbPrintHeader(ftName)
	if dbPrintfOn then
    	print(string.format("Call %s: g_currentMission:getIsServer()=%s | g_currentMission:getIsClient()=%s", ftName, g_currentMission:getIsServer(), g_currentMission:getIsClient()))
	end
end



AnimalFoodOverview = {}; -- Class

-- global variables
AnimalFoodOverview.dir = g_currentModDirectory
AnimalFoodOverview.modName = g_currentModName

AnimalFoodOverview.dlg			= nil

source(AnimalFoodOverview.dir .. "gui/DlgFrame.lua")

function AnimalFoodOverview:loadMap(name)
    dbPrintHeader("AnimalFoodOverview:loadMap()")

	if g_currentMission:getIsClient() then
		-- Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, AnimalFoodOverview.registerActionEvents);
		-- Enterable.onRegisterActionEvents = Utils.appendedFunction(Enterable.onRegisterActionEvents, AnimalFoodOverview.registerActionEvents);
		-- VIPOrderManager.eventName = {};

		-- g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
		-- g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)
	end
end



function AnimalFoodOverview:registerActionEvents()
    -- dbPrintHeader("AnimalFoodOverview:registerActionEvents()")

	-- if g_currentMission:getIsClient() then --isOwner
	-- 	local result2, actionEventId2 = g_inputBinding:registerActionEvent('ShowAnimalFoodDlg',InputBinding.NO_EVENT_TARGET, AnimalFoodOverview.ShowAnimalFoodDlg ,false ,true ,false ,true)
	-- 	dbPrintf("Result2=%s | actionEventId2=%s | g_currentMission:getIsClient()=%s", result2, actionEventId2, g_currentMission:getIsClient())
	-- 	if result2 and actionEventId2 then
	-- 		g_inputBinding:setActionEventTextVisibility(actionEventId2, true)
	-- 		g_inputBinding:setActionEventActive(actionEventId2, true)
	-- 		g_inputBinding:setActionEventTextPriority(actionEventId2, GS_PRIO_VERY_LOW) -- GS_PRIO_VERY_HIGH, GS_PRIO_HIGH, GS_PRIO_LOW, GS_PRIO_VERY_LOW

	-- 		dbPrintf("Action event inserted successfully")
	-- 	end
	-- end
end


--
function AnimalFoodOverview:ShowAnimalFoodDlg(actionName, keyStatus, arg3, arg4, arg5)
    dbPrintHeader("AnimalFoodOverview:ShowAnimalFoodDlg()")

	AnimalFoodOverview.dlg = nil
	g_gui:loadProfiles(AnimalFoodOverview.dir .. "gui/guiProfiles.xml")
	local dlgFrame = DlgFrame.new(g_i18n)
	g_gui:loadGui(AnimalFoodOverview.dir .. "gui/DlgFrame.xml", "DlgFrame", dlgFrame)
	AnimalFoodOverview.dlg = g_gui:showDialog("DlgFrame")

	-- print("")
	-- print("** Start DebugUtil.printTableRecursively() ************************************************************")
	-- printf("==> %s", "g_currentMission.animalFoodSystem.animalMixtures")
	-- DebugUtil.printTableRecursively(g_currentMission.animalFoodSystem.animalMixtures, ".", 0, 4)
	-- print("** End DebugUtil.printTableRecursively() **************************************************************")
end

function AnimalFoodOverview:isTerraLife()
	local mapDirectory = g_mpLoadingScreen.missionInfo.map.baseDirectory
	if mapDirectory == "" then
		--wenn mapDirectory leer ist, handelt es sich um die Basemaps
		return false
	elseif fileExists(mapDirectory .. "dlcDesc.xml") then
		--wenn dlcDesc existiert, handelt es sich um DLC-Map
		return false
	else
		local path = mapDirectory .. "modDesc.xml"
		local xmlFile = XMLFile.load("TempDesc", path)
		if xmlFile:hasProperty("moddesc.terraLife") then
			return true
		else
			return false
		end
		xmlFile:delete()
	end
end


function AnimalFoodOverview:onLoad(savegame)end;
function AnimalFoodOverview:onUpdate(dt)end;
function AnimalFoodOverview:deleteMap()end;
function AnimalFoodOverview:keyEvent(unicode, sym, modifier, isDown)end;
function AnimalFoodOverview:mouseEvent(posX, posY, isDown, isUp, button)end;

addModEventListener(AnimalFoodOverview);