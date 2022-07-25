--[[---------------------------------------------------------------------

@addon:					TinyLittleRaidTools (TLRT)
@author:				McBrain (Celesteria@kerub)

example of a ready check

--]]---------------------------------------------------------------------

local TLRT	= _G.TLRT
local ME 		= {
	-- VarFuncs
	on_start		= "::NOTIFY::ReadyCheck wurde gestartet. Bitte bestätigt eure Anwesenheit mit einem + im Gruppenchat. Sobald alle bereit sind, kommt der Countdown!",
	on_update		= "::SYSTEM::ReadyCheck läuft seit <<timer>>s, folgende Spieler sind noch nicht bereit: <<members_string>>",
	on_stop			= "::SYSTEM::ReadyCheck abgebrochen oder abgelaufen.",
	on_cancel		= "ReadyCheck beendet. Starte CountDown.",
	on_event		= nil,	-- function below
	members			= nil,	-- function below
	-- variables
	name				= "readycheck",	-- required
	duration		= 30,	-- required
	interval		= 5,
	events			= {"CHAT_MSG_PARTY", "PARTY_MEMBER_CHANGED"},
}

local ignoreList	= {}
local readyList		= {}
local includeList	= {"raid1","raid2","raid3","raid4","raid5","raid6","raid7","raid8","raid9","raid10","raid11","raid12"}

--[[---------------------------------------------------------------------------------------

VarFunc

--]]---------------------------------------------------------------------------------------

function ME.members()
	local members, list, i = TLRT.FilterMemberList("uid", "name") or {}, {}
	for _,uid in pairs(includeList) do
		local name = members[uid]
		if name and name~=UnitName("player") and (not ignoreList or not ignoreList[name]) and (not readyList or not readyList[name]) then
			table.insert(list, name)
		end
	end
	return list
end

function ME.members_string()
	local txt = ""
	for _,name in pairs(ME.members()) do
		txt = sprintf("%s%s%s", txt, #txt>0 and ", " or "", name)
	end
	return txt
end

function ME.on_event(event, msg, user)
	if event=="CHAT_MSG_PARTY" then
		local _,name,_	= ParseHyperlink(user)
		msg	= msg:gsub("(|H%w*:%w*|h|h)", ""):gsub("(%s)", "")	-- strip any hyperlink and space
		if msg=="+" then
			local list			= TLRT.FilterMemberList("name", 1)
			if list[name] then
				readyList[name] = true
			end
			if ME.members_string()=="" then
				TLRT.CancelTask(ME)
			end

		elseif msg=="---" then
			TLRT.StopTask(ME)
		end
	elseif event=="PARTY_MEMBER_CHANGED" then
		-- when moving member out of includeList
		if ME.members_string()=="" then
			TLRT.CancelTask(ME)
		end
	end
end

--[[---------------------------------------------------------------------------------------

control

--]]---------------------------------------------------------------------------------------

function ME.Command(cmd, arg1, arg2, arg3)
	if cmd=="start" then										-- /tlrt readycheck start [ignoredUser1] [ignoredUser2]
		if arg2 and type(arg2)=="string" then ME.Command("ignore", "add", arg2) end
		if arg3 and type(arg3)=="string" then ME.Command("ignore", "add", arg3) end
		readyList = {}
		TLRT.StartTask(ME)

	elseif cmd=="stop" then 	-- /tlrt readycheck stop
		if ME.running then TLRT.StopTask(ME) end

	elseif cmd=="cancel" then 	-- /tlrt readycheck cancel
		if ME.running then TLRT.CancelTask(ME) end

	elseif cmd=="ignore" and arg2=="add" then 	-- /tlrt readycheck ignore add ignoredUser
		if type(arg3)=="string" then ignoreList[TLRT.ParseNickname(arg3)] = true end

	elseif cmd=="ignore" and arg2=="del" then 	-- /tlrt readycheck ignore del ignoredUser
		if type(arg3)=="string" and ignoreList[TLRT.ParseNickname(arg3)] then ignoreList[TLRT.ParseNickname(arg3)] = nil end

	elseif cmd=="ignore" and arg2=="clear" then 	-- /tlrt readycheck ignore clear
		ignoreList = {}

	elseif cmd=="duration" then 	-- /tlrt readycheck duration 60
		ME.duration = math.max(10, math.min(300, tonumber(arg2)))

	end
end

function ME.Init()
	SaveVariables("TLRT_ReadyCheck_IgnoreList")
	ignoreList	= _G["TLRT_ReadyCheck_IgnoreList"]
end

return ME
