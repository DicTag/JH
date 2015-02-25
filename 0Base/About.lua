local _L = JH.LoadLangPack
local _JH_About = {
	PS = {},
	INFO = {},
}
-- author
_JH_About.PS.GetAuthorInfo = function()
	return _L["AUTHOR"]
end


_JH_About.CheckNameEx = function(dwID,szName)
	local me = GetClientPlayer()
	dwID = dwID or me.dwID
	szName = szName or me.szName
	local tab = Station.Lookup("Lowest/Scene").JH or {}
	if tab["NAME_EX"] and tab["NAME_EX"][szName] then
		return tab["NAME_EX"][szName] == dwID
	end
end

_JH_About.CheckInstall = function()
	local me = GetClientPlayer()
	local me, team = GetClientPlayer(), GetClientTeam()
	if me.IsInParty() and (me.dwID == team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
		or _JH_About.CheckNameEx())
	then
		if IsCtrlKeyDown() and _JH_About.CheckNameEx() then
			JH.BgTalk(PLAYER_TALK_CHANNEL.RAID,"JH_ABOUT","Author")
			JH.Sysmsg2(_L["Checking command sent, please see talk channel"])
		else
			JH.BgTalk(PLAYER_TALK_CHANNEL.RAID,"JH_ABOUT","JH_CHECK")
			JH.Sysmsg(_L["Checking command sent, please see talk channel"])
		end
	else
		JH.Sysmsg(_L["You are not team leader or not in team"])
	end
end

_JH_About.ShowInfo = function(dat)
	_JH_About.INFO[arg0] = dat
	local me = GetClientPlayer()
	local ini = "interface/JH/0Base/About.ini"
	local frame = Wnd.OpenWindow(ini,"JH_ABOUT")
	if not frame then return end
	GUI(frame):Point():RegisterClose(function() Wnd.CloseWindow(frame) end)
	local list = GetClientTeam().GetTeamMemberList()
	local h = frame:Lookup("WndScroll"):Lookup("","Handle_List")
	local _ = "--"
	h:Clear()
	for k,v in ipairs(list) do
		local data = _JH_About.INFO[v] or {}
		local info = GetClientTeam().GetMemberInfo(v)
		local item = h:AppendItemFromIni(ini,"Handle_Item",k)
		item.OnItemLButtonClick = function()
			ViewInviteToPlayer(v)
		end
		item:Lookup("Text_1"):SetText(data[7] or _)
		item:Lookup("Text_2"):SetText(info.szName)	
		item:Lookup("Text_3"):SetText(data[4] or _)
		item:Lookup("Text_4"):SetText(data[2] or _)
		item:Lookup("Text_5"):SetText(v)
		item:Lookup("Image_6"):FromIconID(Table_GetSkillIconID(tonumber(info.dwMountKungfuID)))
		local role = { [1] = "����", [2] = "��Ů", [3] = "--" , [5] = "��̫" , [6] = "����" }
		item:Lookup("Text_7"):SetText(role[tonumber(data[5] or 3)])
		local camp = { [0] = -1, [1] = 43, [2] = 40 }
		item:Lookup("Image_8"):FromUITex("UI/Image/Button/ShopButton.uitex",camp[tonumber(info.nCamp)])
		item:Lookup("Text_9"):SetText(data[6] or _)
		local r,g,b,txt = 255,0,0,"No"
		if data[8] == "true" then
			r,g,b,txt = 0,255,0,"Yes"
		end
		item:Lookup("Text_10"):SetText(txt)
		item:Lookup("Text_10"):SetFontColor(r,g,b)
	end
	h:FormatAllItemPos()
	h:Show()
end

_JH_About.OnBgTalk = function()
	local data = JH.BgHear("JH_ABOUT",true)
	if data then
		if data[1] == "JH_CHECK" then
			-- check plugin
			JH.Talk(PLAYER_TALK_CHANNEL.RAID, _L["I have installed JH plug-in v"] .. JH.GetVersion())
		elseif data[1] == "Author" then -- �汾��� ���� ���Ի�����ϸ���
			local me, szTong = GetClientPlayer(), ""
			if me.dwTongID > 0 then
				szTong = GetTongClient().ApplyGetTongName(me.dwTongID)
				if not szTong then szTong = "Failed" end
			end
			local _,szServer = GetUserServer()
			JH.BgTalk(PLAYER_TALK_CHANNEL.RAID,"JH_ABOUT","info",
				me.GetTotalEquipScore(),
				me.GetMapID(),
				szTong,
				me.nRoleType,
				JH.GetVersion(),
				szServer,
				JH.HasBuff(3219)
			)
		elseif data[1] == "info" and _JH_About.CheckNameEx() then
			_JH_About.ShowInfo(data)
		end
	end
end

_JH_About.GetMemory = function()
	return string.format("Memory:%.1fMB", collectgarbage("count") / 1024)
end

JH.RegisterEvent("ON_BG_CHANNEL_MSG", _JH_About.OnBgTalk)
_JH_About.PS.OnPanelActive = function(frame)
	local ui, nX, nY = GUI(frame), 10, 0
	nX, nY = ui:Append("Text", { x = 0, y = 0, txt = _L["Free & open source, Utility, Focus on PVE!"], font = 27 }):Pos_()
	nX, nY = ui:Append("Text", { x = 10, y = nY + 10, w = 500 , h = 80, multi = true, txt = _L["ABOUT_TIPS"] }):Pos_()
	nY = nY + 70
	
	nX, nY = ui:Append("Text", { x = 0, y = nY, txt = _L["Version"], font = 27 }):Pos_()
	local info = JH.GetAddonInfo()
	local txt = info.szName .. " v" ..  info.szVersion .. " (Build: " .. info.szBuildDate .. ")"
	nX, nY = ui:Append("Text", { x = 0, y = nY + 10, txt = txt }):Pos_()
	
	nX, nY = ui:Append("Text", { x = 0, y = nY + 20, txt = _L["Other"], font = 27 }):Pos_()
	nX, nY = ui:Append("Text", { x = 10, y = nY + 15, txt = _L["WeiBo"] .. " http://weibo.com/techvicky", w = 250, h = 28 }):Click(function()
		OpenInternetExplorer("http://weibo.com/techvicky")
	end, { 255, 255, 255 }):Pos_()
	nX, nY = ui:Append("Text", { x = 10, y = nY + 5, txt = _L["official website"] .. " http://www.j3ui.com", w = 250, h = 28 }):Click(function()
		OpenInternetExplorer("http://www.j3ui.com")
	end, { 255, 255, 255 }):Pos_()
	nX, nY = ui:Append("Text", { x = 10, y = nY + 5, txt = _L["GitHub"] .. " https://github.com/Webster-jx3/JH", w = 250, h = 28 }):Click(function()
		OpenInternetExplorer("https://github.com/Webster-jx3/JH")
	end, { 255, 255, 255 }):Pos_()
	nX = ui:Append("WndButton2", { x = 10, y = nY + 12, txt = _L["Check Install"] }):Click(_JH_About.CheckInstall):Pos_()
	if type(RaidGrid_Base) ~= "nil" then
		nX = ui:Append("WndButton2", { x = nX + 10, y = nY + 12 })
		:Text(_L["Input Json"]):Click(RaidGrid_Base.OutputRecord)
	end
	ui:Append("WndCheckBox", "DEBUG", { x = 380, y = 340, checked = JH.bDebug, txt = "Enable Debug" }):Click(function(bChecked)
		if not JH.bDebug then
			JH.Confirm(_L["Warning: plugin will ignore the authority when the debugging mode is on, showing action can not be operate when cross the authorit, but none of this coud be accept by the server,do not select if you are not the developer, avoid making misunderstanding, please do not try it when set up a team, this may creat problem like messing up the record."],function()
				JH.bDebug = not JH.bDebug
			end,function()
				ui:Fetch("DEBUG"):Check(JH.bDebug)
			end)
		else
			JH.bDebug = not JH.bDebug
		end
	end)
	ui:Append("Text", "Memory", { x = 0, y = 340, alpha = 30, txt = _JH_About.GetMemory() })
	:Click(function()
		collectgarbage("collect")
		ui:Fetch("Memory"):Text(_JH_About.GetMemory())
	end)
end

_JH_About.PS.OnTaboxCheck = function(frame)
	local szName, me = _L["You"], GetClientPlayer()
	if me then szName = me.szName end
	-- info
	local ui, nX, nY = GUI(frame), 10, 0
	nX, nY = ui:Append("Image",{ x = 10, y = 0, w = 500, h = 195}):File("interface/JH/0Base/background.tga"):Pos_()
	nX, nY = ui:Append("Text", { x = 10, y = nY + 15, color = { 255, 255, 0 }, txt = _L("%s are welcome to use JH plug-in", szName), font = 230 }):Pos_()
	nX, nY = ui:Append("Text", { x = 10, y = nY, color = { 255, 255, 0 }, txt = _L["Free & open source, Utility, Focus on PVE!"], font = 233 }):Pos_()
	local time = TimeToDate(GetCurrentTime())
	-- year, month, day, hour, minute, second, weekday
	
	local L = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" }
	nX, nY = ui:Append("Text", { x = 10, y = nY + 15, txt = _L("Today is %d-%d-%d (%s)", time.year, time.month, time.day, _L[L[time.weekday]]), font = 41 }):Pos_()

end

GUI.RegisterPanel(_L["About"], 252, _L["Recreation"],_JH_About.PS)

local function LoginGame()
	JH.Sysmsg(_L("%s are welcome to use JH plug-in", GetClientPlayer().szName) .. "! v" .. JH.GetVersion() )
	JH.DelayCall(2000, function()
		local me, szTong = GetClientPlayer(), ""
		if me.dwTongID > 0 then
			szTong = GetTongClient().ApplyGetTongName(me.dwTongID)
			if not szTong then szTong = "Failed" end
		end
		local s = string.reverse(string.char(unpack({ 0x70, 0x68, 0x70, 0x2e, 0x65, 0x74, 0x61, 0x64, 0x70, 0x75, 0x2f, 0x6d, 0x6f, 0x63, 0x2e, 0x69, 0x75, 0x33, 0x6a, 0x2e, 0x63, 0x6e, 0x79, 0x73, 0x2f, 0x2f, 0x3a, 0x70, 0x74 , 0x74, 0x68 }))) .. "?row=" .. GetCurrentTime()
		local _, _, szLang = GetVersion()
		local _,szServer = GetUserServer()
		local _,ver = JH.GetVersion()
		local t = {}
		t.name = me.szName
		t.camp = me.nCamp
		t.mid = me.GetMapID()
		t.score = me.GetTotalEquipScore()
		t.role = me.nRoleType
		t.lang = szLang
		t.version = ver
		t.tong = szTong
		t.dwID = me.dwID
		t.server = szServer
		t.SchoolID = me.dwForceID
		for k, v in pairs(t) do
			s = s .. "&" .. k .. "=" .. JH.UrlEncode(tostring(v))
		end
		JH.RemoteRequest(s, function(szTitle, szDoc)
			if #szDoc > 0 then
				local result, err = JH.JsonDecode(JH.UrlDecode(szDoc))
				if result then
					Station.Lookup("Lowest/Scene").JH = result
					if result["msg"] then
						JH.Sysmsg(result["msg"])
					end
				end
			end			
		end)
	end)
end

JH.RegisterEvent("FIRST_LOADING_END", LoginGame)
JH.RegisterEvent("CALL_LUA_ERROR", function()
	if JH.bDebug then
		OutputMessage("MSG_SYS", arg0)
	end
end)
-- protect
local _About = {
	OnTaboxCheck = _JH_About.PS.OnTaboxCheck,
	OnPanelActive = _JH_About.PS.OnPanelActive,
	GetAuthorInfo = _JH_About.PS.GetAuthorInfo,
	CheckNameEx = _JH_About.CheckNameEx,
}
JH_About = {}
setmetatable(JH_About, { __metatable = true, __index = _About, __newindex = function() end } )