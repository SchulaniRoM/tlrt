--[[---------------------------------------------------------------------

@addon:					TinyLittleRaidTools (TLRT)
@author:				McBrain (Celesteria@kerub)

--]]---------------------------------------------------------------------

-- TODO:	konfigurationsinterface

local ME = {
	addonName				= "TinyLittleRaidTools",
	addonShortname	= "TLRT",
	addonAuthor			= "Celesteria@Kerub",
	addonVersion		= 1.07,
	addonPath				= "Interface/Addons/tlrt",
	profileName			= "tlrt_settings",
	debug						= true,
	isActive				= false,
	-- default settings
	defaults = {
		enabled					= true,
		useSound				= true,
	},
	commands = {
-- 		[0]	= {token = "SYNC",		func = "SyncTime"},
		[1]	= {token = "WARNING",	func = "ShowMessage",	sound = "wav/alarm.wav"},
		[2]	= {token = "PANIC",		func = "ShowMessage",	sound = "wav/axe.wav"},
		[4]	= {token = "NOTIFY",	func = "ShowMessage",	sound = "wav/notify2.wav"},
	}
}
_G.TLRT = ME

function ME.ParseNickname(name)
	name = name:lower():gsub("^%l", string.upper)
	return name
end

function ME.HasRights()
	if UnitIsRaidLeader("player") or UnitIsRaidAssistant("player") then return true end
	return false
end

function ME.GetPartyMemberInfo(uid, index)
	local name 		= UnitName(uid)
	if name and name~="" then
		local pClass, sClass = UnitClassToken(uid)
		local pLevel, sLevel = UnitLevel(uid)
		return {
			name			= name,
			group			= math.ceil((index or 1)/6),
			index			= index,
			uid		 		= uid,
			pClass		= pClass,
			pLevel		= pLevel,
			sClass		= sClass,
			sLevel		= sLevel,
			isLead 		= ME.utils.toboolean(UnitIsRaidLeader(uid)),
			isAssist	= ME.utils.toboolean(UnitIsRaidAssistant(uid)),
			isTank		= ME.utils.toboolean(UnitIsRaidMainTank(uid)),
			isAttack	= ME.utils.toboolean(UnitIsRaidMainAttacker(uid)),
		}
	end
	return nil
end

function ME.UpdateParty(event)
	local tbl, i = {}
	if GetNumRaidMembers()+GetNumPartyMembers()>0 then
		if GetNumRaidMembers()==0 then return SwitchToRaid() end
		for i=1,36 do
			tbl["raid"..i]	= ME.GetPartyMemberInfo("raid"..i, i)
		end
		local t,l,a 	= 1,1,1
		ME.members	= {}
		for uid, member in pairs(tbl) do
			ME.members[uid]	= member
			if member.isLead		then ME.members.lead 					= member end
			if member.isAssist	then ME.members["assist"..l]	= member	l = l + 1 end
			if member.isAttack	then ME.members["attack"..a]	= member	a = a + 1 end
			if member.isTank		then ME.members["tank"..t] 		= member	t = t + 1 end
		end
		ME.utils.Debug(ME.addonShortname, "UpdateParty", ME.utils.tableSize(tbl))
	else
		ME.members	= {}
	end
	ME.Activate(ME.utils.tableSize(tbl))
end

function ME.Activate(state)
	local state = ME.utils.toboolean(state)
	if state~=ME.isActive then
		ME.taskList	= {}
		ME.isActive = state
		if ME.isActive then
			ME.utils.Print(ME.addonName, ME.lang.ACTIVATED)
		else
			ME.utils.Print(ME.addonName, ME.lang.DEACTIVATED)
		end
	end
end

function ME.FilterMemberList(indexKey, valueKey)
	local list = {}
	if ME.isActive then
		for uid,member in pairs(ME.members) do
			if indexKey=="uid" then
				list[uid]		= member[valueKey] or valueKey
			else
				list[member[indexKey]] = member[valueKey] or valueKey
			end
		end
	end
	return list
end

-- find and handle TLRT related messages

function ME.SendRaidMessage(command, members, text)					-- member: true for all or {"name1", "name5", "name3"...}
	if not ME.isLoaded or not ME.isActive then return end
	if not ME.HasRights() then
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
		memCode	= ""
		for g=1,6 do
			local tmp, pow = 0, 1
			for p=1,6 do
				tmp	= tmp + (idx[(g-1)*6+p]==1 and pow or 0)
				pow = pow * 2
			end
			memCode = sprintf("%s%02x", memCode, tmp)
		end
	end
	local msg = sprintf("|H%s:%s%s|h|h%s", ME.addonShortname, cmdCode, memCode, text or "")
	ME.utils.Debug(ME.addonShortname, "SendRaidMessage", msg:sub(2))
	ME.utils.GetOriginalFunction(_G, "SendChatMessage")(msg, "party")
end

function ME.ShowMessage(command, members, user, data, text)
	if ME.utils.inTable(members,UnitName("player")) then
		if command.sound then
			PlaySoundByPath(sprintf("%s/%s", ME.addonPath, command.sound))
		end
		if command.token=="WARNING" then SendWarningMsg(text) end
		if command.token=="PANIC" 	then SendSystemMsg(text) end
	end
end

function ME.ParseMessage(msg, user)
	if not ME.isLoaded or not ME.isActive or not msg or not user then return end
	if msg:match("|H"..ME.addonShortname..":%w+|h|h") then
		local cmd, g1, g2, g3, g4, g5, g6, data = msg:match("|H"..ME.addonShortname..":(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%w*)|h|h")
		local text = msg:gsub("|H"..ME.addonShortname..":"..cmd..g1..g2..g3..g4..g5..g6..data.."|h|h", "")
		ME.utils.Debug(ME.addonShortname, "result", cmd, g1, g2, g3, g4, g5, g6, data, text)
		if cmd and ME.commands[tonumber(cmd,16)] then
			cmd	= ME.commands[tonumber(cmd,16)]
			local groups	= {tonumber(g1,16), tonumber(g2,16), tonumber(g3,16), tonumber(g4,16), tonumber(g5,16), tonumber(g6,16)}
			local members, tmp	= {}, ME.FilterMemberList("index", "name")
			for g=1,6 do
				local pow = 1
				for p=1,6 do
					if groups[g]==63 or ME.utils.bitwiseAND(groups[g], pow)==pow then
						table.insert(members, tmp[(g-1)*6+p])
					end
					pow = pow * 2
				end
			end
			local _,user,_ = ParseHyperlink(user)
			ME.utils.Debug(ME.addonShortname, "members", ME.utils.join(members, ","))
			if cmd.func and ME[cmd.func] then
				local success, errMsg = pcall(ME[cmd.func], cmd, members, user, data, text)
				assert(success, errMsg)
			end
		else
			-- unknown command
		end
	else
		-- not found
	end
end

function ME.SendChatMessage(msg, chat, arg1, arg2)
	for i,cmd in pairs(ME.commands) do
		if msg:match("::"..cmd.token.."::") then
			ME.SendRaidMessage(cmd.token, true, msg:gsub("(::"..cmd.token.."::)", ""))
			return false
		end
	end
	ME.utils.GetOriginalFunction(_G, "SendChatMessage")(msg, chat, arg1, arg2)
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
	ME.settings	= ME.defaults
	for k,v in pairs(_G[ME.profileName] or {}) do
		if ME.settings[k]~=nil then
			ME.settings[k] = v
		end
	end
	-- register events
	ME.EventFrame():RegisterEvent("LOADING_END")
	ME.EventFrame():RegisterEvent("SAVE_VARIABLES")
	ME.EventFrame():RegisterEvent("CHAT_MSG_PARTY")
	ME.EventFrame():RegisterEvent("PARTY_MEMBER_CHANGED")
	-- hook functions
	ME.utils.Hook(_G, "SendChatMessage", ME.SendChatMessage)
	_G.SendRaidMessage	= ME.SendRaidMessage
	-- startup finished
	ME.isLoaded = true
	ME.utils.Print(ME.addonName, ME.addonVersion, ME.lang.LOADED)
end

function ME.OnEvent(event, frame, ...)
	if ME[event] then
		local success, errMsg = pcall(ME[event], ...)
		assert(success, errMsg)
	elseif ME.isLoaded then
		if event=="CHAT_MSG_PARTY" 				then ME.ParseMessage(...) end
		if event=="PARTY_MEMBER_CHANGED" 	then ME.UpdateParty(...) end
		if event=="LOADING_END" 					then ME.UpdateParty(...) end
		if event=="SAVE_VARIABLES" 				then _G[ME.profileName] = ME.settings or {} end
	end
end

-- slash command handler

function _G.SlashCmdList.ME(editBox, cmd)
end
_G.SLASH_TLRT1 = "/tlrt"
_G.SLASH_TLRT2 = "/TLRT"

-- startup

ME.EventFrame():RegisterEvent("VARIABLES_LOADED")
