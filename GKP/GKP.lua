-- @Author: Webster
-- @Date:   2015-01-21 15:21:19
-- @Last Modified by:   Webster
-- @Last Modified time: 2015-10-12 19:01:49

-- ���ڴ��� ��Ҫ��д

local PATH_ROOT = JH.GetAddonInfo().szRootPath .. "GKP/"
local _L = JH.LoadLangPack

GKP = {
	bDebug2              = false,
	bOn                  = true,  -- �Ƿ����߾Ϳ���
	bOn2                 = false, -- ���Ƿ����߹ر�
	bMoneyTalk           = false, -- ��Ǯ�䶯����
	bAlertMessage        = true,  -- ���븱�������������
	bMoneySystem         = false, -- ��¼ϵͳ��Ǯ�䶯
	bAutoSetMoney        = false, -- �Զ����÷���ʱ�Ľ�Ǯ
	bAutoBX              = true,  -- �Զ����ñ�����Ƭ�ļ۸�
	bDisplayEmptyRecords = true,  -- show 0 record
	bAutoSync            = true,  -- �Զ����շ����ߵ�ͬ����Ϣ
	bLootStyle           = true,
}
JH.RegisterCustomData("GKP")
---------------------------------------------------------------------->
-- ���غ��������
----------------------------------------------------------------------<
local _GKP = {
	szIniFile = PATH_ROOT .. "ui/GKP.ini",
	aDoodadCache = {}, -- ʰȡ�б�cache
	aDistributeList = {}, -- ��ǰʰȡ�б�
	tLootListMoney = {}, -- �����Ľ�Ǯcache
	tDistribute = {}, -- �������б�
	tEquipCache = {},
	tDistributeRecords = {},
	tDungeonList = {},
	tViewInvite = {},
	DeathWarn = {},
	tSyncQueue = {},
	bSync = {},
	GKP_Record = {},
	GKP_Account = {},
	Config = {
		Subsidies = {
			{ _L["Treasure Chests"], "", true},
			{ JH.GetItemName(73214), "", true},
			{ _L["Boss"], "", true},
			{ _L["Banquet Allowance"], -1000, true},
			{ _L["Fines"], "", true},
			{ _L["Other"], "", true},
		},
		Scheme = {
			{100,true},
			{1000,true},
			{2000,true},
			{3000,true},
			{4000,true},
			{5000,true},
			{6000,true},
			{7000,true},
			{8000,true},
			{9000,true},
			{10000,true},
			{20000,true},
			{50000,true},
			{100000,true},
		},
		Special = {
			[JH.GetItemName(72591)] = true,
			[JH.GetItemName(68362)] = true,
			[JH.GetItemName(66189)] = true,
			[JH.GetItemName(4097)]  = true,
			[JH.GetItemName(73214)] = true,
			[JH.GetItemName(74368)] = true,
		},
	}
}
_GKP.Config = JH.LoadLUAData("config/gkp.cfg") or _GKP.Config
---------------------------------------------------------------------->
-- ���ݴ���
----------------------------------------------------------------------<
setmetatable(GKP,{ __call = function(me, key, value, sort)
	if _GKP[key] then
		if value and type(value) == "table" then
			table.insert(_GKP[key], value)
			_GKP.GKP_Save()
		elseif value and type(value) == "string" then
			if sort == "asc" or sort == "desc" then
				table.sort(_GKP[key], function(a, b)
					if a[value] and b[value] then
						if sort == "asc" then
							return a[value] < b[value] or ( a[value] == b[value] and a.nTime < b.nTime or ( a.nTime == b.nTime and ((a.szName and b.szName and a.szName < b.szName) or false) ) )
						else
							return a[value] > b[value] or ( a[value] == b[value] and a.nTime > b.nTime or ( a.nTime == b.nTime and ((a.szName and b.szName and a.szName > b.szName) or false) ) )
						end
					else
						return false
					end
				end)
			elseif value == "del" then
				if _GKP[key][sort] then
					_GKP[key][sort].bDelete = not _GKP[key][sort].bDelete
					_GKP.GKP_Save()
					return _GKP[key][sort]
				end
			end
			return _GKP[key]
		elseif value and type(value) == "number" then
			if _GKP[key][value] then
				_GKP[key][value] = sort
				_GKP.GKP_Save()
				return _GKP[key][value]
			end
		else
			return _GKP[key]
		end
	end
end})

---------------------------------------------------------------------->
-- ���غ���
----------------------------------------------------------------------<
function _GKP.SaveConfig()
	JH.SaveLUAData("config/gkp.cfg", _GKP.Config)
end

function _GKP.GKP_Save()
	local me = GetClientPlayer()
	local szPath = "GKP/" .. me.szName .. "/" .. FormatTime("%Y-%m-%d",GetCurrentTime()) .. ".gkp"
	JH.SaveLUAData(szPath,{ GKP_Record = GKP("GKP_Record") , GKP_Account = GKP("GKP_Account") })
end

function _GKP.GKP_LoadData(szFile)
	local me = GetClientPlayer()
	local szPath = szFile .. ".gkp"
	local t = JH.LoadLUAData(szPath)
	if t then
		_GKP.GKP_Record = t.GKP_Record or {}
		_GKP.GKP_Account = t.GKP_Account or {}
	end
	_GKP.Draw_GKP_Record()
	_GKP.Draw_GKP_Account()
end
function _GKP.OpenLootPanel()
	if not Station.Lookup("Normal/GKP_Loot") then
		local loot = Wnd.OpenWindow(PATH_ROOT .. "ui/GKP_Loot.ini","GKP_Loot")
		loot:Hide()
		GUI(loot):Title(g_tStrings.STR_LOOT_SHOW_LIST):Point():RegisterClose(_GKP.CloseLootWindow)
		loot:Lookup("Btn_Style").OnLButtonClick = function()
			if IsCtrlKeyDown() then
				if #_GKP.aDistributeList > 0 then
					local t = {}
					for k,v in ipairs(_GKP.aDistributeList) do
						table.insert(t, GKP.GetFormatLink(v))
					end
					JH.Talk(t)
				end
				return
			end
			GKP.bLootStyle = not GKP.bLootStyle
			if _GKP.dwOpenID then
				_GKP.OnOpenDoodad(_GKP.dwOpenID)
			end
		end
	end
	return Station.Lookup("Normal/GKP_Loot")
end
function _GKP.OpenPanel(bDisableSound)
	local frame = Station.Lookup("Normal/GKP") or Wnd.OpenWindow(_GKP.szIniFile, "GKP")
	frame:Show()
	frame:BringToTop()
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	return frame
end
-- close
function _GKP.ClosePanel(bRealClose)
	if _GKP.frame then
		if not bRealClose then
			_GKP.frame:Hide()
		else
			Wnd.CloseWindow(_GKP.frame)
			_GKP.frame = nil
		end
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end
-- toggle
function _GKP.TogglePanel()
	if _GKP.frame and _GKP.frame:IsVisible() then
		_GKP.ClosePanel()
	else
		_GKP.OpenPanel()
	end
end
GKP.OpenPanel   = _GKP.OpenPanel
GKP.ClosePanel  = _GKP.ClosePanel
GKP.TogglePanel = _GKP.TogglePanel
-- initlization
function _GKP.Init()
	if not _GKP.bInit then
		local me = GetClientPlayer()
		Wnd.OpenWindow(PATH_ROOT .. "ui/GKP_Record.ini", "GKP_Record"):Hide()
		_GKP.OpenPanel(true):Hide()
		_GKP.nNowMoney = me.GetMoney().nGold
		_GKP.bInit = true
		JH.DelayCall(125, function() -- Init�Ӻ� ����ͽ��븱����ͻ
			_GKP.GKP_LoadData("GKP/" .. me.szName .. "/" .. FormatTime("%Y-%m-%d", GetCurrentTime()))
		end)
	end
end
JH.RegisterEvent("LOADING_END", _GKP.Init) -- LOADING_END ��Ҫ��Ϊ�˻�ȡ���� ����ѹ��������
-- OnMsgArrive
function _GKP.OnMsgArrive(szMsg)
	if not Station.Lookup("Normal/GKP_Chat") then return end
	local me = Station.Lookup("Normal/GKP_Chat/WndScroll_Chat")
	local h = me:Lookup("", "")
	szMsg = string.gsub(szMsg, _L["[Team]"], "")

	local AppendText = function()
		local t = TimeToDate(GetCurrentTime())
		return GetFormatText(string.format(" %02d:%02d:%02d ", t.hour, t.minute, t.second), 10, 255, 255, 255)
	end
	szMsg = AppendText() .. szMsg
	if MY and MY.Chat and MY.Chat.RenderLink then
		szMsg =  MY.Chat.RenderLink(szMsg)
	end
	if MY_Farbnamen and MY_Farbnamen.Render then
		szMsg = MY_Farbnamen.Render(szMsg)
	end
	local xml = "<image>path=" .. EncodeComponentsString("UI/Image/Button/ShopButton.uitex") .. " frame=1 eventid=786 w=20 h=20 script=\"this.OnItemLButtonClick=GKP.DistributionItem\nthis.OnItemMouseEnter=function() this:SetFrame(2) end\nthis.OnItemMouseLeave=function() this:SetFrame(1) end\"</<image>>"
	h:AppendItemFromString(xml)
	h:AppendItemFromString(szMsg)
	h:FormatAllItemPos()
	me:Lookup("Scroll_All"):ScrollEnd()
end
-- �������ͼ��Ԥ�� �ϸ��ж�
function GKP.DistributionItem()
	local h, i = this:GetParent(), this:GetIndex()
	if not h or not i then
		error("GKP_ERROR -> UI_ERROR")
	end
	local szName = string.match(h:Lookup(i+3):GetText(), "%[(.*)%]")
	local me = Station.Lookup("Normal/GKP_Chat")
	local box = me:Lookup("", "Box") or me:Lookup("", "iteminfolink") or me:Lookup("", "booklink") -- fix setname
	if not _GKP.dwOpenID then
		return JH.Alert(_L["No open doodad"])
	end
	local _, nUiId, dwID, nVersion, dwTabType, dwIndex = box:GetObject()
	local doodad = GetDoodad(_GKP.dwOpenID)
	if type(doodad) ~= "userdata" then return JH.Alert(_L["No open doodad"]) end
	_GKP.OnOpenDoodad(_GKP.dwOpenID)
	local item
	for k, v in ipairs(_GKP.aDistributeList) do
		if v.nUiId == nUiId and v.dwID == dwID and v.nVersion == nVersion and v.dwTabType == dwTabType and v.dwIndex == dwIndex then
			item = v
			break
		end
	end
	if not item then return JH.Alert(_L["The item was not found"]) end
	if not item.dwID then
		_GKP.OnOpenDoodad(_GKP.dwOpenID)
		return GKP.Sysmsg(_L["Userdata is overdue, distribut failed, please try again."])
	end

	local team = GetClientTeam()
	local aPartyMember = _GKP.GetaPartyMember(doodad)
	local p
	for k, v in ipairs(aPartyMember) do
		if v.szName == szName then
			p = v
			break
		end
	end
	if not p or (p and not p.bOnlineFlag) then -- bOnlineFlag ˢ����ʵ���ӳ�
		return JH.Alert(_L["No Pick up Object, may due to Network off - line"])
	end
	if p.dwMapID ~= GetClientPlayer().GetMapID() then
		return JH.Alert(_L["No Pick up Object, Please confirm that in the Dungeon."])
	end
	-- �������Ʒ�ʶ�����MessageBox ��ֹ����ֻ������ʲô��
	local r, g, b = JH.GetForceColor(p.dwForceID)
	local msg = {
		szMessage = FormatLinkString(
			g_tStrings.PARTY_DISTRIBUTE_ITEM_SURE,
			"font=162",
			GetFormatText("[".. GetItemNameByItem(item) .."]", "166"..GetItemFontColorByQuality(item.nQuality, true)),
			GetFormatText("[".. p.szName .."]", 162,r,g,b)
		),
		szName = "Distribute_Item_Sure",
		bRichText = true,
		{
			szOption = g_tStrings.STR_HOTKEY_SURE,
			fnAutoClose = function()
				return false
			end,
			fnAction = function()
				_GKP.DistributeItem(item,p,doodad)
			end
		},
		{szOption = g_tStrings.STR_HOTKEY_CANCEL},
	}
	MessageBox(msg)
end

function _GKP.SetChatWindow(item, ui)
	local me = Station.Lookup("Normal/GKP_Chat")
	if not me then
		me = Wnd.OpenWindow(PATH_ROOT .. "ui/GKP_Chat.ini","GKP_Chat")
		GUI(me):Point():RegisterClose(_GKP.CloseChatWindow):Append("WndButton2",{x = 380, y = 38,txt = _L["Stop Bidding"]}):Click(function()
			JH.Talk(_L["--- Stop Bidding ---"])
			JH.DelayCall(1000,function() UnRegisterMsgMonitor(_GKP.OnMsgArrive) end)
		end)
	end
	local box = me:Lookup("","Box") or me:Lookup("","iteminfolink") or me:Lookup("","booklink") -- fix setname
	local txt = me:Lookup("","Text")
	txt:SetText(GetItemNameByItem(item))
	txt:SetFontColor(GetItemFontColorByQuality(item.nQuality))
	local h = Station.Lookup("Normal/GKP_Chat/WndScroll_Chat"):Lookup("","")
	h:Clear()
	box:SetObject(UI_OBJECT_ITEM_ONLY_ID, item.nUiId, item.dwID, item.nVersion, item.dwTabType, item.dwIndex)
	local iName, iIcon = JH.GetItemName(item.nUiId)
	box:SetObjectIcon(iIcon)
	box.OnItemLButtonClick = ui.OnItemLButtonClick
	box.OnItemMouseLeave = ui.OnItemMouseLeave
	box.OnItemMouseEnter = ui.OnItemMouseEnter
	RegisterMsgMonitor(_GKP.OnMsgArrive,{"MSG_TEAM"})
	me:Show()
	Station.SetFocusWindow(me)
end

function _GKP.CloseChatWindow(bCheck)
	local me = Station.Lookup("Normal/GKP_Chat")
	if not me then return end
	if type(bCheck) == "userdata" then
		local box = me:Lookup("","Box") or me:Lookup("","iteminfolink") or me:Lookup("","booklink") -- fix setname
		local _,nUiId,dwID,nVersion,dwTabType,dwIndex = box:GetObject()
		if bCheck.nUiId ~= nUiId or bCheck.dwID ~= dwID or bCheck.nVersion ~= nVersion or bCheck.dwTabType ~= dwTabType or bCheck.dwIndex ~= dwIndex then
			return
		end
	end
	UnRegisterMsgMonitor(_GKP.OnMsgArrive)
	Wnd.CloseWindow(Station.Lookup("Normal/GKP_Chat"))
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function _GKP.CloseLootWindow()
	Wnd.CloseWindow(Station.Lookup("Normal/GKP_Loot"))
	_GKP.dwOpenID = nil
	_GKP.CloseChatWindow(true)
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

---------------------------------------------------------------------->
-- ���ú���
----------------------------------------------------------------------<
function GKP.Random() -- ����һ������ַ��� �⻹���ظ��ҳ���
	local a = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,_+;*-"
	local t = {}
	for i = 1, 64 do
		local n = math.random(1, string.len(a))
		table.insert(t, string.sub(a, n ,n))
	end
	return table.concat(t)
end

function GKP.Sysmsg(szMsg)
	JH.Sysmsg(szMsg, "[GKP]")
end

function GKP.GetTimeString(nTime, year)
	if year then
		return FormatTime("%H:%M:%S", nTime)
	else
		return FormatTime("%Y-%m-%d %H:%M:%S", nTime)
	end
end

function GKP.GetMoneyCol(Money)
	local Money = tonumber(Money)
	if Money then
		if Money < 0 then
			return 0, 128, 255
		elseif Money < 1000 then
			return 255, 255, 255
		elseif Money < 10000 then
			return 255, 255, 164
		elseif Money < 100000 then
			return 255, 255, 0
		elseif Money < 1000000 then
			return 255, 192, 0
		elseif Money < 10000000 then
			return 255, 92, 0
		else
			return 255, 0, 0
		end
	else
		return 255, 255, 255
	end
end

---------------------------------------------------------------------->
-- ��ʽ������
----------------------------------------------------------------------<
function GKP.GetFormatLink(item, bName)
	if type(item) == "string" then
		if bName then
			return { type = "name", name = item, text = "[" .. item .."]" }
		else
			return { type = "text", text = item }
		end
	else
		if item.nGenre == ITEM_GENRE.BOOK then
			return { type = "book", tabtype = item.dwTabType, index = item.dwIndex, bookinfo = item.nBookID, version = item.nVersion, text = "" }
		else
			return { type = "iteminfo", version = item.nVersion, tabtype = item.dwTabType, index = item.dwIndex, text = "" }
		end
	end
end

function GKP.OnItemLinkDown(item,ui)
	ui.nVersion = item.nVersion
	ui.dwTabType = item.dwTabType
	ui.dwIndex = item.dwIndex
	if item.nGenre == ITEM_GENRE.BOOK then
		ui.nBookRecipeID = BookID2GlobelRecipeID(GlobelRecipeID2BookID(item.nBookID))
		ui:SetName("booklink")
	else
		ui:SetName("iteminfolink")
	end
	return OnItemLinkDown(ui)
end
---------------------------------------------------------------------->
-- ��ȡ�Ŷӳ�Ա menu
----------------------------------------------------------------------<
function GKP.GetTeamList()
	local TeamMemberList = GetClientTeam().GetTeamMemberList()
	local tTeam,menu = {},{}
	for _,v in ipairs(TeamMemberList) do
		local player = GetClientTeam().GetMemberInfo(v)
		table.insert(tTeam,{ szName = player.szName ,dwForce = player.dwForceID})
	end
	table.sort(tTeam,function(a,b) return a.dwForce < b.dwForce end)
	for _,v in ipairs(tTeam) do
		local szIcon,nFrame = GetForceImage(v.dwForce)
		table.insert(menu,{
			szOption = v.szName,
			szLayer = "ICON_RIGHT",
			szIcon = szIcon,
			nFrame = nFrame ,
			rgb = {JH.GetForceColor(v.dwForce)},
			fnAction = function()
				local list = GUI(Station.Lookup("Normal1/GKP_Record/TeamList"))
				local teamlist = list:Text(v.szName):Color(JH.GetForceColor(v.dwForce)).self
				teamlist.dwForceID = v.dwForce
			end
		})
	end
	return menu
end

---------------------------------------------------------------------->
-- ���崴��ʱ�ᱻ����
----------------------------------------------------------------------<
function GKP.OnFrameCreate()
	_GKP.frame = this
	_GKP.GKP_Record_Container = this:Lookup("PageSet_Menu/Page_GKP_Record/WndScroll_GKP_Record/WndContainer_Record_List")
	_GKP.GKP_Account_Container = this:Lookup("PageSet_Menu/Page_GKP_Account/WndScroll_GKP_Account/WndContainer_Account_List")
	_GKP.GKP_Buff_Container = this:Lookup("PageSet_Menu/Page_GKP_Buff/WndScroll_GKP_Buff/WndContainer_Buff_List")
	local frm = Station.Lookup("Normal1/GKP_Record")
	local ui = GUI(this)
	local PageSet = ui:Fetch("PageSet_Menu")
	local record = GUI(frm)
	ui:Title(_L["GKP Golden Team Record"]):Point():RegisterClose(_GKP.ClosePanel):Append("WndComboBox", { x = 805, y = 52, txt = _L["Setting"] }):Click(function()
		JH.OpenPanel(_L["GKP Golden Team Record"])
	end)
	PageSet:Append("WndButton3", { x = 15, y = 610, txt = _L["Add Manually"] }):Click(function()
		if IsCtrlKeyDown() and JH_About.CheckNameEx() then -- ��г����
			return _GKP.GKP_Bidding()
		end
		if record:IsVisible() then
			return JH.Alert(_L["No Record For Current Object."])
		end
		if not JH.IsDistributer() and not JH_About.CheckNameEx() then -- debug
			return JH.Alert(_L["You are not the distrubutor."])
		end
		_GKP.Record()
	end)
	PageSet:Append("WndButton3", { x = 840, y = 570, txt = g_tStrings.GOLD_TEAM_SYLARY_LIST }):Click(_GKP.GKP_Calculation)
	PageSet:Append("WndButton3", "GOLD_TEAM_BID_LIST", {x = 840, y = 610, txt = g_tStrings.GOLD_TEAM_BID_LIST }):Click(_GKP.GKP_SpendingList)
	PageSet:Append("WndButton3", "Debt", { x = 690, y = 610, txt = _L["Debt Issued"] }):Click(_GKP.GKP_OweList)
	PageSet:Append("WndButton3", { x = 540, y = 610, txt = _L["Wipe Record"] }):Click(_GKP.GKP_Clear)
	PageSet:Append("WndButton3", { x = 390, y = 610, txt = _L["Loading Record"] }):Click(_GKP.GKP_Recovery)
	PageSet:Append("WndButton3", { x = 240, y = 610, txt = _L["Manual SYNC"] }):Click(_GKP.GKP_Sync)

	PageSet:Fetch("WndCheck_GKP_Record"):Fetch("Text_GKP_Record"):Text(g_tStrings.GOLD_BID_RECORD_STATIC_TITLE)
	PageSet:Fetch("WndCheck_GKP_Account"):Fetch("Text_GKP_Account"):Text(g_tStrings.GOLD_BID_RPAY_STATIC_TITLE)

	record:Title(_L["GKP Golden Team Record"]):Point():RegisterClose(function()
		if this.userdata then
			record:Fetch("Money"):Text(0)
			return record:Fetch("btn_ok"):Click()
		end
		record:Toggle(false)
		FireUIEvent("GKP_DEL_DISTRIBUTE_ITEM")
	end)

	-- append text
	record:Append("Text",{x = 60,y = 50,font = 65,txt = _L["Keep Account to:"]})
	record:Append("Text",{x = 60,y = 124,font = 65,txt = _L["Name of the Item:"]})
	record:Append("Text",{x = 60,y = 154,font = 65,txt = _L["Route of Acquiring:"]})
	record:Append("Text",{x = 60,y = 184,font = 65,txt = _L["Auction Price:"]})
	record:Append("WndCheckBox", "WndCheckBox",{x = 20,y = 300,font = 65,txt = _L["Equiptment Boss"]})
	record:Append("WndButton3", "btn_ok", {x = 115,y = 300,txt = g_tStrings.STR_HOTKEY_SURE})
	record:Append("WndComboBox", "TeamList", {x = 135,y = 53,txt = g_tStrings.PLAYER_NOT_EMPTY}):Menu(GKP.GetTeamList)
	record:Append("WndEdit", "Source", {x = 135,y = 155,w = 185,h = 25})

	record:Append("WndEdit", "Name", {x = 135, y = 125, w = 185, h = 25}):Autocomplete(function(szText)
		local tList = {}
		for k, v in ipairs(_GKP.Config.Subsidies) do
			if v[3] then
				table.insert(tList, { szOption = v[1], data = v })
			end
		end
		return tList
	end, function(szText, data)
		if data then
			record:Fetch("Money"):Focus()
		end
	end)

	record:Append("WndEdit", "Money", { x = 135, y = 185 ,w = 185, h = 25, limit = 8 }):Type(1):Autocomplete(function(szText)
		if tonumber(szText) and tonumber(szText) <= 1000 and tonumber(szText) >= -1000 and tonumber(szText) ~= 0 then
			local menu = {}
			for k, v in ipairs({2, 3, 4}) do
				local nMoney = string.format("%0.".. v .."f", szText):gsub("%.", "")
				table.insert(menu, {
					szOption = nMoney,
					rgb = { GKP.GetMoneyCol(nMoney) },
					szLayer = "ICON_RIGHT",
					nFrame = 11,
					szIcon = "ui/image/LootPanel/LootPanel.UITex",
				})
			end
			return menu
		else
			return {}
		end
	end):Change(function(szText)
		if tonumber(szText) or szText == "" or szText == "-" then
			this.txt = szText
			this:SetFontColor(GKP.GetMoneyCol(szText))
		else
			JH.Sysmsg(_L["Please enter numbers"])
			this:SetText(this.txt or "")
		end
	end)

	-- ����
	local page = this:Lookup("PageSet_Menu/Page_GKP_Record")
	local t = {
		{"#",         false},
		{"szPlayer",  _L["Gainer"]},
		{"szName",    _L["Name of the Items"]},
		{"nMoney",    _L["Auction Price"]},
		{"szNpcName", _L["Source of the Object"]},
		{"nTime",     _L["Distribution Time"]},
	}
	for k, v in ipairs(t) do
		if v[2] then
			local txt = page:Lookup("", "Text_Record_Break" ..k)
			txt:RegisterEvent(786)
			txt:SetText(v[2])
			txt.OnItemLButtonClick = function()
				local sort = txt.sort or "asc"
				_GKP.Draw_GKP_Record(v[1], sort)
				if sort == "asc" then
					txt.sort = "desc"
				else
					txt.sort = "asc"
				end
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			txt.OnItemMouseLeave = function()
				this:SetFontColor(255, 255, 255)
			end
		end
	end

	-- ����2
	local page = this:Lookup("PageSet_Menu/Page_GKP_Account")
	local t = {
		{"#",        false},
		{"szPlayer", _L["Transation Target"]},
		{"nGold",    _L["Changes in Money"]},
		{"szPlayer", _L["Ways of Money Change"]},
		{"dwMapID",  _L["The Map of Current Location when Money Changes"]},
		{"nTime",    _L["The Change of Time"]},
	}

	for k, v in ipairs(t) do
		if v[2] then
			local txt = page:Lookup("", "Text_Account_Break" .. k)
			txt:RegisterEvent(786)
			txt:SetText(v[2])
			txt.OnItemLButtonClick = function()
				local sort = txt.sort or "asc"
				_GKP.Draw_GKP_Account(v[1], sort)
				if sort == "asc" then
					txt.sort = "desc"
				else
					txt.sort = "asc"
				end
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255, 128, 0)
			end
			txt.OnItemMouseLeave = function()
				this:SetFontColor(255, 255, 255)
			end
		end
	end

end
---------------------------------------------------------------------->
-- ��ȡ���ò˵�
----------------------------------------------------------------------<
local PS = {}
PS.OnPanelActive = function(frame)
	local ui, nX, nY = GUI(frame), 10, 0
	ui:Append("Text", { x = 0, y = 0, txt = _L["Preference Setting"], font = 27 })
	ui:Append("WndButton3", { x = 350, y = 0 }):Text(_L["Open Panel"]):Click(_GKP.OpenPanel)
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = 28, checked = GKP.bDisplayEmptyRecords })
	:Text(_L["Clause with 0 Gold as Record"]):Click(function(bChecked)
		GKP.bDisplayEmptyRecords = bChecked
		_GKP.Draw_GKP_Record()
	end):Pos_()
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = nY, checked = GKP.bAutoSetMoney })
	:Text(_L["Auto Fill Money by Clicking Right Button"]):Click(function(bChecked)
		GKP.bAutoSetMoney = bChecked
	end):Pos_()
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = nY, checked = GKP.bAutoBX })
	:Text(_L["Auto Fill the amount of BiXi Fragment as Price"]):Click(function(bChecked)
		GKP.bAutoBX = bChecked
	end):Pos_()
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = nY, checked = GKP.bAlertMessage })
	:Text(_L["Remind Wipe Data When Enter Dungeon"]):Click(function(bChecked)
		GKP.bAlertMessage = bChecked
	end):Pos_()
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = nY, checked = GKP.bAutoSync })
	:Text(_L["Automatic Reception with Record From Distributor"]):Click(function(bChecked)
		GKP.bAutoSync = bChecked
	end):Pos_()
	nX = ui:Append("WndComboBox", { x = 10, y = nY,w = 130,h = 30 })
	:Text(_L["Popup with Record Options"]):Menu(function()
		return {
			{ szOption = _L["Popup Record for Distributor"],bCheck = true,bChecked = GKP.bOn,fnAction = function()
				GKP.bOn = not GKP.bOn
			end},
			{ szOption = _L["Popup Record for Nondistributor"],bCheck = true,bChecked = GKP.bOn2,fnAction = function()
				GKP.bOn2 = not GKP.bOn2
				if GKP.bOn2 then
					GKP.bAutoSync = false
				else
					GKP.bAutoSync = true
				end
			end},
		}
	end):Pos_()
	nX = ui:Append("WndComboBox", { x = nX + 10, y = nY,w = 130,h = 30 })
	:Text(_L["Edit Allowance Protocols"]):Menu(_GKP.GetSubsidiesMenu):Pos_()
	nX,nY = ui:Append("WndComboBox", { x = nX + 10, y = nY,w = 130,h = 30 })
	:Text(_L["Edit Auction Protocols"]):Menu(_GKP.GetSchemeMenu):Pos_()
	nX,nY = ui:Append("Text", { x = 0, y = nY, txt = _L["Money Record"], font = 27 }):Pos_()
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = nY + 12, checked = GKP.bMoneySystem })
	:Text(_L["Track Money Trend in the System"]):Click(function(bChecked)
		GKP.bMoneySystem = bChecked
	end):Pos_()
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = nY, checked = GKP.bMoneyTalk })
	:Text(_L["Enable Money Trend"]):Click(function(bChecked)
		GKP.bMoneyTalk = bChecked
	end):Pos_()
	if JH_About.CheckNameEx() then
		ui:Append("WndCheckBox", { x = 360, y = nY, checked = GKP.bDebug2 })
		:Text(_L["Debug Mode"]):Click(function(bChecked)
			GKP.bDebug2 = not GKP.bDebug2
		end)
	end
end
GUI.RegisterPanel(_L["GKP Golden Team Record"], { "ui/Image/Common/Money.uitex", 15 }, g_tStrings.CHANNEL_CHANNEL, PS)

---------------------------------------------------------------------->
-- ��ȡ���������˵�
----------------------------------------------------------------------<
_GKP.GetSubsidiesMenu = function()
	local menu = { szOption = _L["Edit Allowance Protocols"], rgb = { 255, 0, 0 } }
	table.insert(menu, {
		szOption = _L["Add New Protocols"],
		rgb = { 255, 255, 0 },
		fnAction = function()
			GetUserInput(_L["New Protocol  Format: Protocol's Name, Money"], function(txt)
				local t = JH.Split(txt, ",")
				table.insert(_GKP.Config.Subsidies, { t[1], tonumber(t[2]) or "", true })
				_GKP.SaveConfig()
			end)
		end
	})
	table.insert(menu, { bDevide = true})
	for k, v in ipairs(_GKP.Config.Subsidies) do
		table.insert(menu, {
			szOption = v[1],
			bCheck = true,
			bChecked = v[3],
			fnAction = function()
				v[3] = not v[3]
				_GKP.SaveConfig()
			end,
		})
	end
	return menu
end
---------------------------------------------------------------------->
-- ��ȡ���������˵�
----------------------------------------------------------------------<
_GKP.GetSchemeMenu = function()
	local menu = { szOption = _L["Edit Auction Protocols"], rgb = { 255, 0, 0 } }
	table.insert(menu,{
		szOption = _L["Edit All Protocols"],
		rgb = { 255, 255, 0 },
		fnAction = function()
			GetUserInput(_L["New Protocol Format: Money, Money, Money"], function(txt)
				local t = JH.Split(txt, ",")
				_GKP.Config.Scheme = {}
				for k, v in ipairs(t) do
					table.insert(_GKP.Config.Scheme, { tonumber(v) or 0, true })
				end
				_GKP.SaveConfig()
			end)
		end
	})
	table.insert(menu, { bDevide = true })
	for k, v in ipairs(_GKP.Config.Scheme) do
		table.insert(menu,{
			szOption = v[1],
			bCheck = true,
			bChecked = v[2],
			fnAction = function()
				v[2] = not v[2]
				_GKP.SaveConfig()
			end,
		})
	end

	return menu
end

---------------------------------------------------------------------->
-- ������Ʒ��¼
----------------------------------------------------------------------<
_GKP.Draw_GKP_Record = function(key,sort)
	local key = key or _GKP.GKP_Record_Container.key or "nTime"
	local sort = sort or _GKP.GKP_Record_Container.sort or "desc"
	local tab = GKP("GKP_Record",key,sort)
	_GKP.GKP_Record_Container.key = key
	_GKP.GKP_Record_Container.sort = sort
	_GKP.GKP_Record_Container:Clear()
	local a, b = _GKP.GetRecordSum()
	local c = 0
	for k, v in ipairs(tab) do
		if GKP.bDisplayEmptyRecords or v.nMoney ~= 0 then
			local wnd = _GKP.GKP_Record_Container:AppendContentFromIni(PATH_ROOT .. "ui/GKP_Record_Item.ini", "WndWindow", k)
			local item = wnd:Lookup("", "")
			if k % 2 == 0 then
				item:Lookup("Image_Line"):Hide()
			end
			if v.bDelete then
				wnd:SetAlpha(80)
			end
			item:RegisterEvent(32)
			item.OnItemRButtonClick = function()
				if not JH.IsDistributer() then
					return JH.Alert(_L["You are not the distrubutor."])
				end
				_GKP.Record(v, k)
			end
			item:Lookup("Text_No"):SetText(k)
			item:Lookup("Image_NameIcon"):FromUITex(GetForceImage(v.dwForceID))
			item:Lookup("Text_Name"):SetText(v.szPlayer)
			item:Lookup("Text_Name"):SetFontColor(JH.GetForceColor(v.dwForceID))
			local szName = v.szName or JH.GetItemName(v.nUiId)
			item:Lookup("Text_ItemName"):SetText(szName)
			if v.nQuality then
				item:Lookup("Text_ItemName"):SetFontColor(GetItemFontColorByQuality(v.nQuality))
			else
				item:Lookup("Text_ItemName"):SetFontColor(255, 255, 0)
			end
			item:Lookup("Text_Money"):SetText(v.nMoney)
			item:Lookup("Text_Money"):SetFontColor(GKP.GetMoneyCol(v.nMoney))

			item:Lookup("Text_Source"):SetText(v.szNpcName)
			if v.bSync then
				item:Lookup("Text_Source"):SetFontColor(0,255,0)
			end
			item:Lookup("Text_Time"):SetText(GKP.GetTimeString(v.nTime))
			if v.bEdit then
				item:Lookup("Text_Time"):SetFontColor(255,255,0)
			end
			local box = item:Lookup("Box_Item")
			if v.dwTabType == 0 and v.dwIndex == 0 then
				box:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
				box:SetObjectIcon(582)
			else
				UpdataItemInfoBoxObject(box, v.nVersion, v.dwTabType, v.dwIndex, v.nStackNum)
			end
			local hItemName = item:Lookup("Text_ItemName")
			for kk, vv in ipairs({"OnItemMouseEnter", "OnItemMouseLeave", "OnItemLButtonDown", "OnItemLButtonUp"}) do
				hItemName[vv] = function()
					if box[vv] then
						this = box
						box[vv]()
					end
				end
			end
			wnd:Lookup("WndButton_Delete").OnLButtonClick = function()
				if not JH.IsDistributer() and not JH_About.CheckNameEx() then
					return JH.Alert(_L["You are not the distrubutor."])
				end
				local tab = GKP("GKP_Record", "del", k)
				if JH.IsDistributer() then
					JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "del", tab)
				end
				_GKP.Draw_GKP_Record()
			end

			wnd:Lookup("WndButton_Edit").OnLButtonClick = function()
				if not JH.IsDistributer() and not JH_About.CheckNameEx() then
					return JH.Alert(_L["You are not the distrubutor."])
				end
				_GKP.Record(v, k)
			end

			-- tip
			item:Lookup("Text_Name"):RegisterEvent(786)
			item:Lookup("Text_Name").OnItemLButtonClick = function()
				if IsCtrlKeyDown() then
					return EditBox_AppendLinkPlayer(v.szPlayer)
				end
			end

			item:Lookup("Text_Name").OnItemMouseEnter = function()
				local szIcon, nFrame = GetForceImage(v.dwForceID)
				local r, g, b = JH.GetForceColor(v.dwForceID)
				local szXml = GetFormatImage(szIcon,nFrame,20,20) .. GetFormatText("  " .. v.szPlayer .. g_tStrings.STR_COLON .. "\n", 136, r, g, b)
				if IsCtrlKeyDown() then
					szXml = szXml .. GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP .. "\n", 136, 255, 0, 0)
					szXml = szXml .. GetFormatText(var2str(v, " "), 136, 255, 255, 255)
				else
					szXml = szXml .. GetFormatText(_L["System Information as Shown Below\n\n"],136,255,255,255)
					local nNum,nNum1,nNum2 = 0,0,0
					for kk,vv in ipairs(GKP("GKP_Record")) do
						if vv.szPlayer == v.szPlayer and not vv.bDelete then
							if  vv.nMoney > 0 then
								nNum = nNum + vv.nMoney
							else
								nNum1 = nNum1 + vv.nMoney
							end
						end
					end
					local r,g,b = GKP.GetMoneyCol(nNum)
					szXml = szXml .. GetFormatText(_L["Total Cosumption:"],136,255,128,0) .. GetFormatText(nNum ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. "\n",136,r,g,b)
					local r,g,b = GKP.GetMoneyCol(nNum1)
					szXml = szXml .. GetFormatText(_L["Total Allowance:"],136,255,128,0) .. GetFormatText(nNum1 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. "\n",136,r,g,b)

					for kk,vv in ipairs(GKP("GKP_Account")) do
						if vv.szPlayer == v.szPlayer and not vv.bDelete and vv.nGold > 0 then
							nNum2 = nNum2 + vv.nGold
						end
					end
					local r,g,b = GKP.GetMoneyCol(nNum2)
					szXml = szXml .. GetFormatText(_L["Total Payment:"],136,255,128,0) .. GetFormatText(nNum2 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. "\n",136,r,g,b)
					local nNum3 = nNum+nNum1-nNum2
					if nNum3 < 0 then
						nNum3 = 0
					end
					local r,g,b = GKP.GetMoneyCol(nNum3)
					szXml = szXml .. GetFormatText(_L["Money on Debt:"],136,255,128,0) .. GetFormatText(nNum3 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. "\n",136,r,g,b)
				end
				local x, y = item:Lookup("Text_No"):GetAbsPos()
				local w, h = item:Lookup("Text_No"):GetSize()
				OutputTip(szXml, 400, { x, y, w, h })
			end

			item:Lookup("Text_Name").OnItemMouseLeave = function()
				HideTip()
			end

			if v.bDelete then
				c = c + 1
			end
		end
	end

	_GKP.GKP_Record_Container:FormatAllContentPos()
	local txt = Station.Lookup("Normal/GKP/PageSet_Menu/Page_GKP_Record", "Text_GKP_RecordSettlement")
	txt:SetText(_L("Statistic: real salary = %d Gold(By Auction: %d Gold + Extra Allowance: %d Gold) %d record has been deleted.", a + b, a, b, c))
	txt:SetFontColor(GKP.GetMoneyCol(a + b))
	FireUIEvent("GKP_RECORD_TOTAL", a, b)
end
---------------------------------------------------------------------->
-- ��г
----------------------------------------------------------------------<
_GKP.GKP_Bidding = function()
	local team = GetClientTeam()
	if not JH.IsDistributer() then
		return JH.Alert(_L["You are not the distrubutor."])
	end
	local nGold = _GKP.GetRecordSum(true)
	if nGold <= 0 then
		return JH.Alert(_L["Auction Money <=0."])
	end
	local t, fnAction = {}, nil
	InsertDistributeMenu(t, false)
	for k, v in ipairs(t[1]) do
		if v.szOption == g_tStrings.STR_LOOTMODE_GOLD_BID_RAID then
			fnAction = v.fnAction
			break
		end
	end
	team.SetTeamLootMode(PARTY_LOOT_MODE.BIDDING)
	local LeaderAddMoney = Wnd.OpenWindow("LeaderAddMoney")
	local fx, fy = Station.GetClientSize()
	local w2, h2 = LeaderAddMoney:GetSize()
	LeaderAddMoney:SetAbsPos((fx - w2) / 2, (fy - h2) / 2)
	LeaderAddMoney:Lookup("Edit_Price"):SetText(nGold)
	LeaderAddMoney:Lookup("Edit_Reason"):SetText("Auto Append Money")
	LeaderAddMoney:Lookup("Btn_Ok").OnLButtonUp = function()
		fnAction()
		Station.SetActiveFrame("GoldTeam")
		Station.Lookup("Normal/GoldTeam"):Lookup("PageSet_Total"):ActivePage(1)
	end
end
---------------------------------------------------------------------->
-- ͬ������
----------------------------------------------------------------------<
_GKP.GKP_Sync = function()
	local me = GetClientPlayer()
	if me.IsInParty() then
		local tMember = GetClientTeam().GetTeamMemberList()
		local tTeam,menu = {},{}
		for _,v in ipairs(tMember) do
			local player = GetClientTeam().GetMemberInfo(v)
			table.insert(tTeam, { szName = player.szName, dwID = v, dwForce = player.dwForceID, bIsOnLine = player.bIsOnLine})
		end
		table.sort(tTeam, function(a, b) return a.dwForce < b.dwForce end)
		table.insert(menu, { szOption = _L["Please select which will be the one you are going to ask record for."], bDisable = true })
		table.insert(menu, { bDevide = true })
		for _, v in ipairs(tTeam) do
			if v.dwID ~= me.dwID then
				local szIcon, nFrame = GetForceImage(v.dwForce)
				table.insert(menu, {
					szOption = v.szName,
					szLayer  = "ICON_RIGHT",
					bDisable = not v.bIsOnLine,
					szIcon   = szIcon,
					nFrame   = nFrame,
					rgb      = { JH.GetForceColor(v.dwForce) },
					fnAction = function()
						JH.Confirm(_L["Wheater replace the current record with the synchronization target's record?\n Please notice, this means you are going to lose the information of current record."], function()
							JH.Alert(_L["Asking for the sychoronization information...\n If no response in longtime, it may because the opposite side are not using GKP plugin or not responding."])
							JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_Sync", v.szName) -- ����ͬ����Ϣ
						end)
					end
				})
			end
		end
		PopupMenu(menu)
	else
		JH.Alert(_L["You are not in the team."])
	end
end

local SYNC_LENG = 0

JH.RegisterBgMsg("GKP", function(nChannel, dwID, szName, data, bIsSelf)
	local me = GetClientPlayer()
	local team = GetClientTeam()
	if team then
		if not bIsSelf then
			if data[1] == "GKP_Sync" and data[2] == me.szName then
				local tab = {
					GKP_Record  = GKP("GKP_Record"),
					GKP_Account = GKP("GKP_Account"),
				}
				local str = JH.JsonEncode(tab)
				local nMax = 600
				local nTotle = math.ceil(#str / nMax)
				-- ����Ƶ������������ ������̫����
				JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_Sync_Start", dwID, nTotle)
				for i = 1, nTotle do
					JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_Sync_Content", dwID, string.sub(str ,(i-1) * nMax + 1, i * nMax))
				end
				JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_Sync_Stop", dwID)
			end

			if data[2] == me.dwID then
				if data[1] == "GKP_Sync_Start" then
					_GKP.bSync, SYNC_LENG = true, data[3]
					JH.Alert(_L["Start Sychoronizing..."])
				end

				if data[1] == "GKP_Sync_Content" and _GKP.bSync then
					table.insert(_GKP.tSyncQueue, data[3])
					if SYNC_LENG ~= 0 then
						local percent = #_GKP.tSyncQueue / SYNC_LENG
						JH.Topmsg(_L("Sychoronizing data please wait %d%% loaded.", percent * 100))
					end
				end
				if data[1] == "GKP_Sync_Stop" then
					local str = table.concat(_GKP.tSyncQueue)
					_GKP.tSyncQueue = {}
					_GKP.bSync, SYNC_LENG = false, 0
					JH.Alert(_L["Sychoronization Complete"])
					JH.Topmsg(_L["Sychoronization Complete"])
					local tData, err = JH.JsonDecode(str)
					if err then
						return GKP.Sysmsg(_L["Abnormal with Data Sharing, Please contact and make feed back with the writer."])
					end
					JH.Confirm(_L("Data Sharing Finished, you have one last chance to confirm wheather cover the current data or not? \n data of team bidding: %s\n transation data: %s", #tData.GKP_Record, #tData.GKP_Account), function()
						_GKP.GKP_Record  = tData.GKP_Record
						_GKP.GKP_Account = tData.GKP_Account
						_GKP.Draw_GKP_Record()
						_GKP.Draw_GKP_Account()
						_GKP.GKP_Save()
					end)
				end
			end

			if (data[1] == "del" or data[1] == "edit" or data[1] == "add") and GKP.bAutoSync then
				local tab = data[2]
				tab.bSync = true
				if data[1] == "add" then
					GKP("GKP_Record", tab)
				else
					for k, v in ipairs(GKP("GKP_Record")) do
						if v.key == tab.key then
							GKP("GKP_Record", k, tab)
							break
						end
					end
				end
				_GKP.Draw_GKP_Record()
				JH.Debug("#GKP# Sync Success")
			end
		end
		if data[1] == "GKP_INFO" then
			if data[2] == "Start" then
				local szFrameName = "GKP_info"
				if data[3] == "Information on Debt" then
					szFrameName = "GKP_Debt"
				end
				if data[3] == "Information on Debt" and szName ~= me.szName then
					return
				end
				local ui = GUI.CreateFrame(szFrameName, { w = 760, h = 350, title = _L["GKP Golden Team Record"], close = true }):Point()
				ui:Append("Text", { w = 725, h = 30, txt = _L[data[3]], align = 1, font = 199, color = { 255, 255, 0 } })
				ui:Append("WndButton2", "ScreenShot", { x = 590, y = 0, txt = _L["Print Ticket"], font = 41 })
				:Enable(false):Click(function()
					local scale = Station.GetUIScale()
					local left, top = ui:Pos()
					local right, bottom = ui:Pos_()
					local path = GetRootPath() .. string.format("\\ScreenShot\\GKP_Ticket_%s.png", FormatTime("%Y-%m-%d_%H.%M.%S", GetCurrentTime()))
					ScreenShot(path, 100, scale * left, scale * top, scale * right, scale * bottom)
					JH.Sysmsg(_L("Shot screen succeed, file saved as %s .", path))
				end)
				ui:Append("Text", { w = 120, h = 30, x = 0, y = 35, txt = _L("Operator:%s", szName), font = 41 })
				ui:Append("Text", { w = 200, h = 30, x = 520, align = 2, y = 35, txt = _L("Print Time:%s", GKP.GetTimeString(GetCurrentTime())), font = 41, align = 2 })
				_GKP.info = ui
			end
			if data[2] == "Info" then
				if data[3] == me.szName and tonumber(data[4]) and tonumber(data[4]) <= -100 then
					JH.OutputWhisper(data[3] .. g_tStrings.STR_COLON .. data[4] .. g_tStrings.STR_GOLD, "GKP")
				end
				local frm = Station.Lookup("Normal/GKP_info")
				if frm and frm.done then
					frm = Station.Lookup("Normal/GKP_Debt")
				end
				if not frm and Station.Lookup("Normal/GKP_Debt") then
					frm = Station.Lookup("Normal/GKP_Debt")
				end
				if frm then
					if not frm.n then frm.n = 0 end
					local n = frm.n
					local ui = GUI(frm)
					if n % 2 == 0 then
						ui:Append("Image", { w = 760, h = 30, x = 0, y = 120 + 30 * n }):File("ui/Image/button/ShopButton.UITex", 75)
					end
					local dwForceID, tBox = -1, {}
					if me.IsInParty() then
						for k, v in ipairs(team.GetTeamMemberList()) do
							if team.GetClientTeamMemberName(v) == data[3] then
								dwForceID = team.GetMemberInfo(v).dwForceID
							end
						end
					end
					for k, v in ipairs(GKP("GKP_Record")) do -- �����ڱ��ؼ�¼ ����Ҳ�����ܲ��쵽��ȥ
						if v.szPlayer == data[3] then
							if dwForceID == -1 then
								dwForceID = v.dwForceID
							end
							table.insert(tBox, v)
						end
					end
					if dwForceID ~= -1 then
						ui:Append("Image", { w = 28, h = 28, x = 30, y = 121 + 30 * n }):File(GetForceImage(dwForceID))
					end
					ui:Append("Text", { w = 140, h = 30, x = 60, y = 120 + 30 * n, txt = data[3], color = { JH.GetForceColor(dwForceID) } })
					local r, g, b = GKP.GetMoneyCol(data[4])
					if tonumber(data[4]) < 0 then
						r, g, b = GKP.GetMoneyCol(tonumber(data[4]) * - 1) -- ������Ƿծ ҲҪץ��ɫ
					end
					ui:Append("Text", { w = 80, h = 30, x = 200, y = 120 + 30 * n, txt = data[4], align = 2, color = { r, g, b } })
					ui:Append("Image", { w = 28, h = 28, x = 283, y = 121 + 30 * n }):File("ui/image/LootPanel/LootPanel.UITex", 11)
					for k, v in ipairs(tBox) do
						if k > 12 then
							ui:Append("Text", { x = 290 + k * 32 + 5, y = 121 + 30 * n, w = 28, h = 28, txt = ".....", font = 23 })
							break
						end
						local alpha = 255
						if v.bDelete then
							alpha = 60
						end
						local hBox = ui:Append("Box", { x = 290 + k * 32, y = 121 + 30 * n, w = 28, h = 28, alpha = alpha })

						if v.nUiId ~= 0 then
							UpdataItemInfoBoxObject(hBox.self, v.nVersion, v.dwTabType, v.dwIndex, v.nStackNum)
						else
							hBox:Icon(582):Hover(function(bHover)
								if bHover then
									local x, y = this:GetAbsPos()
									local w, h = this:GetSize()
									OutputTip(GetFormatText(v.szName .. g_tStrings.STR_TALK_HEAD_SAY1 .. v.nMoney .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP,136,255,255,0), 250, { x, y, w, h })
								else
									HideTip()
								end
							end)
						end
					end
					if frm.n > 5 then
						_GKP.info:Size(760, 30 * frm.n + 200)
					end
					frm.n = frm.n + 1
				end
			end
			if data[2] == "End" then
				local szFrameName = "GKP_Debt"
				if data[4] then
					szFrameName = "GKP_info"
				end
				local frm = Station.Lookup("Normal/" .. szFrameName)
				if frm then
					local ui = GUI(frm)
					local n = frm.n or 0
					ui:Append("Text", { w = 121, h = 30, x = 30, y = 120 + 30 * n + 1, txt = data[3], color = { 255, 255, 0 } })
					if data[4] then
						ui:Append("Text", { w = 121, h = 30, x = 620, y = 120 + 30 * n + 1, txt = string.format("%d/%d = %d", tonumber(data[4]), team.GetTeamSize(), math.floor(tonumber(data[4]) / team.GetTeamSize())), color = { GKP.GetMoneyCol(data[4]) }, align = 2 })
						if data[5] and tonumber(data[5]) then
							local nTime = tonumber(data[5])
							ui:Append("Text", { w = 725, h = 30, x = 0, y = 120 + 30 * n + 1, txt = _L("Spend time approx %d:%d", nTime / 3600, nTime % 3600 / 60), align = 1 })
						end
						_GKP.info:Fetch("ScreenShot"):Enable(true)
						if n >= 4 then
							ui:Append("Image", { x = 640, y = n * 30 + 10, w = 100, h = 107.5 }):File(JH.GetAddonInfo().szRootPath .. "GKP/img/zhcn_img.uitex", 0)
						end
						frm.done = true
					elseif  szFrameName == "GKP_Debt" and not frm:IsVisible() then
						Wnd.CloseWindow(frm)
						_GKP.info = nil
					end
				end
				_GKP.SetButton(true)
			end
		end
	end
end)

_GKP.SetButton = function(bEnable)
	GUI(Station.Lookup("Normal/GKP/PageSet_Menu")):Fetch("GOLD_TEAM_BID_LIST"):Enable(bEnable)
	GUI(Station.Lookup("Normal/GKP/PageSet_Menu")):Fetch("Debt"):Enable(bEnable)
end

---------------------------------------------------------------------->
-- �ָ���¼��ť
----------------------------------------------------------------------<
_GKP.GKP_Recovery = function()
	local me = GetClientPlayer()
	_GKP.szName = _GKP.szName or me.szName
	local menu = {}
	table.insert(menu,{
		szOption = _L("Loading Data of the Character's name: %s (edit by clicking)",_GKP.szName),
		rgb = {255,255,0},
		fnAction = function()
			GetUserInput(_L["Modify to Lead the Character's name"],function(szText)
				_GKP.szName = szText
			end)
		end
	})
	for i = 0 , 19 do
		local nTime = GetCurrentTime() - i * 86400
		local szPath = JH.GetAddonInfo().szDataPath .. "GKP/" .. _GKP.szName .. "/" .. FormatTime("%Y-%m-%d",nTime) .. ".gkp"
		table.insert(menu,{
			szOption = FormatTime("%Y-%m-%d",nTime) .. ".gkp",
			bDisable = not IsFileExist(szPath .. ".jx3dat"),
			fnAction = function()
				JH.Confirm(_L["Are you sure to cover the current information with the last record data?"],function()
					_GKP.GKP_LoadData("GKP/" .. _GKP.szName .. "/" .. FormatTime("%Y-%m-%d",nTime))
					JH.Alert(_L["Reocrd Recovered."])
				end)
			end,
		})
	end
	PopupMenu(menu)
end
---------------------------------------------------------------------->
-- �������
----------------------------------------------------------------------<
_GKP.GKP_Clear = function(bConfirm)
	local fnAction = function()
		_GKP.GKP_Record = {}
		_GKP.GKP_Account = {}
		_GKP.Draw_GKP_Record()
		_GKP.Draw_GKP_Account()
		_GKP.nNowMoney = GetClientPlayer().GetMoney().nGold
		_GKP.tDistributeRecords = {}
		JH.Alert(_L["Recods are wiped"])
	end
	if bConfirm then
		fnAction()
	else
		JH.Confirm(_L["Are you sure to wipe all of the records?"], fnAction)
	end
end
---------------------------------------------------------------------->
-- Ƿ�����
----------------------------------------------------------------------<
_GKP.GKP_OweList = function()
	local me = GetClientPlayer()
	if not me.IsInParty() and not JH_About.CheckNameEx() then return JH.Alert(_L["You are not in the team."]) end
	local tMember = {}
	if IsEmpty(GKP("GKP_Record")) then
		return JH.Alert(_L["No Record"])
	end
	if not JH.IsDistributer() and not JH_About.CheckNameEx() then
		return JH.Alert(_L["You are not the distrubutor."])
	end
	_GKP.SetButton(false)
	for k,v in ipairs(GKP("GKP_Record")) do
		if not v.bDelete then
			if tonumber(v.nMoney) > 0 then
				if not tMember[v.szPlayer] then
					tMember[v.szPlayer] = 0
				end
				tMember[v.szPlayer] = tMember[v.szPlayer] + v.nMoney
			end
		end
	end
	local _Account = {}
	for k,v in ipairs(GKP("GKP_Account")) do
		if not v.bDelete and v.szPlayer and v.szPlayer ~= "System" then
			if tMember[v.szPlayer] then
				tMember[v.szPlayer] = tMember[v.szPlayer] - v.nGold
			else
				if not _Account[v.szPlayer] then
					_Account[v.szPlayer] = 0
				end
				_Account[v.szPlayer] = _Account[v.szPlayer] + v.nGold
			end
		end
	end
	-- Ƿ��
	local tMember2 = {}
	for k,v in pairs(tMember) do
		if v ~= 0 then
			table.insert(tMember2, { szName = k, nGold = v * -1 })
		end
	end
	-- ����
	for k,v in pairs(_Account) do
		if v > 0 then
			table.insert(tMember2, { szName = k, nGold = v })
		end
	end

	table.sort(tMember2, function(a,b) return a.nGold < b.nGold end)
	JH.Talk(_L["Information on Debt"])
	JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_INFO", "Start", "Information on Debt")
	for k,v in pairs(tMember2) do
		if v.nGold < 0 then
			JH.Talk({ GKP.GetFormatLink(v.szName, true), GKP.GetFormatLink(g_tStrings.STR_TALK_HEAD_SAY1 .. v.nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP) })
			JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_INFO", "Info", v.szName, v.nGold, "-")
		else
			JH.Talk({ GKP.GetFormatLink(v.szName, true), GKP.GetFormatLink(g_tStrings.STR_TALK_HEAD_SAY1 .. "+" .. v.nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP) })
			JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_INFO", "Info", v.szName, v.nGold, "+")
		end
	end
	local nGold, nGold2 = 0, 0
	for _,v in ipairs(GKP("GKP_Account")) do
		if not v.bDelete then
			if v.szPlayer and v.szPlayer ~= "System" then -- ����Ҫ�н��׶���
				if tonumber(v.nGold) > 0 then
					nGold = nGold + v.nGold
				else
					nGold2 = nGold2 + v.nGold
				end
			end
		end
	end
	if nGold ~= 0 then
		JH.Talk(_L("Received: %d Gold.", nGold))
	end
	if nGold2 ~= 0 then
		JH.Talk(_L("Spending: %d Gold.", nGold2 * -1))
	end
	JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_INFO", "End", _L("Received: %d Gold.", nGold))
end
---------------------------------------------------------------------->
-- ��ȡ�����ܶ�
----------------------------------------------------------------------<
_GKP.GetRecordSum = function(bAccurate)
	if IsEmpty(GKP("GKP_Record")) then
		return 0, 0
	end
	local a, b = 0, 0
	for k, v in ipairs(GKP("GKP_Record")) do
		if not v.bDelete then
			if tonumber(v.nMoney) > 0 then
				a = a + v.nMoney
			else
				b = b + v.nMoney
			end
		end
	end
	if bAccurate then
		return a + b
	else
		return a, b
	end
end
---------------------------------------------------------------------->
-- ���������ť
----------------------------------------------------------------------<
_GKP.GKP_SpendingList = function()
	local me = GetClientPlayer()
	if not me.IsInParty() and not JH_About.CheckNameEx() then return JH.Alert(_L["You are not in the team."]) end
	local tMember = {}
	if IsEmpty(GKP("GKP_Record")) then
		return JH.Alert(_L["No Record"])
	end
	if not JH.IsDistributer() and not JH_About.CheckNameEx() then
		return JH.Alert(_L["You are not the distrubutor."])
	end
	_GKP.SetButton(false)
	local tTime = {}
	for k, v in ipairs(GKP("GKP_Record")) do
		if not v.bDelete then
			if not tMember[v.szPlayer] then
				tMember[v.szPlayer] = 0
			end
			if tonumber(v.nMoney) > 0 then
				tMember[v.szPlayer] = tMember[v.szPlayer] + v.nMoney
			end
			table.insert(tTime, { nTime = v.nTime })
		end
	end
	table.sort(tTime, function(a, b)
		return a.nTime < b.nTime
	end)
	local nTime = tTime[#tTime].nTime - tTime[1].nTime -- �����ѵ�ʱ��

	JH.Talk(_L["--- Consumption ---"])
	JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_INFO", "Start", "--- Consumption ---")
	local sort = {}
	for k,v in pairs(tMember) do
		table.insert(sort,{ szName = k, nGold = v })
	end

	table.sort(sort,function(a,b) return a.nGold < b.nGold end)
	for k, v in ipairs(sort) do
		if v.nGold > 0 then
			JH.Talk({ GKP.GetFormatLink(v.szName, true), GKP.GetFormatLink(g_tStrings.STR_TALK_HEAD_SAY1 .. v.nGold .. g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP) })
		end
		JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_INFO", "Info", v.szName, v.nGold)
	end
	JH.Talk(_L("Toal Auction: %d Gold.", _GKP.GetRecordSum()))
	JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "GKP_INFO", "End", _L("Toal Auction: %d Gold.", _GKP.GetRecordSum()), _GKP.GetRecordSum(), nTime)
end
---------------------------------------------------------------------->
-- ���㹤�ʰ�ť
----------------------------------------------------------------------<
_GKP.GKP_Calculation = function()
	local me = GetClientPlayer()
	if not me.IsInParty() and not JH_About.CheckNameEx() then return JH.Alert(_L["You are not in the team."]) end
	local team = GetClientTeam()
	if IsEmpty(GKP("GKP_Record")) then
		return JH.Alert(_L["No Record"])
	end
	if not JH.IsDistributer() and not JH_About.CheckNameEx() then
		return JH.Alert(_L["You are not the distrubutor."])
	end
	GetUserInput(_L["Total Amount of People with Output Settle Account"],function(num)
		if not tonumber(num) then return end
		local a,b = _GKP.GetRecordSum()
		JH.Talk(_L["Salary Settle Account"])
		JH.Talk(_L("Salary Statistic: income  %d Gold.",a))
		JH.Talk(_L("Salary Allowance: %d Gold.",b))
		JH.Talk(_L("Reall Salary: %d Gold.",a+b,a,b))
		if a+b >= 0 then
			JH.Talk(_L("Amount of People with Settle Account: %d",num))
			JH.Talk(_L("Actual per person: %d Gold.",math.floor((a+b)/num)))
		else
			JH.Talk(_L["The Account is Negative, no money is coming out!"])
		end
	end,nil,nil,nil,team.GetTeamSize())
end
---------------------------------------------------------------------->
-- open doodad (loot)
----------------------------------------------------------------------<
_GKP.OnOpenDoodad = function(dwID)
	local me = GetClientPlayer()
	local d = GetDoodad(dwID)
	local refresh = false
	if d then
		-- money ʰȡ��Ǯ
		local nM = d.GetLootMoney() or 0
		if nM > 0 then
			LootMoney(d.dwID)
			PlaySound(SOUND.UI_SOUND, g_sound.PickupMoney)
		end
		local nLootItemCount = d.GetItemListCount()
		-- items
		for i = 0, nLootItemCount - 1 do
			-- item Roll Distribute  Bidding
			local item, _ , bDist = d.GetLootItem(i,me)
			if item and item.dwID then
				if bDist or JH.bDebugClient then
					if not refresh then
						refresh = true
						_GKP.aDistributeList = {}
					end
					table.insert(_GKP.aDistributeList, item)
				else
					if item.nQuality > 0 then
						LootItem(d.dwID, item.dwID)
						JH.Debug("LootItem")
					end
				end
			end
		end
	end
	if refresh then
		_GKP.DrawDistributeList(d)
		JH.Debug("distribute items " .. #_GKP.aDistributeList)
	else
		return _GKP.CloseLootWindow()
	end
end

function _GKP.GetaPartyMember(doodad)
	local team = GetClientTeam()
	local aPartyMember = doodad.GetLooterList()
	if not aPartyMember then
		return GKP.Sysmsg(_L["Pick up time limit exceeded, please try again."])
	end
	for k, v in ipairs(aPartyMember) do
		local player = team.GetMemberInfo(v.dwID)
		aPartyMember[k].dwForceID = player.dwForceID
		aPartyMember[k].dwMapID   = player.dwMapID
	end
	return aPartyMember or {}
end

---------------------------------------------------------------------->
-- UpdateDistributeList
----------------------------------------------------------------------<
_GKP.CheckDialog = function()
	if Station.Lookup("Normal/GKP_Loot") and Station.Lookup("Normal/GKP_Loot"):IsVisible() then
		if type(GetDoodad(_GKP.dwOpenID)) == "userdata" then
			JH.DelayCall(200, _GKP.CheckDialog)
		else
			_GKP.CloseLootWindow()
		end
	end
end

_GKP.DrawDistributeList = function(doodad)
	local frame = _GKP.OpenLootPanel()
	local me = GetClientPlayer()

	if #_GKP.aDistributeList == 0 then
		return _GKP.CloseLootWindow()
	end
	frame:Show()
	Wnd.CloseWindow("LootList")
	_GKP.CheckDialog()
	-- append tip
	if not IsFileExist(JH.GetAddonInfo().szDataPath .. "config/lock.jx3dat") then
		JH.Alert(_L["GKP_TIPS"])
		JH.SaveLUAData("config/lock.jx3dat", {["Tips"] = true})
	end
	local handle = frame:Lookup("", "Handle_Box")
	handle:Clear()
	if GKP.bLootStyle then
		if #_GKP.aDistributeList <= 6 then
			frame:Lookup("", "Image_Bg"):SetSize(6 * 72,110)
			frame:Lookup("", "Image_Title"):SetSize(6 * 72,30)
			frame:SetSize(6 * 72,110)
		else
			frame:Lookup("", "Image_Bg"):SetSize(6 * 72,30 + math.ceil(#_GKP.aDistributeList / 6) * 75)
			frame:Lookup("", "Image_Title"):SetSize(6 * 72, 30)
			frame:SetSize(6 * 72, 8 + 30 + math.ceil(#_GKP.aDistributeList / 6) * 75)
		end
		-- local fx, fy = Station.GetClientSize()
		local w, h = frame:GetSize()
		-- frame:SetAbsPos((fx-w)/2,(fy-h)/2) -- �̶�λ�����м� ����˵���þ�ȥ����
		frame:Lookup("Btn_Close"):SetRelPos(w - 30, 4)
		frame:Lookup("Btn_Boss"):SetRelPos(365, 3)
		handle:SetHandleStyle(0)
	else
		frame:Lookup("", "Image_Bg"):SetSize(280, #_GKP.aDistributeList * 56 + 35)
		frame:Lookup("", "Image_Title"):SetSize(280, 30)
		frame:Lookup("Btn_Close"):SetRelPos(250, 4)
		frame:SetSize(280, #_GKP.aDistributeList * 56 + 35)
		handle:SetHandleStyle(3)
		frame:Lookup("Btn_Boss"):SetRelPos(210, 3)
	end

	local team = GetClientTeam()
	local bSpecial = false
	for item_k, item in ipairs(_GKP.aDistributeList) do
		local szItemName = GetItemNameByItem(item)
		if szItemName == JH.GetItemName(72592) or szItemName == JH.GetItemName(68363) or szItemName == JH.GetItemName(66190) then
			bSpecial = true
		end
		local box, h
		if GKP.bLootStyle then
			handle:AppendItemFromString(string.format("<Box>name=\"box_%s\" EventID=816 w=64 h=64 </Box>", item_k))
			box = handle:Lookup("box_" .. item_k)
			-- append box
			local x, y = (item_k - 1) % 6, math.ceil(item_k / 6) - 1
			box:SetRelPos(x * 70 + 5, y * 70 + 5)
		else
			h = handle:AppendItemFromIni(PATH_ROOT .. "ui/GKP_Loot.ini", "Handle_Item", item_k)
			box = h:Lookup("Box_Item")
			local txt = h:Lookup("Text_Item")
			txt:SetText(szItemName)
			txt:SetFontColor(GetItemFontColorByQuality(item.nQuality))
			handle:FormatAllItemPos()
		end
		UpdataItemInfoBoxObject(box, item.nVersion, item.dwTabType, item.dwIndex, item.nStackNum)

		if _GKP.tDistributeRecords[szItemName] then
			box:SetObjectStaring(true)
		end

		local _item = { -- ����� userdata����
			nVersion  = item.nVersion,
			dwTabType = item.dwTabType,
			dwIndex   = item.dwIndex,
			nBookID   = item.nBookID,
			nGenre    = item.nGenre,
		}
		-- Click
		box.OnItemRButtonClick = function()
			local me = GetClientPlayer()
			local nLootMode = team.nLootMode
			if nLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE and not JH.bDebugClient then -- ��Ҫ������ģʽ
				return OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GOLD_CHANGE_DISTRIBUTE_LOOT)
			end
			if not JH.IsDistributer() and not JH.bDebugClient then -- ��Ҫ�Լ��Ƿ�����
				return OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ERROR_LOOT_DISTRIBUTE)
			end
			local tMenu = {}
			table.insert(tMenu,{ szOption = GetItemNameByItem(item) , bDisable = true})
			table.insert(tMenu,{bDevide = true})
			table.insert(tMenu,{
				szOption = "Roll",
				fnAction = function()
					if MY_RollMonitor then
						if MY_RollMonitor.OpenPanel and MY_RollMonitor.Clear then
							MY_RollMonitor.OpenPanel()
							MY_RollMonitor.Clear({echo=false})
						end
					end
					JH.Talk({ GKP.GetFormatLink(_item), GKP.GetFormatLink(_L["Roll the dice if you wang"]) })
				end
			})
			table.insert(tMenu,{bDevide = true})
			for k,v in ipairs(_GKP.Config.Scheme) do
				if v[2] then
					table.insert(tMenu,{
						szOption = v[1],
						fnAction = function()
							_GKP.SetChatWindow(item,box)
							_GKP.tLootListMoney[item.dwID] = v[1]
							JH.Talk({ GKP.GetFormatLink(_item), GKP.GetFormatLink(_L(" %d Gold Start Bidding, off a price if you want.", v[1])) })
						end
					})
				end
			end
			PopupMenu(tMenu)
		end

		box.OnItemLButtonClick = function()
			if IsCtrlKeyDown() or IsAltKeyDown() then
				return
			end
			local me = GetClientPlayer()
			local nLootMode = team.nLootMode
			if nLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE and not JH.bDebugClient then -- ��Ҫ������ģʽ
				return OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GOLD_CHANGE_DISTRIBUTE_LOOT)
			end
			if not JH.IsDistributer() and not JH.bDebugClient then -- ��Ҫ�Լ��Ƿ�����
				return OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ERROR_LOOT_DISTRIBUTE)
			end
			-- ֻ��Ϊ��ˢ��һ����Ϣ
			local aPartyMember = _GKP.GetaPartyMember(doodad)
			table.sort(aPartyMember, function(a, b)
				return a.dwForceID < b.dwForceID
			end)
			local tMenu = {}
			table.insert(tMenu,{ szOption = szItemName , bDisable = true})
			table.insert(tMenu,{bDevide = true})
			local fnAction = function(v, fnMouseEnter, fix, bEnter)
				local szIcon,nFrame = GetForceImage(v.dwForceID)
				return {
					szOption = fix or v.szName,
					bDisable = not v.bOnlineFlag,
					rgb = {JH.GetForceColor(v.dwForceID)},
					szIcon = szIcon,
					szLayer = "ICON_RIGHT",
					nFrame = nFrame,
					fnMouseEnter = fnMouseEnter,
					fnAction = function()
						if not item.dwID then
							_GKP.OnOpenDoodad(_GKP.dwOpenID)
							return GKP.Sysmsg(_L["Userdata is overdue, distribut failed, please try again."])
						end
						if v.dwMapID ~= me.GetMapID() then
							return JH.Alert(_L["No Pick up Object, Please confirm that in the Dungeon."])
						end
						if item.nQuality >= 3 then
							local r,g,b = JH.GetForceColor(v.dwForceID)
							local msg = {
								szMessage = FormatLinkString(
									g_tStrings.PARTY_DISTRIBUTE_ITEM_SURE,
									"font=162",
									GetFormatText("[".. GetItemNameByItem(item) .."]", "166"..GetItemFontColorByQuality(item.nQuality, true)),
									GetFormatText("[".. v.szName .."]", 162,r,g,b)
								),
								szName = "Distribute_Item_Sure",
								bRichText = true,
								{
									szOption = g_tStrings.STR_HOTKEY_SURE,
									fnAutoClose = function()
										return false
									end,
									fnAction = function()
										if IsShiftKeyDown() then
											_GKP.DistributeItem(item,v,doodad,true)
										else
											_GKP.DistributeItem(item,v,doodad,bEnter)
										end
									end
								},
								{szOption = g_tStrings.STR_HOTKEY_CANCEL},
							}
							MessageBox(msg)
						else
							if IsShiftKeyDown() then
								_GKP.DistributeItem(item,v,doodad,true)
							else
								_GKP.DistributeItem(item,v,doodad,bEnter)
							end
						end
					end
				}
			end
			-- �м��������� append meun
			if _GKP.tDistributeRecords[szItemName] then
				local p
				for k, v in ipairs(aPartyMember) do
					if v.dwID == _GKP.tDistributeRecords[szItemName] then
						p = v
						break
					end
				end
				if p then  -- ����˴����Ŷӵ������
					if IsShiftKeyDown() then
						if p.bOnlineFlag then
							_GKP.DistributeItem(item,p,doodad,true)
						else
							GKP.Sysmsg(_L["No Pick up Object, may due to Network off - line"])
						end
						return
					end
					table.insert(tMenu, fnAction(p, function(this)
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local szXml = GetFormatText(_L("You already distrubute [%s] with [%s], you can press Shift and select the object to make a fast distrubution, you can also make distribution to he or her by clicking this menu. \n",szItemName,p.szName,p.szName),136,255,255,255)
						OutputTip(szXml,400,{x,y,w,h})
					end, p.szName .. " - " .. szItemName, true))
					table.insert(tMenu, { bDevide = true })
				end
			end
			-- Create list
			for k, v in ipairs(aPartyMember) do
				table.insert(tMenu, fnAction(v))
			end
			PopupMenu(tMenu)
		end
		if h then
			local fnAction = box.OnItemMouseEnter
			box.OnItemMouseEnter = function()
				if this:IsValid() then
					this:GetParent():Lookup("Image_Copper"):Show()
					fnAction()
				end
			end
			local fnAction = box.OnItemMouseLeave
			box.OnItemMouseLeave = function()
				if this:IsValid() then
					this:GetParent():Lookup("Image_Copper"):Hide()
					fnAction()
				end
			end
			for k, v in ipairs({"OnItemMouseEnter", "OnItemMouseLeave", "OnItemRButtonClick", "OnItemLButtonClick"}) do
				h[v] = function()
					this = box
					box[v]()
				end
			end
		end
	end

	handle:FormatAllItemPos()
	if bSpecial then -- ����
		frame:Lookup("", "Image_Bg"):FromUITex("ui/Image/OperationActivity/RedEnvelope1.uitex", 9)
		frame:Lookup("", "Image_Title"):FromUITex("ui/Image/OperationActivity/RedEnvelope2.uitex", 2)
		frame:Lookup("", "Text_Title"):SetAlpha(255)
		handle:SetRelPos(5, 30)
		handle:GetParent():FormatAllItemPos()
	end
	if _GKP.tDistributeRecords["EquipmentBoss"] then
		frame:Lookup("Btn_Boss"):Show()
		frame:Lookup("Btn_Boss").OnLButtonClick = function()
			local tEquipment = {}
			for k,v in ipairs(_GKP.aDistributeList) do
				if v.nGenre == ITEM_GENRE.EQUIPMENT or IsCtrlKeyDown() then -- ��סCtrl������� ���ӷ��� ����ֻ��װ��
					table.insert(tEquipment,v)
				end
			end
			if #tEquipment == 0 then
				return JH.Alert(_L["No Equiptment left for Equiptment Boss"])
			end
			local p
			local aPartyMember = _GKP.GetaPartyMember(doodad)
			for k, v in ipairs(aPartyMember) do
				if v.szName == _GKP.tDistributeRecords["EquipmentBoss"] then
					p = v
					break
				end
			end
			if p and p.bOnlineFlag then  -- ����˴����Ŷӵ������
				if p.dwMapID ~= me.GetMapID() then
					return JH.Alert(_L["No Pick up Object, Please confirm that in the Dungeon."])
				end
				local szXml = GetFormatText(_L["Are you sure you want the following item\n"], 162,255,255,255)
				local r, g, b = JH.GetForceColor(p.dwForceID)
				for k,v in ipairs(tEquipment) do
					szXml = szXml .. GetFormatText("[".. GetItemNameByItem(v) .."]\n", "166"..GetItemFontColorByQuality(v.nQuality, true))
				end
				szXml = szXml .. GetFormatText(_L["All distrubute to"], 162, 255, 255, 255)
				szXml = szXml .. GetFormatText("[".. p.szName .."]", 162, r, g, b)
				local msg = {
					szMessage = szXml,
					szName = "Distribute_Item_Sure",
					bRichText = true,
					{
						szOption = g_tStrings.STR_HOTKEY_SURE,
						fnAutoClose = function()
							return false
						end,
						fnAction = function()
							for k, v in ipairs(tEquipment) do
								_GKP.DistributeItem(v, p, doodad, true)
							end
						end
					},
					{
						szOption = g_tStrings.STR_HOTKEY_CANCEL
					},
				}
				MessageBox(msg)
			else
				return JH.Alert(_L["No Pick up Object, may due to Network off - line"])
			end
		end
	else
		frame:Lookup("Btn_Boss"):Hide()
	end
end
---------------------------------------------------------------------->
-- ��������ҳ������
----------------------------------------------------------------------<
_GKP.DistributeItem = function(item,player,doodad,bEnter)
	if not item.dwID then
		_GKP.OnOpenDoodad(_GKP.dwOpenID)
		return GKP.Sysmsg(_L["Userdata is overdue, distribut failed, please try again."])
	end
	_GKP.CloseChatWindow(item)
	local szName = GetItemNameByItem(item)
	if _GKP.Config.Special[szName] then -- ��ס�ϴηָ�˭
		_GKP.tDistributeRecords[szName] = player.dwID
		JH.Debug("memory " .. szName .. " -> " .. player.dwID)
	end
	doodad.DistributeItem(item.dwID,player.dwID)
	_GKP.OnOpenDoodad(_GKP.dwOpenID)
	local tab = {
		szPlayer = player.szName,
		nUiId = item.nUiId,
		szNpcName = doodad.szName,
		dwDoodadID = doodad.dwID,
		dwTabType = item.dwTabType,
		dwIndex = item.dwIndex,
		nVersion = item.nVersion,
		nTime = GetCurrentTime(),
		nQuality = item.nQuality,
		dwForceID = player.dwForceID,
		szName = szName,
		nGenre = item.nGenre,
	}
	if item.bCanStack and item.nStackNum > 1 then
		tab.nStackNum = item.nStackNum
	end
	if item.nGenre == ITEM_GENRE.BOOK then
		tab["szName"] = GetItemNameByItem(item)
		tab["nBookID"] = item.nBookID
	end

	if GKP.bOn then
		_GKP.Record(tab,item,bEnter)
	else -- �رյ�������ж���ȫ���ƹ�
		tab.nMoney = 0
		GKP("GKP_Record", tab)
		_GKP.Draw_GKP_Record()
	end
end
---------------------------------------------------------------------->
-- ����ҳ��
----------------------------------------------------------------------<
_GKP.Record = function(tab, item, bEnter)
	local record = GUI(Station.Lookup("Normal1/GKP_Record"))
	local box = record:Fetch("Box"):Pos(170,80).self
	local text = record:Fetch("TeamList")
	local Money = record:Fetch("Money")
	local Name = record:Fetch("Name")
	local Source = record:Fetch("Source")
	local auto = 0
	record:Fetch("WndCheckBox"):Check(false)
	if record:IsVisible() and record:Fetch("btn_Close").self.userdata then -- �ϴ���userdata����û�ر�
		if text:Text() ~= g_tStrings.PLAYER_NOT_EMPTY and Name:Text() ~= "" then
			Money:Text(0)
			record:Fetch("btn_ok"):Click()
		end
	end

	if record:Fetch("btn_Close").self.userdata then
		record:Fetch("btn_Close").self.userdata = nil
	end
	if tab and type(item) == "userdata" then
		text:Text(tab.szPlayer):Color(JH.GetForceColor(tab.dwForceID))
		Name:Text(tab.szName):Enable(false)
		Source:Text(tab.szNpcName):Enable(false)
		if _GKP.tLootListMoney[item.dwID] and GKP.bAutoSetMoney then
			auto = _GKP.tLootListMoney[item.dwID] -- �Զ����÷���ʱ�Ľ�Ǯ
		elseif GKP.bAutoBX and tab.szName == JH.GetItemName(73214) and tab.nStackNum and tab.nStackNum >= 1 then
			auto = tab.nStackNum
		else
			Money:Text("")
		end
		record:Fetch("btn_Close").self.userdata = true
	else
		text:Text(g_tStrings.PLAYER_NOT_EMPTY):Color(255, 255, 255)
		text.self.dwForceID = nil
		Source:Text(_L["Add Manually"]):Enable(false)
		Name:Text(""):Enable(true)
		Money:Text("")
	end
	if tab and type(item) == "number" then -- �༭
		text:Text(tab.szPlayer):Color(JH.GetForceColor(tab.dwForceID))
		text.self.dwForceID = tab.dwForceID
		local iName = JH.GetItemName(tab.nUiId)
		Name:Text(tab.szName or iName):Enable(true)
		Source:Text(tab.szNpcName):Enable(true)
		Money:Text(tab.nMoney)
	end

	if tab and tab.nVersion and tab.nUiId and tab.dwTabType and tab.dwIndex and tab.nUiId ~= 0 then
		UpdataItemInfoBoxObject(box, tab.nVersion, tab.dwTabType, tab.dwIndex, tab.nStackNum)
		box:Show()
	else
		UpdataItemBoxObject(box)
		box:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
		box:SetObjectIcon(582)
	end
	record:Toggle(true)
	if auto == 0 and type(item) ~= "number" and tab then -- edit/add killfocus
		Money:Focus()
	elseif auto > 0 and tab then
		Money:Text(auto) -- OnEditChanged kill
		record:Focus()
	elseif not tab then
		Name:Focus()
	end

	record:Fetch("btn_ok"):Click(function()
		local tab = tab or {
			nUiId = 0,
			dwTabType = 0,
			dwDoodadID = 0,
			nQuality = 1,
			nVersion = 0,
			dwIndex = 0,
			nTime = GetCurrentTime(),
			dwForceID = text.self.dwForceID or 0,
			szName = Name:Text(),
		}
		local nMoney = tonumber(Money:Text()) or 0
		local szPlayer = text:Text()
		if Name:Text() == "" then
			return JH.Alert(_L["Please entry the name of the item"])
		end
		if szPlayer == g_tStrings.PLAYER_NOT_EMPTY then
			return JH.Alert(_L["Select a member who is in charge of account and put money in his account."])
		end

		tab.szNpcName = Source:Text()
		tab.nMoney = nMoney
		tab.szPlayer = szPlayer
		tab.key = tab.key or tab.nUiId .. GKP.Random()
		if tab and type(item) == "userdata" then
			if JH.IsDistributer() then
				JH.Talk({
					GKP.GetFormatLink(tab),
					GKP.GetFormatLink(" ".. nMoney ..g_tStrings.STR_GOLD),
					GKP.GetFormatLink(_L[" Distribute to "]),
					GKP.GetFormatLink(tab.szPlayer, true)
				})
				JH.BgTalk(PLAYER_TALK_CHANNEL.RAID, "GKP", "add", tab)
			end
			if _GKP.tLootListMoney[item.dwID] then
				_GKP.tLootListMoney[item.dwID] = nil
			end
		elseif tab and type(item) == "number" then
			tab.szName = Name:Text()
			tab.dwForceID = text.self.dwForceID or tab.dwForceID or 0
			tab.bEdit = true
			if JH.IsDistributer() then
				JH.Talk({
					GKP.GetFormatLink(tab.szPlayer, true),
					GKP.GetFormatLink(" ".. tab.szName),
					GKP.GetFormatLink(" ".. nMoney ..g_tStrings.STR_GOLD),
					GKP.GetFormatLink(_L["Make changes to the record."]),
				})
				JH.BgTalk(PLAYER_TALK_CHANNEL.RAID,"GKP", "edit", tab)
			end
		else
			if JH.IsDistributer() then
				JH.Talk({
					GKP.GetFormatLink(tab.szName),
					GKP.GetFormatLink(" ".. nMoney ..g_tStrings.STR_GOLD),
					GKP.GetFormatLink(_L["Manually make record to"]),
					GKP.GetFormatLink(tab.szPlayer, true)
				})
				JH.BgTalk(PLAYER_TALK_CHANNEL.RAID,"GKP", "add", tab)
			end
		end
		if record:Fetch("WndCheckBox"):Check() then
			_GKP.tDistributeRecords["EquipmentBoss"] = tab.szPlayer -- 233333 ������ ���ͦ�����
			_GKP.OnOpenDoodad(_GKP.dwOpenID)
		end
		if tab and type(item) == "number" then
			GKP("GKP_Record", item, tab)
		else
			GKP("GKP_Record", tab)
		end

		_GKP.Draw_GKP_Record()
		record:Toggle(false)
		FireUIEvent("GKP_DEL_DISTRIBUTE_ITEM")
	end)
	if bEnter then
		record:Fetch("btn_ok"):Click()
	end

end
---------------------------------------------------------------------->
-- OpenDoodad
----------------------------------------------------------------------<
_GKP.OpenDoodad = function(arg0)
	local team = GetClientTeam()
	local me = GetClientPlayer()
	if me and team then
		local nLootMode = team.nLootMode
		if nLootMode == PARTY_LOOT_MODE.DISTRIBUTE then -- ��Ҫ������ģʽ
			_GKP.dwOpenID = arg0
			_GKP.OnOpenDoodad(arg0)
		end
	end
end
---------------------------------------------------------------------->
-- OpenDoodad cache
----------------------------------------------------------------------<
_GKP._OpenDoodad = function(arg0)
	local team = GetClientTeam()
	local me = GetClientPlayer()
	local refresh = false
	if me and team then
		local d = GetDoodad(arg0)
		if d then
			local nLootItemCount = d.GetItemListCount()
			-- items
			_GKP.aDoodadCache[arg0] = {}
			_GKP.aDoodadCache[arg0].szName = d.szName
			for i = 0, nLootItemCount - 1 do
				-- item Roll Distribute  Bidding
				local item, _ , bDist = d.GetLootItem(i,me)
				if item and bDist then -- ֻ������Ҫ�������Ʒ
					refresh = true
					if item.dwID then
						local tab = {
							item = item,
							nUiId = item.nUiId,
							dwTabType = item.dwTabType,
							dwIndex = item.dwIndex,
							nVersion = item.nVersion,
							nQuality = item.nQuality,
							nGenre = item.nGenre,
							szName = GetItemNameByItem(item),
						}
						if item.bCanStack and item.nStackNum > 1 then
							tab.nStackNum = item.nStackNum
						end
						if item.nGenre == ITEM_GENRE.BOOK then
							tab.nBookID = item.nBookID
						end
						_GKP.aDoodadCache[arg0][item.dwID] = tab
					else
						JH.Debug("not item dwID")
					end
				end
			end
		end
	end
	if not refresh then
		_GKP.aDoodadCache[arg0] = nil
	end
end
---------------------------------------------------------------------->
-- DISTRIBUTE_ITEM
----------------------------------------------------------------------<
RegisterEvent("DISTRIBUTE_ITEM",function() -- DISTRIBUTE_ITEM
	if JH.IsDistributer() then
		return
	end
	local team = GetClientTeam()
	local me = GetClientPlayer()
	local player = team.GetMemberInfo(arg0)
	for k,v in pairs(_GKP.aDoodadCache) do
		if v[arg1] then
			local item = v[arg1]
			item.szPlayer = player.szName
			item.szNpcName = v.szName
			item.dwDoodadID = k
			item.nTime = GetCurrentTime()
			item.dwForceID = player.dwForceID
			if GKP.bOn2 then
				local tab = clone(item)
				tab.item = nil
				table.insert(_GKP.tDistribute,{tab = tab , item = item.item})
				if me.bFightState then
					GKP.Sysmsg(_L["A distribute record has produced, it has been ignored in the combat, it will automatically popup after breaking away from the combat."])
				else
					FireUIEvent("GKP_DISTRIBUTE_ITEM")
				end
			end
			break
		end
	end
	JH.Debug("DISTRIBUTE_ITEM")
end)

RegisterEvent("FIGHT_HINT", function()
	local me = GetClientPlayer()
	if GKP.bOn and #_GKP.tDistribute > 0 and not me.bFightState then
		FireUIEvent("GKP_DISTRIBUTE_ITEM")
	end
end)

RegisterEvent("GKP_DEL_DISTRIBUTE_ITEM", function()
	if #_GKP.tDistribute > 0 then
		table.remove(_GKP.tDistribute,1)
		if #_GKP.tDistribute > 0 then
			FireUIEvent("GKP_DISTRIBUTE_ITEM")
		end
	end
	if IsPopupMenuOpened() then
		Wnd.CloseWindow("PopupMenuPanel")
	end
	JH.Debug("GKP_DEL_DISTRIBUTE_ITEM")
end)

RegisterEvent("GKP_DISTRIBUTE_ITEM", function()
	if _GKP.tDistribute[1] and not Station.Lookup("Normal1/GKP_Record"):IsVisible() then
		local tab = _GKP.tDistribute[1]
		_GKP.Record(tab.tab,tab.item)
	end
	JH.Debug("GKP_DISTRIBUTE_ITEM")
end)

RegisterEvent("SYNC_LOOT_LIST", function()
	local frame = Station.Lookup("Normal/GKP_Loot")
	if _GKP.dwOpenID == arg0 and frame and frame:IsVisible() then
		_GKP.OpenDoodad(arg0)
	end
	if JH.bDebugClient and GKP.bDebug2 and JH.IsInDungeon() and not _GKP.aDoodadCache[arg0] and not frame then
		_GKP.OpenDoodad(arg0)
	end
	_GKP._OpenDoodad(arg0)
end)

RegisterEvent("OPEN_DOODAD", function()
	local team = GetClientTeam()
	local me = GetClientPlayer()
	local nLootMode = team.nLootMode
	if nLootMode == PARTY_LOOT_MODE.DISTRIBUTE then
		_GKP.OpenDoodad(arg0)
		JH.Debug("OPEN_DOODAD " .. arg0)
	end
end)

---------------------------------------------------------------------->
-- ��Ǯ��¼
----------------------------------------------------------------------<
_GKP.TradingTarget = {}

_GKP.MoneyUpdate = function(nGold, nSilver, nCopper)
	if nGold > -20 and nGold < 20  then
		return
	end
	if not _GKP.TradingTarget then
		return
	end
	if not _GKP.TradingTarget.szName and not GKP.bMoneySystem then
		return
	end
	GKP("GKP_Account", {
		nGold = nGold, -- API���������� ���� ֻ���
		szPlayer = _GKP.TradingTarget.szName or "System",
		dwForceID = _GKP.TradingTarget.dwForceID,
		nTime = GetCurrentTime(),
		dwMapID = GetClientPlayer().GetMapID()
	})
	_GKP.Draw_GKP_Account()
	if _GKP.TradingTarget.szName and GKP.bMoneyTalk then
		if nGold > 0 then
			JH.Talk({
				GKP.GetFormatLink(_L["Received"]),
				GKP.GetFormatLink(_GKP.TradingTarget.szName, true),
				GKP.GetFormatLink(_L["The"] .. nGold ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP),
			})
		else
			JH.Talk({
				GKP.GetFormatLink(_L["Pay to"]),
				GKP.GetFormatLink(_GKP.TradingTarget.szName, true),
				GKP.GetFormatLink(" " .. nGold * -1 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP),
			})
		end
	end
end

_GKP.Draw_GKP_Account = function(key,sort)
	local key = key or _GKP.GKP_Account_Container.key or "szPlayer"
	local sort = sort or _GKP.GKP_Account_Container.sort or "desc"
	local tab = GKP("GKP_Account",key,sort)
	_GKP.GKP_Account_Container.key = key
	_GKP.GKP_Account_Container.sort = sort
	_GKP.GKP_Account_Container:Clear()
	local a, b = 0,0
	local tMoney = GetClientPlayer().GetMoney()
	for k, v in ipairs(tab) do
		local c = _GKP.GKP_Account_Container:AppendContentFromIni(PATH_ROOT .. "ui/GKP_Account_Item.ini", "WndWindow", k)
		local item = c:Lookup("", "")
		if k % 2 == 0 then
			item:Lookup("Image_Line"):Hide()
		end
		if v.bDelete then
			c:SetAlpha(80)
		end
		c:Lookup("", "Handle_Money"):AppendItemFromString(GetGoldText(v.nGold, 3))
		if v.nGold  < 0 then
			c:Lookup("", "Handle_Money"):Lookup(0):SetFontColor(255, 0, 0)
		else
			c:Lookup("", "Handle_Money"):Lookup(0):SetFontColor(0, 255, 0)
		end
		c:Lookup("", "Handle_Money"):FormatAllItemPos()
		item:Lookup("Text_No"):SetText(k)
		if v.szPlayer and v.szPlayer ~= "System" then
			item:Lookup("Image_NameIcon"):FromUITex(GetForceImage(v.dwForceID))
			item:Lookup("Text_Name"):SetText(v.szPlayer)
			item:Lookup("Text_Change"):SetText(_L["Player's transation"])
			item:Lookup("Text_Name"):SetFontColor(JH.GetForceColor(v.dwForceID))
		else
			item:Lookup("Image_NameIcon"):FromUITex("ui/Image/uicommon/commonpanel4.UITex",3)
			item:Lookup("Text_Name"):SetText(_L["System"])
			item:Lookup("Text_Change"):SetText(_L["Reward & other ways"])
		end
		item:Lookup("Text_Map"):SetText(Table_GetMapName(v.dwMapID))
		item:Lookup("Text_Time"):SetText(GKP.GetTimeString(v.nTime))
		c:Lookup("WndButton_Delete").OnLButtonClick = function()
			GKP("GKP_Account","del",k)
			_GKP.Draw_GKP_Account()
		end

		-- tip
		item:Lookup("Text_Name"):RegisterEvent(786)
		item:Lookup("Text_Name").OnItemLButtonClick = function()
			if IsCtrlKeyDown() then
				return EditBox_AppendLinkPlayer(v.szPlayer)
			end
		end

		item:Lookup("Text_Name").OnItemMouseEnter = function()
			local szIcon, nFrame = GetForceImage(v.dwForceID)
			local r, g, b = JH.GetForceColor(v.dwForceID)
			local szXml = GetFormatImage(szIcon, nFrame, 20, 20) .. GetFormatText("  " .. v.szPlayer .. g_tStrings.STR_COLON .. "\n", 136, r, g, b)
			if IsCtrlKeyDown() then
				szXml = szXml .. GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP .. "\n", 136, 255, 0, 0)
				szXml = szXml .. GetFormatText(var2str(v, " "), 136, 255, 255, 255)
			else
				szXml = szXml .. GetFormatText(_L["System Information as Shown Below\n\n"],136,255,255,255)
				local nNum,nNum1,nNum2 = 0,0,0
				for kk,vv in ipairs(GKP("GKP_Record")) do
					if vv.szPlayer == v.szPlayer and not vv.bDelete then
						if  vv.nMoney > 0 then
							nNum = nNum + vv.nMoney
						else
							nNum1 = nNum1 + vv.nMoney
						end
					end
				end
				local r,g,b = GKP.GetMoneyCol(nNum)
				szXml = szXml .. GetFormatText(_L["Total Cosumption:"],136,255,128,0) .. GetFormatText(nNum ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. "\n",136,r,g,b)
				local r,g,b = GKP.GetMoneyCol(nNum1)
				szXml = szXml .. GetFormatText(_L["Total Allowance:"],136,255,128,0) .. GetFormatText(nNum1 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. "\n",136,r,g,b)

				for kk,vv in ipairs(GKP("GKP_Account")) do
					if vv.szPlayer == v.szPlayer and not vv.bDelete and vv.nGold > 0 then
						nNum2 = nNum2 + vv.nGold
					end
				end
				local r,g,b = GKP.GetMoneyCol(nNum2)
				szXml = szXml .. GetFormatText(_L["Total Payment:"],136,255,128,0) .. GetFormatText(nNum2 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. "\n",136,r,g,b)
				local nNum3 = nNum+nNum1-nNum2
				if nNum3 < 0 then
					nNum3 = 0
				end
				local r,g,b = GKP.GetMoneyCol(nNum3)
				szXml = szXml .. GetFormatText(_L["Money on Debt:"],136,255,128,0) .. GetFormatText(nNum3 ..g_tStrings.STR_GOLD .. g_tStrings.STR_FULL_STOP .. "\n",136,r,g,b)
			end
			local x, y = item:Lookup("Text_No"):GetAbsPos()
			local w, h = item:Lookup("Text_No"):GetSize()
			OutputTip(szXml,400,{x,y,w,h})
		end
		item:Lookup("Text_Name").OnItemMouseLeave = function()
			HideTip()
		end
		if not v.bDelete then
			if tonumber(v.nGold) > 0 then
				a = a + v.nGold
			else
				b = b + v.nGold
			end
		end
	end
	_GKP.GKP_Account_Container:FormatAllContentPos()
	local txt = Station.Lookup("Normal/GKP/PageSet_Menu/Page_GKP_Account"):Lookup("","Text_GKP_AccountSettlement")
	local text = _L("Statistic: Overall Income = %d Gold (Income: %d Gold + Output: %d Gold)",a+b,a,b)
	if _GKP.nNowMoney then
		text = _L("%s log in with %d Gold in possession",text,_GKP.nNowMoney)
	end
	txt:SetText(text)
	txt:SetFontColor(255,255,0)
end

RegisterEvent("TRADING_OPEN_NOTIFY",function() -- ���׿�ʼ
	_GKP.TradingTarget = GetPlayer(arg0)
end)
RegisterEvent("TRADING_CLOSE",function() -- ���׽���
	_GKP.TradingTarget = {}
end)
RegisterEvent("MONEY_UPDATE",function() --��Ǯ�䶯
	_GKP.MoneyUpdate(arg0,arg1,arg2)
end)

JH.PlayerAddonMenu({ szOption = _L["GKP Golden Team Record"], fnAction = _GKP.OpenPanel })
JH.AddHotKey("JH_GKP",_L["Open/Close Golden Team Record"],_GKP.TogglePanel)


RegisterEvent("LOADING_END",function()
	if JH.IsInDungeon() and GKP.bAlertMessage then
		if not IsEmpty(GKP("GKP_Record")) or not IsEmpty(GKP("GKP_Account")) then
			JH.Confirm(_L["Do you want to wipe the previous data when you enter the dungeon's map?"],function() _GKP.GKP_Clear(true) end)
		end
	end
end)
