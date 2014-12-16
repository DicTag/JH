local _L = JH.LoadLangPack
local _JH_FontList = {
	nCur = 0,
	nMax = 255,
}
_JH_FontList.OnPanelActive = function(frame)
	local ui = GUI(frame)
	local txts = {}
	ui:Append("Text", { txt = _L["Font"], x = 0, y = 0, font = 27 })
	for i = 1, 40 do
		local x = ((i - 1) % 8) * 62
		local y = math.floor((i - 1) / 8) * 55 + 30
		txts[i] = ui:Append("Text", { w = 62, h = 30, x = x, y = y, align = 1 })
	end
	local btn1 = ui:Append("WndButton2", { txt = _L["Up"], x = 0, y = 320 })
	local nX, _ = btn1:Pos_()
	local btn2 = ui:Append("WndButton2", { txt = _L["Next"], x = nX, y = 320 })
	btn1:Click(function()
		_JH_FontList.nCur = _JH_FontList.nCur - #txts
		if _JH_FontList.nCur <= 0 then
			_JH_FontList.nCur = 0
			btn1:Enable(false)
		end
		btn2:Enable(true)
		for k, v in ipairs(txts) do
			local i = _JH_FontList.nCur + k - 1
			if i > _JH_FontList.nMax then
				txts[k]:Text("")
			else
				txts[k]:Text(_L["Jh"] .. i)
				txts[k]:Font(i)
			end
		end
	end):Click()
	btn2:Click(function()
		_JH_FontList.nCur = _JH_FontList.nCur + #txts
		if (_JH_FontList.nCur + #txts) >= _JH_FontList.nMax then
			btn2:Enable(false)
		end
		btn1:Enable(true)
		for k, v in ipairs(txts) do
			local i = _JH_FontList.nCur + k - 1
			if i > _JH_FontList.nMax then
				txts[k]:Text("")
			else
				txts[k]:Text(_L["Jh"] .. i)
				txts[k]:Font(i)
			end
		end
	end)
end
JH_FontList = _JH_FontList