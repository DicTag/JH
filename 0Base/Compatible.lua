-- @Author: Webster
-- @Date:   2015-01-21 15:21:19
-- @Last Modified by:   Webster
-- @Last Modified time: 2015-12-04 17:25:08

DBM_TYPE = {
	OTHER           = 0,
	BUFF_GET        = 1,
	BUFF_LOSE       = 2,
	NPC_ENTER       = 3,
	NPC_LEAVE       = 4,
	NPC_TALK        = 5,
	NPC_LIFE        = 6,
	NPC_FIGHT       = 7,
	SKILL_BEGIN     = 8,
	SKILL_END       = 9,
	SYS_TALK        = 10,
	NPC_ALLLEAVE    = 11,
	NPC_DEATH       = 12,
	NPC_ALLDEATH    = 13,
	TALK_MONITOR    = 14,
	COMMON          = 15,
	NPC_MANA        = 16,
	DOODAD_ENTER    = 17,
	DOODAD_LEAVE    = 18,
	DOODAD_ALLLEAVE = 19,
}
DBM_SCRUTINY_TYPE = { SELF  = 1, TEAM  = 2, ENEMY = 3, TARGET = 4 }

-- skillid, uitex, frame
JH_KUNGFU_LIST = {
	-- MT
	{ 10062, "ui/Image/icon/skill_tiance01.UITex", 0 }, -- ����
	{ 10243, "ui/Image/icon/mingjiao_taolu_7.UITex", 0 }, -- ����
	{ 10389, "ui/Image/icon/Skill_CangY_33.UITex", 0 }, -- ����
	{ 10002, "ui/Image/icon/skill_shaolin14.UITex", 0 }, -- ����
	-- ����
	{ 10080, "ui/Image/icon/skill_qixiu02.UITex", 0 }, -- ����
	{ 10176, "ui/Image/icon/wudu_neigong_2.UITex", 0 }, -- ����
	{ 10028, "ui/Image/icon/skill_wanhua23.UITex", 0 }, -- �뾭
	{ 10448, "ui/Image/icon/skill_0514_23.UITex", 0 }, -- ��֪
	-- �ڹ�
	{ 10225, "ui/Image/icon/skill_tangm_20.UITex", 0 }, -- ����
	{ 10081, "ui/Image/icon/skill_qixiu03.UITex", 0 }, -- ����
	{ 10175, "ui/Image/icon/wudu_neigong_1.UITex", 0 }, -- ����
	{ 10242, "ui/Image/icon/mingjiao_taolu_8.UITex", 0 }, -- ��Ӱ
	{ 10014, "ui/Image/icon/skill_chunyang21.UITex", 0 }, -- ��ϼ
	{ 10021, "ui/Image/icon/skill_wanhua17.UITex", 0 }, -- ����
	{ 10003, "ui/Image/icon/skill_shaolin10.UITex", 0 }, -- �׾�
	{ 10447, "ui/Image/icon/skill_0514_27.UITex", 0 }, -- Ī��
	-- �⹦
	{ 10390, "ui/Image/icon/Skill_CangY_32.UITex", 0 }, -- ��ɽ
	{ 10224, "ui/Image/icon/skill_tangm_01.UITex", 0 }, -- ����
	{ 10144, "ui/Image/icon/cangjian_neigong_1.UITex", 0 }, -- ��ˮ
	{ 10145, "ui/Image/icon/cangjian_neigong_2.UITex", 0 }, -- ɽ��
	{ 10015, "ui/Image/icon/skill_chunyang13.UITex", 0 }, -- ��̥����
	{ 10026, "ui/Image/icon/skill_tiance02.UITex", 0 }, -- ��ѩ
	{ 10268, "ui/Image/icon/skill_GB_30.UITex", 0 }, -- Ц��

}

setmetatable(JH_KUNGFU_LIST, { __index = function(me, key)
	for k, v in pairs(me) do
		if v[1] == key then
			return v
		end
	end
end })

JH_FORCE_COLOR = {
	[0]  = { 255, 255, 255 },
	[1]  = { 255, 178, 95  },
	[2]  = { 196, 152, 255 },
	[3]  = { 255, 111, 83  },
	[4]  = { 89,  224, 232 },
	[5]  = { 255, 129, 176 },
	[6]  = { 55,  147, 255 },
	[7]  = { 121, 183, 54  },
	[8]  = { 214, 249, 93  },
	[9]  = { 205, 133, 63  },
	[10] = { 240, 70,  96  },
	[21] = { 180, 60,  0   },
	[22] = { 100, 250, 180 }
}

setmetatable(JH_FORCE_COLOR, {
	__index = function()
		return { 225, 225, 225 }
	end,
	__metatable = true,
})

JH_TALK_CHANNEL_HEADER = {
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
}
-- ��ͬ���ֵĵ�ͼ ȫ��ָ��ͬһ��ID
JH_MAP_NAME_FIX = {
	[143] = 147,
	[144] = 147,
	[145] = 147,
	[146] = 147,
	[195] = 196,
}

if not PEEK_OTHER_PLAYER_RESPOND then
	PEEK_OTHER_PLAYER_RESPOND = {
		INVALID = 0,
		SUCCESS = 1,
		FAILED = 2,
		CAN_NOT_FIND_PLAYER = 3,
		TOO_FAR = 4
	}
end
if not BATTLE_FIELD_NOTIFY_TYPE then
	BATTLE_FIELD_NOTIFY_TYPE = {
		LEAVE_BLACK_LIST = 5,
		IN_BLACK_LIST = 4,
		LEAVE_BATTLE_FIELD = 3,
		JOIN_BATTLE_FIELD = 2,
		QUEUE_INFO = 1,
		INVALID = 0
	}
end

if not ARENA_NOTIFY_TYPE then
	ARENA_NOTIFY_TYPE = {
		IN_BLACK_LIST = 5,
		LEAVE_BLACK_LIST = 4,
		LOG_OUT_ARENA_MAP = 3,
		LOG_IN_ARENA_MAP = 2,
		ARENA_QUEUE_INFO = 1,
	}
end
if not ACTION_STATE then
	ACTION_STATE = {
		NONE = 1,
		PREPARE = 2,
		DONE = 3,
		BREAK = 4,
		FADE = 5,
	}
end
GLOBAL_HEAD_CLIENTPLAYER = GLOBAL_HEAD_CLIENTPLAYER or 0
GLOBAL_HEAD_OTHERPLAYER = GLOBAL_HEAD_OTHERPLAYER or 1
GLOBAL_HEAD_NPC = GLOBAL_HEAD_NPC or 2

GLOBAL_HEAD_LEFE = GLOBAL_HEAD_LEFE or 0
GLOBAL_HEAD_GUILD = GLOBAL_HEAD_GUILD or 1
GLOBAL_HEAD_TITLE = GLOBAL_HEAD_TITLE or 2
GLOBAL_HEAD_NAME = GLOBAL_HEAD_NAME or 3
BigBagPanel_nCount = 6

--���ֿ��������һ������λ��
INVENTORY_GUILD_BANK = INVENTORY_GUILD_BANK or INVENTORY_INDEX.TOTAL + 1
INVENTORY_GUILD_PAGE_SIZE = INVENTORY_GUILD_PAGE_SIZE or 100

-- middle map
if not CloseWorldMap then
function CloseWorldMap(bDisableSound)
	local frame = Station.Lookup("Topmost1/WorldMap")
	if frame then
		frame:Hide()
	end
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
	end
	-- FIXME��FireDataAnalysisEvent
end
end
if not IsMiddleMapOpened then
function IsMiddleMapOpened()
	local frame = Station.Lookup("Topmost1/MiddleMap")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end
end
if not OpenMiddleMap then
function OpenMiddleMap(dwMapID, nIndex, bTraffic, bDisableSound)
	CloseWorldMap(true)
	local frame = Station.Lookup("Topmost1/MiddleMap")
	if frame then
		frame:Show()
	else
		frame = Wnd.OpenWindow("MiddleMap")
	end
	MiddleMap.bTraffic = bTraffic
	MiddleMap.ShowMap(frame, dwMapID, nIndex)
	MiddleMap.UpdateTraffic(frame, bTraffic)
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
	-- FIXME��OnClientAddAchievement
	MiddleMap.nLastAlpha = MiddleMap.nAlpha
end
end

-- target level
if not GetTargetLevelFont then
function GetTargetLevelFont(nLevelDiff)
	local nFont = 16
	if nLevelDiff > 4 then	-- ��
		nFont = 159
	elseif nLevelDiff > 2 then	-- ��
		nFont = 168
	elseif nLevelDiff > -3 then	-- ��
		nFont = 16
	elseif nLevelDiff > -6 then	-- ��
		nFont = 167
	else	-- ��
		nFont = 169
	end
	return nFont
end
end

-- arena mapt
if not IsInArena then
function IsInArena()
	local me = GetClientPlayer()
	return me ~= nil and me.GetScene().bIsArenaMap
end
end

-- battle map
if not IsInBattleField then
function IsInBattleField()
	local me = GetClientPlayer()
	return me ~= nil and g_tTable.BattleField:Search(me.GetScene().dwMapID) ~= nil
end
end

-- internet exploere
if not OpenInternetExplorer then
function IsInternetExplorerOpened(nIndex)
	local frame = Station.Lookup("Topmost/IE"..nIndex)
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function IE_GetNewIEFramePos()
	local nLastTime = 0
	local nLastIndex = nil
	for i = 1, 10, 1 do
		local frame = Station.Lookup("Topmost/IE"..i)
		if frame and frame:IsVisible() then
			if frame.nOpenTime > nLastTime then
				nLastTime = frame.nOpenTime
				nLastIndex = i
			end
		end
	end
	if nLastIndex then
		local frame = Station.Lookup("Topmost/IE"..nLastIndex)
		x, y = frame:GetAbsPos()
		local wC, hC = Station.GetClientSize()
		if x + 890 <= wC and y + 630 <= hC then
			return x + 30, y + 30
		end
	end
	return 40, 40
end

function OpenInternetExplorer(szAddr, bDisableSound)
	local nIndex, nLast = nil, nil
	for i = 1, 10, 1 do
		if not IsInternetExplorerOpened(i) then
			nIndex = i
			break
		elseif not nLast then
			nLast = i
		end
	end
	if not nIndex then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MSG_OPEN_TOO_MANY)
		return nil
	end
	local x, y = IE_GetNewIEFramePos()
	local frame = Wnd.OpenWindow("InternetExplorer", "IE"..nIndex)
	frame.bIE = true
	frame.nIndex = nIndex

	frame:BringToTop()
	if nLast then
		frame:SetAbsPos(x, y)
		frame:CorrectPos()
		frame.x = x
		frame.y = y
	else
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		frame.x, frame.y = frame:GetAbsPos()
	end
	local webPage = frame:Lookup("WebPage_Page")
	if szAddr then
		webPage:Navigate(szAddr)
	end
	Station.SetFocusWindow(webPage)
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
	return webPage
end
end

-- dialogue panel
if not IsDialoguePanelOpened then
function IsDialoguePanelOpened()
	local frame = Station.Lookup("Normal/DialoguePanel")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end
end

-- doodad loot
if not IsCorpseAndCanLoot then
function IsCorpseAndCanLoot(dwDoodadID)
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
		return false
	end
	return (doodad.nKind == DOODAD_KIND.CORPSE and doodad.CanLoot(GetClientPlayer().dwID))
end
end

-- get segment name
if not Table_GetSegmentName then
function Table_GetSegmentName(dwBookID, dwSegmentID)
	local szSegmentName = ""
	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szSegmentName = tBookSegment.szSegmentName
	end
	return szSegmentName
end
end

-- get item name by item
if not GetItemNameByItem then
function GetItemNameByItem(item)
	if item.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	else
		return Table_GetItemName(item.nUiId)
	end
end
end

-- hotkey panel
function HotkeyPanel_Open(szGroup)
	local frame = Station.Lookup("Topmost/HotkeyPanel")
	if not frame then
		frame = Wnd.OpenWindow("HotkeyPanel")
	elseif not frame:IsVisible() then
		frame:Show()
	end
	if not szGroup then return end
	-- load aKey
	local aKey, nI, bindings = nil, 0, Hotkey.GetBinding(false)
	for k, v in pairs(bindings) do
		if v.szHeader ~= "" then
			if aKey then
				break
			elseif v.szHeader == szGroup then
				aKey = {}
			else
				nI = nI + 1
			end
		end
		if aKey then
			if not v.Hotkey1 then
				v.Hotkey1 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
			end
			if not v.Hotkey2 then
				v.Hotkey2 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
			end
			table.insert(aKey, v)
		end
	end
	if not aKey then return end
	local hP = frame:Lookup("", "Handle_List")
	local hI = hP:Lookup(nI)
	if hI.bSel then return end
	-- update list effect
	for i = 0, hP:GetItemCount() - 1 do
		local hB = hP:Lookup(i)
		if hB.bSel then
			hB.bSel = false
			if hB.IsOver then
				hB:Lookup("Image_Sel"):SetAlpha(128)
				hB:Lookup("Image_Sel"):Show()
			else
				hB:Lookup("Image_Sel"):Hide()
			end
		end
	end
	hI.bSel = true
	hI:Lookup("Image_Sel"):SetAlpha(255)
	hI:Lookup("Image_Sel"):Show()
	-- update content keys [hI.nGroupIndex]
	local hK = frame:Lookup("", "Handle_Hotkey")
	local szIniFile = "UI/Config/default/HotkeyPanel.ini"
	Hotkey.SetCapture(false)
	hK:Clear()
	hK.nGroupIndex = hI.nGroupIndex
	hK:AppendItemFromIni(szIniFile, "Text_GroupName")
	hK:Lookup(0):SetText(szGroup)
	hK:Lookup(0).bGroup = true
	for k, v in ipairs(aKey) do
		hK:AppendItemFromIni(szIniFile, "Handle_Binding")
		local hI = hK:Lookup(k)
		hI.bBinding = true
		hI.nIndex = k
		hI.szTip = v.szTip
		hI:Lookup("Text_Name"):SetText(v.szDesc)
		for i = 1, 2, 1 do
			local hK = hI:Lookup("Handle_Key"..i)
			hK.bKey = true
			hK.nIndex = i
			local hotkey = v["Hotkey"..i]
			hotkey.bUnchangeable = v.bUnchangeable
			hK.bUnchangeable = v.bUnchangeable
			local text = hK:Lookup("Text_Key"..i)
			text:SetText(GetKeyShow(hotkey.nKey, hotkey.bShift, hotkey.bCtrl, hotkey.bAlt))
			-- update btn
			if hK.bUnchangeable then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(56)
			elseif hK.bDown then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
			elseif hK.bRDown then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
			elseif hK.bSel then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(55)
			elseif hK.bOver then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(54)
			elseif hotkey.bChange then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(56)
			elseif hotkey.bConflict then
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(54)
			else
				hK:Lookup("Image_Key"..hK.nIndex):SetFrame(53)
			end
		end
	end
	-- update content scroll
	hK:FormatAllItemPos()
	local wAll, hAll = hK:GetAllItemSize()
    local w, h = hK:GetSize()
    local scroll = frame:Lookup("Scroll_Key")
    local nCountStep = math.ceil((hAll - h) / 10)
    scroll:SetStepCount(nCountStep)
	scroll:SetScrollPos(0)
	if nCountStep > 0 then
		scroll:Show()
    	scroll:GetParent():Lookup("Btn_Up"):Show()
    	scroll:GetParent():Lookup("Btn_Down"):Show()
    else
    	scroll:Hide()
    	scroll:GetParent():Lookup("Btn_Up"):Hide()
    	scroll:GetParent():Lookup("Btn_Down"):Hide()
    end
	-- update list scroll
	local scroll = frame:Lookup("Scroll_List")
	if scroll:GetStepCount() > 0 then
		local _, nH = hI:GetSize()
		local nStep = math.ceil((nI * nH) / 10)
		if nStep > scroll:GetStepCount() then
			nStep = scroll:GetStepCount()
		end
		scroll:SetScrollPos(nStep)
	end
end
---------------------------------------------------------------------
-- Combat text wnd
---------------------------------------------------------------------
local _JH_CombatText = {
	tTextQueue = {},
	g_MaxTraceNumber = 32,
	g_BowledTip = { X = {}, Y = {} },
	g_BowledScale = {},
	g_ExpLog = { X = {}, Y = {} },
	g_ExpLogScale = {},
	g_ExpAlpha = {},
}

-- ��ȡ��������
_JH_CombatText.GetFreeText = function(handle)
	local nItemCount = handle:GetItemCount()
	local nIndex
	if handle.nUseCount < nItemCount then
		local nEnd = nItemCount - 1
		for i = 0, nEnd, 1 do
			local hItem = handle:Lookup(i)
			if hItem.bFree then
				hItem.bFree = false
				handle.nUseCount = handle.nUseCount + 1
				return hItem
			end
		end
	else
		handle:AppendItemFromString("<text> w=550 h=100 halign=1 valign=1 multiline=1 </text>")
		local hItem = handle:Lookup(handle.nUseCount)
		hItem.bFree = false
		handle.nUseCount = handle.nUseCount + 1
		return hItem
	end
end

-- ��ȡ handle
_JH_CombatText.GetHandle = function()
	local handle = Station.Lookup("Lowest/CombatTextWnd", "") or Station.Lookup("Lowest/CombatTextWndEx", "")
	return handle
end

-- ������������
_JH_CombatText.NewText = function(dwCharacterID, szText, fScale, szName)
	local handle = _JH_CombatText.GetHandle()
	if not handle then
		return
	end
    local text = _JH_CombatText.GetFreeText(handle)
	table.insert(_JH_CombatText.tTextQueue, text)
    text:SetText(szText)
    text:SetName(szName)
    text:SetFontScheme(19)
    text:SetFontScale(1.0)
	text:SetAlpha(0)
    text:SetFontScale(fScale)
    text:AutoSize()
	text.aScale = nil
	text.Track = nil
	text.Alpha = nil
	text.dwOwner = dwCharacterID
	text.nFrameCount = 1
	text.fScale = fScale
	text:Hide()
	JH.ApplyTopPoint(function(nX, nY)
		if not nX then return end
		local nW, nH = text:GetSize()
		text:SetAbsPos(nX - nW / 2, nX - nH / 2)
		text:Show()
		text.xScreen = nX
		text.yScreen = nY
	end, dwCharacterID)
	return text
end

-- ��ʼ��������Ϣ
_JH_CombatText.OnInit = function()
	for i = 1, 64, 1 do
		if i <= _JH_CombatText.g_MaxTraceNumber * 0.6 then
			_JH_CombatText.g_BowledTip["X"][i] = 0
			_JH_CombatText.g_BowledTip["Y"][i] = -70
		elseif i <= _JH_CombatText.g_MaxTraceNumber * 0.75  then
			_JH_CombatText.g_BowledTip["X"][i] = 0
			_JH_CombatText.g_BowledTip["Y"][i] = -70
		else
			_JH_CombatText.g_BowledTip["X"][i] = 0
			_JH_CombatText.g_BowledTip["Y"][i] = -70
		end
	end
	for i = 1, 64, 1 do
		if i <= _JH_CombatText.g_MaxTraceNumber * 3/_JH_CombatText.g_MaxTraceNumber then
			_JH_CombatText.g_BowledScale[i] = i
		elseif i <= _JH_CombatText.g_MaxTraceNumber * 8/_JH_CombatText.g_MaxTraceNumber  then
			_JH_CombatText.g_BowledScale[i] = 2.8
		elseif i <= _JH_CombatText.g_MaxTraceNumber * 9/_JH_CombatText.g_MaxTraceNumber then
			_JH_CombatText.g_BowledScale[i] = 2.6
		else
			_JH_CombatText.g_BowledScale[i] = 1.5
		end
	end
	for i = 1, 64, 1 do
		if i <= _JH_CombatText.g_MaxTraceNumber * 0.6 then
			_JH_CombatText.g_ExpLog["X"][i] = 0
			_JH_CombatText.g_ExpLog["Y"][i] = 0
		elseif i <= _JH_CombatText.g_MaxTraceNumber * 0.75  then
			_JH_CombatText.g_ExpLog["X"][i] = 0
			_JH_CombatText.g_ExpLog["Y"][i] = 0
		else
			_JH_CombatText.g_ExpLog["X"][i] = 0
			_JH_CombatText.g_ExpLog["Y"][i] = 0
		end
	end
	for i = 1, 64, 1 do
		if i <= _JH_CombatText.g_MaxTraceNumber * 3/_JH_CombatText.g_MaxTraceNumber then
			_JH_CombatText.g_ExpLogScale[i] = i
		elseif i <= _JH_CombatText.g_MaxTraceNumber * 5/_JH_CombatText.g_MaxTraceNumber  then
			_JH_CombatText.g_ExpLogScale[i] = 4.5
		elseif i <= _JH_CombatText.g_MaxTraceNumber * 6/_JH_CombatText.g_MaxTraceNumber  then
			_JH_CombatText.g_ExpLogScale[i] = 2.8
		else
			_JH_CombatText.g_ExpLogScale[i] = 1.5
		end
	end
	for i = 1, 48, 1 do
		if i <= 8 then
			_JH_CombatText.g_ExpAlpha[i] = i / 8 * 255
		elseif i <= 40 then
			_JH_CombatText.g_ExpAlpha[i] = 255
		else
			_JH_CombatText.g_ExpAlpha[i] = ( 1- ( i - 40) / 8 ) * 255
		end
	end
end

-- ���ɸ�������Ч����������
_JH_CombatText.OnBreathe = function()
	local handle = _JH_CombatText.GetHandle()
	if not handle or #_JH_CombatText.tTextQueue == 0 then
		return
	end
	if not _JH_CombatText.bInit then
		_JH_CombatText.OnInit()
		_JH_CombatText.bInit = true
	end
	for nIndex = #_JH_CombatText.tTextQueue, 1, -1 do
		local bRemove = false
        local text = _JH_CombatText.tTextQueue[nIndex]
        if text:IsValid() then
            local nFrameCount = text.nFrameCount
			local nX = text.Track.X[nFrameCount % _JH_CombatText.g_MaxTraceNumber + 1]
			local nY = text.Track.Y[nFrameCount % _JH_CombatText.g_MaxTraceNumber + 1]
			if nX and nY then
				local nDeltaPosX = nX * 3	--�ֲ�����ϵX�ı���ϵ��
				local nDeltaPosY = nY * 3	--�ֲ�����ϵY�ı���ϵ��
				local fScale = text.fScale
				local dwOwner = text.dwOwner
				if text.aScale and text.aScale[nFrameCount] then
					fScale = text.aScale[nFrameCount]
				end
				text.nFrameCount = nFrameCount + 2 --������ٶ�
				nFrameCount = nFrameCount + 2 --������ٶ�
				local nFadeInFrame = 4		-- COMBAT_TEXT_FADE_IN_FRAME
				local nHoldFrame =20			-- COMBAT_TEXT_HOLD_FRAME
				local nFadeOutFrame = 8	-- COMBAT_TEXT_FADE_OUT_FRAME
				if fScale ~= text.fScale then
					text.fScale = fScale
					text:SetFontScale(fScale)
					text:AutoSize()
				end
				if text.Alpha then
					local alpha = text.Alpha[nFrameCount]
					if alpha then
						text:SetAlpha(alpha)
					else
						bRemove = true
					end
				else
					if nFrameCount < nFadeInFrame then
						text:SetAlpha(255 * nFrameCount / nFadeInFrame)
					elseif nFrameCount < nFadeInFrame + nHoldFrame then
						text:SetAlpha(255)
					elseif nFrameCount < nFadeInFrame + nHoldFrame + nFadeOutFrame then
						text:SetAlpha(255 * (1 - (nFrameCount - nFadeInFrame - nHoldFrame) / nFadeOutFrame))
					else
						bRemove = true
					end
				end
				-- adjust pos/size
				if not bRemove then
					local fnAction = function(nOrgX, nOrgY)
						if not nOrgX then return end
						--����ÿ��任
						local cxText, cyText = text:GetSize()
						nOrgX = nOrgX - cxText / 2
						nOrgY = nOrgY - cyText / 2
						-- �������ֵ���,����
						local nNextPosX =  nOrgX + nDeltaPosX
						local nNextPosY =  nOrgY + nDeltaPosY
						text:SetAbsPos(nNextPosX, nNextPosY)
					end
					if dwOwner == GetClientPlayer().dwID then
						fnAction(text.xScreen, text.yScreen)
					else
						JH.ApplyTopPoint(fnAction, dwOwner)
					end
				end
			else
				bRemove = true
			end
        end
        if bRemove then
			text.bFree = true
			text:Hide()
			handle.nUseCount = handle.nUseCount - 1
			table.remove(_JH_CombatText.tTextQueue, nIndex)
        end
    end
end

-- functions
if not OnCharacterHeadLog then
function OnCharacterHeadLog(dwCharacterID, szTip, nFont, tColor, bMultiLine)
    local text = _JH_CombatText.NewText(dwCharacterID, szTip, 1, "Scores")
	if text then
		if nFont then
			text:SetFontScheme(nFont)
		end
		if tColor then
			text:SetFontColor(unpack(tColor))
		else
			text:SetFontColor(0, 128, 199)
		end
		text:SetMultiLine(bMultiLine or false)
		text.Track = _JH_CombatText.g_ExpLog
		text.aScale = _JH_CombatText.g_ExpLogScale
		text.Alpha = _JH_CombatText.g_ExpAlpha
	end
end
JH.BreatheCall("CombatText", _JH_CombatText.OnBreathe)
end

if not OnBowledCharacterHeadLog then
function OnBowledCharacterHeadLog(dwCharacterID, szTip, nFont, tColor, bMultiLine)
    local text = _JH_CombatText.NewText(dwCharacterID, szTip, 1, "Bowled")
	if text then
		text:SetFontScheme(nFont or 199)
		if tColor then
			text:SetFontColor(unpack(tColor))
		end
		text:SetMultiLine(bMultiLine or false)
		text.Track = _JH_CombatText.g_BowledTip
		text.aScale = _JH_CombatText.g_BowledScale
		text.Alpha = _JH_CombatText.g_ExpAlpha
	end
end
JH.BreatheCall("CombatText", _JH_CombatText.OnBreathe)
end

if not DoAcceptJoinBattleField then
function DoAcceptJoinBattleField(nCenterIndex, dwMapID, nCopyIndex, nGroupID, dwJoinValue)
	JH.DoMessageBox("BattleField_Enter_" .. dwMapID, 1)
end
end

if not DoAcceptJoinArena then
function DoAcceptJoinArena(nArenaType, nCenterID, dwMapID, nCopyIndex, nGroupID, dwJoinValue, dwCorpsID)
	JH.DoMessageBox("Arena_Enter_" .. nArenaType, 1)
end
end

if not MakeNameLink then
function MakeNameLink(szName, szFont)
	local szLink = "<text>text=" .. EncodeComponentsString(szName) ..
	szFont .. " name=\"namelink\" eventid=515</text>"
	return szLink
end
end

if not GetCampImageFrame then
function GetCampImageFrame(eCamp, bFight)	-- ui\Image\UICommon\CommonPanel2.UITex
	local nFrame
	if eCamp == CAMP.GOOD then
		if bFight then
			nFrame = 117
		else
			nFrame = 7
		end
	elseif eCamp == CAMP.EVIL then
		if bFight then
			nFrame = 116
		else
			nFrame = 5
		end
	end
	return nFrame
end
end

if not EditBox_AppendLinkPlayer then
function EditBox_AppendLinkPlayer(szName)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	edit:InsertObj("[".. szName .."]", { type = "name", text = "[".. szName .."]", name = szName })
	Station.SetFocusWindow(edit)
	return true
end
end
if not EditBox_AppendLinkItem then
function EditBox_AppendLinkItem(dwID)
	local item = GetItem(dwID)
	if not item then
		return false
	end
	local szName = "[" .. GetItemNameByItem(item) .."]"
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	edit:InsertObj(szName, { type = "item", text = szName, item = item.dwID })
	Station.SetFocusWindow(edit)
	return true
end
end

if not IsInUICustomMode then
local bCustomMode = false
function IsInUICustomMode()
	return bCustomMode
end
JH.RegisterEvent("ON_ENTER_CUSTOM_UI_MODE", function()
	bCustomMode = true
end)
JH.RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE", function()
	bCustomMode = false
end)
end

if not Table_GetCommonEnchantDesc then
function Table_GetCommonEnchantDesc(enchant_id)
	local res = g_tTable.CommonEnchant:Search(enchant_id)
	if res then
		return res.desc
	end
end
end
if not Table_GetProfessionName then
function Table_GetProfessionName(dwProfessionID)
	local szName = ""
	local tProfession = g_tTable.ProfessionName:Search(dwProfessionID)
	if tProfession then
		szName = tProfession.szName
	end
	return szName
end
end
