---------------------------------------------------------------------
-- �����Դ���
---------------------------------------------------------------------
local ROOT_PATH   = "interface/JH/0Base/"
local DATA_PATH   = "interface/JH/@DATA/"
local SHADOW_PATH = "interface/JH/0Base/item/shadow.ini"
local ADDON_PATH  = "interface/JH/"
local _VERSION_   = 0x0080500
local function GetLang()
	local _, _, szLang = GetVersion()
	local t0 = LoadLUAData(ROOT_PATH .. "lang/default.jx3dat") or {}
	local t1 = LoadLUAData(ROOT_PATH .. "lang/" .. szLang .. ".jx3dat") or {}
	for k, v in pairs(t0) do
		if not t1[k] then
			t1[k] = v
		end
	end
	t1.__import = function(szPath)
		local t2 = LoadLUAData(szPath .. "/" .. szLang .. ".jx3dat") or {}
		for k, v in pairs(t2) do
			t1[k] = v
		end
	end
	local mt = {
		__index = function(t, k) return k end,
		__call = function(t, k, ...) return string.format(t[k] or k, ...) end,
	}
	setmetatable(t1, mt)
	return t1
end
local _L = GetLang()

-- shield sound from mock bg_talk
g_sound_Whisper = g_sound_Whisper or g_sound.Whisper
g_sound.Whisper = nil
setmetatable(g_sound, {
	__index = function(tb, k)
		if k ~= "Whisper" then
			return nil
		end
		local t = GetClientPlayer().GetTalkData()
		if t and #t > 1 and t[1].text == _L["Addon comm."] and t[2].type == "eventlink" then
			return ""
		end
		return g_sound_Whisper
	end
})
---------------------------------------------------------------------
-- �����ʼ
---------------------------------------------------------------------
JH = {
	bDebug = false,
	nChannel = PLAYER_TALK_CHANNEL.RAID,
}
RegisterCustomData("JH.bDebug")
RegisterCustomData("JH.nChannel") -- ����debug�е�TONG
do
	local exp = { GetVersion() }
	if exp and exp[4] == "exp" then
		JH.bDebug = true
	end
end

local _JH = {
	szTitle = _L["JH"],
	tHotkey = {},
	tDelayCall = {},
	tRequest = {},
	tConflict = {},
	tEvent = {},
	tModule = {},
	szShort = _L["JH"],
	nDebug = 2,
	tBuffCache = {},
	tSkillCache = {},
	tMapCache = {},
	tItemCache = {},
	tDungeonList = {},
	aPlayer = {},
	aNpc = {},
	aDoodad = {},
	tBreatheCall = {},
	tItem = { {}, {}, {} },
	tOption = { szOption = _L["JH"] },
	tOption2 = { szOption = _L["JH"] },
	tClass = { _L["General"], _L["RGES"], _L["Other"] },
	szIniFile = ROOT_PATH .. "JH.ini",
	tTalkChannelHeader = {
		[PLAYER_TALK_CHANNEL.NEARBY]        = "/s ",
		[PLAYER_TALK_CHANNEL.FRIENDS]       = "/o ",
		[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = "/a ",
		[PLAYER_TALK_CHANNEL.RAID]          = "/t ",
		[PLAYER_TALK_CHANNEL.BATTLE_FIELD]  = "/b ",
		[PLAYER_TALK_CHANNEL.TONG]          = "/g ",
		[PLAYER_TALK_CHANNEL.SENCE]         = "/y ",
		[PLAYER_TALK_CHANNEL.FORCE]         = "/f ",
		[PLAYER_TALK_CHANNEL.CAMP]          = "/c ",
		[PLAYER_TALK_CHANNEL.WORLD]         = "/h ",
	},
	tForceCol = {
		[0]  = {255, 255, 255},
		[1]  = {255, 178, 95},
		[2]  = {196, 152, 255},
		[3]  = {255, 111, 83},
		[4]  = {89,  224, 232},
		[5]  = {255, 129, 176},
		[6]  = {55,  147, 255},
		[7]  = {121, 183, 54},
		[8]  = {214, 249, 93},
		[9]  = {205, 133, 63},
		[10] = {240, 70,  96},
		[21] = {180, 60,  0}
	},
}

local JH = JH
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
local ipairs, pairs, next = ipairs, pairs, next
local pcall = pcall
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local type, tonumber, tostring = type, tonumber, tostring
local srep = string.rep
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local floor, mmin, mmax, mceil = math.floor, math.min, math.max, math.ceil
local GetClientPlayer, GetPlayer, GetNpc, GetClientTeam = GetClientPlayer, GetPlayer, GetNpc, GetClientTeam
-- ���δ�ӡһ����
JH.print_r = function(root, szPath)
	local cache = {  [root] = "." }
	local function _dump(t,space,name)
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				tinsert(temp, "+" .. key .. " {" .. cache[v] .."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				tinsert(temp, "+" .. key .. _dump(v, space .. (next(t,k) and "|" or " " ) .. srep(" ", #key), new_key))
			else
				tinsert(temp, "+" .. key .. " [" .. tostring(v) .."]")
			end
		end
		return tconcat(temp, "\n"..space)
	end
	if szPath then
		JH.SaveLUAData(szPath, _dump(root, "", ""))
	else
		print(_dump(root, "", ""))
	end
end
-- parse faceicon in talking message
_JH.ParseFaceIcon = function(t)
	if not _JH.tFaceIcon then
		_JH.tFaceIcon = {}
		for i = 1, g_tTable.FaceIcon:GetRowCount() do
			local tLine = g_tTable.FaceIcon:GetRow(i)
			_JH.tFaceIcon[tLine.szCommand] = tLine.dwID
		end
	end
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "faceicon" then
				v.type = "text"
			end
			tinsert(t2, v)
		else
			local nOff, nLen = 1, string.len(v.text)
			while nOff <= nLen do
				local szFace, dwFaceID = nil, nil
				local nPos = StringFindW(v.text, "#", nOff)
				if not nPos then
					nPos = nLen
				else
					for i = nPos + 7, nPos + 2, -1 do
						if i <= nLen then
							local szTest = string.sub(v.text, nPos, i)
							if _JH.tFaceIcon[szTest] then
								szFace, dwFaceID = szTest, _JH.tFaceIcon[szTest]
								nPos = nPos - 1
								break
							end
						end
					end
				end
				if nPos >= nOff then
					tinsert(t2, { type = "text", text = string.sub(v.text, nOff, nPos) })
					nOff = nPos + 1
				end
				if szFace and dwFaceID then
					tinsert(t2, { type = "emotion", text = szFace, id = dwFaceID })
					nOff = nOff + string.len(szFace)
				end
			end
		end
	end
	return t2
end

JH.SetHotKey = function(szGroup)
	HotkeyPanel_Open(szGroup or _JH.szTitle)
end

JH.GetVersion = function()
	local v = _VERSION_
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		floor(v/0x10000)%0x100, floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end

JH.LoadLangPack = _L

JH.GetAddonInfo = function()
	return {
		szName = _L["JH plugins"],
		szVersion = JH.GetVersion(),
		szRootPath = ADDON_PATH,
		szAuthor = _L['JH @ Double Dream Town'],
		szShadowIni = SHADOW_PATH,
		szDataPath = DATA_PATH,
	}
end

-------------------------------------
-- ������忪�ء���ʼ��
-------------------------------------
JH.IsPanelOpened = function()
	return _JH.frame and _JH.frame:IsVisible()
end

JH.OpenPanel = function(szTitle)
	_JH.OpenPanel(szTitle ~= nil)
	if szTitle then
		local nClass, nItem = 0, 0
		for k, v in ipairs(_JH.tItem) do
			if _JH.tClass[k] == szTitle then
				nClass = k
				break
			end
			for kk, vv in ipairs(v) do
				if vv.szTitle == szTitle then
					nClass, nItem = k, kk
				end
			end
		end
		if nClass ~= 0 then
			GUI.Fetch(_JH.frame, "TabBox_" .. nClass):Check(true)
			if nItem ~= 0 then
				GUI.Fetch(_JH.hList, "Button_" .. nItem):Click()
			end
		end
	end
	Station.SetActiveFrame(_JH.frame)
end

-- open
_JH.OpenPanel = function(bDisable)
	local frame = Station.Lookup("Normal/JH") or Wnd.OpenWindow(_JH.szIniFile, "JH")
	frame:Show()
	frame:BringToTop()
	if not bDisable then
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	return frame
end

-- close
_JH.ClosePanel = function(bDisable)
	local frame = Station.Lookup("Normal/JH")
	if frame then
		frame:Hide()
		if not bDisable then
			PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
		end
	end
end

-- toggle
_JH.TogglePanel = function()
	if _JH.frame and _JH.frame:IsVisible() then
		_JH.ClosePanel()
	else
		_JH.OpenPanel()
	end
end
JH.ClosePanel = _JH.ClosePanel
JH.TogglePanel = _JH.TogglePanel

-- register conflict checker
_JH.RegisterConflictCheck = function(fnAction)
	_JH.tConflict = _JH.tConflict or {}
	tinsert(_JH.tConflict, fnAction)
end
_JH.tApplyPointKey = {}
_JH.ApplyPointCallback = function(data, nX, nY)
	if not nX or (nX > 0 and nX < 0.00001 and nY > 0 and nY < 0.00001) then
		nX, nY = nil, nil
	else
		nX, nY = Station.AdjustToOriginalPos(nX, nY)
	end
	if data.szKey then
		_JH.tApplyPointKey[data.szKey] = nil
	end
	local res, err = pcall(data.fnAction, nX, nY)
	if not res then
		JH.Debug("ApplyScreenPoint ERROR: " .. err)
	end
end
-------------------------------------
-- ��������������
-------------------------------------
-- update scrollbar
_JH.UpdateListScroll = function()
	local handle, scroll = _JH.hList, _JH.hScroll
	local w, h = handle:GetSize()
	local wA, hA = handle:GetAllItemSize()
	local nStep = mceil((hA - h) / 10)
	scroll:SetStepCount(nStep)
	if nStep > 0 then
		scroll:Show()
		scroll:GetParent():Lookup("Btn_Up"):Show()
		scroll:GetParent():Lookup("Btn_Down"):Show()
	else
		scroll:Hide()
		scroll:GetParent():Lookup("Btn_Up"):Hide()
		scroll:GetParent():Lookup("Btn_Down"):Hide()
	end
end

-- updae detail content
_JH.UpdateDetail = function(i, data)
	local win = GUI.Fetch(_JH.frame, "Wnd_Detail")
	if win then win:Remove() end
	if not data then
		data = {}
		if JH_About then
			if not i then	-- default
				data.fn = {
					OnPanelActive = JH_About.OnPanelActive,
					GetAuthorInfo = JH_About.GetAuthorInfo,
				}
			elseif JH_About.OnTaboxCheck then	-- switch
				data.fn = {
					OnPanelActive = function(frame) JH_About.OnTaboxCheck(frame, i, _JH.tClass[i]) end,
					GetAuthorInfo = JH_About.GetAuthorInfo
				}
			end
		end
	end
	win = GUI.Append(_JH.frame, "WndActionWindow", "Wnd_Detail")
	win:Size(_JH.hContent:GetSize()):Pos(_JH.hContent:GetRelPos())
	if type(data.fn) == "table" then
		local szInfo = ""
		if data.fn.GetAuthorInfo then
			szInfo = "-- by " .. data.fn.GetAuthorInfo() .. " --"
		end
		_JH.hTotal:Lookup("Text_Author"):SetText(szInfo)
		if data.fn.OnPanelActive then
			data.fn.OnPanelActive(win:Raw())
			win.handle:FormatAllItemPos()
		end
		win.fnDestroy = data.fn.OnPanelDeactive
	end
end

-- create menu item
_JH.NewListItem = function(i, data, dwClass)
	local handle = _JH.hList
	local item = GUI.Append(handle, "BoxButton", "Button_" .. i)
	item:Icon(data.dwIcon):Text(data.szTitle):Click(function()
		_JH.UpdateDetail(dwClass, data)
	end, true, true)
	return item
end

-- update menu list
_JH.UpdateListInfo = function(nIndex)
	local nX, nY = 0, 14
	_JH.hList:Clear()
	_JH.hScroll:ScrollHome()
	_JH.UpdateDetail(nIndex)
	for k, v in ipairs(_JH.tItem[nIndex]) do
		local item = _JH.NewListItem(k, v, nIndex)
		item:Pos(nX, nY)
		nY = nY + 50
	end
	_JH.UpdateListScroll()
end

-- update tab list
_JH.UpdateTabBox = function(frame)
	local nX, nY, first = 25, 52, nil
	for k, v in ipairs(_JH.tClass) do
		if table.getn(_JH.tItem[k]) > 0 then
			local tab = frame:Lookup("TabBox_" .. k)
			if not tab then
				tab = GUI.Append(frame, "WndTabBox", "TabBox_" .. k, { group = "Nav" })
			else
				tab = GUI.Fetch(tab)
			end
			tab:Text(v):Pos(nX, nY):Click(function(bChecked)
				if bChecked then
					_JH.UpdateListInfo(k)
				end
			end):Check(false)
			if not first then
				first = tab
			end
			local nW, _ = tab:Size()
			nX = nX + mceil(nW) + 10
		end
	end
	if first then
		first:Check(true)
	end
end

_JH.EventHandler = function(szEvent)
	local tEvent = 	_JH.tEvent[szEvent]
	if tEvent then
		for k, v in pairs(tEvent) do
			local res, err = pcall(v)
			if not res then
				JH.Debug("EVENT#" .. szEvent .. "." .. k .." ERROR: " .. err)
			end
		end
	end
end

JH.OnFrameCreate = function()
	-- var
	_JH.frame = this
	_JH.hTotal = this:Lookup("Wnd_Content", "")
	_JH.hScroll = this:Lookup("Wnd_Content/Scroll_List")
	_JH.hList = _JH.hTotal:Lookup("Handle_List")
	_JH.hContent = _JH.hTotal:Lookup("Handle_Content")
	_JH.hBox = _JH.hTotal:Lookup("Box_1")
	-- title
	local szTitle =_JH.szTitle .. " v" ..  JH.GetVersion()
	_JH.hTotal:Lookup("Text_Title"):SetText(szTitle)
	-- position
	this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
	-- update list/detail
	_JH.UpdateTabBox(this)
end

JH.OnFrameBreathe = function()
	-- run breathe calls
	local nFrame = GetLogicFrameCount()
	for k, v in pairs(_JH.tBreatheCall) do
		if nFrame >= v.nNext then
			v.nNext = nFrame + v.nFrame
			local res, err = pcall(v.fnAction)
			if not res then
				JH.Debug("BreatheCall#" .. k .." ERROR: " .. err)
			end
		end
	end
	local nTime = GetTime()
	for k = #_JH.tDelayCall, 1, -1 do
		local v = _JH.tDelayCall[k]
		if v.nTime <= nTime then
			local res, err = pcall(v.fnAction)
			if not res then
				Output("DelayCall#" .. k .." ERROR: " .. err)
			end
			tremove(_JH.tDelayCall, k)
		end
	end

	-- run remote request (10s)
	if not _JH.nRequestExpire or _JH.nRequestExpire < nTime then
		if _JH.nRequestExpire then
			local r = tremove(_JH.tRequest, 1)
			if r then
				pcall(r.fnAction)
			end
			_JH.nRequestExpire = nil
		end
		if #_JH.tRequest > 0 then
			local page = Station.Lookup("Normal/JH/Page_1")
			if page then
				page:Navigate(_JH.tRequest[1].szUrl)
			end
			_JH.nRequestExpire = GetTime() + 15000
		end
	end
end

JH.OnDocumentComplete = function()
	local r = tremove(_JH.tRequest, 1)
	if r then
		_JH.nRequestExpire = nil
		pcall(r.fnAction, this:GetLocationName(), this:GetDocument())
	end
end
-- key down
JH.OnFrameKeyDown = function()
	if GetKeyName(Station.GetMessageKey()) == "Esc" then
		_JH.ClosePanel()
		return 1
	end
	return 0
end

JH.Debug = function(szMsg)
	if JH.bDebug then
		OutputMessage("MSG_SYS","[JH_DEBUG] " .. szMsg .."\n")
	end
end

-- ����ģ��ID��ȡ���� û�й���
JH.GetTemplateName = function(tar, bEmployer)
	if not tar then
		return _L["Unknown"]
	end
	local szName = tar.szName
	if not tar.dwID or not IsPlayer(tar.dwID) then
		if szName == "" then
			szName = Table_GetNpcTemplateName(tar.dwTemplateID)
		end
		if tar.dwEmployer and tar.dwEmployer ~= 0 and szName == Table_GetNpcTemplateName(tar.dwTemplateID) and bEmployer then
			local emp = GetPlayer(tar.dwEmployer)
			if not emp then
				szName =  g_tStrings.STR_SOME_BODY .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
			else
				szName = emp.szName .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
			end
		end
		if JH.Trim(szName) == "" then
			szName = tostring(tar.dwTemplateID)
		end
	end
	return szName
end

JH.RegisterEvent = function(szEvent, fnAction)
	local szKey = nil
	local nPos = StringFindW(szEvent, ".")
	if nPos then
		szKey = string.sub(szEvent, nPos + 1)
		szEvent = string.sub(szEvent, 1, nPos - 1)
	end
	if not _JH.tEvent[szEvent] then
		_JH.tEvent[szEvent] = {}
		RegisterEvent(szEvent, function() _JH.EventHandler(szEvent) end)
	end
	local tEvent = _JH.tEvent[szEvent]
	if fnAction then
		if not szKey then
			tinsert(tEvent, fnAction)
		else
			tEvent[szKey] = fnAction
		end
		JH.Debug3("RegisterEvent # " .. szEvent)
	else
		if not szKey then
			_JH.tEvent[szEvent] = {}
		else
			tEvent[szKey] = nil
		end
		JH.Debug3("UnRegisterEvent # " .. szEvent)
	end
end

JH.UnRegisterEvent = function(szEvent)
	JH.RegisterEvent(szEvent, nil)
end

JH.RegisterCustomData = function(szVarPath)
	if _G and type(_G[szVarPath]) == "table" then
		for k, _ in pairs(_G[szVarPath]) do
			RegisterCustomData(szVarPath .. "." .. k)
		end
	else
		RegisterCustomData(szVarPath)
	end
end

-- ��ʼ��һ��ģ��
JH.RegisterInit = function(key, ...)
	local events = { ... }
	if _JH.tModule[key] and IsEmpty(events) then
		for k, v in ipairs(_JH.tModule[key]) do
			if v[1] == "Breathe" then
				JH.UnBreatheCall(key)
			else
				JH.UnRegisterEvent(string.format("%s.%s", v[1], key))
			end
		end
		_JH.tModule[key] = nil
		JH.Debug2("UnInit # "  .. key)
	elseif #events > 0 then
		_JH.tModule[key] = events
		for k, v in ipairs(_JH.tModule[key]) do
			if v[1] == "Breathe" then
				JH.BreatheCall(key, v[2], v[3] or nil)
			else
				JH.RegisterEvent(string.format("%s.%s", v[1], key), v[2])
			end
		end
		JH.Debug2("Init # "  .. key .. " # Events # " .. #_JH.tModule[key])
	end
end

JH.UnRegisterInit = function(key)
	JH.RegisterInit(key)
end

JH.GetTarget = function(dwType, dwID)
	if not dwType then
		local me = GetClientPlayer()
		if me then
			dwType, dwID = me.GetTarget()
		else
			dwType, dwID = TARGET.NO_TARGET, 0
		end
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	if dwID <= 0 or dwType == TARGET.NO_TARGET then
		return nil, TARGET.NO_TARGET
	elseif dwType == TARGET.PLAYER then
		return GetPlayer(dwID), TARGET.PLAYER
	elseif dwType == TARGET.DOODAD then
		return GetDoodad(dwID), TARGET.DOODAD
	else
		return GetNpc(dwID), TARGET.NPC
	end
end

JH.GetForceColor = function(dwForce)
	if _JH.tForceCol[dwForce] then
		return unpack(_JH.tForceCol[dwForce])
	else
		return 255,255,255
	end
end

JH.CanTalk = function(nChannel)
	for _, v in ipairs({"WHISPER", "TEAM", "RAID", "BATTLE_FIELD", "NEARBY", "TONG", "TONG_ALLIANCE" }) do
		if nChannel == PLAYER_TALK_CHANNEL[v] then
			return true
		end
	end
	return false
end

JH.SwitchChat = function(nChannel)
	local szHeader = _JH.tTalkChannelHeader[nChannel]
	if szHeader then
		SwitchChatChannel(szHeader)
	elseif type(nChannel) == "string" then
		SwitchChatChannel("/w " .. nChannel .. " ")
	end
end

JH.Talk = function(nChannel, szText, bNoEmotion, bSaveDeny, bNotLimit)
	local szTarget, me = "", GetClientPlayer()
	-- channel
	if not nChannel then
		nChannel = JH.nChannel
	elseif type(nChannel) == "string" then
		if not szText then
			szText = nChannel
			nChannel = JH.nChannel
		elseif type(szText) == "number" then
			szText, nChannel = nChannel, szText
		else
			szTarget = nChannel
			nChannel = PLAYER_TALK_CHANNEL.WHISPER
		end
	elseif nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	elseif type(nChannel) == "table" then
		szText = nChannel
		nChannel = JH.nChannel
	end
	-- say body
	local tSay = nil
	if type(szText) == "table" then
		tSay = szText
	else
		local tar = JH.GetTarget(me.GetTarget())
		szText = string.gsub(szText, "%$zj", me.szName)
		if tar then
			szText = string.gsub(szText, "%$mb", tar.szName)
		end
		if wstring.len(szText) > 150 and not bNotLimit then
			szText = wstring.sub(szText, 1, 150)
		end
		tSay = {{ type = "text", text = szText .. "\n"}}
	end
	if not bNoEmotion then
		tSay = _JH.ParseFaceIcon(tSay)
	end
	me.Talk(nChannel, szTarget, tSay)
	if bSaveDeny and not JH.CanTalk(nChannel) then
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		edit:ClearText()
		for _, v in ipairs(tSay) do
			if v.type == "text" then
				edit:InsertText(v.text)
			else
				edit:InsertObj(v.text, v)
			end
		end
		-- change to this channel
		JH.SwitchChat(nChannel)
	end
end

JH.Talk2 = function(nChannel, szText, bNoEmotion)
	JH.Talk(nChannel, szText, bNoEmotion, true)
end
JH.BgTalk = function(nChannel, ...)
	local tSay = { { type = "text", text = _L["Addon comm."] } }
	local tArg = { ... }
	-- compatiable with offcial bg channel msg of team
	if nChannel == PLAYER_TALK_CHANNEL.RAID or nChannel == PLAYER_TALK_CHANNEL.TEAM then
		tSay[1].text = "BG_CHANNEL_MSG"
	end
	for _, v in ipairs(tArg) do
		if v == nil then
			break
		end
		tinsert(tSay, { type = "eventlink", name = "", linkinfo = tostring(v) })
	end
	JH.Talk(nChannel, tSay, true)
end

JH.BgHear = function(szKey,bIgnore)
	local me = GetClientPlayer()
	local tSay = me.GetTalkData()
	if tSay and (arg0 ~= me.dwID or bIgnore) and #tSay > 1 and (tSay[1].text == _L["Addon comm."] or tSay[1].text == "BG_CHANNEL_MSG") and tSay[2].type == "eventlink" then
		local tData, nOff = {}, 2
		if szKey then
			if tSay[nOff].linkinfo ~= szKey then
				return nil
			end
			nOff = nOff + 1
		end

		for i = nOff, #tSay do
			tinsert(tData, tSay[i].linkinfo)
		end

		return tData
	end
end

JH.IsParty = function(dwID)
	return GetClientPlayer().IsPlayerInMyParty(dwID)
end

JH.WhisperToTeamMember = function(msg)
	local me = GetClientPlayer()
	if me and me.IsInParty() then
		local team = GetClientTeam()
		for _,v in ipairs(team.GetTeamMemberList()) do
			local szName = team.GetClientTeamMemberName(v)
			JH.Talk(szName,msg)
		end
	end
end

JH.GetAllPlayer = function(nLimit)
	local aPlayer = {}
	for k, _ in pairs(_JH.aPlayer) do
		local p = GetPlayer(k)
		if not p then
			_JH.aPlayer[k] = nil
		elseif p.szName ~= "" then
			tinsert(aPlayer, p)
			if nLimit and #aPlayer == nLimit then
				break
			end
		end
	end
	return aPlayer
end

JH.GetAllPlayerID = function()
	return _JH.aPlayer
end

JH.GetAllNpc = function(nLimit)
	local aNpc = {}
	for k, _ in pairs(_JH.aNpc) do
		local p = GetNpc(k)
		if not p then
			_JH.aNpc[k] = nil
		else
			tinsert(aNpc, p)
			if nLimit and #aNpc == nLimit then
				break
			end
		end
	end
	return aNpc
end

JH.GetAllNpcID = function()
	return _JH.aNpc
end

JH.GetAllDoodad = function(nLimit)
	local aDoodad = {}
	for k, _ in pairs(_JH.aDoodad) do
		local p = GetDoodad(k)
		if not p then
			_JH.aDoodad[k] = nil
		else
			tinsert(aDoodad, p)
			if nLimit and #aDoodad == nLimit then
				break
			end
		end
	end
	return aDoodad
end

JH.GetAllDoodadID = function()
	return _JH.aDoodad
end

JH.GetDistance = function(nX, nY, nZ)
	local me = GetClientPlayer()
	if not nY and not nZ then
		local tar = nX
		nX, nY, nZ = tar.nX, tar.nY, tar.nZ
	elseif not nZ then
		return floor(((me.nX - nX) ^ 2 + (me.nY - nY) ^ 2) ^ 0.5)/64
	end
	return floor(((me.nX - nX) ^ 2 + (me.nY - nY) ^ 2 + (me.nZ/8 - nZ/8) ^ 2) ^ 0.5)/64
end

-- �ϸ��ж�25�˱�
JH.IsInDungeon = function()
	if IsEmpty(_JH.tDungeonList) then
		for k,v in ipairs(GetMapList()) do
			local a = g_tTable.DungeonInfo:Search(v)
			if a and a.dwClassID == 3 then
				_JH.tDungeonList[a.dwMapID] = true
			end
		end
	end
	local me = GetClientPlayer()
	return _JH.tDungeonList[me.GetMapID()] or false
end

-- ֻ�Ǹ��ݵ�ͼ����
JH.IsInDungeon2 = function()
	local me = GetClientPlayer()
	if not me then return end
	local scene = me.GetScene()
	return scene.nType == 1 or scene.nType == 4
end

JH.ApplyTopPoint = function(fnAction, tar, nH, szKey)
	if type(tar) == "number" then
		tar = JH.GetTarget(tar)
	end
	if not tar then
		return fnAction()
	end
	if type(nH) == "string" then
		szKey, nH = nH, nil
	end
	if szKey and IsMultiThread() then
		if _JH.tApplyPointKey[szKey] then
			return
		end
		_JH.tApplyPointKey[szKey] = true
	else
		szKey = nil
	end
	if not nH then
		PostThreadCall(_JH.ApplyPointCallback, { fnAction = fnAction, szKey = szKey },
			"Scene_GetCharacterTopScreenPos", tar.dwID)
	else
		if nH < 64 then
			nH = nH * 64
		end
		PostThreadCall(_JH.ApplyPointCallback, { fnAction = fnAction, szKey = szKey },
			"Scene_GameWorldPositionToScreenPoint", tar.nX, tar.nY, tar.nZ + nH, false)
	end
end

-- button click
JH.OnLButtonClick = function()
	local szName = this:GetName()
	if szName == "Btn_Close" then
		_JH.ClosePanel()
	elseif szName == "Btn_Up" then
		_JH.hScroll:ScrollPrev(1)
	elseif szName == "Btn_Down" then
		_JH.hScroll:ScrollNext(1)
	end
end

-- scrolls
JH.OnScrollBarPosChanged = function()
	if this:GetName() ~= "Scroll_List" then -- ���������Ҳ����������
		return
	end
	local handle, frame = _JH.hList, this:GetParent()
	local nPos = this:GetScrollPos()
	if nPos == 0 then
		frame:Lookup("Btn_Up"):Enable(0)
	else
		frame:Lookup("Btn_Up"):Enable(1)
	end
	if nPos == this:GetStepCount() then
		frame:Lookup("Btn_Down"):Enable(0)
	else
		frame:Lookup("Btn_Down"):Enable(1)
	end
    handle:SetItemStartRelPos(0, - nPos * 10)
end

JH.JsonToTable = function(szJson)
	local result, err = JH.JsonDecode(JH.UrlDecode(szJson))
	if err then
		JH.Debug(err)
		return JH.Alert("json_decode Error")
	end
	if type(result) ~= "table" then
		return JH.Alert("data is invalid")
	end
	local data = {}
	for k, v in pairs(result) do
		local key = tonumber(k) or k
		data[key] = {}
		if type(v) == "table" then
			JH.TableFIXNumber(data[key], v)
		else
			data[key] = v
		end
	end
	return data
end

JH.TableFIXNumber = function(self, tab)
	for k,v in pairs(tab) do
		local key = tonumber(k) or k
		self[key] = {}
		if type(v) == "table" then
			JH.TableFIXNumber(self[key], v)
		else
			self[key] = v
		end
	end
end

JH.Sysmsg = function(szMsg, szHead, szType)
	szHead = szHead or _JH.szShort
	szType = szType or "MSG_SYS"
	OutputMessage(szType, " [" .. szHead .. "] " .. szMsg .. "\n")
end
-- err message
JH.Sysmsg2 = function(szMsg, szHead, col)
	szHead = szHead or _JH.szShort
	local r, g, b = 255, 0, 0
	if col then r, g, b = unpack(col) end
	OutputMessage("MSG_SYS", " [" .. szHead .. "] " .. szMsg .. "\n", false, 10, { r, g, b })
end

JH.Debug = function(szMsg, szHead, nLevel)
	nLevel = nLevel or 1
	if JH.bDebug and _JH.nDebug >= nLevel then
		if nLevel == 3 then szMsg = "### " .. szMsg
		elseif nLevel == 2 then szMsg = "=== " .. szMsg
		else szMsg = "-- " .. szMsg end
		JH.Sysmsg(szMsg, szHead)
	end
end
JH.Debug2 = function(szMsg, szHead) JH.Debug(szMsg, szHead, 2) end
JH.Debug3 = function(szMsg, szHead) JH.Debug(szMsg, szHead, 3) end


JH.Alert = function(szMsg, fnAction, szSure)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3, szMessage = szMsg, szName = "JH_Alert",
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		},
	}
	MessageBox(tMsg)
end

JH.Confirm = function(szMsg, fnAction, fnCancel, szSure, szCancel)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3, szMessage = szMsg, szName = "JH_Confirm",
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		}, {
			szOption = szCancel or g_tStrings.STR_HOTKEY_CANCEL,
			fnAction = fnCancel,
		},
	}
	MessageBox(tMsg)
end

JH.GetLogicTime = function()
	return GetLogicFrameCount() / GLOBAL.GAME_FPS
end

JH.GetEndTime = function(nEndFrame)
	return (nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
end

JH.GetBuffName = function(dwBuffID, dwLevel)
	local xKey = dwBuffID
	if dwLevel then
		xKey = dwBuffID .. "_" .. dwLevel
	end
	if not _JH.tBuffCache[xKey] then
		local tLine = Table_GetBuff(dwBuffID, dwLevel or 1)
		if tLine then
			_JH.tBuffCache[xKey] = { tLine.szName, tLine.dwIconID }
		else
			local szName = "BUFF#" .. dwBuffID
			if dwLevel then
				szName = szName .. ":" .. dwLevel
			end
			_JH.tBuffCache[xKey] = { szName, -1 }
		end
	end
	return unpack(_JH.tBuffCache[xKey])
end

JH.GetSkillName = function(dwSkillID, dwLevel)
	if not _JH.tSkillCache[dwSkillID] then
		local tLine = Table_GetSkill(dwSkillID, dwLevel)
		if tLine and tLine.dwSkillID > 0 and tLine.bShow
			and (StringFindW(tLine.szDesc, "_") == nil  or StringFindW(tLine.szDesc, "<") ~= nil)
		then
			_JH.tSkillCache[dwSkillID] = { tLine.szName, tLine.dwIconID }
		else
			local szName = "SKILL#" .. dwSkillID
			if dwLevel then
				szName = szName .. ":" .. dwLevel
			end
			_JH.tSkillCache[dwSkillID] = { szName, 13 }
		end
	end
	return unpack(_JH.tSkillCache[dwSkillID])
end

JH.GetItemName = function(nUiId)
	if not _JH.tItemCache[nUiId] then
		local szName = Table_GetItemName(nUiId)
		local nIcon = Table_GetItemIconID(nUiId)
		if szName ~= "" and nIocn ~= -1 then
			_JH.tItemCache[nUiId] = { szName, nIcon }
		else
			_JH.tItemCache[nUiId] = { "ITEM#" .. nUiId, 1435 }
		end
	end
	return unpack(_JH.tItemCache[nUiId])
end

JH.GetMapName = function(dwMapID)
	if not _JH.tMapCache[dwMapID] then
		local szName = Table_GetMapName(dwMapID)
		if szName ~= "" then
			_JH.tMapCache[dwMapID] = tostring(dwMapID)
		else
			_JH.tMapCache[dwMapID] = szName
		end
	end
	return _JH.tMapCache[dwMapID]
end

JH.HasBuff = function(dwBuffID, bCanCancel, me)
	if not me and bCanCancel ~= nil and type(bCanCancel) ~= "boolean" then
		me, bCanCancel = bCanCancel, me
	end
	me = me or GetClientPlayer()
	local tBuff = {}
	if type(dwBuffID) == "number" then
		tBuff[dwBuffID] = true
	elseif type(dwBuffID) == "table" then
		for k, v in ipairs(dwBuffID) do
			tBuff[v] = true
		end
	end
	if me then
		local nCount = me.GetBuffCount()
		for i = 1, nCount do
			local _dwID, _nLevel, _bCanCancel = me.GetBuff(i - 1)
			if bCanCancel == nil or bCanCancel == _bCanCancel then
				if tBuff[_dwID] then
					local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = me.GetBuff(i - 1)
					return true, {
						dwID = dwID, nLevel = nLevel, bCanCancel = bCanCancel, nEndFrame = nEndFrame,
						nIndex = nIndex, nStackNum = nStackNum, dwSkillSrcID = dwSkillSrcID, bValid = bValid,
					}
				end
			end
		end
	end
	return false, {}
end

JH.GetBuffTimeString = function(nTime, limit)
	limit = limit or 5999
	nTime = tonumber(nTime) or 0
	if nTime > limit then
		nTime = limit
	end
	if nTime > 60 then
		return string.format("%d'%d\"", nTime / 60, nTime % 60)
	else
		return floor(nTime) .. "\""
	end
end

JH.GetBuffList = function(tar)
	tar = tar or GetClientPlayer()
	local aBuff = {}
	local nCount = tar.GetBuffCount()
	for i = 1, nCount, 1 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = tar.GetBuff(i - 1)
		if dwID then
			tinsert(aBuff, {
				dwID = dwID, nLevel = nLevel, bCanCancel = bCanCancel, nEndFrame = nEndFrame,
				nIndex = nIndex, nStackNum = nStackNum, dwSkillSrcID = dwSkillSrcID, bValid = bValid,
			})
		end
	end
	return aBuff
end


JH.WalkAllBuff = function(tar, fnAction)
	if type(tar) == "function" then
		fnAction = tar
		tar = GetClientPlayer()
	end
	local nCount = tar.GetBuffCount()
	for i = 1, nCount, 1 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = tar.GetBuff(i - 1)
		if dwID then
			local res, ret = pcall(fnAction, dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid)
			if res == true and ret == false then
				break
			end
		end
	end
end

JH.SaveLUAData = function(szPath, data)
	JH.Debug3(_L["SaveLUAData # "] ..  DATA_PATH .. szPath)
	return SaveLUAData(DATA_PATH .. szPath, data)
end

JH.LoadLUAData = function(szPath)
	JH.Debug3(_L["LoadLUAData # "] ..  DATA_PATH .. szPath)
	return LoadLUAData(DATA_PATH .. szPath)
end

JH.IsLeader = function()
	local hTeam = GetClientTeam()
	local hPlayer = GetClientPlayer()
	return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID
end

JH.AddHotKey = function(szName, szTitle, fnAction)
	if string.sub(szName, 1, 3) ~= "JH_" then
		szName = "JH_" .. szName
	end
	tinsert(_JH.tHotkey, { szName = szName, szTitle = szTitle, fnAction = fnAction })
end

JH.GetTarget = function(dwType, dwID)
	if not dwType then
		local me = GetClientPlayer()
		if me then
			dwType, dwID = me.GetTarget()
		else
			dwType, dwID = TARGET.NO_TARGET, 0
		end
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	if dwID <= 0 or dwType == TARGET.NO_TARGET then
		return nil, TARGET.NO_TARGET
	elseif dwType == TARGET.PLAYER then
		return GetPlayer(dwID), TARGET.PLAYER
	elseif dwType == TARGET.DOODAD then
		return GetDoodad(dwID), TARGET.DOODAD
	else
		return GetNpc(dwID), TARGET.NPC
	end
end

_JH.GetMainMenu = function()
	return {
		szOption = _L["JH"],
		fnAction = _JH.TogglePanel,
		bCheck = true,
		bChecked = _JH.frame:IsVisible(),
		szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
		nFrame = 105, nMouseOverFrame = 106,
		szLayer = "ICON_RIGHT",
		fnClickIcon = _JH.TogglePanel
	}
end

_JH.GetPlayerAddonMenu = function()
	local menu = _JH.GetMainMenu()
	tinsert(menu,{ szOption = _L["JH"] .. " v" .. JH.GetVersion(), bDisable = true })
	tinsert(menu,{ bDevide = true })
	for i = 1, #_JH.tOption, 1 do
		local m = _JH.tOption[i]
		if type(m) == "function" then m = m() end
		tinsert(menu, m)
	end
	tinsert(menu, { bDevide = true })
	for i = 1, #_JH.tOption2, 1 do
		local m = _JH.tOption2[i]
		if type(m) == "function" then m = m() end
		tinsert(menu, m)
	end
	
	return { menu }
end

_JH.GetAddonMenu = function()
	local menu = _JH.GetMainMenu()
	tinsert(menu,{ szOption = _L["JH"] .. " v" .. JH.GetVersion(), bDisable = true })
	tinsert(menu,{ bDevide = true })
	for i = 1, #_JH.tOption2, 1 do
		local m = _JH.tOption2[i]
		if type(m) == "function" then m = m() end
		tinsert(menu, m)
	end
	return { menu }
end

JH.PlayerAddonMenu = function(tMenu)
	tinsert(_JH.tOption, tMenu)
end

JH.AddonMenu = function(tMenu)
	tinsert(_JH.tOption2, tMenu)
end

-- ����ȫ��shadow������ �������Է�ֹǰ��˳�򸲸�
JH.GetShadowHandle = function(szName)
	local sh = Station.Lookup("Lowest/JH_Shadows") or Wnd.OpenWindow(ROOT_PATH .. "item/JH_Shadows.ini", "JH_Shadows")
	if not sh:Lookup("", szName) then
		sh:Lookup("", ""):AppendItemFromString(string.format("<handle> name=\"%s\" </handle>", szName))
	end
	JH.Debug3("Create sh # " .. szName)
	return sh:Lookup("", szName)
end

JH.RegisterEvent("PLAYER_ENTER_GAME",function()
	_JH.OpenPanel(true):Hide()
	-- ע���ݼ�
	Hotkey.AddBinding("JH_Total", _L["JH"], _L["JH"], _JH.TogglePanel , nil)
	for _, v in ipairs(_JH.tHotkey) do
		Hotkey.AddBinding(v.szName, v.szTitle, "", v.fnAction, nil)
	end
	-- ע�����ͷ��˵�
	Player_AppendAddonMenu( { _JH.GetPlayerAddonMenu } )
	-- ע�����Ͻǲ˵�
	TraceButton_AppendAddonMenu( { _JH.GetAddonMenu } )
end)

JH.RegisterEvent("LOADING_END", function()
	-- reseting frame count (FIXED BUG FOR Cross Server)
	for k, v in pairs(_JH.tBreatheCall) do
		v.nNext = GetLogicFrameCount()
	end
end)

JH.RegisterEvent("PLAYER_ENTER_SCENE", function() _JH.aPlayer[arg0] = true end)
JH.RegisterEvent("PLAYER_LEAVE_SCENE", function() _JH.aPlayer[arg0] = nil end)
JH.RegisterEvent("NPC_ENTER_SCENE", function() _JH.aNpc[arg0] = true end)
JH.RegisterEvent("NPC_LEAVE_SCENE", function() _JH.aNpc[arg0] = nil end)
JH.RegisterEvent("DOODAD_ENTER_SCENE", function() _JH.aDoodad[arg0] = true end)
JH.RegisterEvent("DOODAD_LEAVE_SCENE", function() _JH.aDoodad[arg0] = nil end)
JH.RegisterEvent("PLAYER_TALK", function()
	local me = GetClientPlayer()
	if not me then return end
	local t = me.GetTalkData()
	if t and arg0 ~= me.dwID and #t> 1 and t[1].text == _L["Addon comm."] and t[2].type == "eventlink" then
		FireUIEvent("ON_BG_CHANNEL_MSG", arg0, arg1, arg2, arg3)
	end
end)

---------------------------------------------------------------------
-- ���ú���
---------------------------------------------------------------------
JH.Trim = function(szText)
	if not szText or szText == "" then
		return ""
	end
	return (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
end
JH.UrlEncode = function(szText)
	local str = szText:gsub("([^0-9a-zA-Z ])", function (c) return string.format ("%%%02X", string.byte(c)) end)
	str = str:gsub(" ", "+")
	return str
end

JH.UrlDecode = function(szText)
	return szText:gsub("+", " "):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
end

JH.AscIIEncode = function(szText)
	return szText:gsub('(.)',function(s) return string.format("%02x",s:byte()) end)
end

JH.AscIIDecode = function(szText)
	return szText:gsub('([0-9a-f][0-9a-f])',function(s) return string.char(tonumber(s, 16)) end)
end

JH.RemoteRequest = function(szUrl, fnAction)
	tinsert(_JH.tRequest, { szUrl = szUrl, fnAction = fnAction })
end

JH.Confirm = function(szMsg, fnAction, fnCancel, szSure, szCancel)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3, szMessage = szMsg, szName = "JH_Confirm",
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		}, {
			szOption = szCancel or g_tStrings.STR_HOTKEY_CANCEL,
			fnAction = fnCancel,
		},
	}
	MessageBox(tMsg)
end

JH.DelayCall = function(nDelay, fnAction)
	local nTime = nDelay + GetTime()
	tinsert(_JH.tDelayCall, { nTime = nTime, fnAction = fnAction })
end

JH.Split = function(szFull, szSep)
	local nOff, tResult = 1, {}
	while true do
		local nEnd = StringFindW(szFull, szSep, nOff)
		if not nEnd then
			tinsert(tResult, string.sub(szFull, nOff, string.len(szFull)))
			break
		else
			tinsert(tResult, string.sub(szFull, nOff, nEnd - 1))
			nOff = nEnd + string.len(szSep)
		end
	end
	return tResult
end
JH.DoMessageBox = function(szName, i)
	local frame = Station.Lookup("Topmost2/MB_" .. szName) or Station.Lookup("Topmost/MB_" .. szName)
	if frame then
		i = i or 1
		local btn = frame:Lookup("Wnd_All/Btn_Option" .. i)
		if btn and btn:IsEnabled() then
			if btn.fnAction then
				if frame.args then
					btn.fnAction(unpack(frame.args))
				else
					btn.fnAction()
				end
			elseif frame.fnAction then
				if frame.args then
					frame.fnAction(i, unpack(frame.args))
				else
					frame.fnAction(i)
				end
			end
			frame.OnFrameDestroy = nil
			CloseMessageBox(szName)
		end
	end
end

JH.BreatheCall = function(szKey, fnAction, nTime)
	local key = StringLowerW(szKey)
	if type(fnAction) == "function" then
		local nFrame = 1
		if nTime and nTime > 0 then
			nFrame = mceil(nTime / 62.5)
		end
		_JH.tBreatheCall[key] = { fnAction = fnAction, nNext = GetLogicFrameCount() + 1, nFrame = nFrame }
		JH.Debug3("BreatheCall # " .. szKey .. " # " .. nFrame)
	else
		_JH.tBreatheCall[key] = nil
		JH.Debug3("UnBreatheCall # " .. szKey)
	end
end
JH.UnBreatheCall = function(szKey)
	JH.BreatheCall(szKey)
end
local _GUI = {}
---------------------------------------------------------------------
-- ���ص� UI �������
---------------------------------------------------------------------

-------------------------------------
-- Base object class
-------------------------------------
_GUI.Base = class()

-- (userdata) Instance:Raw()		-- ��ȡԭʼ����/�������
function _GUI.Base:Raw()
	if self.type == "Label" then
		return self.txt
	end
	return self.wnd or self.edit or self.self
end

-- (void) Instance:Remove()		-- ɾ�����
function _GUI.Base:Remove()
	if self.fnDestroy then
		local wnd = self.wnd or self.self
		self.fnDestroy(wnd)
	end
	local hP = self.self:GetParent()
	if hP.___uis then
		local szName = self.self:GetName()
		hP.___uis[szName] = nil
	end
	if self.type == "WndFrame" then
		Wnd.CloseWindow(self.self)
	elseif string.sub(self.type, 1, 3) == "Wnd" then
		self.self:Destroy()
	else
		hP:RemoveItem(self.self:GetIndex())
	end
end

-- (string) Instance:Name()					-- ȡ������
-- (self) Instance:Name(szName)			-- ��������Ϊ szName ������������֧�ִ��ӵ���
function _GUI.Base:Name(szName)
	if not szName then
		return self.self:GetName()
	end
	self.self:SetName(szName)
	return self
end

-- (self) Instance:Toggle([boolean bShow])			-- ��ʾ/����
function _GUI.Base:Toggle(bShow)
	if bShow == false or (not bShow and self.self:IsVisible()) then
		self.self:Hide()
	else
		self.self:Show()
		if self.type == "WndFrame" then
			self.self:BringToTop()
		end
	end
	return self.self
end
function _GUI.Base:IsVisible()
	return self.self:IsVisible()
end

function _GUI.Base:Point( ... )
	if self.type == "WndFrame" or self.type == "WndWindow" then
		local t = { ... }
		if IsEmpty(t) then
			self.self:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		else
			self.self:SetPoint( ... )
		end
	end
	return self
end
-- (number, number) Instance:Pos()					-- ȡ��λ������
-- (self) Instance:Pos(number nX, number nY)	-- ����λ������
function _GUI.Base:Pos(nX, nY)
	if not nX then
		return self.self:GetRelPos()
	end
	self.self:SetRelPos(nX, nY)
	if self.type == "WndFrame" then
		self.self:CorrectPos()
	elseif string.sub(self.type, 1, 3) ~= "Wnd" then
		self.self:GetParent():FormatAllItemPos()
	end
	return self
end

-- (number, number) Instance:Pos_()			-- ȡ�����½ǵ�����
function _GUI.Base:Pos_()
	local nX, nY = self:Pos()
	local nW, nH = self:Size()
	return nX + nW, nY + nH
end

-- (number, number) Instance:CPos_()			-- ȡ�����һ����Ԫ�����½�����
-- �ر�ע�⣺����ͨ�� :Append() ׷�ӵ�Ԫ����Ч���Ա����ڶ�̬��λ
function _GUI.Base:CPos_()
	local hP = self.wnd or self.self
	if not hP.___last and string.sub(hP:GetType(), 1, 3) == "Wnd" then
		hP = hP:Lookup("", "")
	end
	if hP.___last then
		local ui = GUI.Fetch(hP, hP.___last)
		if ui then
			return ui:Pos_()
		end
	end
	return 0, 0
end

-- (class) Instance:Append(string szType, ...)	-- ��� UI �����
-- NOTICE��only for Handle��WndXXX
function _GUI.Base:Append(szType, ...)
	local hP = self.wnd or self.self
	if string.sub(hP:GetType(), 1, 3) == "Wnd" and string.sub(szType, 1, 3) ~= "Wnd" then
		hP.___last = nil
		hP = hP:Lookup("", "")
	end
	return GUI.Append(hP, szType, ...)
end

-- (class) Instance:Fetch(string szName)	-- �������ƻ�ȡ UI �����
function _GUI.Base:Fetch(szName)
	local hP = self.wnd or self.self
	local ui = GUI.Fetch(hP, szName)
	if not ui and self.handle then
		ui = GUI.Fetch(self.handle, szName)
	end
	return ui
end

-- (number, number) Instance:Align()
-- (self) Instance:Align(number nHAlign, number nVAlign)
function _GUI.Base:Align(nHAlign, nVAlign)
	local txt = self.edit or self.txt
	if txt then
		if not nHAlign and not nVAlign then
			return txt:GetHAlign(), txt:GetVAlign()
		else
			if nHAlign then
				txt:SetHAlign(nHAlign)
			end
			if nVAlign then
				txt:SetVAlign(nVAlign)
			end
		end
	end
	return self
end

-- (number) Instance:Font()
-- (self) Instance:Font(number nFont)
function _GUI.Base:Font(nFont)
	local txt = self.edit or self.txt
	if txt then
		if not nFont then
			return txt:GetFontScheme()
		end
		txt:SetFontScheme(nFont)
	end
	return self
end

-- (number, number, number) Instance:Color()
-- (self) Instance:Color(number nRed, number nGreen, number nBlue)
function _GUI.Base:Color(nRed, nGreen, nBlue)
	if self.type == "Shadow" then
		if not nRed then
			return self.self:GetColorRGB()
		end
		self.self:SetColorRGB(nRed, nGreen, nBlue)
	else
		local txt = self.edit or self.txt
		if txt then
			if not nRed then
				return txt:GetFontColor()
			end
			txt:SetFontColor(nRed, nGreen, nBlue)
			txt.col = { nRed, nGreen, nBlue }
		end
	end
	return self
end

-- (number) Instance:Alpha()
-- (self) Instance:Alpha(number nAlpha)
function _GUI.Base:Alpha(nAlpha)
	local txt = self.edit or self.txt or self.self
	if txt then
		if not nAlpha then
			return txt:GetAlpha()
		end
		txt:SetAlpha(nAlpha)
	end
	return self
end

-------------------------------------
-- Dialog frame
-------------------------------------
_GUI.Frm = class(_GUI.Base)

-- constructor
function _GUI.Frm:ctor(szName, bEmpty)
	local frm, szIniFile = nil, ROOT_PATH .. "ui/WndFrame.ini"
	if bEmpty then
		szIniFile = ROOT_PATH .. "ui/WndFrameEmpty.ini"
	end
	if type(szName) == "string" then
		frm = Station.Lookup("Normal/" .. szName)
		if frm then
			Wnd.CloseWindow(frm)
		end
		frm = Wnd.OpenWindow(szIniFile, szName)
	else
		frm = Wnd.OpenWindow(szIniFile)
	end
	frm:Show()
	if not bEmpty then
		frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		frm:Lookup("Btn_Close").OnLButtonClick = function()
			self:Remove()
		end
		self.wnd = frm:Lookup("Window_Main")
		self.handle = self.wnd:Lookup("", "")
	else
		self.handle = frm:Lookup("", "")
	end
	self.self, self.type = frm, "WndFrame"
end

-- (self) Instance:RegisterClose(boolean bNotButton, boolean bNotKeyDown)		-- ע��Esc��Btn_Close�ر�����
function _GUI.Frm:RegisterClose(bNotButton, bNotKeyDown)
	local wnd = self.self
	if not bNotKeyDown then
		wnd.OnFrameKeyDown = function()
			if GetKeyName(Station.GetMessageKey()) == "Esc" then
				self:Remove()
				return 1
			end
		end
	end
	if not bNotButton then
		wnd:Lookup("Btn_Close").OnLButtonClick = function()
			self:Remove()
		end
	end
	return self
end
-- (number, number) Instance:Size()						-- ȡ�ô����͸�
-- (self) Instance:Size(number nW, number nH)	-- ���ô���Ŀ�͸�
function _GUI.Frm:Size(nW, nH)
	local frm = self.self
	if not nW then
		return frm:GetSize()
	end
	local hnd = frm:Lookup("", "")
	-- empty frame
	if not self.wnd then
		frm:SetSize(nW, nH)
		hnd:SetSize(nW, nH)
		return self
	end
	-- set size
	frm:SetSize(nW, nH)
	frm:SetDragArea(0, 0, nW, 70)
	hnd:SetSize(nW, nH)
	hnd:Lookup("Image_BgT"):SetW(nW)
	hnd:Lookup("Image_BgCT"):SetW(nW - 32)
	hnd:Lookup("Image_BgLC"):SetH(nH - 149)
	hnd:Lookup("Image_BgCC"):SetSize(nW - 16, nH - 149)
	hnd:Lookup("Image_BgRC"):SetH(nH - 149)
	hnd:Lookup("Image_BgCB"):SetW(nW - 132)
	hnd:Lookup("Text_Title"):SetW(nW - 90)
	
	hnd:FormatAllItemPos()
	frm:Lookup("Btn_Close"):SetRelPos(nW - 35, 15)
	self.wnd:SetSize(nW - 90, nH - 90)
	self.wnd:Lookup("", ""):SetSize(nW - 90, nH - 90)
	-- reset position
	local an = GetFrameAnchor(frm)
	frm:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	return self
end

-- (string) Instance:Title()					-- ȡ�ô������
-- (self) Instance:Title(string szTitle)	-- ���ô������
function _GUI.Frm:Title(szTitle)
	local ttl = self.self:Lookup("", "Text_Title")
	if not szTitle then
		return ttl:GetText()
	end
	ttl:SetText(szTitle)
	return self
end

-- (boolean) Instance:Drag()						-- �жϴ����Ƿ������
-- (self) Instance:Drag(boolean bEnable)	-- ���ô����Ƿ������
function _GUI.Frm:Drag(bEnable)
	local frm = self.self
	if bEnable == nil then
		return frm:IsDragable()
	end
	frm:EnableDrag(bEnable == true)
	return self
end

-- (string) Instance:Relation()
-- (self) Instance:Relation(string szName)	-- Normal/Lowest ...
function _GUI.Frm:Relation(szName)
	local frm = self.self
	if not szName then
		return frm:GetParent():GetName()
	end
	frm:ChangeRelation(szName)
	return self
end

-- (userdata) Instance:Lookup(...)
function _GUI.Frm:Lookup(...)
	local wnd = self.wnd or self.self
	return self.wnd:Lookup(...)
end

_GUI.Frm2 = class(_GUI.Base)

-- constructor
function _GUI.Frm2:ctor(szName, bEmpty)
	local frm, szIniFile = nil, ROOT_PATH .. "ui/WndFrame2.ini"
	if bEmpty then
		szIniFile = ROOT_PATH .. "ui/WndFrameEmpty.ini"
	end
	if type(szName) == "string" then
		frm = Station.Lookup("Normal/" .. szName)
		if frm then
			Wnd.CloseWindow(frm)
		end
		frm = Wnd.OpenWindow(szIniFile, szName)
	else
		frm = Wnd.OpenWindow(szIniFile)
	end
	frm:Show()
	if not bEmpty then
		frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		frm:Lookup("Btn_Close").OnLButtonClick = function()
			self:Remove()
		end
		self.wnd = frm:Lookup("Window_Main")
		self.handle = self.wnd:Lookup("", "")
	else
		self.handle = frm:Lookup("", "")
	end
	self.self, self.type = frm, "WndFrame"
end

function _GUI.Frm2:Size(nW, nH)
	local frm = self.self
	if not nW then
		return frm:GetSize()
	end
	local hnd = frm:Lookup("", "")
	-- empty frame
	if not self.wnd then
		frm:SetSize(nW, nH)
		hnd:SetSize(nW, nH)
		return self
	end
	-- set size
	frm:SetSize(nW, nH)
	frm:SetDragArea(0, 0, nW, 30)
	hnd:SetSize(nW, nH)
	hnd:Lookup("Image_Bg"):SetSize(nW, nH)
	hnd:Lookup("Image_Title"):SetW(nW)
	hnd:Lookup("Text_Title"):SetW(nW - 90)
	hnd:FormatAllItemPos()
	frm:Lookup("Btn_Close"):SetRelPos(nW - 30, 5)
	self.wnd:SetSize(nW, nH)
	self.wnd:Lookup("", ""):SetSize(nW, nH)
	-- reset position
	local an = GetFrameAnchor(frm)
	frm:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	return self
end

-- (self) Instance:RegisterClose(boolean bNotButton, boolean bNotKeyDown)		-- ע��Esc��Btn_Close�ر�����
function _GUI.Frm2:RegisterClose(bNotButton, bNotKeyDown)
	local wnd = self.self
	if not bNotKeyDown then
		wnd.OnFrameKeyDown = function()
			if GetKeyName(Station.GetMessageKey()) == "Esc" then
				self:Remove()
				return 1
			end
		end
	end
	if not bNotButton then
		wnd:Lookup("Btn_Close").OnLButtonClick = function()
			self:Remove()
		end
	end
	return self
end

function _GUI.Frm2:RegisterSetting(fnAction)
	local wnd = self.self
	wnd:Lookup("Btn_Setting").OnLButtonClick = fnAction
	return self
end

function _GUI.Frm2:Title(szTitle)
	local ttl = self.self:Lookup("", "Text_Title")
	if not szTitle then
		return ttl:GetText()
	end
	ttl:SetText(szTitle)
	return self
end

-------------------------------------
-- Window Component
-------------------------------------
_GUI.Wnd = class(_GUI.Base)

-- constructor
function _GUI.Wnd:ctor(pFrame, szType, szName)
	local wnd = nil
	if not szType and not szName then
		-- convert from raw object
		wnd, szType = pFrame, pFrame:GetType()
	else
		-- append from ini file
		local szFile = ROOT_PATH .. "ui/" .. szType .. ".ini"
		local frame = Wnd.OpenWindow(szFile, "GUI_Virtual")
		assert(frame, _L("Unable to open ini file [%s]", szFile))
		wnd = frame:Lookup(szType)
		assert(wnd, _L("Can not find wnd component [%s]", szType))
		wnd:SetName(szName)
		wnd:ChangeRelation(pFrame, true, true)
		Wnd.CloseWindow(frame)
	end
	if wnd then
		if string.find(szType, "WndButton") then
			szType = "WndButton"
		end
		self.type = szType
		self.edit = wnd:Lookup("Edit_Default")
		self.handle = wnd:Lookup("", "")
		self.self = wnd
		if self.handle then
			self.txt = self.handle:Lookup("Text_Default")
		end
		if szType == "WndTrackBar" then
			local scroll = wnd:Lookup("Scroll_Track")
			scroll.nMin, scroll.nMax, scroll.szText = 0, scroll:GetStepCount(), self.txt:GetText()
			scroll.nVal = scroll.nMin
			self.txt:SetText(scroll.nVal .. scroll.szText)
			scroll.OnScrollBarPosChanged = function()
				this.nVal = this.nMin + mceil((this:GetScrollPos() / this:GetStepCount()) * (this.nMax - this.nMin))
				if this.OnScrollBarPosChanged_ then
					this.OnScrollBarPosChanged_(this.nVal)
				end
				self.txt:SetText(this.nVal .. this.szText)
			end
		end
	end
end

-- (number, number) Instance:Size()
-- (self) Instance:Size(number nW, number nH)
function _GUI.Wnd:Size(nW, nH)
	local wnd = self.self
	if not nW then
		local nW, nH = wnd:GetSize()
		if self.type == "WndRadioBox" or self.type == "WndCheckBox" or self.type == "WndTrackBar" then
			local xW, _ = self.txt:GetTextExtent()
			nW = nW + xW + 5
		end
		return nW, nH
	end
	if self.edit then
		wnd:SetSize(nW + 2, nH)
		self.handle:SetSize(nW + 2, nH)
		self.handle:Lookup("Image_Default"):SetSize(nW + 2, nH)
		self.edit:SetSize(nW - 3, nH)
	else
		wnd:SetSize(nW, nH)
		if self.handle then
			self.handle:SetSize(nW, nH)
			if self.type == "WndButton" or self.type == "WndTabBox" then
				self.txt:SetSize(nW, nH)
			elseif self.type == "WndComboBox" then
				self.handle:Lookup("Image_ComboBoxBg"):SetSize(nW, nH)
				local btn = wnd:Lookup("Btn_ComboBox")
				local hnd = btn:Lookup("", "")
				local bW, bH = btn:GetSize()
				btn:SetRelPos(nW - bW - 5, mceil((nH - bH)/2))
				hnd:SetAbsPos(self.handle:GetAbsPos())
				hnd:SetSize(nW, nH)
				self.txt:SetSize(nW - mceil(bW/2), nH)
			elseif self.type == "WndCheckBox" then
				local _, xH = self.txt:GetTextExtent()
				self.txt:SetRelPos(nW - 20, floor((nH - xH)/2))
			elseif self.type == "WndRadioBox" then
				local _, xH = self.txt:GetTextExtent()
				self.txt:SetRelPos(nW + 5, floor((nH - xH)/2))
				self.handle:FormatAllItemPos()
			elseif self.type == "WndTrackBar" then
				wnd:Lookup("Scroll_Track"):SetSize(nW, nH - 13)
				wnd:Lookup("Scroll_Track/Btn_Track"):SetSize(mceil(nW/5), nH - 13)
				self.handle:Lookup("Image_BG"):SetSize(nW, nH - 15)
				self.handle:Lookup("Text_Default"):SetRelPos(nW + 5, mceil((nH - 25)/2))
				self.handle:FormatAllItemPos()
			end
		end
	end
	return self
end

function _GUI.Wnd:Title(szTitle)
	local ttl = self.self:Lookup("", "Text_Title")
	if not szTitle then
		return ttl:GetText()
	end
	ttl:SetText(szTitle)
	return self
end

-- (boolean) Instance:Enable()
-- (self) Instance:Enable(boolean bEnable)
function _GUI.Wnd:Enable(bEnable)
	local wnd = self.edit or self.self
	local txt = self.edit or self.txt
	if bEnable == nil then
		if self.type == "WndButton" then
			return wnd:IsEnabled()
		end
		return self.enable ~= false
	end
	if bEnable then
		if self.type == "WndTrackBar" then
			wnd:Lookup("Scroll_Track/Btn_Track"):Enable(1)
		end
		wnd:Enable(1)
		if txt then
			if self.font then
				txt:SetFontScheme(self.font)
			end
			if txt.col then
				txt:SetFontColor(unpack(txt.col))
			end
		end
		self.enable = true
	else
		if self.type == "WndTrackBar" then
			wnd:Lookup("Scroll_Track/Btn_Track"):Enable(0)
		end
		wnd:Enable(0)
		if txt and self.enable ~= false then
			self.font = txt:GetFontScheme()
			txt:SetFontScheme(161)
		end
		self.enable = false
	end
	return self
end

-- (self) Instance:AutoSize([number hPad[, number vPad]])
function _GUI.Wnd:AutoSize(hPad, vPad)
	local wnd = self.self
	if self.type == "WndTabBox" or self.type == "WndButton" then
		local _, nH = wnd:GetSize()
		local nW, _ = self.txt:GetTextExtent()
		local nEx = self.txt:GetTextPosExtent()
		if hPad then
			nW = nW + hPad + hPad
		end
		if vPad then
			nH = nH + vPad + vPad
		end
		self:Size(nW + nEx + 16, nH)
	elseif self.type == "WndComboBox" then
		local bW, _ = wnd:Lookup("Btn_ComboBox"):GetSize()
		local nW, nH = self.txt:GetTextExtent()
		local nEx = self.txt:GetTextPosExtent()
		if hPad then
			nW = nW + hPad + hPad
		end
		if vPad then
			nH = nH + vPad + vPad
		end
		self:Size(nW + bW + 20, nH + 6)
	end
	return self
end

-- (boolean) Instance:Check()
-- (self) Instance:Check(boolean bCheck)
-- NOTICE��only for WndCheckBox
function _GUI.Wnd:Check(bCheck)
	local wnd = self.self
	if wnd:GetType() == "WndCheckBox" then
		if bCheck == nil then
			return wnd:IsCheckBoxChecked()
		end
		wnd:Check(bCheck == true)
	end
	return self
end

-- (string) Instance:Group()
-- (self) Instance:Group(string szGroup)
-- NOTICE��only for WndCheckBox
function _GUI.Wnd:Group(szGroup)
	local wnd = self.self
	if wnd:GetType() == "WndCheckBox" then
		if not szGroup then
			return wnd.group
		end
		wnd.group = szGroup
	end
	return self
end

-- (string) Instance:Url()
-- (self) Instance:Url(string szUrl)
-- NOTICE��only for WndWebPage
function _GUI.Wnd:Url(szUrl)
	local wnd = self.self
	if self.type == "WndWebPage" then
		if not szUrl then
			return wnd:GetLocationURL()
		end
		wnd:Navigate(szUrl)
	end
	return self
end

-- (number, number, number) Instance:Range()
-- (self) Instance:Range(number nMin, number nMax[, number nStep])
-- NOTICE��only for WndTrackBar
function _GUI.Wnd:Range(nMin, nMax, nStep)
	if self.type == "WndTrackBar" then
		local scroll = self.self:Lookup("Scroll_Track")
		if not nMin and not nMax then
			return scroll.nMin, scroll.nMax, scroll:GetStepCount()
		end
		if nMin then scroll.nMin = nMin end
		if nMax then scroll.nMax = nMax end
		if nStep then scroll:SetStepCount(nStep) end
		self:Value(scroll.nVal)
	end
	return self
end

-- (number) Instance:Value()
-- (self) Instance:Value(number nVal)
-- NOTICE��only for WndTrackBar
function _GUI.Wnd:Value(nVal)
	if self.type == "WndTrackBar" then
		local scroll = self.self:Lookup("Scroll_Track")
		if not nVal then
			return scroll.nVal
		end
		scroll.nVal = mmin(mmax(nVal, scroll.nMin), scroll.nMax)
		scroll:SetScrollPos(mceil((scroll.nVal - scroll.nMin) / (scroll.nMax - scroll.nMin) * scroll:GetStepCount()))
		self.txt:SetText(scroll.nVal .. scroll.szText)
	end
	return self
end

-- (string) Instance:Text()
-- (self) Instance:Text(string szText[, boolean bDummy])
-- bDummy		-- ��Ϊ true ������������ onChange �¼�
function _GUI.Wnd:Text(szText, bDummy)
	local txt = self.edit or self.txt
	if txt then
		if not szText then
			return txt:GetText()
		end
		if self.type == "WndTrackBar" then
			local scroll = self.self:Lookup("Scroll_Track")
			scroll.szText = szText
			txt:SetText(scroll.nVal .. scroll.szText)
		elseif self.type == "WndEdit" and bDummy then
			local fnChanged = txt.OnEditChanged
			txt.OnEditChanged = nil
			txt:SetText(szText)
			txt.OnEditChanged = fnChanged
		else
			txt:SetText(szText)
		end
		if self.type == "WndTabBox" then
			self:AutoSize()
		end
		if self.type == "WndCheckBox" or self.type == "WndRadioBox" then
			local nWidth, nHeight = txt:GetTextExtent()
			txt:SetSize(nWidth + 26, nHeight)
			self.handle:SetSize(nWidth + 26, nHeight)
			self.handle:FormatAllItemPos()
		end
	end
	return self
end

-- (boolean) Instance:Multi()
-- (self) Instance:Multi(boolean bEnable)
-- NOTICE: only for WndEdit
function _GUI.Wnd:Multi(bEnable)
	local edit = self.edit
	if edit then
		if bEnable == nil then
			return edit:IsMultiLine()
		end
		edit:SetMultiLine(bEnable == true)
	end
	return self
end

-- (number) Instance:Limit()
-- (self) Instance:Limit(number nLimit)
-- NOTICE: only for WndEdit
function _GUI.Wnd:Limit(nLimit)
	local edit = self.edit
	if edit then
		if not nLimit then
			return edit:GetLimit()
		end
		edit:SetLimit(nLimit)
	end
	return self
end

-- (self) Instance:Change()			-- �����༭���޸Ĵ�����
-- (self) Instance:Change(func fnAction)
-- NOTICE��only for WndEdit��WndTrackBar
function _GUI.Wnd:Change(fnAction)
	if self.type == "WndTrackBar" then
		self.self:Lookup("Scroll_Track").OnScrollBarPosChanged_ = fnAction
	elseif self.edit then
		local edit = self.edit
		if not fnAction then
			if edit.OnEditChanged then
				local _this = this
				this = edit
				edit.OnEditChanged()
				this = _this
			end
		else
			edit.OnEditChanged = function()
				if not this.bChanging then
					this.bChanging = true
					fnAction(this:GetText())
					this.bChanging = false
				end
			end
		end
	end
	return self
end

-- (self) Instance:Focus()
-- (self) Instance:Focus(func fnAction)
-- NOTICE��only for WndEdit
function _GUI.Wnd:Focus(SetfnAction,KillfnAction)
	if type(SetfnAction) == "function" then
		local wnd = self.edit
		if SetfnAction then
			wnd.OnSetFocus = SetfnAction
		end
		if KillfnAction then
			wnd.OnKillFocus = KillfnAction
		end
	else
		Station.SetFocusWindow(self.edit)
	end
	return self
end


-- (self) Instance:Menu(table menu)		-- ���������˵�
-- NOTICE��only for WndComboBox
function _GUI.Wnd:Menu(menu)
	if self.type == "WndComboBox" then
		local wnd = self.self
		self:Click(function()
			local _menu = nil
			local nX, nY = wnd:GetAbsPos()
			local nW, nH = wnd:GetSize()
			if type(menu) == "function" then
				_menu = menu()
			else
				_menu = menu
			end
			_menu.nMiniWidth = nW
			_menu.x = nX
			_menu.y = nY + nH
			PopupMenu(_menu)
		end)
	end
	return self
end

function _GUI.Wnd:RegisterClose(fnAction, bNotButton, bNotKeyDown)
	local wnd = self.self
	if not bNotKeyDown then
		wnd.OnFrameKeyDown = function()
			if GetKeyName(Station.GetMessageKey()) == "Esc" then
				fnAction()
				return 1
			end
		end
	end
	if not bNotButton then
		wnd:Lookup("Btn_Close").OnLButtonClick = fnAction
	end
	return self
end

-- (self) Instance:Click()
-- (self) Instance:Click(func fnAction)	-- �����������󴥷�ִ�еĺ���
-- fnAction = function([bCheck])			-- ���� WndCheckBox �ᴫ�� bCheck �����Ƿ�ѡ
function _GUI.Wnd:Click(fnAction)
	local wnd = self.self
	if self.type == "WndComboBox" then
		wnd = wnd:Lookup("Btn_ComboBox")
	end
	if wnd:GetType() == "WndCheckBox" then
		if not fnAction then
			self:Check(not self:Check())
		else
			wnd.OnCheckBoxCheck = function()
				if wnd.group then
					local uis = this:GetParent().___uis or {}
					for _, ui in pairs(uis) do
						if ui:Group() == this.group and ui:Name() ~= this:GetName() then
							ui.bCanUnCheck = true
							ui:Check(false)
							ui.bCanUnCheck = nil
						end
					end
				end
				fnAction(true)
			end
			wnd.OnCheckBoxUncheck = function()
				if wnd.group and not self.bCanUnCheck then
					self:Check(true)
				else
					fnAction(false)
				end
			end
		end
	else
		if not fnAction then
			if wnd.OnLButtonClick then
				local _this = this
				this = wnd
				wnd.OnLButtonClick()
				this = _this
			end
		else
			wnd.OnLButtonClick = fnAction
		end
	end
	return self
end

-- (self) Instance:Hover(func fnEnter[, func fnLeave])	-- ����������������
-- fnEnter = function(true)		-- ������ʱ����
-- fnLeave = function(false)		-- ����Ƴ�ʱ���ã���ʡ����ͽ��뺯��һ��
function _GUI.Wnd:Hover(fnEnter, fnLeave)
	local wnd = self.self
	if self.type == "WndComboBox" then
		wnd = wnd:Lookup("Btn_ComboBox")
	end
	if wnd then
		fnLeave = fnLeave or fnEnter
		if fnEnter then
			wnd.OnMouseEnter = function() fnEnter(true) end
		end
		if fnLeave then
			wnd.OnMouseLeave = function() fnLeave(false) end
		end
	end
	return self
end

function _GUI.Wnd:Type(nType)
	if self.type == "WndEdit" then
		self.edit:SetType(nType)
	end
	return self
end

-------------------------------------
-- Handle Item
-------------------------------------
_GUI.Item = class(_GUI.Base)

-- xml string
_GUI.tItemXML = {
	["Text"] = "<text>w=150 h=30 valign=1 font=162 eventid=257 </text>",
	["Image"] = "<image>w=100 h=100 </image>",
	["Animate"] = "<Animate>w=100 h=100 </Animate>",
	["Box"] = "<box>w=48 h=48 eventid=525311 </box>",
	["Shadow"] = "<shadow>w=15 h=15 eventid=277 </shadow>",
	["Handle"] = "<handle>firstpostype=0 w=10 h=10</handle>",
	["Label"] = "<handle>w=150 h=30 eventid=257 <text>name=\"Text_Label\" w=150 h=30 font=162 valign=1 </text></handle>",
}

-- construct
function _GUI.Item:ctor(pHandle, szType, szName)
	local hnd = nil
	if not szType and not szName then
		-- convert from raw object
		hnd, szType = pHandle, pHandle:GetType()
	else
		local szXml = _GUI.tItemXML[szType]
		if szXml then
			-- append from xml
			local nCount = pHandle:GetItemCount()
			pHandle:AppendItemFromString(szXml)
			hnd = pHandle:Lookup(nCount)
			if hnd then hnd:SetName(szName) end
		else
			-- append from ini
			hnd = pHandle:AppendItemFromIni(ROOT_PATH .. "ui/HandleItems.ini","Handle_" .. szType, szName)
		end
		assert(hnd, _L("Unable to append handle item [%s]", szType))
	end
	if szType == "BoxButton" then
		self.txt = hnd:Lookup("Text_BoxButton")
		self.img = hnd:Lookup("Image_BoxIco")
		hnd.OnItemMouseEnter = function()
			if not this.bSelected then
				this:Lookup("Image_BoxBg"):Hide()
				this:Lookup("Image_BoxBgOver"):Show()
			end
		end
		hnd.OnItemMouseLeave = function()
			if not this.bSelected then
				this:Lookup("Image_BoxBg"):Show()
				this:Lookup("Image_BoxBgOver"):Hide()
			end
		end
	elseif szType == "TxtButton" then
		self.txt = hnd:Lookup("Text_TxtButton")
		self.img = hnd:Lookup("Image_TxtBg")
		hnd.OnItemMouseEnter = function()
			self.img:Show()
		end
		hnd.OnItemMouseLeave = function()
			if not this.bSelected then
				self.img:Hide()
			end
		end
	elseif szType == "Label" then
		self.txt = hnd:Lookup("Text_Label")
	elseif szType == "Text" then
		self.txt = hnd
	elseif szType == "Image" then
		self.img = hnd
	end
	self.self, self.type = hnd, szType
	hnd:SetRelPos(0, 0)
	hnd:GetParent():FormatAllItemPos()
end

-- (number, number) Instance:Size()
-- (self) Instance:Size(number nW, number nH)
function _GUI.Item:Size(nW, nH)
	local hnd = self.self
	if not nW then
		local nW, nH = hnd:GetSize()
		if self.type == "Text" or self.type == "Label" then
			nW, nH = self.txt:GetTextExtent()
		end
		return nW, nH
	end
	hnd:SetSize(nW, nH)
	if self.type == "BoxButton" then
		local nPad = mceil(nH * 0.2)
		hnd:Lookup("Image_BoxBg"):SetSize(nW - 12, nH + 8)
		hnd:Lookup("Image_BoxBgOver"):SetSize(nW - 12, nH + 8)
		hnd:Lookup("Image_BoxBgSel"):SetSize(nW - 1, nH + 11)
		self.img:SetSize(nH - nPad, nH - nPad)
		self.img:SetRelPos(10, mceil(nPad / 2))
		self.txt:SetSize(nW - nH - nPad, nH)
		self.txt:SetRelPos(nH + 10, 0)
		hnd:FormatAllItemPos()
	elseif self.type == "TxtButton" then
		self.img:SetSize(nW, nH - 5)
		self.txt:SetSize(nW - 10, nH - 5)
	elseif self.type == "Label" then
		self.txt:SetSize(nW, nH)
	end
	return self
end

-- (self) Instance:Zoom(boolean bEnable)	-- �Ƿ����õ����Ŵ�
-- NOTICE��only for BoxButton
function _GUI.Item:Zoom(bEnable)
	local hnd = self.self
	if self.type == "BoxButton" then
		local bg = hnd:Lookup("Image_BoxBg")
		local sel = hnd:Lookup("Image_BoxBgSel")
		if bEnable == true then
			local nW, nH = bg:GetSize()
			sel:SetSize(nW + 11, nH + 3)
			sel:SetRelPos(1, -5)
		else
			sel:SetSize(bg:GetSize())
			sel:SetRelPos(5, -2)
		end
		hnd:FormatAllItemPos()
	end
	return self
end

-- (self) Instance:Select()		-- ����ѡ�е�ǰ��Ŧ��������Ч����
-- NOTICE��only for BoxButton��TxtButton
function _GUI.Item:Select()
	local hnd = self.self
	if self.type == "BoxButton" or self.type == "TxtButton" then
		local hParent, nIndex = hnd:GetParent(), hnd:GetIndex()
		local nCount = hParent:GetItemCount() - 1
		for i = 0, nCount do
			local item = GUI.Fetch(hParent:Lookup(i))
			if item and item.type == self.type then
				if i == nIndex then
					if not item.self.bSelected then
						hnd.bSelected = true
						hnd.nIndex = i
						if self.type == "BoxButton" then
							hnd:Lookup("Image_BoxBg"):Hide()
							hnd:Lookup("Image_BoxBgOver"):Hide()
							hnd:Lookup("Image_BoxBgSel"):Show()
							self.txt:SetFontScheme(65)
							local icon = hnd:Lookup("Image_BoxIco")
							local nW, nH = icon:GetSize()
							local nX, nY = icon:GetRelPos()
							icon:SetSize(nW + 8, nH + 8)
							icon:SetRelPos(nX - 3, nY - 5)
							hnd:FormatAllItemPos()
						else
							self.img:Show()
						end
					end
				elseif item.self.bSelected then
					item.self.bSelected = false
					if item.type == "BoxButton" then
						item.self:SetIndex(item.self.nIndex)
						if hnd.nIndex >= item.self.nIndex then
							hnd.nIndex = hnd.nIndex + 1
						end
						item.self:Lookup("Image_BoxBg"):Show()
						item.self:Lookup("Image_BoxBgOver"):Hide()
						item.self:Lookup("Image_BoxBgSel"):Hide()
						item.txt:SetFontScheme(163)
						local icon = item.self:Lookup("Image_BoxIco")
						local nW, nH = icon:GetSize()
						local nX, nY = icon:GetRelPos()
						icon:SetSize(nW - 8, nH - 8)
						icon:SetRelPos(nX + 3, nY + 5)
						item.self:FormatAllItemPos()
					else
						item.img:Hide()
					end
				end
			end
		end
		if hnd.nIndex then
			hnd:SetIndex(nCount)
		end
	end
	return self
end

-- (string) Instance:Text()
-- (self) Instance:Text(string szText)
function _GUI.Item:Text(szText)
	local txt = self.txt
	if txt then
		if not szText then
			return txt:GetText()
		end
		txt:SetText(szText)
	end
	return self
end
function _GUI.Item:Scale(fScale)
	local txt = self.txt
	if txt then
		if not fScale then
			return txt:GetFontScale()
		end
		txt:SetFontScale(fScale)
	end
	return self
end

-- (boolean) Instance:Multi()
-- (self) Instance:Multi(boolean bEnable)
-- NOTICE: only for Text��Label
function _GUI.Item:Multi(bEnable)
	local txt = self.txt
	if txt then
		if bEnable == nil then
			return txt:IsMultiLine()
		end
		txt:SetMultiLine(bEnable == true)
	end
	return self
end

-- (self) Instance:File(string szUitexFile, number nFrame)
-- (self) Instance:File(string szTextureFile)
-- (self) Instance:File(number dwIcon)
-- NOTICE��only for Image��BoxButton
function _GUI.Item:File(szFile, nFrame)
	local img = nil
	if self.type == "Image" then
		img = self.self
	elseif self.type == "BoxButton" then
		img = self.img
	end
	if img then
		if type(szFile) == "number" then
			img:FromIconID(szFile)
		elseif not nFrame then
			img:FromTextureFile(szFile)
		else
			img:FromUITex(szFile, nFrame)
		end
	end
	return self
end
function _GUI.Item:Animate(szImage, nGroup, nLoopCount)
	if self.type == "Animate" then
		self.self:SetAnimate(szImage, nGroup, nLoopCount)
	end
	return self
end

-- (self) Instance:Type()
-- (self) Instance:Type(number nType)		-- �޸�ͼƬ���ͻ� BoxButton �ı�������
-- NOTICE��only for Image��BoxButton
function _GUI.Item:Type(nType)
	local hnd = self.self
	if self.type == "Image" then
		if not nType then
			return hnd:GetImageType()
		end
		hnd:SetImageType(nType)
	elseif self.type == "BoxButton" then
		if nType == nil then
			local nFrame = hnd:Lookup("Image_BoxBg"):GetFrame()
			if nFrame == 16 then
				return 2
			elseif nFrame == 18 then
				return 1
			end
			return 0
		elseif nType == 0 then
			hnd:Lookup("Image_BoxBg"):SetFrame(1)
			hnd:Lookup("Image_BoxBgOver"):SetFrame(2)
			hnd:Lookup("Image_BoxBgSel"):SetFrame(3)
		elseif nType == 1 then
			hnd:Lookup("Image_BoxBg"):SetFrame(18)
			hnd:Lookup("Image_BoxBgOver"):SetFrame(19)
			hnd:Lookup("Image_BoxBgSel"):SetFrame(22)
		elseif nType == 2 then
			hnd:Lookup("Image_BoxBg"):SetFrame(16)
			hnd:Lookup("Image_BoxBgOver"):SetFrame(17)
			hnd:Lookup("Image_BoxBgSel"):SetFrame(15)
		end
	end
	return self
end

-- (self) Instance:ToGray(bGray)
-- NOTICE��only for Box
function _GUI.Item:ToGray(bGray)
	if self.type == "Box" then
		if bGray then
			self.self:IconToGray()
		else
			self.self:IconToNormal()
		end
	end
	return self
end

-- (self) Instance:Icon(number dwIcon)
-- NOTICE��only for Box��Image��BoxButton
function _GUI.Item:Icon(dwIcon)
	if self.type == "BoxButton" or self.type == "Image" then
		self.img:FromIconID(dwIcon)
	elseif self.type == "Box" then
		self.self:SetObject(UI_OBJECT_ITEM)
		self.self:SetObjectIcon(dwIcon)
	end
	return self
end

function _GUI.Item:OverText(nPos, szText, nOverTextIndex, nFontScheme)
	if self.type == "Box" then
		if nPos and szText then
			nOverTextIndex = nOverTextIndex or 0
			nFontScheme = nFontScheme or 15
			self.self:SetOverTextPosition(nOverTextIndex, nPos)
			self.self:SetOverTextFontScheme(nOverTextIndex, nFontScheme)
			self.self:SetOverText(nOverTextIndex, szText)
		else
			nPos = nPos or 0
			return self.self:GetOverText(nPos)
		end
	end
	return self
end

function _GUI.Item:Sparking(bSparking)
	if self.type == "Box" then
		self.self:SetObjectSparking(bSparking)
	end
	return self
end
function _GUI.Item:Staring(bStaring)
	if self.type == "Box" then
		self.self:SetObjectStaring(bStaring)
	end
	return self
end

function _GUI.Item:Percentage(fPercentage)
	if self.type == "Image" then
		if fPercentage then
			self.self:SetImageType(1)
			self.self:SetPercentage(fPercentage)
		else
			return self.self:GetPercentage()
		end
	end
	return self
end

function _GUI.Item:Type(nType)
	if self.type == "Image" then
		self.self:SetImageType(nType)
	elseif self.type == "Handle" then
		self.self:SetHandleStyle(nType)
	end
	return self
end

function _GUI.Item:Event(dwEventID)
	if dwEventID then
		self.self:RegisterEvent(dwEventID)
	else
		self.self:ClearEvent()
	end
	return self
end
-- (self) Instance:Click()
-- (self) Instance:Click(func fnAction[, boolean bSound[, boolean bSelect]])	-- �Ǽ������������
-- (self) Instance:Click(func fnAction[, table tLinkColor[, tHoverColor]])		-- ͬ�ϣ�ֻ���ı�
function _GUI.Item:Click(fnAction, bSound, bSelect)
	local hnd = self.self
	--hnd:RegisterEvent(0x001)
	if not fnAction then
		if hnd.OnItemLButtonDown then
			local _this = this
			this = hnd
			hnd.OnItemLButtonDown()
			this = _this
		end
	elseif self.type == "BoxButton" or self.type == "TxtButton" then
		hnd.OnItemLButtonDown = function()
			if bSound then PlaySound(SOUND.UI_SOUND, g_sound.Button) end
			if bSelect then self:Select() end
			fnAction()
		end
	else
		hnd.OnItemLButtonDown = fnAction
		-- text link��tLinkColor��tHoverColor
		local txt = self.txt
		if txt then
			local tLinkColor = bSound or { 255, 255, 0 }
			local tHoverColor = bSelect or { 255, 200, 100 }
			if bSound then
				txt:SetFontColor(unpack(tLinkColor))
			end
			if tHoverColor then
				self:Hover(function(bIn)
					if bSound then
						if bIn then
							txt:SetFontColor(unpack(tHoverColor))
						else
							txt:SetFontColor(unpack(tLinkColor))
						end
					end
				end)
			end
		end
	end
	return self
end

-- (self) Instance:Hover(func fnEnter[, func fnLeave])	-- ����������������
-- fnEnter = function(true)		-- ������ʱ����
-- fnLeave = function(false)		-- ����Ƴ�ʱ���ã���ʡ����ͽ��뺯��һ��
function _GUI.Item:Hover(fnEnter, fnLeave)
	local hnd = self.self
	--hnd:RegisterEvent(0x300)
	fnLeave = fnLeave or fnEnter
	if fnEnter then
		hnd.OnItemMouseEnter = function() fnEnter(true) end
	end
	if fnLeave then
		hnd.OnItemMouseLeave = function() fnLeave(false) end
	end
	return self
end

---------------------------------------------------------------------
-- ������ API��GUI.xxx
---------------------------------------------------------------------
GUI = {}
setmetatable(GUI, { __call = function(me, ...) return me.Fetch(...) end, __metatable = true })

-- ����һ���յĶԻ�������棬������ GUI ��װ����
-- (class) GUI.CreateFrame([string szName, ]table tArg)
-- szName		-- *��ѡ* ���ƣ���ʡ�����Զ������
-- tArg {			-- *��ѡ* ��ʼ�����ò������Զ�������Ӧ�ķ�װ�������������Ծ���ѡ
--		w, h,			-- ��͸ߣ��ɶԳ�������ָ����С��ע���Ȼ��Զ����ͽ�����Ϊ��770/380/234���߶���С 200
--		x, y,			-- λ�����꣬Ĭ������Ļ���м�
--		title			-- �������
--		drag			-- ���ô����Ƿ���϶�
--		close		-- ����رհ�Ŧ���Ƿ������رմ��壨��Ϊ false �������أ�
--		empty		-- �����մ��壬����������ȫ͸����ֻ�ǽ�������
--		fnCreate = function(frame)		-- �򿪴����ĳ�ʼ��������frame Ϊ���ݴ��壬�ڴ���� UI
--		fnDestroy = function(frame)	-- �ر����ٴ���ʱ���ã�frame Ϊ���ݴ��壬���ڴ��������
-- }
-- ����ֵ��ͨ�õ�  GUI ���󣬿�ֱ�ӵ��÷�װ����
GUI.CreateFrame = function(szName, tArg)
	if type(szName) == "table" then
		szName, tArg = nil, szName
	end
	tArg = tArg or {}
	local ui = _GUI.Frm.new(szName, tArg.empty == true)
	Station.SetFocusWindow(ui.self)
	-- apply init setting
	if tArg.w and tArg.h then ui:Size(tArg.w, tArg.h) end
	if tArg.x and tArg.y then ui:Pos(tArg.x, tArg.y) end
	if tArg.title then ui:Title(tArg.title) end
	if tArg.drag ~= nil then ui:Drag(tArg.drag) end
	if tArg.close ~= nil then ui.self.bClose = tArg.close end
	if tArg.fnCreate then tArg.fnCreate(ui:Raw()) end
	if tArg.fnDestroy then ui.fnDestroy = tArg.fnDestroy end
	if tArg.parent then ui:Relation(tArg.parent) end
	ui:Point() -- fix Size
	return ui
end

-- �����մ���
GUI.CreateFrameEmpty = function(szName, szParent)
	return GUI.CreateFrame(szName, { empty  = true, parent = szParent })
end
-- ͸���Ĵ���
GUI.CreateFrame2 = function(szName, tArg)
	if type(szName) == "table" then
		szName, tArg = nil, szName
	end
	tArg = tArg or {}
	local ui = _GUI.Frm2.new(szName, tArg.empty == true)
	Station.SetFocusWindow(ui.self)
	-- apply init setting
	if tArg.w and tArg.h then ui:Size(tArg.w, tArg.h) end
	if tArg.x and tArg.y then ui:Pos(tArg.x, tArg.y) end
	if tArg.title then ui:Title(tArg.title) end
	if tArg.drag ~= nil then ui:Drag(tArg.drag) end
	if tArg.close ~= nil then ui.self.bClose = tArg.close end
	if tArg.fnCreate then tArg.fnCreate(ui:Raw()) end
	if tArg.fnDestroy then ui.fnDestroy = tArg.fnDestroy end
	if tArg.parent then ui:Relation(tArg.parent) end
	ui:Point() -- fix Size
	return ui
end
-- ��ĳһ��������������  INI �����ļ��еĲ��֣������� GUI ��װ����
-- (class) GUI.Append(userdata hParent, string szIniFile, string szTag, string szName)
-- hParent		-- �����������ԭʼ����GUI ������ֱ����  :Append ������
-- szIniFile		-- INI �ļ�·��
-- szTag			-- Ҫ��ӵĶ���Դ�����������ڵĲ��� [XXXX]������ hParent ƥ����� Wnd ���������
-- szName		-- *��ѡ* �������ƣ�����ָ��������ԭ����
-- ����ֵ��ͨ�õ�  GUI ���󣬿�ֱ�ӵ��÷�װ������ʧ�ܻ������ nil
-- �ر�ע�⣺�������Ҳ֧����Ӵ������
GUI.AppendIni = function(hParent, szFile, szTag, szName)
	local raw = nil
	if hParent:GetType() == "Handle" then
		if not szName then
			szName = "Child_" .. hParent:GetItemCount()
		end
		raw = hParent:AppendItemFromIni(szFile, szTag, szName)
	elseif string.sub(hParent:GetType(), 1, 3) == "Wnd" then
		local frame = Wnd.OpenWindow(szFile, "GUI_Virtual")
		if frame then
			raw = frame:Lookup(szTag)
			if raw and string.sub(raw:GetType(), 1, 3) == "Wnd" then
				raw:ChangeRelation(hParent, true, true)
				if szName then
					raw:SetName(szName)
				end
			else
				raw = nil
			end
			Wnd.CloseWindow(frame)
		end
	end
	assert(raw, _L("Fail to add component [%s@%s]", szTag, szFile))
	return GUI.Fetch(raw)
end

-- ��ĳһ�������������� GUI ��������ط�װ����
-- (class) GUI.Append(userdata hParent, string szType[, string szName], table tArg)
-- hParent		-- �����������ԭʼ����GUI ������ֱ����  :Append ������
-- szType			-- Ҫ��ӵ�������ͣ��磺WndWindow��WndEdit��Handle��Text ������
-- szName		-- *��ѡ* ���ƣ���ʡ�����Զ������
-- tArg {			-- *��ѡ* ��ʼ�����ò������Զ�������Ӧ�ķ�װ�������������Ծ���ѡ�����û�������
--		w, h,			-- ��͸ߣ��ɶԳ�������ָ����С
--		x, y,			-- λ������
--		txt, font, multi, limit, align		-- �ı����ݣ����壬�Ƿ���У��������ƣ����뷽ʽ��0����1���У�2���ң�
--		color, alpha			-- ��ɫ����͸����
--		checked				-- �Ƿ�ѡ��CheckBox ר��
--		enable					-- �Ƿ�����
--		file, icon, type		-- ͼƬ�ļ���ַ��ͼ���ţ�����
--		group					-- ��ѡ���������
-- }
-- ����ֵ��ͨ�õ�  GUI ���󣬿�ֱ�ӵ��÷�װ������ʧ�ܻ������ nil
-- �ر�ע�⣺Ϊͳһ�ӿڴ˺���Ҳ������ AppendIni �ļ��������� GUI.AppendIni һ��
-- (class) GUI.Append(userdata hParent, string szIniFile, string szTag, string szName)
GUI.Append = function(hParent, szType, szName, tArg)
	-- compatiable with AppendIni
	if StringFindW(szType, ".ini") ~= nil then
		return GUI.AppendIni(hParent, szType, szName, tArg)
	end
	-- reset parameters
	if not tArg and type(szName) == "table" then
		szName, tArg = nil, szName
	end
	if not szName then
		if not hParent.nAutoIndex then
			hParent.nAutoIndex = 1
		end
		szName = szType .. "_" .. hParent.nAutoIndex
		hParent.nAutoIndex = hParent.nAutoIndex + 1
	else
		szName = tostring(szName)
	end
	-- create ui
	local ui = nil
	if string.sub(szType, 1, 3) == "Wnd" then
		assert(string.sub(hParent:GetType(), 1, 3) == "Wnd", _L["The 1st arg for adding component must be a [WndXxx]"])
		ui = _GUI.Wnd.new(hParent, szType, szName)
	else
		assert(hParent:GetType() == "Handle", _L["The 1st arg for adding item must be a [Handle]"])
		ui = _GUI.Item.new(hParent, szType, szName)
	end
	local raw = ui:Raw()
	if raw then
		-- for reverse fetching
		hParent.___uis = hParent.___uis or {}
		for k, v in pairs(hParent.___uis) do
			if not v.self.___id then
				hParent.___uis[k] = nil
			end
		end
		hParent.___uis[szName] = ui
		hParent.___last = szName
		-- apply init setting
		tArg = tArg or {}
		if tArg.w and tArg.h then ui:Size(tArg.w, tArg.h) end
		if tArg.x and tArg.y then ui:Pos(tArg.x, tArg.y) end
		if tArg.font then ui:Font(tArg.font) end
		if tArg.multi ~= nil then ui:Multi(tArg.multi) end
		if tArg.limit then ui:Limit(tArg.limit) end
		if tArg.color then ui:Color(unpack(tArg.color)) end
		if tArg.align ~= nil then ui:Align(tArg.align) end
		if tArg.alpha then ui:Alpha(tArg.alpha) end
		if tArg.txt then ui:Text(tArg.txt) end
		if tArg.checked ~= nil then ui:Check(tArg.checked) end
		-- wnd only
		if tArg.enable ~= nil then ui:Enable(tArg.enable) end
		if tArg.group then ui:Group(tArg.group) end
		if ui.type == "WndComboBox" and (not tArg.w or not tArg.h) then
			ui:Size(185, 25)
		end
		-- item only
		if tArg.file then ui:File(tArg.file, tArg.num) end
		if tArg.icon ~= nil then ui:Icon(tArg.icon) end
		if tArg.type then ui:Type(tArg.type) end
		return ui
	end
end

-- (class) GUI(...)
-- (class) GUI.Fetch(hRaw)						-- �� hRaw ԭʼ����ת��Ϊ GUI ��װ����
-- (class) GUI.Fetch(hParent, szName)	-- �� hParent ����ȡ��Ϊ szName ����Ԫ����ת��Ϊ GUI ����
-- ����ֵ��ͨ�õ�  GUI ���󣬿�ֱ�ӵ��÷�װ������ʧ�ܻ������ nil
GUI.Fetch = function(hParent, szName)
	if type(hParent) == "string" then
		hParent = Station.Lookup(hParent)
	end
	if not szName then
		szName = hParent:GetName()
		hParent = hParent:GetParent()
	end
	-- exists
	if hParent.___uis and hParent.___uis[szName] then
		local ui = hParent.___uis[szName]
		if ui and ui.self.___id then
			return ui
		end
	end
	-- convert
	local hRaw = hParent:Lookup(szName)
	if hRaw then
		local ui
		if string.sub(hRaw:GetType(), 1, 3) == "Wnd" then
			ui = _GUI.Wnd.new(hRaw)
		else
			ui = _GUI.Item.new(hRaw)
		end
		hParent.___uis = hParent.___uis or {}
		hParent.___uis[szName] = ui
		return ui
	end
end

GUI.RegisterPanel = function(szTitle, dwIcon, szClass, fn)
	-- find class
	local dwClass = nil
	if not szClass then
		dwClass = 1
	else
		for k, v in ipairs(_JH.tClass) do
			if v == szClass then
				dwClass = k
			end
		end
		if not dwClass then
			tinsert(_JH.tClass, szClass)
			dwClass = table.getn(_JH.tClass)
			_JH.tItem[dwClass] = {}
		end
	end
	-- check to update
	for _, v in ipairs(_JH.tItem[dwClass]) do
		if v.szTitle == szTitle then
			v.dwIcon, v.fn, dwClass = dwIcon, fn, nil
			break
		end
	end
	-- create new one
	if dwClass then
		tinsert(_JH.tItem[dwClass], { szTitle = szTitle, dwIcon = dwIcon, fn = fn })
	end
	if _JH.frame then
		_JH.UpdateTabBox(_JH.frame)
	end
	if fn and fn.OnConflictCheck then
		_JH.RegisterConflictCheck(fn.OnConflictCheck)
	end
end

GUI.UnRegisterPanel = function(szTitle)
	local find = false
	for k, vv in pairs(_JH.tItem) do
		for _, v in ipairs(vv) do
			if v.szTitle == szTitle then
				tremove(vv, _)
				find = true
				break
			end
		end
	end
	if _JH.frame and find then
		_JH.UpdateTabBox(_JH.frame)
	end
end

-- ����ѡ�����
GUI.OpenFontTablePanel = function(fnAction)
	local wnd = GUI.CreateFrame2("JH_FontTable", { w = 1000, h = 630, title = g_tStrings.FONT, close = true }):RegisterClose()
	for i = 0, 236 do
		wnd:Append("Text", { x = (i % 15) * 65 + 10, y = floor(i / 15) * 35 + 15, alpha = 200, txt = g_tStrings.FONT .. i, font = i })
		:Click(function()
			if fnAction then fnAction(i) end
			wnd:Remove()
		end)
		:Hover(function(bHover)
			if bHover then
				this:SetAlpha(255)
			else
				this:SetAlpha(200)
			end
		end)
	end
end

-- ��ɫ��
GUI.OpenColorTablePanel = function(fnAction)
	local wnd = GUI.CreateFrame2("JH_ColorTable", { w = 900, h = 500, title = _L["Color Picker"], close = true }):RegisterClose()
	local fnHover = function(bHover, r, g, b, img)
		if bHover then
			wnd:Fetch("Select"):Color(r, g, b)
			wnd:Fetch("Select_Text"):Text(string.format("r=%d, g=%d, b=%d", r, g, b))
		else
			wnd:Fetch("Select"):Color(255, 255, 255)
			wnd:Fetch("Select_Text"):Text(g_tStrings.STR_NONE)
		end
	end
	local fnClick = function( ... )
		if fnAction then fnAction( ... ) end
		if not IsCtrlKeyDown() then wnd:Remove() end
	end
	for nRed = 1, 8 do
		for nGreen = 1, 8 do
			for nBlue = 1, 8 do
				local x = 20 + ((nRed - 1) % 4) * 220 + (nGreen - 1) * 25
				local y = 10 + math.modf((nRed - 1) / 4) * 220 + (nBlue - 1) * 25
				local r, g, b  = nRed * 32 - 1, nGreen * 32 - 1, nBlue * 32 - 1
				wnd:Append("Shadow", { w = 23, h = 23, x = x, y = y, color = { r, g, b } })
				:Hover(function(bHover)
					wnd:Fetch("Select_Image"):Pos(this:GetRelPos()):Toggle(bHover)
					fnHover(bHover, r, g, b, img)
				end)
				:Click(function()
					fnClick(r, g, b)
				end)
			end
		end
	end
	
	for i = 1, 16 do
		local x = 480 + (i - 1) * 25
		local y = 435
		local r, g, b  = i * 16 - 1, i * 16 - 1, i * 16 - 1
		local key = x .. y
		wnd:Append("Shadow", { w = 23, h = 23, x = x, y = y, color = { r, g, b }, alpha = 200 })
		:Hover(function(bHover)
			wnd:Fetch("Select_Image"):Pos(this:GetRelPos()):Toggle(bHover)
			fnHover(bHover, r, g, b)
		end)
		:Click(function()
			fnClick(r, g, b)
		end)
	end
	wnd:Append("Image", "Select_Image", { w = 23, h = 23 }):File("ui/Image/Common/Box.Uitex", 9):Toggle(false)
	wnd:Append("Shadow", "Select", { w = 25, h = 25, x = 20, y = 435 })
	wnd:Append("Text", "Select_Text", { x = 65, y = 435 })
end
