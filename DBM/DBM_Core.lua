-- @Author: Webster
-- @Date:   2015-05-13 16:06:53
-- @Last Modified by:   Webster
-- @Last Modified time: 2015-05-20 00:10:25
local _L = JH.LoadLangPack
local DEBUG = true
local DBM_TYPE, DBM_SCRUTINY_TYPE = DBM_TYPE, DBM_SCRUTINY_TYPE
local DBM_MAX_CACHE = 1000 -- 最大的cache数量 主要是UI的问题
local DBM_DEL_CACHE = 500  -- 每次清理的数量 然后会做一次gc
local DBM_DATAPATH = JH.GetAddonInfo().szDataPath
local DBM_INIFILE  = JH.GetAddonInfo().szRootPath .. "DBM/ui/DBM.ini"
local CACHE = {
	TEMP = { -- 近期事件记录MAP 这里用弱表 方便处理
		BUFF    = setmetatable({}, { __mode = "v" }),
		DEBUFF  = setmetatable({}, { __mode = "v" }),
		CASTING = setmetatable({}, { __mode = "v" }),
		NPC     = setmetatable({}, { __mode = "v" }),
	},
	MAP = { -- 需要监控的数据MAP
		BUFF    = {},
		DEBUFF  = {},
		CASTING = {},
		NPC     = {},
	},
	NPC_LIST = {},
	SKILL_LIST = {},
}
local D = {
	tDungeonList = {},
	FILE = { -- 文件原始数据
		BUFF    = {
			[-1] = {
				{ dwID = 103, nLevel = 1, },
			}
		},
		DEBUFF  = {
			[-1] = {
				{ dwID = 1674, nLevel = 1, },
			}
		},
		CASTING = {
			[-1] = {
				{ dwID = 17, nLevel = 1, },
				{ dwID = 4097, nLevel = 1, },
			}
		},
		NPC     = {
			[-1] = {
				{ dwID = 11051, nFrame = 52 },
			}
		},
		TALK    = {},
	},
	TEMP = { -- 近期事件记录
		BUFF    = {},
		DEBUFF  = {},
		CASTING = {},
		NPC     = {},
	},
	DATA = { -- 需要监控的数据合集
		BUFF    = {},
		DEBUFF  = {},
		CASTING = {},
		NPC     = {},
		TALK    = {},
	}
}

DBM = {
	bEnable             = true,
	bPushbScreenHead    = true,
	bPushCenterAlarm    = true,
	bPushbBigFontAlarm  = true,
	bBigFontAlarm       = true,
	bPushTeamPanel      = true, -- 面板buff监控
	bPushFullScreen     = true, -- 全屏泛光
	bPushTeamChannel    = true, -- 团队报警
	bPushWhisperChannel = true, -- 密聊报警
	bPushBuffList       = true,
	bMonSkillTarget     = true,
}

function DBM.OnFrameCreate()
	this:RegisterEvent("NPC_ENTER_SCENE")
	this:RegisterEvent("NPC_LEAVE_SCENE")
	this:RegisterEvent("BUFF_UPDATE")
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("DO_SKILL_CAST")
	this:RegisterEvent("LOADING_END")
	this:RegisterEvent("DBM_CREATE_CACHE")
	this:RegisterEvent("PLAYER_SAY")
	this:RegisterEvent("JH_NPC_FIGHT")
	this:RegisterEvent("JH_NPC_ALLLEAVE_SCENE")
	this:RegisterEvent("ON_WARNING_MESSAGE")
	this:RegisterEvent("JH_NPC_LIFE_CHANGE")
end

function DBM.OnFrameBreathe()
	D.CheckNpcState()
end

function DBM.OnEvent(szEvent)
	if szEvent == "BUFF_UPDATE" then
		D.OnBuff(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	elseif szEvent == "SYS_MSG" then
		if arg0 == "UI_OME_DEATH_NOTIFY" then
			D.OnDeath(arg1, arg3)
		elseif arg0 == "UI_OME_SKILL_CAST_LOG" then
			D.OnSkillCast(arg1, arg2, arg3, arg0)
		elseif (arg0 == "UI_OME_SKILL_BLOCK_LOG"
		or arg0 == "UI_OME_SKILL_SHIELD_LOG" or arg0 == "UI_OME_SKILL_MISS_LOG"
		or arg0 == "UI_OME_SKILL_DODGE_LOG"	or arg0 == "UI_OME_SKILL_HIT_LOG")
		and arg3 == SKILL_EFFECT_TYPE.SKILL then
			D.OnSkillCast(arg1, arg4, arg5, arg0)
		elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" and arg4 == SKILL_EFFECT_TYPE.SKILL then
			D.OnSkillCast(arg1, arg5, arg6, arg0)
		end
	elseif szEvent == "DO_SKILL_CAST" then
		D.OnSkillCast(arg0, arg1, arg2, szEvent)
	elseif szEvent == "NPC_ENTER_SCENE" then
		local npc = GetNpc(arg0)
		if npc then
			D.OnNpcEvent(npc, true)
		end
	elseif szEvent == "NPC_LEAVE_SCENE" then
		local npc = GetNpc(arg0)
		if npc then
			D.OnNpcEvent(npc, false)
		end
	elseif szEvent == "JH_NPC_ALLLEAVE_SCENE" then
		D.OnNpcAllLeave(arg0)
	elseif szEvent == "JH_NPC_FIGHT" then
		D.OnNpcFight(arg0, arg1)
	elseif szEvent == "JH_NPC_LIFE_CHANGE" then
		D.OnNpcLife(arg0, arg1)
	elseif szEvent == "LOADING_END" or szEvent == "DBM_CREATE_CACHE" then
		D.CreateData()
	end
end

function D.Log(szMsg)
	if DEBUG then
		Log("[DBM] " .. szMsg)
	end
end

local function CreateCache(szType, tab)
	local data  = D.DATA[szType]
	local cache = CACHE.MAP[szType]
	for k, v in ipairs(tab) do
		data[#data + 1] = v
		if v.nLevel then
			cache[v.dwID] = cache[v.dwID] or {}
			cache[v.dwID][v.nLevel] = k
		else -- other
			cache[v.dwID] = k
		end
	end
	D.Log("Create " .. szType .. " data Success!")
end

function D.CreateData()
	local me = GetClientPlayer()
	local dwMapID = me.GetMapID()
	local nTime = GetTime()
	-- 清空当前数据和MAP
	for k, v in pairs(D.DATA) do
		D.DATA[k] = {}
	end
	for k, v in pairs(CACHE.MAP) do
		CACHE.MAP[k] = {}
	end
	for _, szType in ipairs({ "BUFF", "DEBUFF", "CASTING", "NPC", "TALK" }) do
		local data  = D.DATA[szType]
		local cache = CACHE.MAP[szType]
		if D.FILE[szType][-1] then -- 通用数据
			CreateCache(szType, D.FILE[szType][-1])
		end
		if D.FILE[szType][dwMapID] then -- 本地图数据
			CreateCache(szType, D.FILE[szType][dwMapID])
		end
	end
	for k, v in pairs(D.FILE)  do
		setmetatable(D.FILE[k], { __index = function(me, index)
			if index == _L["All Data"] then
				local t = {}
				for k, v in pairs(D.FILE[k]) do
					for _, vv in ipairs(v) do
						t[#t +1] = vv
					end
				end
				return t
			end
		end })
	end
	D.Log("MAPID: " .. dwMapID ..  " Create data Success:" .. GetTime() - nTime  .. "ms")
end

function D.FreeCache(szType)
	D.Log(szType .. " cache clear!")
	local t = {}
	local tTemp = D.TEMP[szType]
	for i = DBM_DEL_CACHE, #tTemp do
		t[#t + 1] = tTemp[i]
	end
	D.TEMP[szType] = t
	collectgarbage("collect")
	FireEvent("DBMUI_TEMP_RELOAD", szType)
end

function D.CheckScrutinyType(nScrutinyType, dwID)
	if nScrutinyType == DBM_SCRUTINY_TYPE.SELF and dwID ~= UI_GetClientPlayerID() then
		return false
	elseif nScrutinyType == DBM_SCRUTINY_TYPE.TEAM and not JH.IsParty(dwID) then
		return false
	elseif nScrutinyType == DBM_SCRUTINY_TYPE.ENEMY and not IsEnemy(UI_GetClientPlayerID(), dwID) then
		return false
	end
	return true
end
-- 倒计时处理 支持定义无限的倒计时
function D.FireCountdownEvent(data, nClass)
	if data.tCountdown then
		for k, v in ipairs(data.tCountdown) do
			if nClass == v.nClass then
				FireEvent("JH_ST_CREATE", nClass, k .. "." .. data.dwID .. "." .. (data.nLevel or 0), {
					nTime    = v.nTime,
					nRefresh = v.nRefresh,
					szName   = v.szName or data.szName,
					nIcon    = v.nIcon or data.nIcon,
					bTalk    = DBM.bPushTeamChannel and v.bTeamChannel
				})
			end
		end
	end
end

-- 通用的事件发送
function D.FireAlertEvent(data, cfg, xml, dwID, nClass)
	-- 中央报警
	if DBM.bPushCenterAlarm and cfg.bCenterAlarm then
		FireEvent("JH_CA_CREATE", table.concat(xml), 3, true)
	end
	-- 特大文字
	if DBM.bBigFontAlarm and cfg.bBigFontAlarm then
		local txt = GetPureText(table.concat(xml))
		FireEvent("JH_LARGETEXT", txt, { GetHeadTextForceFontColor(dwID, UI_GetClientPlayerID()) }, UI_GetClientPlayerID() == dwID )
	end
end

-- 事件操作
function D.OnBuff(dwCaster, bDelete, nIndex, bCanCancel, dwBuffID, nCount, nEndFrame, bInit, nBuffLevel, dwSkillSrcID)
	local me = GetClientPlayer()
	local szType = bCanCancel and "BUFF" or "DEBUFF"
	local data = D.GetData(szType, dwBuffID, nBuffLevel)
	local cfg, nClass
	if not bDelete then
		-- 近期记录
		local tWeak, tTemp = CACHE.TEMP[szType], D.TEMP[szType]
		local key = dwBuffID .. "_" .. nBuffLevel
		if not tWeak[key] then
			local t = {
				dwMapID   = me.GetMapID(),
				dwID      = dwBuffID,
				nLevel    = nBuffLevel,
				bIsPlayer = IsPlayer(dwSkillSrcID)
			}
			tWeak[key] = t
			tTemp[#tTemp + 1] = tWeak[key]
			if #tTemp > DBM_MAX_CACHE then
				D.FreeCache(szType)
			else
				FireEvent("DBMUI_TEMP_UPDATE", szType, t)
			end
		end
	end
	if data then
		if data.nScrutinyType and not D.CheckScrutinyType(data.nScrutinyType, dwCaster) then -- 监控对象检查
			return
		end
		if data.nCount and nCount < data.nCount then -- 层数检查
			return
		end
		if bDelete then
			cfg, nClass = data[DBM_TYPE.BUFF_LOSE], DBM_TYPE.BUFF_LOSE
		else
			cfg, nClass = data[DBM_TYPE.BUFF_GET], DBM_TYPE.BUFF_GET
		end
		D.FireCountdownEvent(data, nClass)
		if cfg then
			local szName, nIcon = JH.GetBuffName(dwBuffID, nBuffLevel)
			local KObject = IsPlayer(dwCaster) and GetPlayer(dwCaster) or GetNpc(dwCaster)
			if not KObject then
				return D.Log("ERROR " .. szType .. " object:" .. dwCaster .. " does not exist!")
			end
			szName = data.szName or szName
			nIcon  = data.nIcon or nIcon
			local szSrcName = JH.GetTemplateName(KObject)
			local xml = {}
			table.insert(xml, GetFormatText(_L["["], 44, 255, 255, 255))
			if UI_GetClientPlayerID() == dwMemberID then
				table.insert(xml, GetFormatText(g_tStrings.STR_YOU, 44, 255, 255, 0))
			else
				table.insert(xml, GetFormatText(szSrcName, 44, 255, 255, 0))
			end
			table.insert(xml, GetFormatText(_L["]"], 44, 255, 255, 255))
			if nClass == DBM_TYPE.BUFF_GET then
				table.insert(xml, GetFormatText(_L["Get Buff"], 44, 255, 255, 255))
				table.insert(xml, GetFormatText(szName .. " x" .. nCount, 44, 255, 255, 0))
				if data.szNote then
					table.insert(xml, GetFormatText(" " .. data.szNote, 44, 255, 255, 255))
				end
			else
				table.insert(xml, GetFormatText(_L["Lose Buff"], 44, 255, 255, 255))
				table.insert(xml, GetFormatText(szName, 44, 255, 255, 0))
			end
			local txt = GetPureText(table.concat(xml))
			-- 通用的报警事件处理
			D.FireAlertEvent(data, cfg, xml, dwCaster, nClass)
			-- 获得处理
			if nClass == DBM_TYPE.BUFF_GET then
				-- 重要Buff列表
				if IsPlayer(dwCaster) and cfg.bPartyBuffList and (JH.IsParty(dwCaster) or UI_GetClientPlayerID() == dwCaster) then
					FireEvent("JH_PARTYBUFFLIST", dwCaster, data.dwID, data.nLevel)
				end
				-- 头顶报警
				if DBM.bPushbScreenHead and cfg.bScreenHead then
					FireEvent("JH_SCREENHEAD", dwCaster, { type = szType, dwID = data.dwID, szName = data.szName or szName, col = data.col })
				end
				if UI_GetClientPlayerID() == dwCaster then
					if DBM.bPushBuffList and cfg.bBuffList then
						-- TODO push BUFF状态栏
					end
					-- 全屏泛光
					if DBM.bPushFullScreen and cfg.bFullScreen then
						FireEvent("JH_FS_CREATE", data.dwID .. "_"  .. data.nLevel, {
							nTime = 3,
							col = data.col,
							tBindBuff = { data.dwID, data.nLevel }
						})
					end
				end
				-- 添加到团队面板
				if DBM.bPushTeamPanel and cfg.bTeamPanel and ( not cfg.bOnlySelfSrc or dwSkillSrcID == UI_GetClientPlayerID()) then
					FireEvent("JH_RAID_REC_BUFF", dwCaster, data.dwID, data.nLevel, data.col)
				end
			end
			if DBM.bPushTeamChannel and cfg.bTeamChannel then
				JH.Talk(txt)
			end
			if DBM.bPushWhisperChannel and cfg.bWhisperChannel then
				JH.Talk(szSrcName, txt:gsub(szSrcName, g_tStrings.STR_NAME_YOU))
			end
		end
	end
end
-- 技能事件
function D.OnSkillCast(dwCaster, dwCastID, dwLevel, szEvent)
	local key = dwCastID .. "_" .. dwLevel
	local nTime = GetTime()
	CACHE.SKILL_LIST[dwCaster] = CACHE.SKILL_LIST[dwCaster] or {}
	if CACHE.SKILL_LIST[dwCaster][key] and nTime - CACHE.SKILL_LIST[dwCaster][key] < 100 then -- 0.1秒内 直接忽略
		return
	end
	CACHE.SKILL_LIST[dwCaster][key] = nTime
	local tWeak, tTemp = CACHE.TEMP.CASTING, D.TEMP.CASTING
	local me = GetClientPlayer()
	local data = D.GetData("CASTING", dwCastID, dwLevel)
	if not tWeak[key] then
		local t = {
			dwMapID   = me.GetMapID(),
			dwID      = dwCastID,
			nLevel    = dwLevel,
			bIsPlayer = IsPlayer(dwCaster)
		}
		tWeak[key] = t
		tTemp[#tTemp + 1] = tWeak[key]
		if #tTemp > DBM_MAX_CACHE then
			D.FreeCache("CASTING")
		else
			FireEvent("DBMUI_TEMP_UPDATE", "CASTING", t)
		end
	end
	-- 监控数据
	if data then
		if data.nScrutinyType and not D.CheckScrutinyType(data.nScrutinyType, dwCaster) then -- 监控对象检查
			return
		end
		local szName, nIcon = JH.GetSkillName(dwCastID, dwLevel)
		local KObject = IsPlayer(dwCaster) and GetPlayer(dwCaster) or GetNpc(dwCaster)
		if not KObject then
			return D.Log("ERROR CASTING object:" .. dwCaster .. " does not exist!")
		end
		szName = data.szName or szName
		nIcon  = data.nIcon or nIcon
		local szSrcName = JH.GetTemplateName(KObject)
		local dwTargetType, dwTargetID = KObject.GetTarget()
		local szTargetName
		if dwTargetID > 0 then
			szTargetName = JH.GetTemplateName(IsPlayer(dwTargetID) and GetPlayer(dwTargetID) or GetNpc(dwTargetID))
		end
		local cfg, nClass
		if szEvent == "UI_OME_SKILL_CAST_LOG" then
			cfg, nClass = data[DBM_TYPE.SKILL_BEGIN], DBM_TYPE.SKILL_BEGIN
		else
			cfg, nClass = data[DBM_TYPE.SKILL_END], DBM_TYPE.SKILL_END
		end
		D.FireCountdownEvent(data, nClass)
		if cfg then
			local xml = {}
			table.insert(xml, GetFormatText(_L["["], 44, 255, 255, 255))
			table.insert(xml, GetFormatText(szSrcName, 44, 255, 255, 0))
			table.insert(xml, GetFormatText(_L["]"], 44, 255, 255, 255))
			if nClass == DBM_TYPE.SKILL_END then
				table.insert(xml, GetFormatText(_L["use of"], 44, 255, 255, 255))
			else
				table.insert(xml, GetFormatText(_L["Building"], 44, 255, 255, 255))
			end
			table.insert(xml, GetFormatText(_L["["], 44, 255, 255, 255))
			table.insert(xml, GetFormatText(szName, 44, 255, 255, 0))
			table.insert(xml, GetFormatText(_L["]"], 44, 255, 255, 255))
			if DBM.bMonSkillTarget and szTargetName then
				table.insert(xml, GetFormatText(g_tStrings.TARGET, 44, 255, 255, 255))
				table.insert(xml, GetFormatText(_L["["], 44, 255, 255, 255))
				if me.dwID == dwTargetID then
					table.insert(xml, GetFormatText(g_tStrings.STR_YOU, 44, 255, 255, 0))
				else
					table.insert(xml, GetFormatText(szTargetName, 44, 255, 255, 0))
				end
				table.insert(xml, GetFormatText(_L["]"], 44, 255, 255, 255))
			end
			if data.szNote then
				table.insert(xml, " " .. GetFormatText(data.szNote, 44, 255, 255, 255))
			end
			-- 通用的报警事件处理
			D.FireAlertEvent(data, cfg, xml, dwCaster, nClass)
			-- 头顶报警
			if DBM.bPushbScreenHead and cfg.bScreenHead then
				FireEvent("JH_SCREENHEAD", dwCaster, { type = "CASTING", txt = data.szName or szName, col = data.col })
			end
			-- 全屏泛光
			if DBM.bPushFullScreen and cfg.bFullScreen then
				FireEvent("JH_FS_CREATE", data.dwID .. "#SKILL#"  .. data.nLevel, { nTime = 3, col = data.col})
			end
			if DBM.bPushTeamChannel and cfg.bTeamChannel then
				JH.Talk(txt)
			end
			if DBM.bPushWhisperChannel and cfg.bWhisperChannel then
				--TODO 全团密聊
			end
		end
	end
end

-- NPC事件
function D.OnNpcEvent(npc, bEnter)
	local me = GetClientPlayer()
	local data = D.GetData("NPC", npc.dwTemplateID)
	local nTime = GetTime()
	local cfg, nClass
	if bEnter then
		CACHE.NPC_LIST[npc.dwTemplateID] = CACHE.NPC_LIST[npc.dwTemplateID] or { bFightState = false, tList = {}, nTime = -1, nLife = math.floor(npc.nCurrentLife / npc.nMaxLife * 100) }
		table.insert(CACHE.NPC_LIST[npc.dwTemplateID].tList, npc.dwID)
		local tWeak, tTemp = CACHE.TEMP.NPC, D.TEMP.NPC
		if not tWeak[npc.dwTemplateID] then
			local t = {
				dwMapID = me.GetMapID(),
				dwID    = npc.dwTemplateID,
				nFrame  = select(2, GetNpcHeadImage(npc.dwID)),
				col     = { GetHeadTextForceFontColor(npc.dwID, me.dwID) }
			}
			tWeak[npc.dwTemplateID] = t
			tTemp[#tTemp + 1] = tWeak[npc.dwTemplateID]
			if #tTemp > DBM_MAX_CACHE then
				D.FreeCache("NPC")
			else
				FireEvent("DBMUI_TEMP_UPDATE", "NPC", t)
			end
		end
	else
		if CACHE.NPC_LIST[npc.dwTemplateID] and CACHE.NPC_LIST[npc.dwTemplateID].tList then
			local tab = CACHE.NPC_LIST[npc.dwTemplateID]
			for k, v in ipairs(tab.tList) do
				if v == npc.dwID then
					table.remove(tab.tList, k)
					if #tab.tList == 0 then
						local nTime = GetTime() - (tab.nSec or GetTime())
						if tab.bFightState then
							FireEvent("JH_NPC_FIGHT", npc.dwTemplateID, false, nTime)
						end
						CACHE.NPC_LIST[npc.dwTemplateID] = nil
						FireEvent("JH_NPC_ALLLEAVE_SCENE", npc.dwTemplateID)
					end
					break
				end
			end
		end
	end
	if data then
		if bEnter then
			cfg, nClass = data[DBM_TYPE.NPC_ENTER], DBM_TYPE.NPC_ENTER
		else
			cfg, nClass = data[DBM_TYPE.NPC_LEAVE], DBM_TYPE.NPC_LEAVE
		end
		if nClass == DBM_TYPE.NPC_LEAVE then
			if data.bAllLeave and CACHE.NPC_LIST[npc.dwTemplateID] then
				return
			end
		else
			-- 场地上的NPC数量没达到预期数量
			if data.nCount and data.nCount > #CACHE.NPC_LIST[npc.dwTemplateID].tList then
				return
			end
			-- 这些需要全部mark 所以单独列出来
			if cfg then
				if cfg.bScreenHead then
					FireEvent("JH_SCREENHEAD", npc.dwID, { type = "Object", txt = data.szNote, col = data.col })
				end
				-- TODO NPC需要标记
			end
			if nTime - CACHE.NPC_LIST[npc.dwTemplateID].nTime < 500 then -- 0.5秒内进入相同的NPC直接忽略
				return D.Log("IGNORE NPC ENTER SCENE ID:" .. npc.dwTemplateID .. " TIME:" .. nTime .. " TIME2:" .. CACHE.NPC_LIST[npc.dwTemplateID].nTime)
			else
				CACHE.NPC_LIST[npc.dwTemplateID].nTime = nTime
			end
		end
		D.FireCountdownEvent(data, nClass)
		if cfg then
			local szName = JH.GetTemplateName(npc)
			local xml = {}
			table.insert(xml, GetFormatText(_L["["], 44, 255, 255, 255))
			table.insert(xml, GetFormatText(szName, 44, 255, 255, 0))
			table.insert(xml, GetFormatText(_L["]"], 44, 255, 255, 255))
			if nClass == DBM_TYPE.NPC_ENTER then
				table.insert(xml, GetFormatText(_L["Appear"], 44, 255, 255, 255))
				if data.szNote then
					table.insert(xml, GetFormatText(" " .. data.szNote, 44, 255, 255, 255))
				end
			else
				table.insert(xml, GetFormatText(_L["leave"], 44, 255, 255, 255))
			end
			D.FireAlertEvent(data, cfg, xml, dwCaster, nClass)
			if DBM.bPushTeamChannel and cfg.bTeamChannel then
				JH.Talk(txt)
			end
			if DBM.bPushWhisperChannel and cfg.bWhisperChannel then
				--TODO 全团密聊
			end
			local txt = GetPureText(table.concat(xml))
			if nClass == DBM_TYPE.NPC_ENTER then
				if DBM.bPushFullScreen and cfg.bFullScreen then
					FireEvent("JH_FS_CREATE", "NPC", { nTime  = 3, col = data.col, bFlash = true })
				end
			end
		end
	end
end

-- NPC死亡事件 触发倒计时
function D.OnDeath(dwCharacterID, szKiller)
	if IsPlayer(dwCharacterID) then
		return
	end
	local npc = GetNpc(dwCharacterID)
	if npc then
		local data = D.GetData("NPC", npc.dwTemplateID)
		if data then
			D.FireCountdownEvent(data, DBM_TYPE.NPC_DEATH)
		end
	end
end

-- NPC进出战斗事件 触发倒计时
function D.OnNpcFight(dwTemplateID, bFight)
	local data = D.GetData("NPC", dwTemplateID)
	if data then
		if bFight then
			D.FireCountdownEvent(data, DBM_TYPE.NPC_FIGHT)
		else
			if data.tCountdown then
				for k, v in ipairs(data.tCountdown) do
					if v.nClass == DBM_TYPE.NPC_FIGHT then
						FireEvent("JH_ST_DEL", v.nClass, k .. "."  .. data.dwID .. "." .. (data.nLevel or 0), true) -- try kill
					end
				end
			end
		end
	end
end

-- NPC 血量倒计时处理 这个很可能以后会是 最大的性能消耗 格外留意
function D.OnNpcLife(dwTemplateID, nLife)
	local data = D.GetData("NPC", dwTemplateID)
	if data and data.tCountdown then
		for k, v in ipairs(data.tCountdown) do
			if v.nClass == DBM_TYPE.NPC_LIFE then
				local t = JH.Split(tTime, ";")
				for kk, vv in ipairs(t) do
					local time = JH.Split(v, ",")
					if time[1] and time[2] and time[3] and tonumber(JH.Trim(time[1])) and tonumber(JH.Trim(time[2])) and JH.Trim(time[3]) ~= "" then
						if tonumber(JH.Trim(time[1])) == nLife then -- hit
							FireEvent("JH_ST_CREATE", DBM_TYPE.NPC_LIFE, k .. "." .. dwTemplateID .. "." .. kk, {
								nTime    = tonumber(JH.Trim(time[2])),
								szName   = time[3],
								nIcon    = v.nIcon,
								bTalk    = DBM.bPushTeamChannel and v.bTeamChannel
							})
							break
						end
					end
				end
			end
		end
	end
end
-- NPC 全部消失的倒计时处理
function D.OnNpcAllLeave(dwTemplateID)
	local data = D.GetData("NPC", dwTemplateID)
	if data then
		D.FireCountdownEvent(data, DBM_TYPE.NPC_ALLLEAVE)
	end
end

function D.CheckNpcState()
	for k, v in pairs(CACHE.NPC_LIST) do
		local data = D.GetData("NPC", k)
		if data then
			local bFightFlag
			local fNpcPer = 1
			for kk, vv in ipairs(v.tList) do
				local npc = GetNpc(vv)
				if npc then
					local fPer = npc.nCurrentLife / npc.nMaxLife
					if fPer < fNpcPer then -- 取血量最少的NPC
						fNpcPer = fPer
					end
					-- 战斗标记检查
					if npc.bFightState then
						if npc.bFightState ~= v.bFightState then
							bFightFlag = true
							v.bFightState = true
							break
						end
					else
						if kk == #v.tList and npc.bFightState ~= v.bFightState then
							bFightFlag = false
							v.bFightState = false
						end
					end
				end
			end
			fNpcPer = math.floor(fNpcPer * 100)
			if v.nLife > fNpcPer then
				local nCount, step = v.nLife - fNpcPer, 1
				if nCount > 50 then -- 如果boss血量一下被干掉50%以上 那直接步进2 【鄙视秒BOSS的 小心扯着蛋
					step = 2
				end
				for i = 1, nCount, step do
					FireEvent("JH_NPC_LIFE_CHANGE", k, v.nLife - i)
				end
			end
			v.nLife = fNpcPer
			if bFightFlag then
				local nTime = GetTime()
				v.nSec = GetTime()
				FireEvent("JH_NPC_FIGHT", k, true, nTime)
			elseif bFightFlag == false then
				local nTime = GetTime() - (v.nSec or GetTime())
				v.nSec = nil
				FireEvent("JH_NPC_FIGHT", k, false, nTime)
			end
		end
	end
end

-- UI操作
function D.GetFrame()
	return Station.Lookup("Normal/DBM")
end

function D.Open()
	if not D.GetFrame() then
		Wnd.OpenWindow(DBM_INIFILE, "DBM")
	end
end

function D.Close()
	if D.GetFrame() then
		Wnd.CloseWindow(Station.Lookup("Normal/DBM")) -- kill all event
	end
end

function D.Enable(bEnable)
	if bEnable then
		local res, err = pcall(D.Open)
		if not res then
			JH.Sysmsg2(err)
		end
	else
		D.Close()
	end
end

function D.Init()
	D.Enable(DBM.bEnable)
end

function D.GetDungeon()
	if IsEmpty(D.tDungeonList) then
		for k, v in ipairs(GetMapList()) do
			local a = g_tTable.DungeonInfo:Search(v)
			if a and a.dwClassID == 3 then
				table.insert(D.tDungeonList, {
					dwMapID      = a.dwMapID,
					szLayer3Name = a.szLayer3Name
				})
			end
		end
		table.sort(D.tDungeonList, function(a, b)
			return a.dwMapID > b.dwMapID
		end)
	end
	return D.tDungeonList
end

-- 获取整个表
function D.GetTable(szType, bTemp)
	if bTemp then
		if szType == "CIRCLE" then -- 如果请求圈圈的近期数据 返回NPC的
			szType = "NPC"
		end
		return D.TEMP[szType]
	else
		if szType == "CIRCLE" then -- 如果请求圈圈
			return Circle.GetData()
		end
		return D.FILE[szType]
	end
end

local function GetData(tab, szType, dwID, nLevel)
	D.Log("LOOKUP TYPE:" .. szType .. " ID:" .. dwID .. " LEVEL:" .. nLevel)
	if nLevel then
		for k, v in ipairs(tab) do
			if v.dwID == dwID and (not v.bCheckLevel or v.nLevel == nLevel) then
				CACHE.MAP[szType][dwID][nLevel] = k
				return v
			end
		end
	else
		for k, v in ipairs(tab) do
			if v.dwID == dwID then
				CACHE.MAP[szType][dwID] = k
				return v
			end
		end
	end
end

-- 获取监控数据 注意 不是获取文件内的 如果想找文件内的 请使用 GetFileData
function D.GetData(szType, dwID, nLevel)
	local tab = D.DATA[szType]
	local cache = CACHE.MAP[szType][dwID]
	if cache then
		if nLevel then
			if cache[nLevel] then -- 如果可以直接命中 O(∩_∩)O
				local data = tab[cache[nLevel]]
				if data and data.dwID == dwID and (not data.bheckLevel or data.nLevel == nLevel) then
					D.Log("HIT TYPE:" .. szType .. " ID:" .. dwID .. " LEVEL:" .. nLevel)
					return data
				else
					D.Log("RELOOKUP TYPE:" .. szType .. " ID:" .. dwID .. " LEVEL:" .. nLevel)
					return GetData(tab, szType, dwID, nLevel)
				end
			else -- 不能直接命中的情况下 遍历下面的level /(ㄒoㄒ)/~~
				for k, v in pairs(cache) do
					local data = tab[cache[k]]
					if data and data.dwID == dwID and (not data.bheckLevel or data.nLevel == nLevel) then -- 能直接命中是最好了 ;-)
						D.Log("HIT TYPE:" .. szType .. " ID:" .. dwID .. " LEVEL:" .. nLevel)
						return data
					else -- 不能命中的话 就一次机会 直接lookup
						D.Log("RELOOKUP TYPE:" .. szType .. " ID:" .. dwID .. " LEVEL:" .. nLevel)
						return GetData(tab, szType, dwID, k) -- 这里必须传k 不要乱改 O__O "…"
					end
				end
			end
		else
			local data = tab[cache]
			if data and data.dwID == dwID then
				D.Log("HIT TYPE:" .. szType .. " ID:" .. dwID .. " LEVEL:0")
				return data
			else
				D.Log("RELOOKUP TYPE:" .. szType .. " ID:" .. dwID .. " LEVEL:0")
				return GetData(tab, szType, dwID)
			end
		end
	else
		-- D.Log("IGNORE TYPE:" .. szType .. " ID:" .. dwID .. " LEVEL:" .. (nLevel or 0))
	end
end

function D.GetFileData()
	return D.FILE
end

-- 公开接口
local ui = {
	GetTable    = D.GetTable,
	GetDungeon  = D.GetDungeon,
	GetData     = D.GetData,
	GetFileData = D.GetFileData,
}
DBM_API = setmetatable({}, { __index = ui, __newindex = function() end, __metatable = true })

JH.RegisterEvent("LOADING_END", D.Init)
