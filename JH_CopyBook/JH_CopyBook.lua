-- ʲôʱ��Ĵ����Ҷ�������
local _L = JH.LoadLangPack
JH_CopyBook = {
	szBookName = _L["BOOK_143"],
	nCopyNum   = 1,
	tIgnore    = {},
}
JH.RegisterCustomData("JH_CopyBook")

local Book = {
	tCache  = {},
	bEnable = false,
	nBook   = 1
}

-- ����ֵ �鱾ID���鱾��������Ҫ����, ��ü౾
function Book.GetBook(szName)
	local me = GetClientPlayer()
	local nCount = g_tTable.BookSegment:GetRowCount() --��ȡ�������
	local dwBookID, dwBookNumber
	local nThew, nExamPrint, nMaxLevel, nMaxLevelEx, nMaxPlayerLevel, dwProfessionIDExt = 0, 0, 0, 0, 0, 0
	local tItems, tBooks, tTool = {}, {}, {}
	for i = 1, nCount do
		local item = g_tTable.BookSegment:GetRow(i)
		if item.szBookName == szName then
			dwBookID     = item.dwBookID
			dwBookNumber = item.dwBookNumber
			break
		end
	end
	if dwBookID then
		for i = 1, dwBookNumber do
			local tRecipe = GetRecipe(12, dwBookID, i)
			if not JH_CopyBook.tIgnore[i] then
				nThew           = nThew + tRecipe.nThew
				nMaxLevel       = math.max(nMaxLevel, tRecipe.dwRequireProfessionLevel) -- �Ķ��ȼ�
				nMaxPlayerLevel = math.max(nMaxPlayerLevel, tRecipe.nRequirePlayerLevel) -- ��ɫ�ȼ�
				if nMaxLevelEx < tRecipe.dwRequireProfessionLevelExt then
					nMaxLevelEx = tRecipe.dwRequireProfessionLevelExt
					if dwProfessionIDExt == 0 then -- ��֪��Ϊë��������档����
						dwProfessionIDExt = tRecipe.dwProfessionIDExt
					end
				end
				for nIndex = 1, 4, 1 do
					local dwTabType = tRecipe["dwRequireItemType"  .. nIndex]
					local dwIndex   = tRecipe["dwRequireItemIndex" .. nIndex]
					local nCount    = tRecipe["dwRequireItemCount" .. nIndex]
					if nCount > 0 then
						local item = GetItemInfo(dwTabType, dwIndex)
						tItems[item.szName] = tItems[item.szName] or { dwTabType = dwTabType, dwIndex = dwIndex, nUiId = item.nUiId, nCount = 0 }
						tItems[item.szName].nCount = tItems[item.szName].nCount + nCount
					end
				end
				if tRecipe.dwToolItemType ~= 0 and tRecipe.dwToolItemIndex ~= 0 then
					local item   = GetItemInfo(tRecipe.dwToolItemType, tRecipe.dwToolItemIndex)
					local nCount = me.GetItemAmount(tRecipe.dwToolItemType, tRecipe.dwToolItemIndex)
					tTool[item.szName] = nCount
				end
			end
			table.insert(tBooks, {
				dwTabType = tRecipe.dwCreateItemType,
				dwIndex   = tRecipe.dwCreateItemIndex,
				nUiId     = GetItemInfo(tRecipe.dwCreateItemType, tRecipe.dwCreateItemIndex).nUiId
			})
		end
		local tTable = g_tTable.BookEx:Search(dwBookID)
		if tTable then
			nExamPrint = tTable.dwPresentExamPrint
		end
	end
	return dwBookID, dwBookNumber, nThew, nExamPrint, nMaxLevel, nMaxLevelEx, nMaxPlayerLevel, dwProfessionIDExt, tItems, tBooks, tTool
end

function Book.UpdateInfo(szName)
	local ui = Book.ui
	if not ui then return end
	local me = GetClientPlayer()
	local dwBookID, dwBookNumber, nThew, nExamPrint, nMaxLevel, nMaxLevelEx, nMaxPlayerLevel, dwProfessionIDExt, tItems, tBooks, tTool = Book.GetBook(szName and szName or JH_CopyBook.szBookName)
	if dwBookID then
		local bCanCopy = nThew > 0  and true or false
		local green, red = { 255, 255, 255 }, { 255, 0, 0 }
		ui:Fetch("Copy"):Enable(true)
		local nMax = math.max(math.floor(me.nCurrentThew / math.max(nThew, 1)), 1)
		if JH_CopyBook.nCopyNum > nMax and not Book.bEnable then
			JH_CopyBook.nCopyNum = nMax
		end
		ui:Fetch("Count"):Enable(bCanCopy):Change(nil):Range(0, nMax, math.max(nMax, 0)):Value(JH_CopyBook.nCopyNum):Change(function(nNum)
			JH_CopyBook.nCopyNum = nNum
			Book.UpdateInfo()
		end)
		local handle = ui:Fetch("Require"):Clear()
		local nX ,nY = 10, 0
		if IsEmpty(JH_CopyBook.tIgnore) then
			nX ,nY = handle:Append("Text", { x = nX, y = nY, txt = FormatString(g_tStrings.CRAFT_COPY_REWARD_EXAMPRINT, " " .. JH_CopyBook.nCopyNum * nExamPrint .. " ") .. string.format("  (1 = %.2f)", nThew / nExamPrint), color = { 255, 128, 0 } }):Pos_()
		end
		bCanCopy = bCanCopy and JH_CopyBook.nCopyNum * nThew <= me.nCurrentThew
		nX ,nY = handle:Append("Text", { x = 10, y = nY + 5, txt = FormatString(g_tStrings.STR_MSG_NEED_COST_THEW, me.nCurrentThew .. "/" .. JH_CopyBook.nCopyNum * nThew), color = JH_CopyBook.nCopyNum * nThew <= me.nCurrentThew and green or red }):Pos_()
		-- �Ķ��ȼ�����
		local nPlayerLevel = me.GetProfessionLevel(8)
		bCanCopy = bCanCopy and nPlayerLevel >= nMaxLevel
		nX, nY = handle:Append("Text", { x = 10, y = nY + 5, txt = FormatString(g_tStrings.CRAFT_READING_REQUIRE_LEVEL, nPlayerLevel .. "/" .. nMaxLevel), color = nPlayerLevel >= nMaxLevel and green or red }):Pos_()
		-- XX�ȼ�����
		if dwProfessionIDExt ~= 0 then
			local ProfessionExt = GetProfession(dwProfessionIDExt)
			if ProfessionExt then
				local nExtLevel = me.GetProfessionLevel(dwProfessionIDExt)
				bCanCopy = bCanCopy and nExtLevel >= nMaxLevelEx
				nX, nY = handle:Append("Text", { x = 10, y = nY + 5, txt = Table_GetProfessionName(dwProfessionIDExt) .. nExtLevel .. "/" .. nMaxLevelEx .. g_tStrings.LEVEL_BLANK, color = nExtLevel >= nMaxLevelEx and green or red }):Pos_()
			end
		end
		if nMaxPlayerLevel ~= 0 then
			bCanCopy = bCanCopy and me.nLevel >= nMaxPlayerLevel
			nX, nY = handle:Append("Text", { x = 10, y = nY + 5, txt = FormatString(g_tStrings.STR_CRAFT_READ_NEED_PLAYER_LEVEL, me.nLevel .. "/" .. nMaxPlayerLevel), color = me.nLevel >= nMaxPlayerLevel and green or red }):Pos_()
		end
		if not IsEmpty(tTool) then
			nX = handle:Append("Text", { x = 10, y = nY + 5, txt = g_tStrings.CRAFT_NEED_TOOL, color = green }):Pos_()
			for k, v in pairs(tTool) do
				bCanCopy = bCanCopy and v ~= 0
				nX = handle:Append("Text", { x = nX + 5, y = nY + 5, txt = k, color = v ~= 0 and green or red }):Pos_()
			end
			nY = nY + 15
		end
		-- tTool[item.szName]
		local i = 0
		for k, v in pairs(tItems) do
			local nCount = me.GetItemAmount(v.dwTabType, v.dwIndex)
			bCanCopy = bCanCopy and nCount >= v.nCount * JH_CopyBook.nCopyNum
			nX = handle:Append("Box", "iteminfolink", { x = (i % 9) * 58, y = nY + math.floor(i / 9 ) * 55 + 15, w = 48, h = 48, icon = Table_GetItemIconID(v.nUiId)})
			:OverText(ITEM_POSITION.RIGHT_BOTTOM, nCount .. "/" .. v.nCount * JH_CopyBook.nCopyNum, 0, nCount >= v.nCount * JH_CopyBook.nCopyNum and 15 or 159)
			:Click(function()
				this.nVersion  = GLOBAL.CURRENT_ITEM_VERSION
				this.dwTabType = v.dwTabType
				this.dwIndex   = v.dwIndex
				return OnItemLinkDown(this)
			end):Hover(function(bHover)
				if bHover then
					this:SetObjectMouseOver(true)
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					OutputItemTip(UI_OBJECT_ITEM_INFO,GLOBAL.CURRENT_ITEM_VERSION, v.dwTabType, v.dwIndex, { x, y, w, h })
				else
					this:SetObjectMouseOver(false)
					HideTip()
				end
			end):Pos_()
			i = i + 1
		end
		local hBooks = ui:Fetch("Books"):Toggle(true):Clear()
		nX = 5
		local tBS, tCheck = me.GetBookSegmentList(dwBookID), {}
		for k, v in ipairs(tBS) do
			tCheck[v] = true
		end
		for k, v in ipairs(tBooks) do
			if not JH_CopyBook.tIgnore[k] then
				bCanCopy = bCanCopy and tCheck[k] or false
			end
			nX = hBooks:Append("Box", "booklink", { x = nX + 10, y = 5, w = 32, h = 32, icon = Table_GetItemIconID(v.nUiId)})
			:ToGray(not tCheck[k])
			:Enable(not JH_CopyBook.tIgnore[k] and true or false)
			:Click(function()
				if not IsCtrlKeyDown() then
					this:EnableObject(this:IsObjectEnable())
					JH_CopyBook.tIgnore[k] = this:IsObjectEnable() or nil
					Book.UpdateInfo()
				else
					this.nVersion      = GLOBAL.CURRENT_ITEM_VERSION
					this.dwTabType     = v.dwTabType
					this.dwIndex       = v.dwIndex
					this.nBookRecipeID = BookID2GlobelRecipeID(dwBookID, k)
					return OnItemLinkDown(this)
				end
			end):Hover(function(bHover)
				if bHover then
					this:SetObjectMouseOver(true)
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()

					OutputTip(GetBookTipByItemInfo(GetItemInfo(v.dwTabType, v.dwIndex), dwBookID, k, true), 400, { x, y, w, h })
				else
					this:SetObjectMouseOver(false)
					HideTip()
				end
			end):Pos_()
		end
		ui:Fetch("Copy"):Enable(bCanCopy and JH_CopyBook.nCopyNum > 0)
		if szName then
			JH_CopyBook.szBookName = szName
		end
		if not Book.bEnable and Book.nBook ~= 1 and Book.szBookName and Book.szBookName == JH_CopyBook.szBookName then
			ui:Fetch("go_on"):Toggle(true)
		else
			ui:Fetch("go_on"):Toggle(false)
		end
	else
		ui:Fetch("Count"):Enable(false)
		ui:Fetch("Copy"):Enable(false)
		ui:Fetch("Books"):Toggle(false)
		local handle = ui:Fetch("Require"):Clear()
		handle:Append("Text", { x = 0, y = 0, txt = _L["No Books"], color = { 0, 255, 0 } })
	end
end

function Book.CheckCopy()
	if Book.bEnable then
		return JH.Sysmsg(g_tStrings.STR_ERROR_IN_OTACTION)
	end
	local dwBookID, dwBookNumber = Book.GetBook(JH_CopyBook.szBookName)
	if Book.nBook and Book.nBook > 1
		and Book.szBookName and JH_CopyBook.szBookName == Book.szBookName
	then
		JH.Confirm(_L("%s, go on?", Book.szBookName .. " " .. Book.nBook .. "/" .. dwBookNumber), function()
			Book.Copy()
		end, function()
			Book.nBook = 1
			Book.Copy()
		end, _L["go on"], _L["restart"])
	else
		Book.Copy()
	end
end

function Book.Copy()
	local me = GetClientPlayer()
	Book.bEnable     = true
	Book.szBookName  = JH_CopyBook.szBookName
	local dwBookID, dwBookNumber, nThew, nExamPrint, nMaxLevel, nMaxLevelEx, nMaxPlayerLevel, dwProfessionIDExt, tItems, tBooks = Book.GetBook(szName and szName or JH_CopyBook.szBookName)
	assert(dwBookID)
	JH.Sysmsg(_L("Start Copy Book %s", Book.szBookName))
	local function Stop()
		Book.bLock   = false
		Book.bEnable = false
		JH.UnBreatheCall("CokyBook")
		JH.UnRegisterEvent("DO_RECIPE_PREPARE_PROGRESS.CopyBook")
		JH.UnRegisterEvent("OT_ACTION_PROGRESS_BREAK.CopyBook")
		JH.Sysmsg(_L("Stop Copy Book %s", Book.szBookName))
		Book.UpdateInfo()
	end
	JH.RegisterEvent("OT_ACTION_PROGRESS_BREAK.CopyBook", function()
		if arg0 == GetClientPlayer().dwID then
			JH.Debug("COPYBOOK # OT_ACTION_PROGRESS_BREAK #" .. arg0)
			return Stop()
		end
	end)
	JH.RegisterEvent("DO_RECIPE_PREPARE_PROGRESS.CopyBook", function()
		Book.nTotalFrame = GetLogicFrameCount() + arg0
	end)
	JH.BreatheCall("CokyBook", function()
		local me = GetClientPlayer()
		if not me then
			return
		end
		local nBook = Book.nBook
		if me.nMoveState ~= MOVE_STATE.ON_STAND then -- ����վ��״ֱ̬�Ӵ��
			JH.Debug("COPYBOOK # MOVE_STATE #" .. me.nMoveState)
			return Stop()
		end
		if not Book.bLock then
			if JH_CopyBook.tIgnore[Book.nBook] then
				Book.bLock       = true
				Book.nTotalFrame = 0
			else
				local nState = me.CastProfessionSkill(12, dwBookID, nBook)
				if nState ~= 1 then
					JH.Debug("COPYBOOK # CAST_ERROR #" .. nState)
					return Stop()
				end
				Book.bLock = true
				Book.nTotalFrame = GetLogicFrameCount() + 16 -- ��Сʱ���
			end
		elseif GetLogicFrameCount() > Book.nTotalFrame then
			repeat
				Book.nBook = Book.nBook + 1
				if Book.nBook > dwBookNumber then -- һ���鳭����
					Book.nBook = 1
					if me.nCurrentThew < nThew then -- ��������һ����
						Stop()
						return JH.Sysmsg(_L["Not Enough Thew"])
					end
					JH_CopyBook.nCopyNum = JH_CopyBook.nCopyNum - 1
					if JH_CopyBook.nCopyNum == 0 then
						return Stop()
					end
					Book.UpdateInfo()
				end
			until not JH_CopyBook.tIgnore[Book.nBook]
			Book.bLock = false
		end
	end)
end

local PS = {}
function PS.OnPanelActive(frame)
	local ui, nX, nY = GUI(frame), 10, 0
	Book.ui = ui
	nX, nY = ui:Append("Text", { x = 0, y = 0, txt = _L["Copy Book"], font = 27 }):Pos_()
	nX = ui:Append("Text", { x = 10, y = nY + 10, txt = _L["Books Name"] }):Pos_()
	nX = ui:Append("WndEdit", "Name", { x = nX + 5, y = nY + 12, txt = JH_CopyBook.szBookName }):Autocomplete(function(szText)
		if not Book.tBookList then
			local tName = {}
			Book.tBookList = {}
			for i = 2, g_tTable.BookSegment:GetRowCount() do
				local item = g_tTable.BookSegment:GetRow(i)
				if not tName[item.szBookName] then
					table.insert(Book.tBookList, { szOption = item.szBookName })
					tName[item.szBookName] = true
				end
			end
			setmetatable(Book.tBookList, { __index = tName })
		end
		return Book.tBookList
	end, Book.UpdateInfo):Pos_()
	nX = ui:Append("WndButton2", "Copy", { x = nX + 5, y = nY + 12, txt = _L["Start Copy"] }):Click(Book.CheckCopy):Pos_()
	nX, nY = ui:Append("WndButton2", "go_on", { x = nX + 5, y = nY + 12, txt = _L["go on"] }):Toggle(false):Click(Book.Copy):Pos_()
	nX = ui:Append("Text", { x = 10, y = nY, txt = _L["Copy Count"] }):Pos_()
	nX, nY = ui:Append("WndTrackBar", "Count", { x = nX + 5, y = nY + 5, txt = "" }):Range(1, 1, 1):Pos_()
	nX, nY = ui:Append("Handle", "Books", { x = 0, y = nY, h = 40, w = 500 }):Pos_()
	nX, nY = ui:Append("Text", { x = 0, y = nY, txt = g_tStrings.STR_CRAFT_TIP_RECIPE_REQUIRE, font = 27 }):Pos_()
	nX, nY = ui:Append("Handle", "Require", { x = 0, y = nY + 5, h = 200, w = 500})
	Book.UpdateInfo()
	JH.RegisterEvent("BAG_ITEM_UPDATE.CokyBook", function() Book.UpdateInfo() end)
	JH.RegisterEvent("PROFESSION_LEVEL_UP.CokyBook", function() Book.UpdateInfo() end)
end

function PS.OnPanelDeactive()
	JH.UnRegisterEvent("BAG_ITEM_UPDATE.CokyBook")
	JH.UnRegisterEvent("PROFESSION_LEVEL_UP.CokyBook")
end

GUI.RegisterPanel(_L["Copy Book"], 415, g_tStrings.CHANNEL_CHANNEL, PS)
