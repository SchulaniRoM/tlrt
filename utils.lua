
local ME = {}

function ME.toboolean(value)
	if type(value)=="boolean"	then return value end
	if type(value)=="number"	then return (value>0) and true or false end
	if type(value)=="string"	then return not (value:lower()=="false" or value:lower()=="off" or value:lower()=="no" or value=="") and true or false end
	return value~=nil and true or false
end

function ME.tableRemove(tbl, key)
	if type(tbl)=="table" then
		local value = tbl[key or 1]
		if value then
			table.remove(tbl, key or 1)
			return value
		end
	end
	return ""
end

function ME.tableSize(tbl)
	local c = 0
	if tbl and type(tbl)=="table" then
		for _,_ in pairs(tbl) do c = c + 1 end
	end
	return c
end

function ME.inTable(table, value, key)
	if type(table)=="table" then
		for k,v in pairs(table) do
			if (type(v) == "table" and key) then
				if v[key] == value then
					return true
				end
			elseif (type(v) == "table" and not key) then
				if k == value then
					return true
				end
			elseif (type(v) ~= "table" and key) then
				if k == key then
					return true
				end
			else
				if v == value then
					return true
				end
			end
		end
	end
	return false
end

function ME.join(tbl, separator, withKey, withValue)
	local r, s, k, v = "", separator or ","
	local wk = withKey==true
	local wv = withValue~=false
	if type(tbl)=="table" then
		for k,v in pairs(tbl) do
			r = sprintf("%s%s%s%s%s", r, #r>0 and s or "", wk==true and tostring(k) or "", (wk==true and wv==true) and "=" or "", wv==true and tostring(v) or "")
		end
	else
		r = toString(tbl)
	end
	return r
end

function ME.split(str, delim, limit)
	str 	=str and tostring(str) or ""
	delim	= delim and tostring(delim) or ",[%s%c]*"
	limit = tonumber(limit) and tonumber(limit) or 0
	if not str:find(delim) then return {str} end
	local res, lastPos = {}, 0
	local pat = sprintf("(.-)%s()", delim)
	for part, pos in str:gfind(pat) do
		res[#res+1] = part
		lastPos			= pos
		if #res == limit then break end
	end
	if #res ~= limit then
		res[#res+1] = str:sub(lastPos)
	end
	return res
end

function ME.deepCopy(tbl, seen)
  if type(tbl) == "table" then
		if seen and seen[tbl] then
			return seen[tbl]
		else
			local seen = seen or {}
			local res = setmetatable({}, getmetatable(tbl))
			seen[tbl] = res
			for k, v in pairs(tbl) do
				res[ME.deepCopy(k, seen)] = ME.deepCopy(v, seen)
			end
			return res
		end
	else
		return tbl
	end
end

function ME.numToBits(num)
	assert(tonumber(num) and num==math.floor(num), "not an integer")
	local tbl, cnt = {}, 1
	while num>0 do
		local last = math.mod(num, 2)
		if last==1 then
			tbl[cnt] = 1
		else
			tbl[cnt] = 0
		end
		num	= (num-last)/2
		cnt = cnt + 1
	end
	return tbl
end

function ME.bitsToNum(tbl)
	local num, pow = 0, 1
	for i = 1, #tbl do
		num = num + (tbl[i] or 0) * pow
		pow = pow * 2
	end
	return num
end

function ME.bitwiseAND(a, b)
	local tbl_a = ME.numToBits(a)
	local tbl_b = ME.numToBits(b)
	local tbl = {}
	for i = 1, math.max(#tbl_a, #tbl_b) do
		tbl[i] = ((tbl_a[i] or 0) + (tbl_b[i] or 0)==2) and 1 or 0
	end
	return ME.bitsToNum(tbl)
end

function ME.Hook(funcRoot, funcName, newFunc)
	if funcRoot[funcName] then
		funcRoot.TLRTHookedFunctions = funcRoot.TLRTHookedFunctions or {}
		if not funcRoot.TLRTHookedFunctions[funcName] then
			funcRoot.TLRTHookedFunctions[funcName] = funcRoot[funcName]
		end
	end
	funcRoot[funcName] = newFunc
	return ME.GetOriginalFunction(funcRoot, funcName)
end

function ME.GetOriginalFunction(funcRoot, funcName)
	return funcRoot.TLRTHookedFunctions and funcRoot.TLRTHookedFunctions[funcName] or funcRoot[funcName]
end

function ME.Print(...)
	local txt = ''
	for k,arg in pairs({...}) do txt = sprintf("%s%s ", txt, tostring(arg)) end
	DEFAULT_CHAT_FRAME:AddMessage(txt, .9, .3, .9)
end

function ME.Error(str, ...)
	str = select("#",...)>0 and tostring(str):format(...) or tostring(str)
	DEFAULT_CHAT_FRAME:AddMessage(str, .9, .3, .3)
end

function ME.Format(text, object)
	if text and type(text)=="string" and text~="" then
		for k,v in pairs(object or {}) do
			text = text:gsub("<<"..tostring(k)..">>", type(v)=="number" and MoneyNormalization(v) or tostring(v))
		end
	end
	return text
end

return ME
