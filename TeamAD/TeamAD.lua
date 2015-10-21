-- @Author: Webster
-- @Date:   2015-01-21 15:21:19
-- @Last Modified by:   Webster
-- @Last Modified time: 2015-10-21 14:47:20
local _L = JH.LoadLangPack
local TeamAD = {
	szDataFile = "TeamAD.jx3dat",
	szAD = _L["Edit AD"],
	tItem = {
		{ dwTabType = 5, dwIndex = 24430, nUiId = 153192 },
		{ dwTabType = 5, dwIndex = 23988, nUiId = 152748 },
		{ dwTabType = 5, dwIndex = 23841, nUiId = 152596 },
		{ dwTabType = 5, dwIndex = 22939, nUiId = 151677 },
		{ dwTabType = 5, dwIndex = 23759, nUiId = 152512 },
		{ dwTabType = 5, dwIndex = 22084, nUiId = 150827 },
		{ dwTabType = 5, dwIndex = 22085, nUiId = 150828 },
		{ dwTabType = 5, dwIndex = 22086, nUiId = 150829 },
		{ dwTabType = 5, dwIndex = 22087, nUiId = 150830 },
		{ dwTabType = 5, dwIndex = 25831, nUiId = 153898 },
	}
}


TeamAD.SetEdit = function(edit,tab) -- ������ ������������ �񾭲�һ��������
	edit:ClearText()
	for kk,vv in ipairs(tab) do
		for kkk,vvv in ipairs(vv) do
			local text = "[link]"
			if vvv.text then text = vvv.text end
			edit:InsertObj(text,vvv)
		end
		if vv.text then
			edit:InsertObj(vv.text,vv)
		end
	end
end
TeamAD.PS = {}
TeamAD.PS.OnPanelActive = function(frame)
	TeamAD.tADList = JH.LoadLUAData(TeamAD.szDataFile) or {}
	local ui, nX, nY = GUI(frame), 10, 0
	nX,nY = ui:Append("Text", { x = 0, y = nY, txt = _L["TeamAD"], font = 27 }):Pos_()
	nX,nY = ui:Append("WndEdit","WndEditAD", { x = 10, y = 28,w = 500, h = 80,multi = true,limit = 164 }):Pos_()
	TeamAD.edit = ui:Fetch("WndEditAD").edit
	nX = ui:Append("WndButton2", { x = 10, y = nY + 10 })
	:Text(_L["Save AD"]):Click(function(bChecked)
		local ad = ui:Fetch("WndEditAD"):Text()
		local data = TeamAD.edit:GetTextStruct()
		GetUserInput(_L["Save Name"],function(txt)
			if #TeamAD.tADList == 18 then return end
			table.insert(TeamAD.tADList,{key = txt,txt = ad,ad = data})
			TeamAD.SetEdit(TeamAD.edit,data)
			JH.SaveLUAData(TeamAD.szDataFile,TeamAD.tADList, "\t")
			JH.OpenPanel(_L["TeamAD"])
		end,nil,nil,nil,nil,5)
	end):Pos_()
	nX = ui:Append("WndButton2", { x = nX + 10, y = nY + 10 })
	:Text(_L["push Edit"]):Click(function(bChecked)
		local ad = ui:Fetch("WndEditAD"):Text()
		local data = TeamAD.edit:GetTextStruct()
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		TeamAD.SetEdit(edit,data)
		Station.SetFocusWindow(edit)
	end):Pos_()
	nX,nY = ui:Append("WndButton2", { x = nX + 10, y = nY + 10 })
	:Text(_L["Import"]):Click(function()
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		TeamAD.SetEdit(TeamAD.edit,edit:GetTextStruct())
	end):Pos_()
	local t = TeamAD.tItem
	for k, v in ipairs(t) do
		if k % #t == 1 then nX = 10 end
		nX = ui:Append("Box", { x = nX + 12, y = nY + 5, w = 38, h = 38 }):ItemInfo(GLOBAL.CURRENT_ITEM_VERSION, v.dwTabType, v.dwIndex):Pos_()
	end
	nY = nY + 48
	nX, nY = ui:Append("Text", { x = 0, y = nY, txt = _L["AD List"], font = 27 }):Pos_()
	nY = nY - 10
	for k,v in ipairs(TeamAD.tADList) do
		if k % 4 == 1 then nX = 10 end
		nX = ui:Append("WndButton2", { x = nX + 15, y = nY + math.ceil(k/4) * 32 })
		:Text(v.key):Click(function()
			local txt = GUI(this):Text()
			if IsCtrlKeyDown() then
				table.remove(TeamAD.tADList,k)
				JH.SaveLUAData(TeamAD.szDataFile,TeamAD.tADList, "\t")
				JH.OpenPanel(_L["TeamAD"])
			else
				local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
				TeamAD.SetEdit(edit,v.ad)
				TeamAD.SetEdit(TeamAD.edit,v.ad)
				Station.SetFocusWindow(edit)
			end
		end):Pos_()
	end
end

GUI.RegisterPanel(_L["TeamAD"], 5958, g_tStrings.CHANNEL_CHANNEL, TeamAD.PS)
-- public
JH.TeamAD = {}
JH.TeamAD.SetEdit = TeamAD.SetEdit
