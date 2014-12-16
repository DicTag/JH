-- ----------------------------------------------------------------------------------------------------------
-- Title:	�Ŷ���ǿ
-- Date:	2010.06.22
-- Author:	Danexx
-- Comment:	�ҿ����ܶ��Ļ�����л��
--			�ɹ��ܶ��������߿�ɬ�Ĺ�ʵ��
--			�����ܶ�����ĺþƣ�
--			ȴֻ������һ���ܾ��׹������ˡ��� 
-- ----------------------------------------------------------------------------------------------------------
RaidGridEx = RaidGridEx or {}
RaidGridEx.tGroupList = {}			-- ����ʵ��С�������򱣴浱ǰ�Ŷ�λ��
RaidGridEx.tForceList = {}			-- �������ɷ��ౣ�������Ŷ�λ��
RaidGridEx.tCustomList = {}			-- �Զ����Ŷ�λ��
RaidGridEx.tRoleIDList = {}			-- ���Ŷ��еĽ�ɫID�ܱ�

RaidGridEx.nMaxCol = 5
RaidGridEx.nMaxRow = 5

local szIniFile = "Interface/JH/RaidGridEx/RaidGridEx.ini"
-- ----------------------------------------------------------------------------------------------------------
-- ������صĿ��ƺʹ���
-- ----------------------------------------------------------------------------------------------------------
-- �������п��ܵĸ���, һ���ڳ�ʼ����ʱ�����
function RaidGridEx.CreateAllRoleHandle()
	RaidGridEx.handleRoles:Clear()
	for nCol = 0, RaidGridEx.nMaxCol -1 do
		for nRow = 1, RaidGridEx.nMaxRow  do
			local handleRole = RaidGridEx.handleRoles:AppendItemFromIni(szIniFile, "Handle_RoleDummy", "Handle_Role_" .. nCol .. "_" .. nRow)
			handleRole:SetRelPos((nCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound)* RaidGridEx.fScale, ((nRow - 1) * RaidGridEx.nRowLength + RaidGridEx.nBottomBound)* RaidGridEx.fScale)
			handleRole:Show()
			handleRole.nGroupIndex = nCol
			handleRole.nSortIndex = nRow
			handleRole.dwMemberID = nil
			RaidGridEx.HideRoleHandle(nCol, nRow)
			handleRole:Scale(RaidGridEx.fScale, RaidGridEx.fScale)
		end
	end
	RaidGridEx.handleRoles:FormatAllItemPos()
end

-- ��ʾһ������
function RaidGridEx.ShowRoleHandle(nCol, nRow, handleRole)
	local handleRole = handleRole or RaidGridEx.handleRoles:Lookup("Handle_Role_" .. tostring(nCol) .. "_" .. tostring(nRow))
	if not handleRole then
		return
	end
	handleRole:Show()
	handleRole:SetAlpha(255)	
	--handleRole:Lookup("Animate_SelectRole"):Hide()
	handleRole:Lookup("Text_Name"):SetText("")
	handleRole:Lookup("Image_LifeBG"):Show()
	handleRole:Lookup("Image_LifeBG"):SetAlpha(48)
	handleRole:Lookup("Image_BGBox_White"):Show()
	handleRole:Lookup("Image_BGBox_White"):SetAlpha(16)
	RaidGridEx.HideAllLifeBar(handleRole)
	handleRole:Lookup("Text_LifeValue"):SetText("")
	handleRole:Lookup("Image_ManaBG"):Show()
	handleRole:Lookup("Image_ManaBG"):SetAlpha(64)
	handleRole:Lookup("Image_Mana"):Show()
	RaidGridEx.HideAllManaBar(handleRole)
	handleRole:Lookup("Image_Leader"):Hide()
	handleRole:Lookup("Image_Looter"):Hide()
	handleRole:Lookup("Image_Mark"):Hide()
	handleRole:Lookup("Image_MarkImage"):Hide()
	handleRole:Lookup("Image_Matrix"):Hide()
end

-- ����һ������
function RaidGridEx.HideRoleHandle(nCol, nRow, handleRole)
	local handleRole = handleRole or RaidGridEx.handleRoles:Lookup("Handle_Role_" .. nCol .. "_" .. nRow)
	if not handleRole then
		return
	end
	handleRole:Show()
	handleRole:SetAlpha(32)	
	--handleRole:Lookup("Animate_SelectRole"):Hide()
	handleRole:Lookup("Text_Name"):SetText("")
	handleRole:Lookup("Image_LifeBG"):Hide()
	handleRole:Lookup("Image_BGBox_White"):Show()
	handleRole:Lookup("Image_BGBox_White"):SetAlpha(8)
	RaidGridEx.HideAllLifeBar(handleRole)
	handleRole:Lookup("Text_LifeValue"):SetText("")
	handleRole:Lookup("Image_ManaBG"):Hide()
	handleRole:Lookup("Image_Mana"):Hide()
	RaidGridEx.HideAllManaBar(handleRole)
	handleRole:Lookup("Image_Leader"):Hide()
	handleRole:Lookup("Image_Looter"):Hide()
	handleRole:Lookup("Image_Mark"):Hide()
	handleRole:Lookup("Image_MarkImage"):Hide()
	handleRole:Lookup("Image_Matrix"):Hide()
end

-- ����ƶ�������
function RaidGridEx.EnterRoleHandle(nCol, nRow, handleRole)
	handleRole = handleRole or RaidGridEx.handleRoles:Lookup("Handle_Role_" .. nCol .. "_" .. nRow)
	if not handleRole then
		return
	end
	nCol = nCol or handleRole.nGroupIndex
	nRow = nRow or handleRole.nSortIndex
	
	if handleRole:GetAlpha() == 32 then
		handleRole:SetAlpha(128)
	elseif handleRole:GetAlpha() == 255 then
		handleRole:Lookup("Animate_SelectRole"):Show()
		local dwMemberID = RaidGridEx.tGroupList[nCol]
		if dwMemberID then
			dwMemberID = RaidGridEx.tGroupList[nCol][nRow]
		end
		if not dwMemberID then
			return
		end
		local tMemberInfo = RaidGridEx.GetTeamMemberInfo(dwMemberID)
		if not tMemberInfo then
			return
		end		
		local nLifeValue = tMemberInfo.nCurrentLife
		local nLifePercentage = tMemberInfo.nCurrentLife / tMemberInfo.nMaxLife
		
		if IsCtrlKeyDown() then
			nLifeValue = math.floor((nLifeValue / tMemberInfo.nMaxLife) * 100) .. "%"
		end
		local textLifeValue = handleRole:Lookup("Text_LifeValue")
		--�ڷ�Ѫ������ģʽ��,Ҫ��ʾ��ֵ����ȷ��Ŀ����������
		if textLifeValue and not RaidGridEx.bShowLifeValue and tMemberInfo.bIsOnLine and not tMemberInfo.bDeathFlag then
			textLifeValue:SetText(nLifeValue)
			textLifeValue:SetFontScale(RaidGridEx.fontScale)
			if nLifePercentage < 0.3 then
				textLifeValue:SetFontColor(255,96,96)
			elseif nLifePercentage <0.7 then
				textLifeValue:SetFontColor(255,192,64)
			else
				textLifeValue:SetFontColor(255,128,128)
			end
			textLifeValue:Show()
		end		
		local nX, nY = RaidGridEx.frameSelf:GetAbsPos()
		local nW, nH = RaidGridEx.frameSelf:GetSize()
		OutputTeamMemberTip(dwMemberID, {nX, nY, nW, nH})
	end
end

-- ����뿪����
function RaidGridEx.LeaveRoleHandle(nCol, nRow, handleRole)
	local handleRole = handleRole or RaidGridEx.handleRoles:Lookup("Handle_Role_" .. nCol .. "_" .. nRow)
	if not handleRole then
		return
	end
	nCol = nCol or handleRole.nGroupIndex
	nRow = nCol or handleRole.nSortIndex
	
	if handleRole:GetAlpha() == 128 then
		RaidGridEx.HideRoleHandle(nCol, nRow, handleRole)
	elseif handleRole:GetAlpha() == 255 then
		if RaidGridEx.handleLastSelect ~= handleRole then
			handleRole:Lookup("Animate_SelectRole"):Hide()
			RaidGridEx.handleLastSelect = nil
		end
		local textLifeValue = handleRole:Lookup("Text_LifeValue")
		--�����ڷ�Ѫ������ģʽ��,ȷ��������ּȲ�������Ҳ�������˲�������ֲ������ı��ؼ�,����Ӳ�����
		if textLifeValue and not RaidGridEx.bShowLifeValue and textLifeValue:GetText() ~= "����" and textLifeValue:GetText() ~= "����" then
			textLifeValue:SetText("")
			textLifeValue:SetFontScale(RaidGridEx.fontScale)
			textLifeValue:SetFontColor(255,255,255)
			textLifeValue:Hide()
		end
		HideTip()
	end
end

-- ͨ����ɫ ID ������ ID �Ľ�ɫ���Ŷ��е�λ��
function RaidGridEx.GetHandlePosByID(dwMemberID)
	for nCol = 0, RaidGridEx.nMaxCol -1 do
		for nRow = 1, RaidGridEx.nMaxRow  do
			if RaidGridEx.tGroupList and RaidGridEx.tGroupList[nCol] and RaidGridEx.tGroupList[nCol][nRow] == dwMemberID then
				return nCol, nRow
			end
		end
	end
end

-- ͨ����ɫ ID �������ж�Ӧ�ؼ�������
function RaidGridEx.GetHandleNameByID(dwMemberID)
	local nCol, nRow = RaidGridEx.GetHandlePosByID(dwMemberID)
	if nCol and nRow then
		return "Handle_Role_" .. nCol .. "_" .. nRow
	end
end

-- ͨ����ɫ ID �������ж�Ӧ�ؼ�
function RaidGridEx.GetRoleHandleByID(dwMemberID)
	local szName = RaidGridEx.GetHandleNameByID(dwMemberID)
	if szName then
		local handleRole = RaidGridEx.handleRoles:Lookup(szName)
		return handleRole
	end
end

-- ���»����ض���ɫ��Ѫ��������
function RaidGridEx.RedrawMemberHandleHPnMP(dwMemberID)
	local handleRole = RaidGridEx.GetRoleHandleByID(dwMemberID)
	local tMemberInfo = RaidGridEx.GetTeamMemberInfo(dwMemberID)

	if not handleRole or not tMemberInfo then
		return
	end
	handleRole:Show()
	
	-- Ѫ����ʾ�����߱��
	RaidGridEx.HideAllLifeBar(handleRole)
	local textLifeValue = handleRole:Lookup("Text_LifeValue")
	if tMemberInfo.bIsOnLine then
		local nMaxLife = tMemberInfo.nMaxLife
		if nMaxLife == 0 then nMaxLife = 1 end
		local nLifePercentage = tMemberInfo.nCurrentLife / nMaxLife
		if RaidGridEx.bAutoDistColor then
			handleRole.imageLifeF = handleRole.imageLifeF or handleRole:Lookup("Image_Life_Green")
		else
			if nLifePercentage <= 0.3 then
				handleRole.imageLifeF = handleRole:Lookup("Image_Life_Red")
			elseif nLifePercentage <= 0.6 then
				handleRole.imageLifeF = handleRole:Lookup("Image_Life_Orange")
			else
				handleRole.imageLifeF = handleRole:Lookup("Image_Life_Green")
			end
		end
		if nLifePercentage < 0 or nLifePercentage > 1 then
			nLifePercentage = 1
		end
		handleRole.imageLifeF:Show()
		handleRole.imageLifeF:SetPercentage(nLifePercentage)
		handleRole.imageLifeF:SetAlpha(230)
		-- ������,����ӱ��
		if tMemberInfo.bDeathFlag then
			textLifeValue:SetText("����")
			textLifeValue:SetFontScale(RaidGridEx.fontScale)
			textLifeValue:SetFontColor(255,0,0)
			textLifeValue:Show()
		else
			--�ڷ�Ѫ������ģʽ��,��Ŀ�������������ȴ����������������ֲ������ı��ؼ�
			if not RaidGridEx.bShowLifeValue and textLifeValue:GetText() == "����" then
				textLifeValue:SetText("")
				textLifeValue:SetFontScale(RaidGridEx.fontScale)
				textLifeValue:SetFontColor(255,255,255)
				textLifeValue:Hide()
			end
			--��Ѫ������ģʽ��,ֻ�е�������Ѫ��ʾ״̬����ѪΪ0ʱ,�����Ѫ������
			if tMemberInfo.nCurrentLife and RaidGridEx.bShowLifeValue then
				local nLifeValue = tMemberInfo.nCurrentLife
				local nCostLife = tMemberInfo.nMaxLife - tMemberInfo.nCurrentLife
				local nCostLife2 = nCostLife
				if RaidGridEx.bLifePercent then
					nLifeValue = math.ceil((tMemberInfo.nCurrentLife / tMemberInfo.nMaxLife) * 100) .. "%"
					nCostLife2 = math.ceil((nCostLife / tMemberInfo.nMaxLife) * 100) .. "%"
				elseif RaidGridEx.bLifeSimplify then
					if nLifeValue > 9999 then
						nLifeValue = string.format("%.1f",nLifeValue / 10000) .. "w"
					end
					if nCostLife > 9999 then
						nCostLife2 = string.format("%.1f",nCostLife / 10000) .. "w"
					end
				end
				
				if RaidGridEx.bShowLastLife then
					textLifeValue:SetText(nLifeValue)
					textLifeValue:SetFontScale(RaidGridEx.fontScale)
					textLifeValue:SetFontColor(255,255,255)
					textLifeValue:Show()
				else			
					if nCostLife > 0 then
						textLifeValue:SetText("-"..nCostLife2)
						textLifeValue:SetFontScale(RaidGridEx.fontScale)
						if nLifePercentage < 0.3 then
							textLifeValue:SetFontColor(255,96,96)
						elseif nLifePercentage <0.7 then
							textLifeValue:SetFontColor(255,192,64)
						else
							textLifeValue:SetFontColor(255,128,128)
						end
						textLifeValue:Show()
					else
						textLifeValue:SetText("")
						textLifeValue:SetFontScale(RaidGridEx.fontScale)
						textLifeValue:SetFontColor(255,255,255)
						textLifeValue:Hide()
					end
				end
			end
		end
	else
		textLifeValue:SetText("����")
		textLifeValue:SetFontScale(RaidGridEx.fontScale)
		textLifeValue:SetFontColor(96,96,96)
		textLifeValue:Show()
	end
	
	-- ������ʾ
	RaidGridEx.HideAllManaBar(handleRole)
	local playerMember = GetPlayer(dwMemberID)
	local imageMana = handleRole:Lookup("Image_Mana")
	if playerMember and (tMemberInfo.dwMountKungfuID == 10144 or tMemberInfo.dwMountKungfuID == 10145)  and playerMember.nCurrentRage > 0 then
		local nCurrentRage = playerMember.nCurrentRage
		local nMaxRage = playerMember.nMaxRage
		if nMaxRage == 0 then nMaxRage = 1 end
		local nRagePercentage = nCurrentRage / nMaxRage
		if nRagePercentage < 0 or nRagePercentage > 1 then
			nRagePercentage = 1
		end
		imageMana = handleRole:Lookup("Image_CJRage")
		imageMana:SetPercentage(nRagePercentage)
	elseif playerMember and (tMemberInfo.dwMountKungfuID == 10224 or tMemberInfo.dwMountKungfuID == 10225) and playerMember.nCurrentEnergy > 0 then
		local nCurrentEnergy = playerMember.nCurrentEnergy
		local nMaxEnergy = playerMember.nMaxEnergy
		if nMaxEnergy == 0 then nMaxEnergy = 1 end
		local nEnergyPercentage = nCurrentEnergy / nMaxEnergy
		if nEnergyPercentage < 0 or nEnergyPercentage > 1 then
			nEnergyPercentage = 1
		end
		
		imageMana = handleRole:Lookup("Image_TMRage")
		imageMana:SetPercentage(nEnergyPercentage)
	else
		local nMaxMana = tMemberInfo.nMaxMana
		if nMaxMana == 0 then nMaxMana = 1 end
		local nPercentage = tMemberInfo.nCurrentMana / nMaxMana
		if nPercentage < 0 or nPercentage > 1 then
			nPercentage = 1
		end
		imageMana:SetPercentage(nPercentage)
	end
	if tMemberInfo.bIsOnLine then
		imageMana:Show()
	else
		imageMana:Hide()
	end
end

-- ���»��ƶ��ѱ��ͼ��
local tMarkerImageList = {66, 67, 73, 74, 75, 76, 77, 78, 81, 82}
function RaidGridEx.UpdateMarkImage(dwMemberID)
	local team = GetClientTeam()
	local tPartyMark = team.GetTeamMark()
	if not tPartyMark then
		return
	end	
	local handleRole = RaidGridEx.GetRoleHandleByID(dwMemberID)
	if handleRole then
		local nMarkImageIndex = tPartyMark[dwMemberID]
		if nMarkImageIndex and tMarkerImageList[nMarkImageIndex] and RaidGridEx.bShowMark then
			local imageMark = handleRole:Lookup("Image_MarkImage")
			imageMark:SetFrame(tMarkerImageList[nMarkImageIndex])
			imageMark:Show()
			imageMark:SetAlpha(255)
			imageMark.nFlashDegSpeed = -1
		else
			local imageMark = handleRole:Lookup("Image_MarkImage")
			imageMark:Hide()
		end
	end
end

-- ���»����ض���ɫ��״̬ͼ��, ������, �ӳ���
function RaidGridEx.RedrawMemberHandleState(dwMemberID)
	local handleRole = RaidGridEx.GetRoleHandleByID(dwMemberID)
	local tMemberInfo = RaidGridEx.GetTeamMemberInfo(dwMemberID)
	if not handleRole or not tMemberInfo then
		return
	end
	handleRole:Show()
	
	-- �ӳ�
	local imageLeader = handleRole:Lookup("Image_Leader")
	if RaidGridEx.IsLeader(dwMemberID) then
		imageLeader:Show()
	else
		imageLeader:Hide()
	end
	
	-- ������
	local imageLooter = handleRole:Lookup("Image_Looter")
	if RaidGridEx.IsLooter(dwMemberID) then
		imageLooter:Show()
	else
		imageLooter:Hide()
	end
	
	-- �����
	local imageMark = handleRole:Lookup("Image_Mark")
	if RaidGridEx.IsMarker(dwMemberID) then
		imageMark:Show()
	else
		imageMark:Hide()
	end
	
	-- ���� 
	local imageMatrix = handleRole:Lookup("Image_Matrix")
	if RaidGridEx.IsMatrixcore(dwMemberID) then
		imageMatrix:Show()
	else
		imageMatrix:Hide()
	end
	
	-- ���ѱ��
	RaidGridEx.UpdateMarkImage(dwMemberID)
end

-- �����������½�ɫ��BUFF״̬, �� BUFF���� ��
function RaidGridEx.UpdateMemberBuff(dwMemberID)
	local handleRole = RaidGridEx.GetRoleHandleByID(dwMemberID)
	local hPlayer = GetPlayer(dwMemberID)
	if not hPlayer or handleRole:GetAlpha() == 32 then
		return
	end
	
	if not handleRole.tBoxes then	
		local handleDebuffs = handleRole:Lookup("Handle_Debuffs")
		if not handleDebuffs then
			return
		end
		local tBoxes = {}
		for i = 1, 4, 1 do
			local box = handleDebuffs:Lookup("Box_" .. i)
			if box then
				box:Hide()
				box:SetAlpha(RaidGridEx.nBuffFlashAlpha)
				box:SetObject(1,0)
				box:ClearObjectIcon()
			
				box.szName = nil
				box.nIconID = -1
				box.bShow = false
				box.nEndFrame = 0
				box.nRate = 9999
				box.szColor = nil
				box.nAlpha = RaidGridEx.nBuffFlashAlpha
				box.nTrend = 1
				tBoxes[i] = box
			end
		end
		handleRole.tBoxes = tBoxes
	end
	
	local nBoxAlpha = RaidGridEx.nBuffFlashAlpha
	local bFlash = false
	if not RaidGridEx.bAutoBUFFColor then
		nBoxAlpha = 0
	elseif RaidGridEx.nBuffFlashTime == 0 then
		nBoxAlpha = RaidGridEx.nBuffFlashAlpha
	else
		bFlash = true
	end
	
	for i = 1, 4 do
		if handleRole.tBoxes[i].bShow then
			if bFlash then
				nBoxAlpha = handleRole.tBoxes[i].nAlpha
				local nTrend = handleRole.tBoxes[i].nTrend
				if nBoxAlpha <= 70 then
					nBoxAlpha = nBoxAlpha + (RaidGridEx.nBuffFlashTime * nTrend) / 15
				elseif nBoxAlpha <= (70 + (RaidGridEx.nBuffFlashAlpha - 70) / 2) then
					nBoxAlpha = nBoxAlpha + (RaidGridEx.nBuffFlashTime * nTrend) / 2
				elseif nBoxAlpha >= (RaidGridEx.nBuffFlashAlpha - 10) then
					nBoxAlpha = nBoxAlpha + (RaidGridEx.nBuffFlashTime * nTrend) / 10
				else
					nBoxAlpha = nBoxAlpha + (RaidGridEx.nBuffFlashTime * nTrend)
				end
				if nBoxAlpha >= RaidGridEx.nBuffFlashAlpha then
					nBoxAlpha = RaidGridEx.nBuffFlashAlpha
					nTrend = nTrend * -1
				elseif nBoxAlpha <= 50 then
					nBoxAlpha = 50
					nTrend = nTrend * -1
				end
				handleRole.tBoxes[i].nAlpha = nBoxAlpha
				handleRole.tBoxes[i].nTrend = nTrend
			end
		
			handleRole.tBoxes[i]:Show()
			handleRole.tBoxes[i]:SetAlpha(nBoxAlpha)
			if nBoxAlpha == RaidGridEx.nBuffFlashAlpha then
				handleRole.tBoxes[i]:SetObjectStaring(true)
			end
			
			-- ������ʱ��
			if handleRole.tBoxes[i].nEndFrame then
				local nLogic = GetLogicFrameCount()
				if nLogic > ((handleRole.tBoxes[i].nEndFrame) or 0) then
					handleRole.tBoxes[i].szName = nil
					handleRole.tBoxes[i].nIconID = -1
					handleRole.tBoxes[i].bShow = false
					handleRole.tBoxes[i].nEndFrame = 0
					handleRole.tBoxes[i].nRate = 9999
					handleRole.tBoxes[i].szColor = nil
					handleRole.tBoxes[i].nAlpha = RaidGridEx.nBuffFlashAlpha
					handleRole.tBoxes[i].nTrend = 1
					handleRole.tBoxes[i]:ClearObjectIcon()
					handleRole.tBoxes[i]:Hide()
				end
			end
		else
			handleRole.tBoxes[i]:Hide()
		end
	end
	
	local shadow = handleRole:Lookup("Shadow_Color")
	if shadow then
		shadow:SetAlpha(RaidGridEx.nBuffCoverAlpha)
		local nEndFrame = shadow.nEndFrame or 0
		local nLogic = GetLogicFrameCount()
		if nLogic > nEndFrame then
			shadow.nEndFrame = 0
			shadow.nRate = 9999
			shadow:Hide()
		end
	end
end

-- �����������½�ɫ��һЩ������ʾ, �� ������ӵ�, ������ֵ�
function RaidGridEx.UpdateMemberSpecialState(dwMemberID)
	local handleRole = RaidGridEx.GetRoleHandleByID(dwMemberID)
	local tMemberInfo = RaidGridEx.GetTeamMemberInfo(dwMemberID)
	if not handleRole or not tMemberInfo then
		return
	end
	handleRole:Show()
	
	-- ������ʾ, ��ɫ��ʾ
	local KungfuInfo = RaidGridEx.GetKungfuByID(dwMemberID)
	local textName = handleRole:Lookup("Text_Name")
	local textKungfu = handleRole:Lookup("Text_Kungfu")
	local imageKungfu = handleRole:Lookup("Image_Kungfu")
	local szName = tMemberInfo.szName
	local NameLimit = ((RaidGridEx.fScale/0.2)-4)*2 +4
	
		local tcamp = {
		["ALL"] = -1;
		["NEUTRAL"] = 0;
		["GOOD"] = 1;--CAMP.GOOD
		["EVIL"] = 2;
	}

	textName:SetFontScheme(RaidGridEx.szFontScheme)
	
	--�����ɫ�����Զ��������������Ʊ���ʹ��ż�������������ģ�
	if NameLimit > 12 then
		NameLimit = 12
	end	
	if RaidGridEx.szFontScheme == 23 then
		NameLimit = NameLimit - 2
	end
	
	--����������ɫ
	local nRed, nGreen, nBlue = RaidGridEx.GetCharacterColor(dwMemberID, tMemberInfo.dwForceID)
	if tMemberInfo.bDeathFlag then
		nRed, nGreen, nBlue = 255, 0, 0
	elseif not tMemberInfo.bIsOnLine then
		nRed, nGreen, nBlue = 128, 128, 128
	else
		if RaidGridEx.bShowNameColorByCondition == 2 and KungfuInfo then
			nRed, nGreen, nBlue = KungfuInfo[2],KungfuInfo[3],KungfuInfo[4]
		elseif RaidGridEx.bShowNameColorByCondition == 3 then
			if not tMemberInfo.nCamp or tMemberInfo.nCamp == 0 then
				nRed, nGreen, nBlue = 128,255,128
			elseif tMemberInfo.nCamp == tcamp.GOOD or tMemberInfo.nCamp == 1 then
				nRed, nGreen, nBlue = 64,64,255
			elseif tMemberInfo.nCamp == tcamp.EVIL or tMemberInfo.nCamp == 2 then
				nRed, nGreen, nBlue = 255,64,64
			end
		end
	end	
	
	-- if #szName <= NameLimit then
		-- textName:SetFontSpacing(-1)
		textName:SetText(tMemberInfo.szName)
	-- else
		-- textName:SetFontSpacing(-3)
		-- textName:SetText(tMemberInfo.szName:sub(1, NameLimit) .. "��")
	-- end
	
	textName:SetFontColor(nRed, nGreen, nBlue)
	
	if KungfuInfo and RaidGridEx.bShowKungfu then
		if RaidGridEx.bShowKungfuIcon then
			local nIconID = Table_GetSkillIconID(KungfuInfo[5], 0)
			if nIconID and KungfuInfo[5] ~= 10000 then
				textKungfu:Hide()
				imageKungfu:FromIconID(nIconID)
				imageKungfu:Show()
			else
				imageKungfu:Hide()
			end
		else
			imageKungfu:Hide()
			textKungfu:SetText(KungfuInfo[1])
			textKungfu:SetFontColor(KungfuInfo[2],KungfuInfo[3],KungfuInfo[4])
			textKungfu:Show()
		end
	else
		imageKungfu:Hide()
		textKungfu:Hide()
	end
	
	if RaidGridEx.bFightNameAlpha and GetClientPlayer().bFightState then
		imageKungfu:SetAlpha(192)
		textName:SetAlpha(192)
		textKungfu:SetAlpha(192)
	else
		imageKungfu:SetAlpha(240)
		textName:SetAlpha(240)
		textKungfu:SetAlpha(240)
	end
	
	-- ���봦�����ɫ
	local objPlayer = GetPlayer(dwMemberID)
	if RaidGridEx.bAutoDistColor then			-- ����ģʽ
		if not tMemberInfo.bIsOnLine then		-- ������
			handleRole.imageLifeF = handleRole:Lookup("Image_Life_White")
		elseif objPlayer then					-- ͬ����Χ��
			local player = GetClientPlayer()
			if player then
				local nDist2d = math.floor(((objPlayer.nX - player.nX) ^ 2 + (objPlayer.nY - player.nY) ^ 2) ^ 0.5)
				local nDistM = nDist2d / 64
				if nDistM <= RaidGridEx.nDis1 then			-- 8������
					handleRole.imageLifeF = handleRole:Lookup("Image_Life_" .. RaidGridEx.szDistColor_8)
				elseif nDistM <= RaidGridEx.nDis2 then		-- 20������
					handleRole.imageLifeF = handleRole:Lookup("Image_Life_" .. RaidGridEx.szDistColor_20)
				elseif nDistM <= RaidGridEx.nDis3 then		-- 24������
					handleRole.imageLifeF = handleRole:Lookup("Image_Life_" .. RaidGridEx.szDistColor_24)
				else							-- 24��֮��
					handleRole.imageLifeF = handleRole:Lookup("Image_Life_" .. RaidGridEx.szDistColor_999)
				end				
			end
			RaidGridEx.RedrawMemberHandleHPnMP(dwMemberID)
		else									-- ͬ����Χ��
			handleRole.imageLifeF = handleRole:Lookup("Image_Life_" .. RaidGridEx.szDistColor_0)
			RaidGridEx.RedrawMemberHandleHPnMP(dwMemberID)
		end
	end
end

-- �������е�Ѫ����ɫ
function RaidGridEx.HideAllLifeBar(handleRole)
	handleRole:Lookup("Image_Life_White"):Hide()
	handleRole:Lookup("Image_Life_Red"):Hide()
	handleRole:Lookup("Image_Life_Orange"):Hide()
	handleRole:Lookup("Image_Life_Blue"):Hide()
	handleRole:Lookup("Image_Life_Green"):Hide()
end

function RaidGridEx.HideAllManaBar(handleRole)
	handleRole:Lookup("Image_Mana"):Hide()
	handleRole:Lookup("Image_CJRage"):Hide()
	handleRole:Lookup("Image_TMRage"):Hide()
end



-- �Զ���С�Ŷӽ���, bFullMode ��ʾģʽ
function RaidGridEx.AutoScalePanel()
	if not RaidGridEx.bAutoScalePanel or RaidGridEx.bDrag then
		for nCol = 0, RaidGridEx.nMaxCol -1 do
			for nRow = 1, RaidGridEx.nMaxRow do
				local handleRole = RaidGridEx.handleRoles:Lookup("Handle_Role_" .. nCol .. "_" .. nRow)
				handleRole:SetRelPos((nCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, ((nRow - 1) * RaidGridEx.nRowLength + RaidGridEx.nBottomBound)*RaidGridEx.fScale)
				handleRole:Show()
			end
		end
		-- �������ͳߴ�
		RaidGridEx.handleBG:Lookup("Image_Title_BG"):SetSize((RaidGridEx.nMaxCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, RaidGridEx.nTitleHeight)
		RaidGridEx.handleBG:Lookup("Image_BG"):SetSize((RaidGridEx.nMaxCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, (RaidGridEx.nMaxRow * RaidGridEx.nRowLength + RaidGridEx.nBottomBound) * RaidGridEx.fScale)
		RaidGridEx.frameSelf:SetSize((RaidGridEx.nMaxCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, (RaidGridEx.nMaxRow * RaidGridEx.nRowLength + RaidGridEx.nTopBound + RaidGridEx.nBottomBound) * RaidGridEx.fScale)	
		RaidGridEx.frameSelf:SetDragArea(0, 0, (RaidGridEx.nMaxCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, 25)
	else
		local nMaxRow = 0
		local nMaxCol = 0
		local nOffsetDepth = 0
		for nCol = 0, RaidGridEx.nMaxCol -1 do
			local bEmptyGroup = true
			for nRow = 1, RaidGridEx.nMaxRow do
				local handleRole = RaidGridEx.handleRoles:Lookup("Handle_Role_" .. nCol .. "_" .. nRow)
				handleRole:SetRelPos(((nCol + nOffsetDepth) * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, ((nRow - 1) * RaidGridEx.nRowLength + RaidGridEx.nBottomBound) * RaidGridEx.fScale)
				
				if handleRole:GetAlpha() == 32 then				-- �ո���
					handleRole:Hide()
				else
					nMaxRow = math.max(nMaxRow, nRow)
					bEmptyGroup = false
				end
			end
			if bEmptyGroup then
				nOffsetDepth = nOffsetDepth - 1
			else
				nMaxCol = nMaxCol + 1
			end
		end
		-- �������ͳߴ�
		nMaxRow = math.max(nMaxRow, 1)
		nMaxCol = math.max(nMaxCol, 2)
		RaidGridEx.handleBG:Lookup("Image_Title_BG"):SetSize((nMaxCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, RaidGridEx.nTitleHeight)
		RaidGridEx.handleBG:Lookup("Image_BG"):SetSize((nMaxCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, (nMaxRow * RaidGridEx.nRowLength + RaidGridEx.nBottomBound) * RaidGridEx.fScale)
		RaidGridEx.frameSelf:SetSize((nMaxCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, (nMaxRow * RaidGridEx.nRowLength + RaidGridEx.nTopBound + RaidGridEx.nBottomBound) * RaidGridEx.fScale)
		RaidGridEx.frameSelf:SetDragArea(0, 0, (nMaxCol * RaidGridEx.nColLength + RaidGridEx.nLeftBound) * RaidGridEx.fScale, 25)
	end
	
	RaidGridEx.handleRoles:FormatAllItemPos()
end

-- ----------------------------------------------------------------------------------------------------------
-- ���ػ������ݳ�ʼ���Լ�����: ���������ŶӸ����¼������±��ػ���, �����������������ȫ���Ի���������
-- ----------------------------------------------------------------------------------------------------------
-- ���¼��������Ŷ�����
-- ��Ҫ���������ݵĽṹ, ���������������ʽ�����д���: С��ģʽ(Ĭ��ģʽ)/����ģʽ/�Զ���ģʽ/��ɫģʽ(IDģʽ), ǰ���ַ�ʽ����������TITLE���н��п���л�, ��������ϵͳ�ڲ�ʹ�õ�
function RaidGridEx.ReloadEntireTeamInfo(bRedraw)
	local team = GetClientTeam()
	if not team then
		return
	end
	if bRedraw then
		RaidGridEx.frameSelf:Lookup("", "Text_Title"):SetText(RaidGridEx.szTitleText)
		if RaidGridEx.tRollQualityImage and RaidGridEx.tRollQualityImage[team.nRollQuality] then
			RaidGridEx.tRollQualityImage[team.nRollQuality]:SetAlpha(255)
		end
		if RaidGridEx.tLootModeImage and RaidGridEx.tLootModeImage[team.nLootMode] then
			RaidGridEx.tLootModeImage[team.nLootMode]:SetAlpha(255)
		end
	end

	RaidGridEx.tGroupList = {}
	RaidGridEx.tForceList = {}
	--RaidGridEx.tCustomList = {}
	RaidGridEx.tRoleIDList = {}
	
	if GetClientPlayer().IsInParty() then
		for nGroupIndex = 0, math.min(4, team.nGroupNum - 1) do
			local tGroupInfo = team.GetGroupInfo(nGroupIndex)
			if tGroupInfo then
				RaidGridEx.tGroupList[nGroupIndex] = RaidGridEx.tGroupList[nGroupIndex] or {}		
				for nSortIndex = 1, #tGroupInfo.MemberList do
					local dwMemberID = tGroupInfo.MemberList[nSortIndex]
					RaidGridEx.OnMemberJoinTeam(dwMemberID, nGroupIndex)
					
					if bRedraw then
						RaidGridEx.ShowRoleHandle(nGroupIndex, nSortIndex)
						RaidGridEx.RedrawMemberHandleHPnMP(dwMemberID)
						RaidGridEx.RedrawMemberHandleState(dwMemberID)
						RaidGridEx.UpdateMemberSpecialState(dwMemberID)
					end
				end
			end
		end
	end
end

-- On PARTY_SYNC_MEMBER_DATA / PARTY_ADD_MEMBER [dwMemberID:arg1, nGroupIndex:arg2]
-- ���������¶�Ա�����ʱ�򴥷��¼�
function RaidGridEx.OnMemberJoinTeam(dwMemberID, nGroupIndex)
	local team = GetClientTeam()
	if not team then
		return
	end
	
	local tMemberInfo = team.GetMemberInfo(dwMemberID)
	if tMemberInfo then
		RaidGridEx.tForceList[tMemberInfo.dwForceID] = RaidGridEx.tForceList[tMemberInfo.dwForceID] or {}
		table.insert(RaidGridEx.tGroupList[nGroupIndex], dwMemberID)				-- ���浽С���б�����
		table.insert(RaidGridEx.tForceList[tMemberInfo.dwForceID], dwMemberID)		-- ���浽�����б�����
		RaidGridEx.tRoleIDList[dwMemberID] = dwMemberID								-- ���浽��ɫģʽ
	end
end

function RaidGridEx.GetBuffList(obj)
	local aBuffTable = {}

	local nCount = obj.GetBuffCount()
	for i=1,nCount,1 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = obj.GetBuff(i - 1)
		if dwID then
			table.insert(aBuffTable,{dwID = dwID, nLevel = nLevel, bCanCancel = bCanCancel, nEndFrame = nEndFrame, nIndex = nIndex, nStackNum = nStackNum, dwSkillSrcID = dwSkillSrcID, bValid = bValid})
		end
	end

	return aBuffTable
end


-- On BUFF_UPDATE [dwMemberID:arg0, bIsRemoved:arg1, nIndex:arg2, dwBuffID:arg4, nStackNum:arg5, nEndFrame:arg6, nLevel:arg8, dwSrcID:arg9]
-- ������պ͸���BUFF���ӵ�����
function RaidGridEx.OnUpdateBuffData(dwMemberID, bIsRemoved, nIndex, dwBuffID, nStackNum, nEndFrame, nLevel)
	if nLevel <= 0 then
		return
	end
	
	local member = GetPlayer(dwMemberID)
	if not member then
		return
	end
	
	local tBuffList = RaidGridEx.GetBuffList(member)	
	if not tBuffList then
		return
	end
	
	local szBuffName = Table_GetBuffName(dwBuffID, nLevel)
	if not szBuffName or szBuffName == "" then
		return
	end

	local handleRole = RaidGridEx.GetRoleHandleByID(dwMemberID)
	if not handleRole.tBoxes then
		RaidGridEx.UpdateMemberBuff(dwMemberID)
	end
	
	local tBoxes = handleRole.tBoxes
	
	-- �����ɾ��, ��������ɾ��
	if bIsRemoved then
		for i = 1, 4, 1 do
			local box = tBoxes[i]
			if box.szName == szBuffName then
				box.szName = nil
				box.nIconID = -1
				box.bShow = false
				box.nEndFrame = 0
				box.nRate = 9999
				box.szColor = nil
				box.nAlpha = RaidGridEx.nBuffFlashAlpha
				box.nTrend = 1
				box:ClearObjectIcon()
				local shadow = handleRole:Lookup("Shadow_Color")
				shadow:Hide()
			end
		end
		return
	end
	
	-- ��������, ���Ƿ��ڹ�ע�б���
	local tSplitTextTable = DebuffSettingPanel.FormatDebuffNameList()
	if RaidGridEx.SearchBuffNameInTable(szBuffName,tSplitTextTable) ~= "" then
		szBuffName = RaidGridEx.SearchBuffNameInTable(szBuffName,tSplitTextTable)
	else
		return
	end
	
	local nRate = tSplitTextTable[szBuffName][1]
	local szColor = tSplitTextTable[szBuffName][2] or ""
	local tCurrentDebuff = {}
	local bInserted = false
	for i = 1, 4, 1 do
		local box = tBoxes[i]
		if box:IsVisible() then
			box.nRate = box.nRate or 9999
			if nRate < box.nRate and not bInserted then
				local nIconID = Table_GetBuffIconID(dwBuffID, nLevel)
				if nIconID then
					bInserted = true
					table.insert(tCurrentDebuff, {szName = szBuffName, nIconID = nIconID, bShow = true, nEndFrame = nEndFrame, nRate = nRate, szColor = szColor, nAlpha = RaidGridEx.nBuffFlashAlpha, nTrend = 1})
				end
			end
			if szBuffName ~= box.szName then
				table.insert(tCurrentDebuff, {szName = box.szName, nIconID = box.nIconID, bShow = box.bShow, nEndFrame = box.nEndFrame, nRate = box.nRate, szColor = box.szColor, nAlpha = box.nAlpha, nTrend = box.nTrend})
			end
		end
		--bInserted = false
	end
	
	if #tCurrentDebuff == 0 then
		local nIconID = Table_GetBuffIconID(dwBuffID, nLevel)
		if nIconID then
			table.insert(tCurrentDebuff, {szName = szBuffName, nIconID = nIconID, bShow = true, nEndFrame = nEndFrame, nRate = nRate, szColor = szColor, nAlpha = RaidGridEx.nBuffFlashAlpha, nTrend = 1})
		end
	end
	
	for i = 1, 4, 1 do
		if tCurrentDebuff[i] then
			tBoxes[i].szName = tCurrentDebuff[i].szName
			tBoxes[i].nIconID = tCurrentDebuff[i].nIconID
			tBoxes[i].bShow = tCurrentDebuff[i].bShow
			tBoxes[i].nEndFrame = tCurrentDebuff[i].nEndFrame
			tBoxes[i].nRate = tCurrentDebuff[i].nRate
			tBoxes[i].szColor = tCurrentDebuff[i].szColor
			tBoxes[i].nAlpha = tCurrentDebuff[i].nAlpha
			tBoxes[i].nTrend = tCurrentDebuff[i].nTrend
			tBoxes[i]:ClearObjectIcon()
			tBoxes[i]:SetObjectIcon(tBoxes[i].nIconID)
			
			local shadow = handleRole:Lookup("Shadow_Color")
			if shadow and (shadow.nEndFrame == 0 or tBoxes[i].nRate < shadow.nRate) then
				local tColor = DebuffSettingPanel.tColorCover[tBoxes[i].szColor]
				local r, g, b, a = 255, 255, 255, 0
				if tColor then
					r, g, b, a = tColor[1], tColor[2], tColor[3], RaidGridEx.nBuffCoverAlpha
				end
				shadow:SetTriangleFan(true)
				shadow:ClearTriangleFanPoint()
				shadow:AppendTriangleFanPoint(0, 0, r, g, b, a)
				shadow:AppendTriangleFanPoint(0, 34, r, g, b, a)
				shadow:AppendTriangleFanPoint(56, 34, r, g, b, a)
				shadow:AppendTriangleFanPoint(56, 0, r, g, b, a)
				shadow:Scale(RaidGridEx.fScale,RaidGridEx.fScale)
				shadow:Show()
				shadow.nEndFrame = tBoxes[i].nEndFrame or 0
				shadow.nRate = tBoxes[i].nRate
			end
		else
			tBoxes[i].szName = nil
			tBoxes[i].nIconID = -1
			tBoxes[i].bShow = false
			tBoxes[i].nEndFrame = 0
			tBoxes[i].nRate = 9999
			tBoxes[i].szColor = nil
			tBoxes[i].nAlpha = RaidGridEx.nBuffFlashAlpha
			tBoxes[i].nTrend = 1
			tBoxes[i]:ClearObjectIcon()
		end
	end
end

-- On TEAM_CHANGE_MEMBER_GROUP [dwSrcMember:arg0, nSrcGroup:arg1, dwDesMember:arg3, nDesGroup:arg2]
-- ������ʾ�˸ı�ǰ��Դ��Ŀ������, dwDesMember Ϊ 0 ��ʾ��Դ�ƶ������ǽ���
-- ���ӳ�����һ�����󴥷��¼�, ����Ĳ�����ʾ��λ���ǸĶ�ǰ��
function RaidGridEx.OnMemberChangeGroup(dwSrcMember, nSrcGroup, dwDesMember, nDesGroup)
	RaidGridEx.CreateAllRoleHandle()
	RaidGridEx.ReloadEntireTeamInfo(true)
	RaidGridEx.AutoScalePanel()
	RaidGridEx.EnableRaidPanel()
end

-- ----------------------------------------------------------------------------------------------------------
-- ���ػ������ݷ���: 
-- ----------------------------------------------------------------------------------------------------------
-- ��ȡ�ų� ID
function RaidGridEx.GetLeader()
	local team = GetClientTeam()
	if not team then
		return
	end
	return team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
end

-- �ж�����Ƿ����ŶӶӳ�
function RaidGridEx.IsLeader(dwMemberID)
	return dwMemberID == RaidGridEx.GetLeader()
end

-- ��ȡ���� ID
function RaidGridEx.GetMatrixcore(nGroupIndex)
	local team = GetClientTeam()
	if not team then
		return
	end
	if GetClientPlayer().IsInParty() then
		local tGroupInfo = team.GetGroupInfo(nGroupIndex)
		if tGroupInfo and tGroupInfo.MemberList and #tGroupInfo.MemberList > 0 then
			return tGroupInfo.dwFormationLeader
		end
	end
end

-- �ж�����Ƿ�������
function RaidGridEx.IsMatrixcore(dwMemberID)
	local team = GetClientTeam()
	if not team then
		return
	end
	if GetClientPlayer().IsInParty() then
		for i = 0, math.min(4, team.nGroupNum - 1) do
			local tGroupInfo = team.GetGroupInfo(i)
			if tGroupInfo and tGroupInfo.MemberList and #tGroupInfo.MemberList > 0 and tGroupInfo.dwFormationLeader == dwMemberID then
				return true
			end
		end
	end
	return false
end

-- ��ȡʰȡ�� ID
function RaidGridEx.GetLooter()
	local team = GetClientTeam()
	if not team then
		return
	end
	return team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
end

-- �ж�����Ƿ�ʰȡ��
function RaidGridEx.IsLooter(dwMemberID)
	return dwMemberID == RaidGridEx.GetLooter()
end

-- ��ȡ����� ID
function RaidGridEx.GetMarker()
	local team = GetClientTeam()
	if not team then
		return
	end
	return team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK)
end

-- �ж�����Ƿ�����
function RaidGridEx.IsMarker(dwMemberID)
	return dwMemberID == RaidGridEx.GetMarker()
end

-- ��ȡʰȡģʽ��Ʒ��
function RaidGridEx.GetLootModenQuality()
	local team = GetClientTeam()
	if not team then
		return
	end
	return team.nLootMode, team.nRollQuality
end

-- ͨ�� ID ��ȡһ������, �ⲻ��һ������, �����������ݵļ��ϱ�
function RaidGridEx.GetTeamMemberInfo(dwMemberID)
	local player = GetClientPlayer()
	if not player then return end
	local team = GetClientTeam()
	if not team then return end
	local member = team.GetMemberInfo(dwMemberID)
	if not member then
		return
	end
	member.nX = member.nPosX
	member.nY = member.nPosY
	return member
end

-- ��ȡ��ɫ�ڱ��е��������: nSortIndex
-- nTypeIndex: �� tGroupMode �б�ʾС��ID, �� tForceMode �б�ʾ����(����)ID
function RaidGridEx.GetSortIndex(tTeamInfoSubTable, nTypeIndex, dwMemberID)
	local tInfo = tTeamInfoSubTable[nTypeIndex]
	if not tInfo then
		return
	end
	for i = 1, #tInfo do
		if tInfo[i] and tInfo[i] == dwMemberID then
			return i
		end
	end
end

-- ȡ�ý�ɫ���ڵ�С�ӵ����
function RaidGridEx.GetGroupIndex(dwMemberID)
	local team = GetClientTeam()
	return team.GetMemberGroupIndex(dwMemberID)
end

-- ��ȡ���λ�����ĸ�С�ӷ�Χ��
function RaidGridEx.GetMouseGroupIndex()
	local nX = RaidGridEx.frameSelf:GetAbsPos()
	local nMouseX = Cursor.GetPos()
	for i = 0, 4, 1 do
		if nMouseX <= nX + (i + 1) * RaidGridEx.nColLength then
			return i
		end
	end
	return 4
end

-- ģ��ƥ��Buff����
function RaidGridEx.SearchBuffNameInTable(szBuffName,tSplitTextTable)
	for k,v in pairs(tSplitTextTable) do
		if string.find(tostring(szBuffName),tostring(k)) then
			return tostring(k)
		end
	end
	return ""
end

-- ----------------------------------------------------------------------------------------------------------
-- ����: 
-- ----------------------------------------------------------------------------------------------------------
function RaidGridEx.Message(szMessage)
	OutputMessage("MSG_SYS", "[RaidGridEx] " .. tostring(szMessage) .. "\n")
end

function RaidGridEx.GetCharacterColor(dwCharacterID, dwForceID)
	local player = GetClientPlayer()
	if not player then
		return 128, 128, 128
	end
	if not IsPlayer(dwCharacterID) then
		return 168, 168, 168
	end
	
	if not dwForceID then
		local target = GetPlayer(dwCharacterID)
		if not target then
			return 128, 128, 128
		end
		
		dwForceID = target.dwForceID
		if not dwForceID then
			return 168, 168, 168
		end
	end

	if dwForceID == 0 then		-- ��
		return 255, 255, 255
	elseif dwForceID == 1 then	-- ����
		return 255,178,95
	elseif dwForceID == 2 then	-- ��
		return 196, 152, 255
	elseif dwForceID == 3 then	-- ���
		return 255, 111, 83
	elseif dwForceID == 4 then	-- ����
		return 89,224,232
	elseif dwForceID == 5 then	-- ����
		return 255,129,176
	elseif dwForceID == 6 then	-- �嶾
		return 55,147,255
	elseif dwForceID == 7 then	-- ����
		return 121,183,54
	elseif dwForceID == 8 then	-- �ؽ�
		return 214,249,93
	elseif dwForceID == 9 then
		return 205,133,63
	elseif dwForceID == 10 then
		return 240,70,96
	end
	return 168, 168, 168
end

function RaidGridEx.GetKungfuByID(dwMemberID)
	local tMemberInfo = RaidGridEx.GetTeamMemberInfo(dwMemberID)
	local dwKungfuID = tMemberInfo.dwMountKungfuID
	if not dwKungfuID then return {"��",255,255,255,10000}
	elseif dwKungfuID == 10080 then return {"��",255,129,176,dwKungfuID}
	elseif dwKungfuID == 10081 then return {"��",255,129,176,dwKungfuID}
	elseif dwKungfuID == 10021 then return {"��",196,152,255,dwKungfuID}
	elseif dwKungfuID == 10028 then return {"��",196,152,255,dwKungfuID}
	elseif dwKungfuID == 10026 then return {"��",255,111,83,dwKungfuID}
	elseif dwKungfuID == 10062 then return {"��",255,111,83,dwKungfuID}
	elseif dwKungfuID == 10002 then return {"ϴ",255,178,95,dwKungfuID}
	elseif dwKungfuID == 10003 then return {"��",255,178,95,dwKungfuID}
	elseif dwKungfuID == 10014 then return {"��",89,224,232,dwKungfuID}
	elseif dwKungfuID == 10015 then return {"��",89,224,232,dwKungfuID}
	elseif dwKungfuID == 10144 then return {"��",214,249,93,dwKungfuID}
	elseif dwKungfuID == 10145 then return {"ɽ",214,249,93,dwKungfuID}
	elseif dwKungfuID == 10175 then return {"��",55,147,255,dwKungfuID}
	elseif dwKungfuID == 10176 then return {"��",55,147,255,dwKungfuID}
	elseif dwKungfuID == 10224 then return {"��",121,183,54,dwKungfuID}
	elseif dwKungfuID == 10225 then return {"��",121,183,54,dwKungfuID}
	elseif dwKungfuID == 10242 then return {"��",240,70,96,dwKungfuID}
	elseif dwKungfuID == 10243 then return {"��",240,70,96,dwKungfuID}
	elseif dwKungfuID == 10268 then return {"ؤ",205,133,63,dwKungfuID}
	elseif dwKungfuID == 10390 then return {"��",128,128,128,dwKungfuID}
	elseif dwKungfuID == 10389 then return {"��",255,255,255,dwKungfuID}
	else return {"unknown",255,255,255,dwKungfuID}
	end
end


function RaidGridEx.SetPanelPos(nX, nY)
	local frame = Station.Lookup("Normal/RaidGridEx")
	if not frame then
		frame = Wnd.OpenWindow("Interface\\JH\\RaidGridEx\\RaidGridEx.ini", "RaidGridEx")
	end
	if not nX or not nY then
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
	else
		local nW, nH = Station.GetClientSize(true)
		if nX < 0 then nX = 0 end
		if nX > nW - 100 then nX = nW - 100 end
		if nY < 0 then nY = 0 end
		if nY > nH - 100 then nY = nH - 100 end
		frame:SetRelPos(nX, nY)
	end
	RaidGridEx.tLastLoc.nX, RaidGridEx.tLastLoc.nY = frame:GetRelPos()
end

function RaidGridEx.ChangeReadyConfirm(dwMemberID, nReadyState)
	local handleRole = RaidGridEx.GetRoleHandleByID(dwMemberID)
	local imgReadyCheck = handleRole:Lookup("Image_ReadyCheck")
	local imgReadyCheckNo = handleRole:Lookup("Image_ReadyCheck_No")
	if nReadyState == 1 then
		imgReadyCheck:Hide()
	elseif nReadyState == 2 then
		imgReadyCheckNo:Show()
	end	
end