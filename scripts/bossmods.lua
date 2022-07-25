--[[---------------------------------------------------------------------

@addon:					TinyLittleRaidTools (TLRT)
@author:				McBrain (Celesteria@kerub)
								Wichtl (Gagh@kerub)

main bossmods module

--]]---------------------------------------------------------------------

local TLRT	= _G.TLRT
local ME 		= {
	-- VarFuncs
	on_event		= nil,	-- function below
	-- variables
	name				= "bossmods",
	events			= {"ZONE_CHANGED"},
},

local zones = {
	[256] = {
		name = "Pantheon",
		ZONE_SPLINTFANG_STOOP		= { file = "pantheon/B1.lua", name = "Boss 1" },	-- Pantheon B1: Langzahn-Korridor
		ZONE_SERPENTBEARER_PITH	= { file = "pantheon/B2.lua", name = "Boss 2" },	-- Pantheon B2: Schlangenmutter-Brutgrube
		ZONE_BYPASS_WELLSPRING	= { file = "pantheon/B3.lua", name = "Boss 3" },	-- Pantheon B3: Kanalquelle
	},
}

--[[---------------------------------------------------------------------------------------

VarFuncs

--]]---------------------------------------------------------------------------------------

function ME.on_event(event, arg1, ...)
	if event=="ZONE_CHANGED" then
		local zID = GetZoneID()
		if zones[zID) then
			for zone, boss in pairs(zones[zID]) do
				if arg1 == TEXT(zone) then
					SendSystemMsg(zones[zID].name.." "..boss.name.." gefunden")
-- 					load BossMod file
				end
			end
		end
	end
end

--[[---------------------------------------------------------------------------------------

control

--]]---------------------------------------------------------------------------------------

function ME.Command(cmd, arg1, arg2, arg3)
	if cmd=="start" then										-- /tlrt bossmods start
		TLRT.StartTask(ME)

	elseif cmd=="stop" or cmd=="cancel" then 	-- /tlrt bossmods stop
		if ME.running then TLRT.CancelTask(ME) end

	end
end

function ME.Init()
end

return ME
