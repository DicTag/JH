-- @Author: Webster
-- @Date:   2015-02-27 14:44:16
-- @Last Modified by:   Webster
-- @Last Modified time: 2015-02-27 15:33:09
local _L = JH.LoadLangPack
local tEventIndex = {
	{ "���̰���", 13 },
	{ "���̵���", 14 },

	{ "�������", 1 },
	{ "�������", 3 },
	{ "������", 5 },
	{ "���˫��", 7 },
	{ "�����ק", 20 },

	{ "�Ҽ�����", 2 },
	{ "�Ҽ�����", 4 },
	{ "�Ҽ����", 6 },
	{ "�Ҽ�˫��", 8 },
	{ "�Ҽ���ק", 19 },

	{ "�м�����", 15 },
	{ "�м�����", 16 },
	{ "�м����", 17 },
	{ "�м�˫��", 18 },
	{ "�м���ק", 21 },

	{ "������", 9 },
	{ "�������", 10 },
	{ "����ƶ�", 11 },
	{ "�����ͣ", 22 },
	{ "�����¼�", 12 },
}

local PS = {}
function PS.OnPanelActive(frame)
	local ui, nX, nY = GUI(frame), 10, 0
	local function BitTable2UInt()
		local tBitTab = {}
		for k, v in ipairs(tEventIndex) do
			if ui:Fetch(v[1]) then
				if ui:Fetch(v[1]):Check() then
					tBitTab[v[2]] = 1
				else
					tBitTab[v[2]] = 0
				end
			end
		end
		local nUInt = 0
		for i = 1, 24 do
			nUInt = nUInt + (tBitTab[i] or 0) * (2 ^ (i - 1))
		end
		ui:Fetch("WndEdit"):Text(nUInt)
	end

	nX, nY = ui:Append("Text", { x = 0, y = 0, txt = _L["Events"], font = 27 }):Pos_()
	nX, nY = ui:Append("WndEdit", "WndEdit", { txt = 0, x = 10, y = nY + 10, font = 201, color = { 255, 255, 255 }}):Pos_()
	nX, nY = 5, nY + 10
	for i = 1, 2 do
		local v = tEventIndex[i]
		nX = ui:Append("WndCheckBox", v[1], { txt = v[1], x = nX + 5, y = nY }):Click(function(bCheck)
			if bCheck then
				ui:Fetch(v[1]):Color(255, 128, 0)
			else
				ui:Fetch(v[1]):Color(255, 255, 255)
			end
			BitTable2UInt()
		end):Pos_()
	end
	nX, nY = 5, nY + 25
	for i = 3, 22 do
		local v = tEventIndex[i]
		nX = ui:Append("WndCheckBox", v[1], { txt = v[1], x = nX + 5, y = nY }):Click(function(bCheck)
			if bCheck then
				ui:Fetch(v[1]):Color(255, 128, 0)
			else
				ui:Fetch(v[1]):Color(255, 255, 255)
			end
			BitTable2UInt()
		end):Pos_()
		if(i - 1) % 5 == 1 then
			nX, nY = 5, nY + 25
		end
	end
end

GUI.RegisterPanel(_L["Events"], 6060, _L["Dev"], PS)
