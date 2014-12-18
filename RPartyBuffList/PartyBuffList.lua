local _L = JH.LoadLangPack
PartyBuffList = {
	bEnable = true,
	bEnableRGES = true,
	bHoverSelect = false,
	tList = {},
	tAnchor = {},
}
JH.RegisterCustomData("PartyBuffList")

local _PartyBuffList = {
	tList = {},
	tTempTarget = {},
	szIniFile = "interface/JH/RPartyBuffList/ui/PartyBuffList.ini"
}

function PartyBuffList.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	_PartyBuffList.frame = this
	_PartyBuffList.bg = this:Lookup("", "Image_Bg")
	local ui = GUI(this)
	ui:Title(_L["PartyBuffList"]):Close(_PartyBuffList.ClosePanel, false, true)
	_PartyBuffList.UpdateAnchor(this)
	ui:Fetch("Btn_Style"):Click(function()
		JH.OpenPanel(_L["PartyBuffList"])
	end)
end
function PartyBuffList.OnEvent(event)
	if event == "UI_SCALED" then
		_PartyBuffList.UpdateAnchor(this)
	end
end
function PartyBuffList.OnFrameDragEnd()
	this:CorrectPos()
	PartyBuffList.tAnchor = GetFrameAnchor(this)
end
_PartyBuffList.OpenPanel = function()
	local frame = _PartyBuffList.frame or Wnd.OpenWindow(_PartyBuffList.szIniFile,"PartyBuffList")
	return frame
end
_PartyBuffList.IsPanelOpened = function()
	return _PartyBuffList.frame
end

_PartyBuffList.UiMode = function(szEvent)
	if szEvent == "ON_ENTER_CUSTOM_UI_MODE" and not _PartyBuffList.IsPanelOpened() then
		_PartyBuffList.OpenPanel()
	elseif szEvent == "ON_LEAVE_CUSTOM_UI_MODE" and IsEmpty(_PartyBuffList.tList) then
		_PartyBuffList.ClosePanel()
	end
end
_PartyBuffList.UpdateAnchor = function(frame)
	local a = PartyBuffList.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint("CENTER", 0, 0, "CENTER", 400, 0)
	end
end

_PartyBuffList.ClosePanel = function()
	Wnd.CloseWindow(_PartyBuffList.frame)
	_PartyBuffList.frame = nil
	_PartyBuffList.tList = {}
end

_PartyBuffList.GetListText = function()
	local tName = {}
	for k, _ in pairs(PartyBuffList.tList) do
		if type(k) == "string" then
			table.insert(tName, k)
		end
	end
	return table.concat(tName, "\n")
end

_PartyBuffList.UpdateFrame = function()
	if not PartyBuffList.bEnable then return end
	local data = _PartyBuffList.tList
	if #data == 0 then
		return _PartyBuffList.ClosePanel()
	end
	if not _PartyBuffList.frame then
		_PartyBuffList.OpenPanel()
	end
	local me = GetClientPlayer()
	local team = GetClientTeam()
	if not me or not team then return end
	local container = _PartyBuffList.frame:Lookup("WndContainer_List")
	container:Clear()
	local dwID, dwType = Target_GetTargetData()
	for k,v in ipairs(data) do
		local p,info
		if v.dwID == me.dwID then
			p = me
			info = {
				dwMountKungfuID = UI_GetPlayerMountKungfuID(),
				szName = me.szName,
				nMaxLife = me.nMaxLife,
				nCurrentLife = me.nCurrentLife,
				dwForce = me.dwForce,
			}
		else
			p = GetPlayer(v.dwID)
			info = team.GetMemberInfo(v.dwID)
		end
		if p and info then
			local wnd = container:AppendContentFromIni(_PartyBuffList.szIniFile,"WndWindow_Item",k)
			local ui = GUI(wnd)
			local nMaxLife = info.nMaxLife
			if nMaxLife == 0 then nMaxLife = 1 end -- fix bug
			ui:Append("Image","Life",{ x = 0, y = 0, w = 200, h = 40}):File("ui/Image/Common/money.uitex",215):Percentage(info.nCurrentLife / nMaxLife)
			local nDistance = JH.GetDistance(p)
			if nDistance > 20 then
				ui:Fetch("Life"):Alpha(120)
			else
				ui:Fetch("Life"):Alpha(255)
			end
			ui:Append("Image",{ x = 2, y = 2, w = 34, h = 34, icon = Table_GetSkillIconID(info.dwMountKungfuID) or 1435 })
			ui:Hover(function()
				if not PartyBuffList.bHoverSelect then return end
				SetTarget(TARGET.PLAYER, v.dwID)
			end).self.OnLButtonDown = function()
				SetTarget(TARGET.PLAYER, v.dwID)
			end
			ui:Append("Box",{ x = 165, y = 6, w = 28, h = 28,icon = Table_GetBuffIconID(v.dwBuffID,v.nLevel) }):Staring(true)
			ui:Append("Text",{ x = 37, y = 5, txt = k .. " " .. info.szName, font = 15  })
			ui:Append("Animate","Animate",{ x = -50, y = 2, w = 300, h = 36}):Animate("ui/Image/Common/Box.UITex",17,-1):Toggle(dwID == v.dwID)
			v.k = k
			ui.self.tab = v
		else
			table.remove(data,k)
			return pcall(_PartyBuffList.UpdateFrame)
		end
	end
	local w, h = 200, 40
	local n = container:GetAllContentCount()
	container:SetSize(w, h * n)
	_PartyBuffList.frame:SetSize(w, h * n + 30)
	_PartyBuffList.bg:SetSize(w, h * n + 30)
	container:FormatAllContentPos()
	_PartyBuffList.frame:Show()
end

_PartyBuffList.OnBreathe = function()
	if not PartyBuffList.bEnable then return end
	if not _PartyBuffList.frame then return end
	local me = GetClientPlayer()
	local team = GetClientTeam()
	if not me or not team then return end
	local container = _PartyBuffList.frame:Lookup("WndContainer_List")
	local n = container:GetAllContentCount()
	for i = n, 1, -1 do
		local wnd = container:Lookup(i)
		if not wnd then return end
		local v = wnd.tab
		local p,info
		if v.dwID == me.dwID then
			p = me
			info = {
				dwMountKungfuID = UI_GetPlayerMountKungfuID(),
				szName = me.szName,
				nMaxLife = me.nMaxLife,
				nCurrentLife = me.nCurrentLife,
				dwForce = me.dwForce,
			}
		else
			p = GetPlayer(v.dwID)
			info = team.GetMemberInfo(v.dwID)
		end
		local buff = JH.HasBuff(v.dwBuffID,p)
		if p and info and buff then
			local ui = GUI(wnd)
			local nMaxLife = info.nMaxLife
			if nMaxLife == 0 then nMaxLife = 1 end -- fix bug
			ui:Fetch("Life"):Percentage(info.nCurrentLife / nMaxLife)
			local nDistance = JH.GetDistance(p)
			if nDistance > 20 then
				ui:Fetch("Life"):Alpha(120)
			else
				ui:Fetch("Life"):Alpha(255)
			end
		else
			table.remove(_PartyBuffList.tList,v.k)
			return pcall(_PartyBuffList.UpdateFrame)
		end
	end
end

-- buff update
-- arg0：dwPlayerID，arg1：bDelete，arg2：nIndex，arg3：bCanCancel
-- arg4：dwBuffID，arg5：nStackNum，arg6：nEndFrame，arg7：？update all?
-- arg8：nLevel，arg9：dwSkillSrcID
_PartyBuffList.OnBuffUpdate = function()
	if not PartyBuffList.bEnable then return end
	if arg1 then return end
	local szName = JH.GetBuffName(arg4,arg8)
	if PartyBuffList.tList[szName] then
		PartyBuffList(arg0,arg4,arg8)
	end
end
-- public api
setmetatable(PartyBuffList,{ __call = function(me,dwID,dwBuffID,nLevel)
	for k,v in ipairs(_PartyBuffList.tList) do
		if v.dwID == dwID and v.dwBuffID == dwBuffID and v.nLevel == nLevel then
			return
		end
	end
	table.insert(_PartyBuffList.tList, { dwID = dwID, dwBuffID = dwBuffID, nLevel = nLevel })
	pcall(_PartyBuffList.UpdateFrame)
end})
local PS = {}
PS.OnPanelActive = function(frame)
	local ui, nX, nY = GUI(frame), 10, 0
	ui:Append("Text", { x = 0, y = 0, txt = _L["PartyBuffList"], font = 27 })
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = 28, checked = PartyBuffList.bEnable })
	:Text(_L["Enable PartyBuffList"]):Click(function(bChecked)
		PartyBuffList.bEnable = bChecked
		if not bChecked then
			_PartyBuffList.ClosePanel()
		end
	end):Pos_()
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = nY, checked = PartyBuffList.bEnableRGES })
	:Text(_L["Bind RGES"]):Click(function(bChecked)
		PartyBuffList.bEnableRGES = bChecked
	end):Pos_()
	nX,nY = ui:Append("WndCheckBox", { x = 10, y = nY, checked = PartyBuffList.bHoverSelect })
	:Text(_L["Mouse Enter select"]):Click(function(bChecked)
		PartyBuffList.bHoverSelect = bChecked
	end):Pos_()
	
	nX,nY = ui:Append("Text", { x = 0, y = nY, txt = _L["Manually add (One per line)"], font = 27 }):Pos_()
	nX,nY = ui:Append("WndEdit",{ x = 10, y = nY + 10, w = 450, h = 100, limit = 4096,multi = true})
	:Text(_PartyBuffList.GetListText()):Change(function(szText)
		local t = {}
		for _, v in ipairs(JH.Split(szText, "\n")) do
			v = JH.Trim(v)
			if v ~= "" then
				t[v] = true
			end
		end
		PartyBuffList.tList = t
	end):Pos_()
	nX,nY = ui:Append("Text", { x = 0, y = nY, txt = _L["Tips"], font = 27 }):Pos_()
	nX,nY = ui:Append("Text", { x = 10, y = nY + 10, w = 500 , h = 40, multi = true, txt = _L["PartyBuffList_TIPS"] }):Pos_()
end

JH.RegisterInit("PartyBuffList", 
	{ "ON_ENTER_CUSTOM_UI_MODE" , function() _PartyBuffList.UiMode("ON_ENTER_CUSTOM_UI_MODE") end },
	{ "ON_LEAVE_CUSTOM_UI_MODE" , function() _PartyBuffList.UiMode("ON_LEAVE_CUSTOM_UI_MODE") end },
	{ "BUFF_UPDATE" , _PartyBuffList.OnBuffUpdate },
	{ "UPDATE_SELECT_TARGET" , _PartyBuffList.UpdateFrame },
	{ "Breathe" , _PartyBuffList.OnBreathe }
)

GUI.RegisterPanel(_L["PartyBuffList"], 1453, _L["RGES"], PS)
