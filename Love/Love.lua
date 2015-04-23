-- @Author: Webster
-- @Date:   2015-01-21 15:21:19
-- @Last Modified by:   Webster
-- @Last Modified time: 2015-04-23 15:22:25
local _L = JH.LoadLangPack
JH_Love = {
	bQuiet = false,				-- ����ţ��ܾ������˵Ĳ鿴����
	szNone = _L["Singleton"],		-- û��Եʱ��ʾ����
	szJabber = _L["Hi, I seem to meet you somewhere ago"],	-- ��ڨ����
	bAutoFocus = true,	-- �Զ�����
}
JH.RegisterCustomData("JH_Love")
JH_Love.szTitle = _L["Lover of JX3"]

--[[
������Ե��
========
1. ÿ����ɫֻ������һ����Ե����Ե�����Ǻ���
2. ��Ҫ̹��������Ե��Ϣ�޷����أ����ѿ�ֱ�Ӳ鿴�������������ȷ�ϣ�
3. ����˫����Ե��Ҫ�����غ�����Ӳ���5���ڣ�������Ҫ�����֮�ģ���ѡ��ΪĿ�꣬�ٵ���ȷ��
4. ������Ե������ѡ��һ�� 3�غø����ϵ����ߺ��ѣ��Է����յ�����֪ͨ
5. ��Ե������ʱ����������������֪ͨ�Է���������Ե����������֪ͨ��
6. ��ɾ����Ե�������Զ������Ե��ϵ


�Ķ���Ե��
    XXXXXXXXX (198����� ...) [ն��˿]
	���ͣ�����/˫��  ʱ����X��XСʱX����X��

	�����ض��ѽ�����[___________] ������4���ڣ���һ�����֮�ģ�
	����ĳ�����غ��ѣ�[___________] ��Ҫ�����ߣ�����֪ͨ�Է���
	û��Եʱ��ʾʲô��[___________]  [**] ���������ģʽ

    ��Ե���ԣ� [________________________________________________________]
	��ڨ��� [________________________________________________________]

С��ʾ��
    1. ����װ���������Ҳ����໥��������
	2. ��Ե���Ե�����ɾ����˫����Ե��ͨ�����ĸ�֪�Է�
	3. �Ƕ��Ѳ鿴��ԵʱĿ�ᵯ��ȷ�Ͽ򣨿ɿ�����������Σ�
--]]

---------------------------------------------------------------------
-- ���غ����ͱ���
---------------------------------------------------------------------
local _i = Table_GetItemName
local _JH_Love = {
	dwID = 0,				-- ��Ե ID
	szName = "",		-- ��Ե����
	dwAvatar = 0,		-- ��Եͷ��
	nRoleType = 0,	-- ��Ե���ͣ�0������Ե��
	nLoveType = 0,	-- ��Ե���ͣ�����0��˫��1��
	nStartTime = 0,	-- ��Ե��ʼʱ�䣨��λ���룩
	szSign = "",			-- ��Ե���ԣ�����ǩ����
	tOther = {},			-- �鿴����Ե���ݣ�[0] = szName, [1] = dwAvatar,  [2] = szSign, [3] = nRoletype, [4] = nLoveType��
	tViewer = {},			-- �Ⱥ�鿴��������б�
	dwRoot = 2669320,		-- root user id
}

-- ���ر�����������ף�˫����ȡ������֪ͨ��
_JH_Love.tAutoSay = {
	_L["Some people fancy you"],
	_L["Other side terminate love you"],
	_L["Some people fall in love with you"],
	_L["Other side gave up love you"],
}

-- ��ȡ����ָ��������Ʒ
_JH_Love.GetBagItemPos = function(szName)
	local me = GetClientPlayer()
	for dwBox = 1, BigBagPanel_nCount do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local it = me.GetItem(dwBox, dwX)
			if it and GetItemNameByItem(it) == szName then
				return dwBox, dwX
			end
		end
	end
end

-- ���ݱ��������ȡ��Ʒ������
_JH_Love.GetBagItemNum = function(dwBox, dwX)
	local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX)
	if not item then
		return 0
	elseif not item.bCanStack then
		return 1
	else
		return item.nStackNum
	end
end

-- �Ƿ�ɽ�˫����ѣ����������֮�ĵ�λ��
_JH_Love.GetDoubleLoveItem = function(aInfo)
	if aInfo then
		local tar = GetPlayer(aInfo.id)
		if aInfo.attraction >= 800 and tar and JH.IsParty(tar.dwID) and JH.GetDistance(tar) <= 4 then
			return _JH_Love.GetBagItemPos(_i(67291))
		end
	end
end

-- ��ȡͷ���ļ�·����֡���Ƿ񶯻�
_JH_Love.GetAvatarFile = function(dwAvatar, nRoleType)
	-- mini avatar
	if dwAvatar > 0 then
		local tInfo = g_tTable.RoleAvatar:Search(dwAvatar)
		if tInfo then
			if nRoleType == ROLE_TYPE.STANDARD_MALE then
				return tInfo.szM2Image, tInfo.nM2ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.STANDARD_FEMALE then
				return tInfo.szF2Image, tInfo.nF2ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.STRONG_MALE then
				return tInfo.szM3Image, tInfo.nM3ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.SEXY_FEMALE then
				return tInfo.szF3Image, tInfo.nF3ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.LITTLE_BOY then
				return tInfo.szM1Image, tInfo.nM1ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.LITTLE_GIRL then
				return tInfo.szF1Image, tInfo.nF1ImgFrame, tInfo.bAnimate
			end
		end
	end
	-- force avatar
	local tForce = { "shaolin", "wanhua", "tiance", "chunyang", "qixiu", "wudu", "tangmen", "cangjian", "gaibang", "mingjiao" }
	local szForce = tForce[0 - dwAvatar] or "jianghu"
	return "ui\\Image\\PlayerAvatar\\" .. szForce .. ".tga", -2, false
end

-- �����������
_JH_Love.SaveFellowRemark = function(id, remark)
	if not remark or remark == "" then
		remark = " "
	end
	GetClientPlayer().SetFellowshipRemark(id, remark)
	--[[
	Wnd.CloseWindow("PartyPanel")
	local frame = Wnd.OpenWindow("PartyPanel")
	local page = frame:Lookup("Wnd_FriendInfo")
	if not page then return end
	local edit = page:Lookup("Edit_Name")
	if not edit then return end
	page.dwID = id
	edit:SetLimit(128)
	Station.SetFocusWindow(edit)
	edit:SetText(remark)
	Station.SetFocusWindow(frame)
	Wnd.CloseWindow("PartyPanel")
	--]]
end

-- ���� ID ��ȡ���ݺ�����Ϣ
_JH_Love.GetFellowDataByID = function(id)
	local me = GetClientPlayer()
	local aGroup = me.GetFellowshipGroupInfo() or {}
	table.insert(aGroup, 1, {id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND})
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for _, vv in ipairs(aFriend) do
			if vv.id == id then
				return vv
			end
		end
	end
	return nil
end

-- ����У���ȷ�����ݲ����۸ģ�0-255��
_JH_Love.EncodeString = function(szData)
	local nCrc = 0
	for i = 1, string.len(szData) do
		nCrc = (nCrc + string.byte(szData, i)) % 255
	end
	return string.format("%02x", nCrc) .. szData
end

-- �޳�У�����ȡԭʼ����
_JH_Love.DecodeString = function(szData)
	if string.len(szData) > 2 then
		local nCrc = 0
		for i = 3, string.len(szData) do
			nCrc = (nCrc + string.byte(szData, i)) % 255
		end
		if nCrc == tonumber(string.sub(szData, 1, 2), 16) then
			return string.sub(szData, 3)
		end
	end
end

-- ����ֵ�������ݵ����ѱ�ע���ɹ� true��ʧ�� false��
-- FIXME��ͨ�� ID ��������ʱ���ܻḲ������������������ݣ�����
_JH_Love.SetFellowDataByKey = function(szKey, szData, dwID, bEnc)
	local szKey, me, slot = "#HM#" .. szKey .. "#", GetClientPlayer(), nil
	if not me then return Output("not me") end
	local aGroup = me.GetFellowshipGroupInfo() or {}
	table.insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })
	if bEnc and szData then
		szData = _JH_Love.EncodeString(szData)
	end
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for i = #aFriend, 1, -1 do
			local info = aFriend[i]
			local bMatch = string.sub(info.remark, 1, string.len(szKey)) == szKey
			if not szData then
				-- fetch data
				if bMatch then
					local szData = string.sub(info.remark, string.len(szKey) + 1)
					if bEnc then
						szData = _JH_Love.DecodeString(szData)
					end
					return szData, info
				end
			elseif not dwID then
				-- set by Key
				if bMatch then
					_JH_Love.SaveFellowRemark(info.id, szKey .. szData)
					return true, info
				end
				-- find slot
				if string.sub(info.remark, 1, 4) ~= "#HM#" and (not slot or info.attraction < slot.attraction) then
					slot = info
				end
			else
				-- set by ID (unique key)
				if dwID == info.id then
					slot = info
				elseif bMatch then
					_JH_Love.SaveFellowRemark(info.id, "")
				end
			end
		end
	end
	-- last result
	if szData then
		if slot then
			_JH_Love.SaveFellowRemark(slot.id, szKey .. szData)
			return true, slot
		else
			return false, nil
		end
	end
end

-- ����ֵ�Ӻ��ѱ�ע����ȡ���ݣ��ɹ��������� + rawInfo��ʧ�� nil��
_JH_Love.GetFellowDataByKey = function(szKey, bEnc)
	return _JH_Love.SetFellowDataByKey(szKey, nil, nil, bEnc)
end

-- ת��������ϢΪ��Ե��Ϣ
_JH_Love.ToLocalLover = function(aInfo)
	if not aInfo then
		_JH_Love.dwID = 0
		_JH_Love.szName = ""
		_JH_Love.dwAvatar = 0
		_JH_Love.nRoleType = 0
		_JH_Love.nLoveType = 0
		_JH_Love.nStartTime = 0
	else
		_JH_Love.dwID = aInfo.id
		_JH_Love.szName = aInfo.name
		_JH_Love.dwAvatar = aInfo.miniavatar
		_JH_Love.nRoleType = aInfo.roletype
		if aInfo.miniavatar == 0 then
			_JH_Love.dwAvatar = 0 - aInfo.forceid
		end
	end
end

-- ��ȡ��Ե����
_JH_Love.GetLoverType = function(nType)
	nType = nType or _JH_Love.nLoveType
	if nType == 1 then
		return _L["Mutual love"]
	else
		return _L["Blind love"]
	end
end

-- ��ȡ��Եʱ��
_JH_Love.GetLoverTime = function(nTime)
	nTime = nTime or _JH_Love.nStartTime
	local nSec = GetCurrentTime() - nTime
	local szTime = ""
	if nSec <= 60 then
		return nSec .. _L["sec"]
	elseif nSec < 3600 then	-- X����X��
		return _L("%d min %d sec", nSec / 60, nSec % 60)
	elseif nSec < 86400 then	-- XСʱX����
		return _L("%d hour %d min", nSec / 3600, (nSec % 3600) / 60)
	elseif nSec < 31536000 then	-- X��XСʱ
		return _L("%d day %d hour", nSec / 86400, (nSec % 86400) / 3600)
	else	-- X��X��
		return _L("%d year %d day", nSec / 31536000, (nSec % 31536000) / 86400)
	end
end

-- ������Ե
_JH_Love.SaveLover = function(aInfo, nType, nTime)
	nTime = nTime or GetCurrentTime()
	_JH_Love.SetFellowDataByKey("LOVER", nType .. "#" .. nTime, aInfo.id, true)
	_JH_Love.ToLocalLover(aInfo)
	_JH_Love.nLoveType = nType
	_JH_Love.nStartTime = nTime
	_JH_Love.PS.Refresh()
	JH.Talk(PLAYER_TALK_CHANNEL.TONG, _L("From now on, my heart lover is [%s]", aInfo.name))
end

-- ������Ե
_JH_Love.SetLover = function(dwID, nType)
	if not dwID then
		-- ȡ����Ե
		if _JH_Love.nLoveType == 1 then			-- ˫������������
			JH.Talk(_JH_Love.szName, _L["Sorry, I decided to just a swordman, bye my plugin lover"])
		elseif _JH_Love.nLoveType == 0 then	-- ����ֻ֪ͨ���ߵ�
			local aInfo = _JH_Love.GetFellowDataByID(_JH_Love.dwID)
			if aInfo and aInfo.isonline then
				JH.BgTalk(_JH_Love.szName, "HM_LOVE", "REMOVE0")
			end
		end
		-- �������
		JH.Talk(PLAYER_TALK_CHANNEL.TONG, _L("A blade and cut, no longer meet with [%s]", _JH_Love.szName))
		_JH_Love.SaveFellowRemark(_JH_Love.dwID, "")
		_JH_Love.ToLocalLover(nil)
		_JH_Love.PS.Refresh()
		JH.Sysmsg(_L["Congratulations, do not repeat the same mistakes ah"])
	else
		-- ���ó�Ϊ��Ե�����ߺ��ѣ�
		local aInfo = _JH_Love.GetFellowDataByID(dwID)
		if not aInfo or not aInfo.isonline then
			return JH.Alert(_L["Lover must be a online friend"])
		end
		if nType == 0 then
			-- ������Ե���򵥣�
			_JH_Love.SaveLover(aInfo, nType)
			JH.BgTalk(aInfo.name, "HM_LOVE", "LOVE0")
		else
			-- ˫����Ե�����ߣ����һ�𣬲�����4���ڣ����𷽴���һ�����֮�ģ�
			if not _JH_Love.GetDoubleLoveItem(aInfo) then
				return JH.Alert(_L("Inadequate conditions, requiring Lv6 friend/party/4-feet distance/%s", _i(67291)))
			end
			JH.BgTalk(aInfo.name, "HM_LOVE", "LOVE_ASK")
			JH.Sysmsg(_L("Love request has been sent to [%s], wait please", aInfo.name))
		end
	end
end

-- ɾ����Ե
_JH_Love.RemoveLover = function()
	if _JH_Love.dwID ~= 0 then
		local nTime = GetCurrentTime() - _JH_Love.nStartTime
		if nTime < 3600 then
			return JH.Alert(_L("Love can not run a red-light, [%d] seconds left", 3600 - nTime))
		end
		JH.Confirm(_L("Are you sure to cut love with [%s]?", _JH_Love.szName), function()
			JH.DelayCall(50, function() JH.Confirm(_L["Past five hundred times looking back only in exchange for a chance encounter this life, you really decided?"], function()
				JH.DelayCall(50, function() JH.Confirm(_L["You do not really want to cut off love it, really sure?"], function()
					_JH_Love.SetLover(nil)
				end) end)
			end) end)
		end)
	end
end

-- �޸�˫����Ե
_JH_Love.FixLover = function()
	if _JH_Love.nLoveType ~= 1 then
		return JH.Alert(_L["Repair feature only supports mutual love!"])
	end
	if not JH.IsParty(_JH_Love.dwID) then
		return JH.Alert(_L["Both sides must in a team to be repaired!"])
	end
	JH.BgTalk(_JH_Love.szName, "HM_LOVE", "FIX1", _JH_Love.nStartTime)
	JH.Sysmsg(_L["Repair request has been sent, wait please"])
end

-- ��ȡ����Ե�����б�
_JH_Love.GetLoverMenu = function(nType)
	local me, m0 = GetClientPlayer(), {}
	local aGroup = me.GetFellowshipGroupInfo() or {}
	table.insert(aGroup, 1, {id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND})
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for _, vv in ipairs(aFriend) do
			if vv.attraction >= 200 and (nType ~= 1 or vv.attraction >= 800) then
				table.insert(m0, {
					szOption = vv.name,
					fnDisable = function() return not vv.isonline end,
					fnAction = function()
						JH.Confirm(_L("Do you want to love with [%s]?", vv.name), function()
							_JH_Love.SetLover(vv.id, nType)
						end)
					end
				})
			end
		end
	end
	if #m0 == 0 then
		table.insert(m0, { szOption = _L["<Non-avaiable>"] })
	end
	return m0
end

-- ����ǩ��
_JH_Love.SetSign = function(szSign)
	szSign = JH.Trim(szSign)
	_JH_Love.szSign = szSign
	JH.DelayCall(3000, function()
		if szSign == _JH_Love.szSign then
			local szPart1, szPart2 = "", ""
			if string.len(szSign) > 22 then
				-- �ָ�ȷ��������
				local i = 1
				while i < 21 do
					if string.byte(szSign, i) < 128 then
						i = i + 1
					else
						i = i + 2
					end
				end
				szPart1 = string.sub(szSign, 1, i - 1)
				szPart2 = string.sub(szSign, i)
			else
				szPart1, szPart2 = szSign, " "
			end
			if not _JH_Love.SetFellowDataByKey("S1", szPart1) then
				return JH.Alert(_L["Save signature failed, please add some friends."])
			end
			_JH_Love.SetFellowDataByKey("S2", szPart2)
		end
	end)
end

-- ������Ե�����Ϣ
_JH_Love.UpdatePage = function()
	local p = Station.Lookup("Normal/PlayerView/Page_Main/Page_Love")
	if not p then return end
	local tar = GetPlayer(p:GetParent().dwPlayer)
	if not tar then
		return p:GetRoot():Hide()
	end
	local h, t = p:Lookup("", ""), _JH_Love.tOther
	-- t = {  szName, dwAvatar, szSign, nRoleType, nLoveType, nStartTime }
	h:Lookup("Text_LTitle"):SetText(tar.szName .. _L["'s Lover"])
	-- lover
	local txt = h:Lookup("Text_Lover")
	txt:SetText(t[1] or _L["...Loading..."])
	txt.szPlayer = t[1]
	-- avatar
	local dwAvatar = tonumber(t[2]) or 0
	local img, ani = h:Lookup("Image_Lover"), h:Lookup("Animate_Lover")
	if dwAvatar == 0 then
		img:Hide()
		ani:Hide()
		txt:SetRelPos(42, 92)
		txt:SetSize(300, 25)
		txt:SetHAlign(1)
	else
		local szFile, nFrame, bAnimate = _JH_Love.GetAvatarFile(dwAvatar, tonumber(t[4]) or 1)
		if bAnimate then
			ani:SetAnimate(szFile, nFrame)
			--ani:SetAnimateType(ANIMATE.FLIP_HORIZONTAL)
			ani:Show()
			img:Hide()
			ani.szPlayer = t[1]
		else
			if nFrame < 0 then
				img:FromTextureFile(szFile)
			else
				img:FromUITex(szFile, nFrame)
			end
			if nFrame == -2 then
				img:SetImageType(IMAGE.NORMAL)
			else
				img:SetImageType(IMAGE.FLIP_HORIZONTAL)
			end
			ani:Hide()
			img:Show()
			img.szPlayer = t[1]
		end
		txt:SetRelPos(130, 92)
		txt:SetSize(200, 25)
		txt:SetHAlign(0)
	end
	-- lover info
	local inf = h:Lookup("Text_LoverInfo")
	if t[5] and t[6] and dwAvatar ~= 0 then
		local szText = _JH_Love.GetLoverType(tonumber(t[5]) or 0) .. "   " .. _JH_Love.GetLoverTime(tonumber(t[6]) or 0)
		inf:SetText(szText)
	else
		inf:SetText("")
	end
	-- sign title
	h:Lookup("Text_SignTTL"):SetText(tar.szName .. _L["'s Love signature:"])
	-- sign
	local szSign = t[3]
	if not szSign then
		szSign = _L["If it is always loading, the target may not install plugin or turn on quiet mode, strongly recommend to query after team up."]
	elseif szSign == "" then
		szSign = _L["This guy is very lazy, nothing left!"]
	end
	h:Lookup("Text_Sign"):SetText(szSign)
	-- btn
	local txt = p:Lookup("Btn_LoveYou"):Lookup("", "Text_LoveYou")
	if tar.nGender == 2 then
		txt:SetText(_L["Strike up her"])
	else
		txt:SetText(_L["Strike up him"])
	end
	h:FormatAllItemPos()
end

-- ��̨������˵���Ե����
_JH_Love.AskOtherData = function(dwID)
	local tar = GetPlayer(dwID)
	if not tar then
		return
	end

	_JH_Love.tOther = {}
	_JH_Love.UpdatePage()
	if tar.bFightState and not JH.IsParty(tar.dwID) then
		_JH_Love.bActiveLove = false
		return JH.Sysmsg("[" .. tar.szName .. "] " .. _L[" in fighting, no time for you"])
	end
	JH.BgTalk(tar.szName, "HM_LOVE", "VIEW")

end

-------------------------------------
-- �¼�����
-------------------------------------
-- �������ݸ��£���ʱ�����Ե�仯��ɾ�����Ѹı�ע�ȣ�
_JH_Love.OnFellowUpdate = function()
	-- ������Ե
	local szData, aInfo = _JH_Love.GetFellowDataByKey("LOVER", true)
	if not szData and _JH_Love.dwID ~= 0 then
		_JH_Love.ToLocalLover(nil)
		_JH_Love.PS.Refresh()
	end
	if aInfo and _JH_Love.dwID ~= aInfo.id then
		local data = SplitString(szData, "#")
		_JH_Love.ToLocalLover(aInfo)
		_JH_Love.nLoveType = tonumber(data[1]) or 0
		_JH_Love.nStartTime = tonumber(data[2]) or GetCurrentTime()
		_JH_Love.PS.Refresh()
		-- ������ʾ
		if not _JH_Love.bLoaded and aInfo.isonline then
			local szMsg = _L["Warm tip: Your "] .. _JH_Love.GetLoverType() .. _L("Lover <link0> is happy in [%s].\n", Table_GetMapName(aInfo.mapid))
			_JH_Love.OnLoverMsg(szMsg)
		end
	end
	-- ��һ�μ��أ�ǩ��
	if not _JH_Love.bLoaded then
		local szData, _ = _JH_Love.GetFellowDataByKey("S1")
		if szData then
			_JH_Love.szSign =szData
			local szData, _ = _JH_Love.GetFellowDataByKey("S2")
			if szData then
				_JH_Love.szSign = _JH_Love.szSign .. szData
			end
			_JH_Love.szSign = JH.Trim(_JH_Love.szSign)
		end
		_JH_Love.bLoaded = true
	end
end

-- �鿴����װ������Ե
_JH_Love.OnPeekOtherPlayer = function()
	if arg0 ~= 1 then return end
	local mPage = Station.Lookup("Normal/PlayerView/Page_Main")
	if not mPage then
		return
	end
	-- attach page
	if not mPage.bLoved then
		local frame = Wnd.OpenWindow("interface/JH/Love/Love.ini", "HM_Love")
		local pageset = frame:Lookup("Page_Main")
		local checkbox = pageset:Lookup("CheckBox_Love")
		local page = pageset:Lookup("Page_Love")
		checkbox:ChangeRelation(mPage, true, true)
		page:ChangeRelation(mPage, true, true)
		Wnd.CloseWindow(frame)
		checkbox:SetRelPos(270, 510)
		page:SetRelPos(0, 0)
		mPage:AddPage(page, checkbox)
		checkbox:Show()
		mPage.bLoved = true
		-- events
		mPage.OnActivePage = function()
			PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
			if this:GetActivePage():GetName() == "Page_Love" then
				_JH_Love.AskOtherData(this.dwPlayer)
			end
		end
		page:Lookup("Btn_LoveYou").OnLButtonClick = function()
			local mp = this:GetParent():GetParent()
			local tar = GetPlayer(mp.dwPlayer)
			if tar then
				JH.Talk(tar.szName, JH_Love.szJabber)
			end
		end
		page:Lookup("Btn_LoveYou").OnRButtonClick = function()
			local mp = this:GetParent():GetParent()
			local tar = GetPlayer(mp.dwPlayer)
			if tar then
				local m0, me = {}, GetClientPlayer()
				InsertInviteTeamMenu(m0, tar.szName)
				if me.IsInParty() and me.dwID == GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) then
					InsertMarkMenu(m0, tar.dwID)
				end
				if me.IsInParty() and me.IsPlayerInMyParty(tar.dwID) then
					InsertTeammateLeaderMenu(m0, tar.dwID)
				end
				if #m0 > 0 then
					table.insert(m0, { bDevide = true })
				end
				InsertPlayerCommonMenu(m0, tar.dwID, tar.szName)
				PopupMenu(m0)
			end
		end
		page:Lookup("", "Image_Lover").OnItemRButtonDown = function()
			if this.szPlayer then
				local m0 = {}
				InsertPlayerCommonMenu(m0, 0, this.szPlayer)
				PopupMenu(m0)
			end
		end
		page:Lookup("", "Text_Lover").OnItemRButtonDown = page:Lookup("", "Image_Lover").OnItemRButtonDown
		page:Lookup("", "Animate_Lover").OnItemRButtonDown = page:Lookup("", "Image_Lover").OnItemRButtonDown
		page:Lookup("", "Text_LTitle"):SetText(_L["Lover"])
		page:Lookup("", "Text_SignTTL"):SetText(_L["Love signature:"])
		page:Lookup("", "Text_Lover"):SetFontColor(255, 128, 255)
		checkbox:Lookup("", "Text_LoveCaptical"):SetText(_L["Lover"])
	end
	-- update page
	mPage.dwPlayer = arg1
	-- active page
	if _JH_Love.bActiveLove then
		_JH_Love.bActiveLove = false
		mPage:ActivePage("Page_Love")
	end
end

-- �ظ���Ե��Ϣ
_JH_Love.ReplyLove = function(bCancel)
	local szName, bRoot = _JH_Love.szName, false
	local root = nil
	if _JH_Love.dwID == 0 then
		szName = "<" .. JH_Love.szNone .. ">"
		bRoot = GetClientPlayer().szName == _L["HMM5"]
		if not bRoot then
			root = GetPlayer(_JH_Love.dwRoot)
		end
	elseif bCancel then
		szName = _L["<Not tell you>"]
	end
	for k, v in pairs(_JH_Love.tViewer) do
		if bRoot or root then
			local p = root or GetPlayer(k)
			if p then
				szName = p.szName
				_JH_Love.dwAvatar = p.dwMiniAvatarID
				_JH_Love.nRoleType = p.nRoleType
				_JH_Love.nLoveType = 1
				_JH_Love.nStartTime =  GetCurrentTime() - 1173600
				if p.dwMiniAvatarID == 0 then
					_JH_Love.dwAvatar = 0 - p.dwForceID
				end
			end
		end
		JH.BgTalk(v, "HM_LOVE", szName,
			_JH_Love.dwAvatar, _JH_Love.szSign, _JH_Love.nRoleType,
			_JH_Love.nLoveType, _JH_Love.nStartTime)
	end
	_JH_Love.tViewer = {}
end

-- ��̨ͬ��
_JH_Love.OnBgTalk = function()
	if HM_Love then return end
	local data = JH.BgHear("HM_LOVE")
	if data then
		if data[1] == "VIEW" then
			local dwTarget, szTarget = arg0, arg3
			if JH.IsParty(dwTarget) then
				_JH_Love.tViewer[dwTarget] = szTarget
				_JH_Love.ReplyLove()
			elseif not GetClientPlayer().bFightState and not JH_Love.bQuiet then
				_JH_Love.tViewer[dwTarget] = szTarget
				JH.Confirm(
					"[" .. szTarget .. "] " .. _L["want to see your lover info, OK?"],
					function() _JH_Love.ReplyLove() end,
					function() _JH_Love.ReplyLove(true) end
				)
			end
		elseif data[1] == "LOVE0" or data[1] == "REMOVE0" then
			local i = math.random(1, math.floor(table.getn(_JH_Love.tAutoSay)/2)) * 2
			if data[1] == "LOVE0" then
				i = i - 1
			end
			OutputMessage("MSG_WHISPER", _L["[Mystery] quietly said:"] .. _JH_Love.tAutoSay[i] .. "\n")
			PlaySound(SOUND.UI_SOUND,g_sound.Whisper)
		elseif data[1] == "LOVE_ASK" then
			local szTarget = arg3
			-- ������Եֱ�Ӿܾ�
			if _JH_Love.dwID ~= 0 and (_JH_Love.dwID ~= arg0 or _JH_Love.nLoveType == 1) then
				return JH.BgTalk(szTarget, "HM_LOVE", "LOVE_ANS", "EXISTS")
			end
			-- ѯ�����
			JH.Confirm("[" .. szTarget .. "] " .. _L["want to mutual love with you, OK?"], function()
				JH.BgTalk(szTarget, "HM_LOVE", "LOVE_ANS", "YES")
			end, function()
				JH.BgTalk(szTarget, "HM_LOVE", "LOVE_ANS", "NO")
			end)
		elseif data[1] == "FIX1" then
			if _JH_Love.dwID == 0 or (_JH_Love.dwID == arg0 and _JH_Love.nLoveType ~= 1) then
				local aInfo = _JH_Love.GetFellowDataByID(arg0)
				if aInfo then
					JH.Confirm("[" .. aInfo.name .. "] " .. _L["want to repair love relation with you, OK?"], function()
						_JH_Love.SaveLover(aInfo, 1, tonumber(data[2]))
						JH.Sysmsg(_L("Congratulations, love relation with [%s] has been fixed!", aInfo.name))
					end)
				end
			else
				JH.BgTalk(arg3, "HM_LOVE", "LOVE_ANS", "EXISTS")
			end
		elseif data[1] == "LOVE_ANS" then
			if data[2] == "EXISTS" then
				local szMsg = _L["Unfortunately the other has lover, but you can still blind love him!"]
				JH.Sysmsg(szMsg)
				JH.Alert(szMsg)
			elseif data[2] == "NO" then
				local szMsg = _L["The other refused you without reason, but you can still blind love him!"]
				JH.Sysmsg(szMsg)
				JH.Alert(szMsg)
			elseif data[2] == "YES" then
				local aInfo = _JH_Love.GetFellowDataByID(arg0)
				local dwBox, dwX = _JH_Love.GetDoubleLoveItem(aInfo)
				if dwBox then
					local nNum = _JH_Love.GetBagItemNum(dwBox, dwX)
					SetTarget(TARGET.PLAYER, aInfo.id)
					OnUseItem(dwBox, dwX)
					JH.DelayCall(500, function()
						if _JH_Love.GetBagItemNum(dwBox, dwX) ~= nNum then
							_JH_Love.SaveLover(aInfo, 1)
							JH.BgTalk(aInfo.name, "HM_LOVE", "LOVE_ANS", "CONF")
							JH.Sysmsg(_L("Congratulations, success to attach love with [%s]!", aInfo.name))
						end
					end)
				end
			elseif data[2] == "CONF" then
				local aInfo = _JH_Love.GetFellowDataByID(arg0)
				if aInfo then
					_JH_Love.SaveLover(aInfo, 1)
					JH.Sysmsg(_L("Congratulations, success to attach love with [%s]!", aInfo.name))
				end
			end
		else
			_JH_Love.tOther = data
			_JH_Love.UpdatePage()
		end
	end
end

-- ��Ե��������֪ͨ
_JH_Love.OnLoverMsg = function(szMsg)
	local szChannel = "MSG_SYS"
	local szFont = GetMsgFontString(szChannel)
	szMsg = FormatLinkString(szMsg, szFont, MakeNameLink("[" .. _JH_Love.szName .. "]", szFont))
	OutputMessage(szChannel, szMsg, true)
end

-- ���ߣ�����֪ͨ��bOnLine, szName, bFoe
_JH_Love.OnFriendLogin = function()
	if not  arg2 and arg1 == _JH_Love.szName then
		local szMsg = _L["Warm tip: Your "] .. _JH_Love.GetLoverType() .. _L["Lover <link0>"]
		if arg0 then
			szMsg = szMsg .. _L["online, hurry doing needy doing.\n"]
			OnBowledCharacterHeadLog(GetClientPlayer().dwID, _L["Love Tip: "] .. arg1 .. _L["onlines now"], 199, { 255, 0, 255 })
			PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
		else
			szMsg = szMsg .. _L["offline, hurry doing like doing.\n"]
		end
		_JH_Love.OnLoverMsg(szMsg)
	end
end

-- ��ֹ�޸���Ե���ѱ�ע����ֹ��ʾ��ע
_JH_Love.OnBreathe = function()
	-- social list
	local hL = Station.Lookup("Normal/SocialPanel/PageSet_Company/Page_Friend/WndScroll_Friend", "")
	if hL and hL:IsVisible() then
		for i = 0, hL:GetItemCount() - 1, 1 do
			local hI = hL:Lookup(i)
			if hI.bPlayer and hI.info and hI.info.remark
				and (hI.info.remark == " " or string.sub(hI.info.remark, 1, 4) == "#HM#")
			then
				hI:Lookup("Text_N"):SetText(hI.info.name)
			end
		end
		local input = Station.Lookup("Topmost/GetNamePanel")
		if input and not input.bChecked
			and input:Lookup("", "Text_Msg"):GetText() == g_tStrings.STR_FRIEND_INPUT_MARK
		then
			local edit = input:Lookup("Edit_Input")
			if string.sub(edit:GetText(), 1, 10) == "#HM#LOVER#" then
				edit:Enable(0)
				input:Lookup("Btn_Sure"):Enable(false)
			end
			input.bChecked = true
		end
	end
	-- friendrank
	local hL = Station.Lookup("Normal/FriendRank/Wnd_PRanking", "Handle_RankingMes")

end

-- player enter
_JH_Love.OnPlayerEnter = function()
	if JH_Love.bAutoFocus and arg0 == _JH_Love.dwID then
		if HM_TargetList and HM_TargetList.AddFocus and not IsInArena() then
			HM_TargetList.AddFocus(arg0)
		end
	end
end

-------------------------------------
-- ���ý���
-------------------------------------
_JH_Love.PS = {}

-- refresh
_JH_Love.PS.Refresh = function()
	if _JH_Love.ui then
		JH.OpenPanel(JH_Love.szTitle)
	end
end

-- init
_JH_Love.PS.OnPanelActive = function(frame)
	local ui, nX = GUI(frame), 0
	ui:Append("Text", { txt = _L["Heart lover"], x = 0, y = 0, font = 27 })
	-- lover info
	if _JH_Love.dwID == 0 then
		ui:Append("Text", { txt = _L["No lover :-("], font = 19, x = 10, y = 36 })
		-- create lover
		nX = ui:Append("Text", { txt = _L["Mutual love friend Lv.6: "], x = 10, y = 72 }):Pos_()
		nX = ui:Append("WndComboBox", { txt = _L["- Select plz -"], x = nX + 5, y = 72, w = 200, h = 25 })
		:Menu(function() return _JH_Love.GetLoverMenu(1) end):Pos_()
		ui:Append("Text", { txt = _L("(4-feets, +%s)", _i(67291)), x = nX + 5, y = 72 })
		nX = ui:Append("Text", { txt = _L["Blind love friend Lv.2: "], x = 10, y = 100 }):Pos_()
		nX = ui:Append("WndComboBox", { txt = _L["- Select plz -"], x = nX + 5, y = 100, w = 200, h = 25 })
		:Menu(function() return _JH_Love.GetLoverMenu(0) end):Pos_()
		ui:Append("Text", { txt = _L["(Online required, notify anonymous)"], x = nX + 5, y = 100 })
	else
		-- show lover
		ui:Append("Text", { txt = _JH_Love.szName, font = 19, x = 10, y = 36 })
		:Color(255, 128, 255)
		nX = ui:Append("Text", { txt = _JH_Love.GetLoverType(), font = 2, x = 10, y = 72 }):Pos_()
		nX = ui:Append("Text", { txt = _JH_Love.GetLoverTime(), font = 2, x = nX + 10, y = 72 }):Pos_()
		nX = ui:Append("Text", { txt = _L["[Break love]"], x = nX + 10, y = 72 })
		:Click(_JH_Love.RemoveLover, { 128, 255, 255 }, { 0, 255, 255 }):Pos_()
		if _JH_Love.nLoveType == 1 then
			nX = ui:Append("Text", { txt = _L["[Recovery]"], x = nX + 10, y = 72 }):Click(_JH_Love.FixLover, { 128, 255, 255 }, { 0, 255, 255 }):Pos_()
		end
		ui:Append("WndCheckBox", { txt = _L["Auto focus lover"], x = nX + 10, y = 72, checked = JH_Love.bAutoFocus })
		:Click(function(bChecked)
			JH_Love.bAutoFocus = bChecked
			if not bChecked and _JH_Love.dwID ~=0 and HM_TargetList and HM_TargetList.DelFocus then
				HM_TargetList.DelFocus(_JH_Love.dwID)
			end
		end)
	end
	-- local setting
	nX = ui:Append("Text", { txt = _L["Non-love display: "], x = 10, y = 128 }):Pos_()
	nX = ui:Append("WndEdit", { x = nX + 5, y = 128, limit = 20, w = 198, h = 25, txt = JH_Love.szNone })
	:Change(function(szText) JH_Love.szNone = szText end):Pos_()
	ui:Append("WndCheckBox", { txt = _L["Enable quiet mode"], x = nX + 5, y = 128, checked = JH_Love.bQuiet  })
	:Click(function(bChecked) JH_Love.bQuiet = bChecked end)
	-- jabber
	nX = ui:Append("Text", { txt = _L["Quick to accost text: "], x = 10, y = 156 }):Pos_()
	ui:Append("WndEdit", { x = nX + 5, y = 156, limit = 128, w = 340, h = 25, txt = JH_Love.szJabber })
	:Change(function(szText) JH_Love.szJabber = szText end)
	-- signature
	nX = ui:Append("Text", { txt = _L["Love signature: "], x = 10, y = 192, font = 27 }):Pos_()
	ui:Append("WndEdit", { x = nX + 5, y = 192, limit = 42, w = 340, h = 48, multi = true, txt = _JH_Love.szSign }):Change(_JH_Love.SetSign)
	-- tips
	ui:Append("Text", { txt = _L["Tips"], x = 0, y = 228, font = 27 })
	ui:Append("Text", { txt = _L["1. Amuse only, both sides need to install this plug-in"], x = 10, y = 253 })
	ui:Append("Text", { txt = _L["2. You can break love one-sided"], x = 10, y = 278 })
	ui:Append("Text", { txt = _L["3. Non-party views need to confirm (enable quiet to avoid)"], x = 10, y = 303 })
	_JH_Love.ui = ui
end

-- deinit
_JH_Love.PS.OnPanelDeactive = function()
	_JH_Love.ui = nil
end

---------------------------------------------------------------------
-- ע���¼�����ʼ��
---------------------------------------------------------------------
if not HM_Love then
	JH.RegisterEvent("ON_BG_CHANNEL_MSG", _JH_Love.OnBgTalk)
	JH.RegisterEvent("PEEK_OTHER_PLAYER", _JH_Love.OnPeekOtherPlayer)
	JH.RegisterEvent("PLAYER_FELLOWSHIP_LOGIN", _JH_Love.OnFriendLogin)

	JH.RegisterEvent("PLAYER_ENTER_SCENE", _JH_Love.OnPlayerEnter)
	JH.BreatheCall("JH_Love", _JH_Love.OnBreathe)
end
JH.RegisterEvent("PLAYER_FELLOWSHIP_UPDATE", _JH_Love.OnFellowUpdate)
GUI.RegisterPanel(JH_Love.szTitle, 329, _L["Recreation"], _JH_Love.PS)

-- view other lover by dwID
function JH_Love.PeekOther(dwID)
	ViewInviteToPlayer(dwID)
	_JH_Love.bActiveLove = true
	if not JH.IsParty(dwID) then
		_JH_Love.AskOtherData(dwID)
	end
end

if not HM_Love then
Target_AppendAddonMenu({ function(dwID)
	return {{
		szOption = _L["View love info"],
		fnDisable = function() return dwID == GetClientPlayer().dwID or not IsPlayer(dwID) end,
		fnAction = function() JH_Love.PeekOther(dwID) end
	}}
end })
end
