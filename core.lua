--[[---------------------------------------------------------------------

@addon:					TinyLittleRaidTools (TLRT)
@author:				McBrain (Celesteria@kerub)

--]]---------------------------------------------------------------------

-- TODO:	konfigurationsinterface

local ME = {
	addonName				= "TinyLittleRaidTools",
	addonShortname	= "TLRT",
	addonAuthor			= "Celesteria@Kerub",
	addonVersion		= 1.08,
	addonPath				= "Interface/Addons/tlrt",
	profileName			= "tlrt_settings",
	debug						= true,
	isActive				= false,
	-- default settings
	defaults = {
		enabled					= true,
		useSound				= true,
		autoAssist			= true,
	},
	commands = {
		[0]	= {token = "SYNC",			rights = "member",	func = "Sync"},
		[1]	= {token = "WARNING",		rights = "assist",	func = "ShowMessage",	sound = "wav/alarm.wav"},
		[2]	= {token = "PANIC",			rights = "assist",	func = "ShowMessage",	sound = "wav/axe.wav"},
		[3]	= {token = "NOTIFY",		rights = "assist",	func = "ShowMessage",	sound = "wav/notify2.wav"},
		[4]	= {token = "GIVELEAD",	rights = "member",	func = "GiveLead"},
	},
	funcHooks = {	-- number is the argument position of unitID. use {1,2} if more than one
		TargetUnit			= 1,
		FollowUnit			= 1,
		FocusUnit				= 1,
		CastSpellByName = 2,
	},
	lastLeader			= nil,
}
_G.TLRT = ME

local C_RED			= "|cffff00ff"
local C_GREEN		= "|cff00ff00"

function ME.ParseNickname(name)
	name = name:lower():gsub("^%l", string.upper)
	return name
end

function ME.HasRights(command)
	local hasLead 	= UnitIsRaidLeader("player")
	local hasAssist	= UnitIsRaidAssistant("player")
	for _,cmd in pairs(ME.commands) do
		if cmd.rights	== "leader" and hasLead then return true end
		if cmd.rights	== "assist" and hasAssist then return true end
		if cmd.rights == "member" then return true end
	end
	return false
end

function ME.GetPartyMemberInfo(uid, index)
	local name 		= UnitName(uid)
	if name and name~="" then
		ME.players				= ME.players or {}
		ME.players[name]	= ME.players[name] or {name = name, uid = uid}
		ME.players[name].pClass,	ME.players[name].sClass		= UnitClassToken(uid)
		ME.players[name].pLevel,	ME.players[name].sLevel		= UnitLevel(uid)
	_,ME.players[name].online,	ME.players[name].isAssist	= GetRaidMember(index or 1)
		ME.players[name].group,		ME.players[name].index		= math.ceil(((index or 1)-1)/6), index or 1
		ME.players[name].isLead 	= ME.utils.toboolean(UnitIsRaidLeader(uid))
		ME.players[name].isTank		= ME.utils.toboolean(UnitIsRaidMainTank(uid))
		ME.players[name].isAttack	= ME.utils.toboolean(UnitIsRaidMainAttacker(uid))
		ME.players[name].hasTLRT	= ME.players[name].hasTLRT or false
		return ME.players[name]
	end
	return nil
end

function ME.GiveLead(uid)
	if UnitIsRaidLeader("player") then
		PromoteToPartyLeader(uid)
		return true
	end
	return false
end

function ME.CheckLeader()
	-- TODO think about ist
end

function ME.CheckAssist()
	if not UnitIsRaidLeader("player") or not ME.settings.autoAssist then return end
	ME.utils.Debug(ME.addonShortName, "CheckAssist")
	for uid,member in pairs(ME.members) do
		ME.utils.Debug(ME.addonShortName, name, "assist", member.isAssist)
		if name~=UnitName("player") and not member.isAssist and not member.isLead then
			ME.utils.Print(ME.addonName, "gives assist to", member.name)
			SwithRaidAssistant(member.index, true)	-- misspelling correct
		end
	end
end

function ME.UpdateParty(event, ...)
	local t,a,l,c 	= 0,0,0,0
	local tbl, i = {}
	if GetNumRaidMembers()+GetNumPartyMembers()>0 then
		if GetNumRaidMembers()==0 then return SwitchToRaid() end
		for i=1,36 do
			tbl["raid"..i]	= ME.GetPartyMemberInfo("raid"..i, i)
		end
		ME.members	= {}
		for uid, member in pairs(tbl) do
			ME.members[uid]	= member
			if member.isAssist	then l = l + 1	ME.members["assist"..l]	= member end
			if member.isAttack	then a = a + 1	ME.members["attack"..a]	= member end
			if member.isTank		then t = t + 1	ME.members["tank"..t] 	= member end
			c = c + 1
		end
		ME.utils.Debug(ME.addonShortname, "UpdateParty", c, t, a, l)
	else
		ME.members		= {}
	end
	ME.Activate(ME.utils.tableSize(tbl))
	if ME.isActive then
		ME.CheckLeader()
		if (l<c) then ME.CheckAssist() end
	end
end

function ME.Activate(state)
	local state = ME.settings.enabled and ME.utils.toboolean(state)
	if state~=ME.isActive then
		ME.taskList	= {}
		ME.isActive = state
		if ME.isActive then
			ME.utils.Print(ME.addonName, C_GREEN..ME.lang.ON.."|r")
		else
			ME.utils.Print(ME.addonName, C_RED..ME.lang.OFF.."|r")
		end
	end
end

-- available keys: name, uid, group, index, pClass, pLevel, sClass, sLevel, isOnline, isLead, isAssist, isTank, isAttack
function ME.FilterMemberList(indexKey, valueKey)
	local list = {}
	if ME.isLoaded and ME.isActive then
		for uid,member in pairs(ME.members) do
			local data = valueKey and (member[valueKey] or valueKey) or member
			if indexKey=="uid" then
				list[uid] = data
			else
				list[member[indexKey]] = data
			end
		end
	end
	return list
end

-- find and handle TLRT related messages

function ME.SendRaidMessage(command, members, text)					-- member: true for all or {"name1", "name5", "name3"...}
	if not ME.isLoaded or not ME.isActive then return end
	if not ME.HasRights(command) then
		return ME.utils.Print(ME.lang.NORIGHTS)
	end
	local cmdCode, memCode = nil, "3F3F3F3F3F3F"
	for i=0,math.min(255,#ME.commands) do
		if ME.commands[i]~=nil and command:upper()==ME.commands[i].token then
			cmdCode = sprintf("%02x", i) break
		end
	end
	assert(cmdCode, "invalid command code")
	if members and type(members)=="table" then
		local idx, tmp = ME.FilterMemberList("index", 0), ME.FilterMemberList("name", "index")
		for _,name in pairs(members) do
			idx[tmp[ME.ParseNickname(name)]] = 1
		end
		memCode,c,p	= "",0,1
		for m=1,36 do
			c	= c + (idx[m]==1 and p or 0)
			p	= p * 2
			if p==64 then
				memCode,c,p = sprintf("%s%02x", memCode, c),0,1
			end
		end
	end
	local msg = sprintf("|H%s:%s%s|h|h%s", ME.addonShortname, cmdCode, memCode, text or "")
	ME.utils.Debug(ME.addonShortname, "SendRaidMessage", msg:sub(2))
	ME.utils.GetOriginalFunction(_G, "SendChatMessage")(msg, "party")
end

function ME.ShowMessage(command, members, user, data, text)
	if ME.utils.inTable(members,UnitName("player")) then
		if command.sound and ME.settings.useSound then
			PlaySoundByPath(sprintf("%s/%s", ME.addonPath, command.sound))
		end
		if command.token=="WARNING" then SendWarningMsg(text) end
		if command.token=="PANIC" 	then SendSystemMsg(text) end
	end
end

function ME.ParseMessage(msg, user)
	if not ME.isLoaded or not ME.isActive or not msg or not user then return end
	if msg:match("|H"..ME.addonShortname..":%w+|h|h") then
		local cmd, data	= msg:match("|H"..ME.addonShortname..":(%x%x)(%w*)|h|h")
		local _,user,_	= ParseHyperlink(user)
		if cmd then					-- its a tlrt message
			if cmd=="00" then	-- its a tlrt sync (any non command) message
				ME.utils.Debug(ME.addonShortname, "SYNC", user)
				ME.players[user].hasTLRT = true
			elseif ME.commands[tonumber(cmd,16)] then	-- its a known command
				local g1, g2, g3, g4, g5, g6, info = data:match("(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%w*)")
				local text = msg:gsub("|H"..ME.addonShortname..":"..cmd..g1..g2..g3..g4..g5..g6..data.."|h|h", "")
				local groups	= {tonumber(g1,16), tonumber(g2,16), tonumber(g3,16), tonumber(g4,16), tonumber(g5,16), tonumber(g6,16)}
				local members, tmp	= {}, ME.FilterMemberList("index", "name")
				ME.utils.Debug(ME.addonShortname, "parseresult", cmd, g1, g2, g3, g4, g5, g6, info, text)
				cmd	= ME.commands[tonumber(cmd,16)]
				for g=1,6 do
					local pow = 1
					for p=1,6 do
						if groups[g]==63 or ME.utils.bitwiseAND(groups[g], pow)==pow then
							table.insert(members, tmp[(g-1)*6+p])
						end
						pow = pow * 2
					end
				end
				ME.utils.Debug(ME.addonShortname, "members", ME.utils.join(members, ","))
				if cmd.func and ME[cmd.func] and ME.isLoaded and ME.isActive then
					local success, errMsg = pcall(ME[cmd.func], cmd, members, user, data, text)
					assert(success, errMsg)
				end
			end
		end
	end
end

function ME.SendChatMessage(msg, chat, arg1, arg2)
	if chat:lower()=="party" and ME.isLoaded and ME.isActive then
		for i,cmd in pairs(ME.commands) do
			if msg:match("::"..cmd.token.."::") then
				ME.SendRaidMessage(cmd.token, true, msg:gsub("(::"..cmd.token.."::)", ""))
				return false
			end
		end
		ME.SendRaidMessage("SYNC", true, msg)
		return false
	end
	local orig = ME.utils.GetOriginalFunction(_G, "SendChatMessage")
	orig(msg, chat, arg1, arg2)
end

-- handle "new" uid

function ME.UnitID(uid)
	if type(uid)=="string" and ME.isLoaded and ME.isActive then
		local id		= uid:lower()
		local list	= ME.FilterMemberList("uid", "uid")
		uid = uid:gsub("^(atta?c?k?e?r?)", "attack"):gsub("^assista?n?t?", "assist"):gsub("^leade?r?", "lead")
		if string.find(id, "^party")	then uid = uid:gsub("party", "raid") end
		if string.find(id, "^tank") 	then uid = uid:gsub("^(tank%d+)", list) end
		if string.find(id, "^attack") then uid = uid:gsub("^(attack%d+)", list) end
		if string.find(id, "^assist") then uid = uid:gsub("^(assist%d+)", list) end
		if string.find(id, "^lead") 	then uid = uid:gsub("^(lead)", list) end
	end
	return uid
end

function ME.HookUidFunctions()
	for func,argPos in pairs(ME.funcHooks) do
		ME.utils.Hook(_G, func, function(...)
			local args, argPos = {...}, type(argPos)=="number" and {argPos} or argPos
			for _,pos in pairs(argPos) do
				ME.utils.Debug(func, args[pos], "-->", ME.UnitID(args[pos]))
				args[pos]	= ME.UnitID(args[pos])
			end
			ME.utils.GetOriginalFunction(_G, func)(unpack(args))
		end)
	end
end

-- handle events

function ME.EventFrame()
	if not ME.eventFrame then
		local eventFrame = CreateUIComponent("Frame", "TLRTEventFrame", "UIParent")
		eventFrame:SetAnchor("BOTTOMLEFT", "BOTTOMLEFT", "UIParent")
		eventFrame:SetSize(1, 1)
		eventFrame:SetScripts('OnUpdate',	[=[ TLRT.OnEvent("ONUPDATE", this, elapsedTime) ]=])
		eventFrame:SetScripts('OnEvent',	[=[ TLRT.OnEvent(event, this, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ]=])
		eventFrame:SetScripts('OnLoad',		[=[ TLRT.OnEvent("ONLOAD", this) ]=])
		ME.eventFrame = eventFrame
	end
	return ME.eventFrame
end

function ME.VARIABLES_LOADED(...)
	-- load utils
	local file = sprintf("%s/utils.lua", ME.addonPath)
	local success, errMsg	= pcall(loadfile, file)		assert(success, errMsg)
	ME.utils 		= dofile(file)
	-- load lang
	local file = sprintf("%s/lang/%s.lua", ME.addonPath, GetLanguage():sub(1,2))
	local success, errMsg	= pcall(loadfile, file)		assert(success, errMsg)
	ME.lang = dofile(file)
	-- merge settings
	SaveVariablesPerCharacter(ME.profileName)
	local tmp = _G[ME.profileName] or {}
	ME.settings = {}
	for k,v in pairs(ME.defaults) do
		if tmp[k]~=nil then
			ME.settings[k] = tmp[k]
		else
			ME.settings[k] = v
		end
	end
	-- register events
	ME.EventFrame():RegisterEvent("LOADING_END")
	ME.EventFrame():RegisterEvent("SAVE_VARIABLES")
	ME.EventFrame():RegisterEvent("CHAT_MSG_PARTY")
	ME.EventFrame():RegisterEvent("PARTY_MEMBER_CHANGED")
	ME.EventFrame():RegisterEvent("PARTY_LEADER_CHANGED")
	-- hook functions
	ME.utils.Hook(_G, "SendChatMessage", ME.SendChatMessage)
	_G.SendRaidMessage	= ME.SendRaidMessage
	ME.HookUidFunctions()
	-- startup finished
	ME.isLoaded = true
	ME.utils.Print(ME.addonName, ME.addonVersion, ME.lang.LOADED)
end

function ME.ONUPDATE(elapsedTime)
end

function ME.OnEvent(event, frame, ...)
	if ME[event] then
		local success, errMsg = pcall(ME[event], ...)
		assert(success, errMsg)
	elseif ME.isLoaded then
		if event=="CHAT_MSG_PARTY" 			then ME.ParseMessage(...)
		elseif event=="SAVE_VARIABLES" 	then _G[ME.profileName] = ME.settings or {}
		else ME.UpdateParty(event, ...) end
	end
end

-- change settings

function ME.SetSettings(key, val)
	if not val or val=="" then ME.settings[key] = not ME.settings[key]
	elseif val==true or val=="on" or val=="true" then ME.settings[key] = true
	elseif val==false or val=="off" or val=="false" then ME.settings[key] = false
	end
	if key=="enabled" and ME.settings.enabled~=ME.isActive then
		return ME.Activate(ME.settings.enabled)
	end
	ME.showSettings(key)
	if key=="autoAssist" and ME.settings.autoAssist then
		ME.CheckAssist()
	end
end

function ME.showSettings(key)
	local output = {enabled = ME.addonName, useSound = "Sound", autoAssist = "AutoAssist"}
	if output[key] then
		if ME.settings[key] then
			ME.utils.Print(output[key], C_GREEN..ME.lang.ON.."|r")
		else
			ME.utils.Print(output[key], C_RED..ME.lang.OFF.."|r")
		end
	end
end

-- slash command handler

function _G.SlashCmdList.TLRT(editBox, msg)
	cmd = msg:lower():match("(%w*)")
	prm = msg:lower():match(" (%w*)")
	ME.utils.Debug(cmd, prm)
	if cmd=="sound" or cmd=="usesound" then															return ME.SetSettings("useSound", prm)
	elseif cmd=="assist" or cmd=="autoassist" then											return ME.SetSettings("autoAssist", prm)
	elseif cmd=="on" or cmd=="true" or cmd=="off" or cmd=="false" then	return ME.SetSettings("enabled", cmd)
	end
	ME.showSettings("enabled")
	if ME.settings.enabled then
		ME.showSettings("useSound")
		ME.showSettings("autoAssist")
	end
end
_G.SLASH_TLRT1 = "/tlrt"
_G.SLASH_TLRT2 = "/TLRT"

-- startup

ME.EventFrame():RegisterEvent("VARIABLES_LOADED")
