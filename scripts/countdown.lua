--[[---------------------------------------------------------------------

@addon:					TinyLittleRaidTools (TLRT)
@author:				McBrain (Celesteria@kerub)

example of a countdown

--]]---------------------------------------------------------------------

local TLRT	= _G.TLRT
local ME 		= {
	-- VarFuncs
	on_start	= "::NOTIFY::<<timer>>s CountDown gestartet",
	on_update	= "::BEEP::<<timer>>s",
	[10]			= nil,	-- function below
	[8]				= "::BEEP::<<timer>>s - MUSIK starten !",
	[2]				= "::WARNING::<<timer>>s - |H|h|cffFF0000TANK|r|h GOGOGO !!!",
	on_stop		= "::WARNING::<<timer>>s - |H|h|cff00FF00PARTY|r|h GOGOGO !!!",
	on_cancel	= "CountDown abgebrochen...",
	-- variables
	name			= "countdown",	-- required
	reverse		= true,	-- running down
	duration	= 15,	-- required
	interval	= 5,
	members		= true,	-- will be set later
}
local includeList	= {"raid1","raid2","raid3","raid4","raid5","raid6","raid7","raid8","raid9","raid10","raid11","raid12"}

--[[---------------------------------------------------------------------------------------

VarFunc

--]]---------------------------------------------------------------------------------------

ME[10] = function()	-- lets go faster for last 10 seconds
	ME.interval	= 2
	return "::BEEP::<<timer>>s - Schumas Verzauberter Wurf aktivieren, Warmages Blitzende Verbrennungswaffe anwerfen !"
end

function ME.members()
	local members, list = TLRT.FilterMemberList("uid", nil) or {}, {}
	for _,uid in pairs(includeList) do
		if members[uid] then
			if ME.timer==2 then	-- send sound for message 2 only to tanks
				if members[uid].isTank then table.insert(list, members[uid].name) end
			elseif ME.timer==0 then	-- send sound for last message to all except tanks
				if not members[uid].isTank then table.insert(list, members[uid].name) end
			else	-- send all other message sound to all
				table.insert(list, members[uid].name)
			end
		end
	end
	return list
end

--[[---------------------------------------------------------------------------------------

control

--]]---------------------------------------------------------------------------------------

function ME.Command(cmd, arg1, arg2, arg3)
	if cmd=="start" then										-- /tlrt countdown start 15
		if arg1 then
			ME.duration = tonumber(arg1) or ME.duration
		end
		ME.interval	= 5
		TLRT.StartTask(ME)

	elseif cmd=="stop" or cmd=="cancel" then 	-- /tlrt countdown stop
		if ME.running then TLRT.CancelTask(ME) end

	end
end

function ME.Init()
	-- nothing to do here
end

return ME
