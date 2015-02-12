RaidGrid_CTM_Edition = RaidGrid_CTM_Edition or {}
RaidGrid_CTM_Edition.tOptions = {}

RaidGrid_CTM_Edition.bAltNeededForDrag = true;						RegisterCustomData("RaidGrid_CTM_Edition.bAltNeededForDrag")
RaidGrid_CTM_Edition.bRaidEnable = true;							RegisterCustomData("RaidGrid_CTM_Edition.bRaidEnable")
RaidGrid_CTM_Edition.bShowRaid = true;								RegisterCustomData("RaidGrid_CTM_Edition.bShowRaid")
RaidGrid_CTM_Edition.bShowInRaid = false;							RegisterCustomData("RaidGrid_CTM_Edition.bShowInRaid")
RaidGrid_CTM_Edition.bAutoHideCTM = true;							RegisterCustomData("RaidGrid_CTM_Edition.bAutoHideCTM")
RaidGrid_CTM_Edition.bShowSystemRaidPanel = false;					RegisterCustomData("RaidGrid_CTM_Edition.bShowSystemRaidPanel")
RaidGrid_CTM_Edition.bShowSystemTeamPanel = false;					RegisterCustomData("RaidGrid_CTM_Edition.bShowSystemTeamPanel")
RaidGrid_CTM_Edition.bAutoLinkAllPanel = true;						RegisterCustomData("RaidGrid_CTM_Edition.bAutoLinkAllPanel")
RaidGrid_CTM_Edition.nAutoLinkMode = 5;								RegisterCustomData("RaidGrid_CTM_Edition.nAutoLinkMode")
RaidGrid_CTM_Edition.bShowAllPanel = false;							RegisterCustomData("RaidGrid_CTM_Edition.bShowAllPanel")
RaidGrid_CTM_Edition.bShowAllMemberGrid = false;					RegisterCustomData("RaidGrid_CTM_Edition.bShowAllMemberGrid")
RaidGrid_CTM_Edition.bFloatNumber = true;							RegisterCustomData("RaidGrid_CTM_Edition.bFloatNumber")
RaidGrid_CTM_Edition.nHPShownMode = 2;								RegisterCustomData("RaidGrid_CTM_Edition.nHPShownMode")
RaidGrid_CTM_Edition.nShowMP = false;								RegisterCustomData("RaidGrid_CTM_Edition.nShowMP")
RaidGrid_CTM_Edition.bLowMPBar = true;								RegisterCustomData("RaidGrid_CTM_Edition.bLowMPBar")
RaidGrid_CTM_Edition.bHPHitAlert = true;							RegisterCustomData("RaidGrid_CTM_Edition.bHPHitAlert")
RaidGrid_CTM_Edition.bColoredName = true;							RegisterCustomData("RaidGrid_CTM_Edition.bColoredName")
RaidGrid_CTM_Edition.bColoredGrid = false;							RegisterCustomData("RaidGrid_CTM_Edition.bColoredGrid")
RaidGrid_CTM_Edition.bShowIcon = 2;									RegisterCustomData("RaidGrid_CTM_Edition.bShowIcon")
RaidGrid_CTM_Edition.bShowDistance = false;							RegisterCustomData("RaidGrid_CTM_Edition.bShowDistance")
RaidGrid_CTM_Edition.bColorHPBarWithDistance = true;				RegisterCustomData("RaidGrid_CTM_Edition.bColorHPBarWithDistance")

RaidGrid_CTM_Edition.bShowSelectImage = true;						RegisterCustomData("RaidGrid_CTM_Edition.bShowSelectImage")
RaidGrid_CTM_Edition.bShowTargetTargetAni = true;					RegisterCustomData("RaidGrid_CTM_Edition.bShowTargetTargetAni")

function RaidGrid_CTM_Edition.RaidPanel_Switch(bOpen)
	local frame = Station.Lookup("Normal/RaidPanel_Main")
	if frame then
		if bOpen then
			frame:Show()
		else
			frame:Hide()
		end
	end
end

function RaidGrid_CTM_Edition.TeammatePanel_Switch(bOpen)
	local hFrame = Station.Lookup("Normal/Teammate")
	if hFrame then
		if bOpen then
			hFrame:Show()
		else
			hFrame:Hide()
		end
	end	
end

function RaidGrid_CTM_Edition.ShadowSetting()
	local Recall = function(szText)
		if not szText or szText == "" then
			return
		end
		local nCount = tonumber(szText)
		if not nCount then
			return
		end
		if nCount > 0 and nCount < 256 then
			RaidGrid_Party.Shadow.a = nCount
		end
	end
	GetUserInput("����1-255֮�����", Recall, nil, function() end, nil, RaidGrid_Party.Shadow.a, 31)
end

function RaidGrid_CTM_Edition.ShadowSetting2()
	local Recall = function(szText)
		if not szText or szText == "" then
			return
		end
		local nCount = tonumber(szText)
		if not nCount then
			return
		end
		if nCount > 0 and nCount <= 1 then
			RaidGrid_Party.Shadow.d = nCount
		end
	end
	GetUserInput("���������0��С�ڵ���1֮�����", Recall, nil, function() end, nil, RaidGrid_Party.Shadow.d, 31)
end

function RaidGrid_CTM_Edition.PopOptions()
	RaidGrid_CTM_Edition.tOptions = {
		{
			szOption = "���ų�������ء���",
			{
				szOption = g_tStrings.STR_RAID_READY_CONFIRM_START, fnAction = RaidGrid_Party.InitReadyCheckCover,
			},
			{
				szOption = g_tStrings.STR_RAID_READY_CONFIRM_RESET, fnAction =  RaidGrid_Party.ClearReadyCheckCover,
			},
			{
				bDevide = true
			},
			{
				szOption = "�谴סAlt���ܵ��ӣ��ų�ʱ��", bCheck = true, bChecked = RaidGrid_CTM_Edition.bAltNeededForDrag, fnAction = function(UserData, bCheck) RaidGrid_CTM_Edition.bAltNeededForDrag = bCheck end,
			},
			{
				bDevide = true
			},
		},
		{
			bDevide = true
		},
		{
			szOption = "����������á���",
			{
				szOption = "�ر�Ѫ������ɫ", bCheck = true, bChecked = RaidGrid_Party.Shadow.bLife, fnAction = function(UserData, bCheck)
					RaidGrid_Party.Shadow.bLife = bCheck
				end,
			},
			{
				szOption = "�ر���������ɫ", bCheck = true, bChecked = RaidGrid_Party.Shadow.bMana, fnAction = function(UserData, bCheck)
					RaidGrid_Party.Shadow.bMana = bCheck
				end,
			},
			{
				szOption = "͸��������",fnAction = function()
					RaidGrid_CTM_Edition.ShadowSetting()
				end,
			},
			{
				szOption = "��ɫ�������",fnAction = function()
					RaidGrid_CTM_Edition.ShadowSetting2()
				end,
			},
		},
		{
			szOption = "���Ŷ������ء���",
			{
				szOption = "�￪������Ŷ���幦��", bCheck = true, bChecked = RaidGrid_CTM_Edition.bRaidEnable, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bRaidEnable = bCheck
					RaidGrid_CTM_Edition.bShowRaid = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "��ֻ���Ŷ�ʱ����ʾ", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowInRaid, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bShowInRaid = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "��CTM������������Զ�����", bCheck = true, bChecked = RaidGrid_CTM_Edition.bAutoHideCTM, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bAutoHideCTM = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "�������Ŷ���С������λ��", bCheck = true, bChecked = RaidGrid_CTM_Edition.bAutoLinkAllPanel, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bAutoLinkAllPanel = bCheck
					if RaidGrid_CTM_Edition.bAutoLinkAllPanel then
						RaidGrid_Party.AutoLinkAllPanel()
					end
				end,
			},
			{
				szOption = "���������Զ����и�ʽ��",
				{szOption = "һ�У�����/����", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 5, fnAction = function()
					RaidGrid_CTM_Edition.nAutoLinkMode = 5
					RaidGrid_Party.ReloadRaidPanel()
				end},
				{szOption = "���У�һ��/����", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 1, fnAction = function()
					RaidGrid_CTM_Edition.nAutoLinkMode = 1
					RaidGrid_Party.ReloadRaidPanel()
				end},
				{szOption = "���У�����/����", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 2, fnAction = function()
					RaidGrid_CTM_Edition.nAutoLinkMode = 2
					RaidGrid_Party.ReloadRaidPanel()
				end},
				{szOption = "���У�����/����", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 3, fnAction = function()
					RaidGrid_CTM_Edition.nAutoLinkMode = 3
					RaidGrid_Party.ReloadRaidPanel()
				end},
				{szOption = "���У�����/һ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 4, fnAction = function()
					RaidGrid_CTM_Edition.nAutoLinkMode = 4
					RaidGrid_Party.ReloadRaidPanel()
				end},
			},
			{
				szOption = "����������С�����λ��", bCheck = false, bChecked = false, fnAction = function(UserData, bCheck) RaidGrid_Party.AutoLinkAllPanel() end,
			},
			{
				szOption = "��������ʾ������С�Ӹ���", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowAllMemberGrid, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bShowAllMemberGrid = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "��������ʾ�����Ŷ����", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowAllPanel, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bShowAllPanel = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "������ϵͳ�Ŷ����", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowSystemRaidPanel, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bShowSystemRaidPanel = bCheck;
					RaidGrid_CTM_Edition.RaidPanel_Switch(bCheck)
				end,
			},
			{
				szOption = "������ϵͳС�����", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowSystemTeamPanel, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bShowSystemTeamPanel = bCheck
					RaidGrid_CTM_Edition.TeammatePanel_Switch(bCheck)
				end,
			},
		},
		{
			szOption = "���Ŷ����ߴ����á���",
			{
				szOption = "�ﻹԭΪĬ�� 1:1", bCheck = false, bChecked = false, fnAction = function(UserData, bCheck)
					RaidGrid_Party.fScaleX = 1
					RaidGrid_Party.fScaleY = 1
					RaidGrid_Party.fScaleFont = 1
					RaidGrid_Party.fScaleIcon = 1
					RaidGrid_Party.fScaleShadowX = 1
					RaidGrid_Party.fScaleShadowY = 1
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "���Ŷӽ��桾��ȡ�������", fnAction = function()
					local x, y = Cursor.GetPos()
					local fScaleX = RaidGrid_Party.fScaleX
					GetUserPercentage(function(val)
						RaidGrid_Party.fScaleX = tonumber(val)
						RaidGrid_Party.ReloadRaidPanel()
						Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
					end, nil, (fScaleX - 0.5) / 1.00, "���" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
				end
			},
			{
				szOption = "���Ŷӽ��桾�߶ȡ�������", fnAction = function()
					local x, y = Cursor.GetPos()
					local fScaleY = RaidGrid_Party.fScaleY
					GetUserPercentage(function(val)
						RaidGrid_Party.fScaleY = tonumber(val)
						RaidGrid_Party.ReloadRaidPanel()
						Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
					end, nil, (fScaleY - 0.5) / 1.00, "�߶�" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
				end
			},
			{
				szOption = "���Ŷӽ��桾���ִ�С��������", fnAction = function()
					local x, y = Cursor.GetPos()
					local fScaleFont = RaidGrid_Party.fScaleFont
					GetUserPercentage(function(val)
						RaidGrid_Party.fScaleFont = tonumber(val)
						RaidGrid_Party.ReloadRaidPanel()
						Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
					end, nil, (fScaleFont - 0.5) / 1.00, "���ִ�С" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
				end
			},
			{
				szOption = "���Ŷӽ��桾buffͼ�꡿������", fnAction = function()
					local x, y = Cursor.GetPos()
					local fScaleIcon = RaidGrid_Party.fScaleIcon
					GetUserPercentage(function(val)
						RaidGrid_Party.fScaleIcon = tonumber(val)
						RaidGrid_Party.ReloadRaidPanel()
						Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
					end, nil, (fScaleIcon - 0.5) / 1.00, "BUFF��С" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
				end
			},
			{
				szOption = "���Ŷӽ��桾buff����ɫ����ȱ�����", fnAction = function()
					local x, y = Cursor.GetPos()
					local fScaleShadowX = RaidGrid_Party.fScaleShadowX
					GetUserPercentage(function(val)
						RaidGrid_Party.fScaleShadowX = tonumber(val)
						RaidGrid_Party.ReloadRaidPanel()
						Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
					end, nil, (fScaleShadowX - 0.5) / 1.00, "BUFF����ɫ���" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
				end
			},
			{
				szOption = "���Ŷӽ��桾buff����ɫ���߶ȱ�����", fnAction = function()
					local x, y = Cursor.GetPos()
					local fScaleShadowY = RaidGrid_Party.fScaleShadowY
					GetUserPercentage(function(val)
						RaidGrid_Party.fScaleShadowY = tonumber(val)
						RaidGrid_Party.ReloadRaidPanel()
						Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
					end, nil, (fScaleShadowY - 0.5) / 1.00, "BUFF����ɫ�߶�" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
				end
			},
		},
		{
			bDevide = true
		},
		{
			szOption = "����������ģʽ��", bCheck = true, bChecked = RaidGrid_Party.bTempTargetEnable, fnAction = function(UserData, bCheck)
				RaidGrid_Party.bTempTargetEnable = bCheck
			end,
		},
		{
			szOption = "������ģʽս���в���ʾTIP��", bCheck = true, bChecked = RaidGrid_Party.bTempTargetFightTip, fnAction = function(UserData, bCheck)
				RaidGrid_Party.bTempTargetFightTip = bCheck
			end,
		},
		{
			szOption = "��������Ϊ��ء���",
			{
				szOption = "����ʾѡ�еĶ��ѱ�ɫ", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowSelectImage, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bShowSelectImage = bCheck
					RaidGrid_Party.RedrawTargetSelectImage(true)
				end,
			},
			{
				szOption = "����ʾ��Ŀ��ѡ�еĶ��Ѷ���", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowTargetTargetAni, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bShowTargetTargetAni = bCheck
					RaidGrid_Party.RedrawTargetSelectImage(true)
				end,
			},
			{
				bDevide = true
			},
			{
				szOption = "�����Ѿ�����ʾ", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowDistance, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bShowDistance = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			
		},
		{
			bDevide = true
		},
		{
			szOption = "��Ѫ��������ʾ��ء���",
			{
				szOption = "����ʾ��ֵ����Ϊ 0.1", bCheck = true, bChecked = RaidGrid_CTM_Edition.bFloatNumber, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bFloatNumber = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				bDevide = true
			},
			{
				szOption = "����ϸ��������ʾģʽ", bCheck = true, bChecked = RaidGrid_CTM_Edition.bLowMPBar, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bLowMPBar = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "����ʾ����ʣ����", bCheck = true, bChecked = RaidGrid_CTM_Edition.nShowMP, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.nShowMP = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				bDevide = true
			},
			{
				szOption = "��Ѫ����ʾģʽ",
				{szOption = "���ٵ�Ѫ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownMode == 1, fnAction = function()
					RaidGrid_CTM_Edition.nHPShownMode = 1
					RaidGrid_Party.ReloadRaidPanel()
				end},
				{szOption = "ʣ���Ѫ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownMode == 2, fnAction = function()
					RaidGrid_CTM_Edition.nHPShownMode = 2
					RaidGrid_Party.ReloadRaidPanel()
				end},
				{szOption = "������ʾѪ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownMode == 4, fnAction = function()
					RaidGrid_CTM_Edition.nHPShownMode = 4
					RaidGrid_Party.ReloadRaidPanel()
				end},
				{szOption = "Ѫ���ٷֱ�", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownMode == 3, fnAction = function()
					RaidGrid_CTM_Edition.nHPShownMode = 3
					RaidGrid_Party.ReloadRaidPanel()
				end},
				{szOption = "����ʾ(ͬʱ��������/���߱��)", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownMode == 0, fnAction = function()
					RaidGrid_CTM_Edition.nHPShownMode = 0
					RaidGrid_Party.ReloadRaidPanel()
				end},
			},
			{
				szOption = "��Ѫ�����ݾ�����ɫ", bCheck = true, bChecked = RaidGrid_CTM_Edition.bColorHPBarWithDistance, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bColorHPBarWithDistance = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				bDevide = true
			},
			{
				szOption = "��������������ʾ", bCheck = true, bChecked = RaidGrid_CTM_Edition.bHPHitAlert, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bHPHitAlert = bCheck
					RaidGrid_Party.RedrawAllFadeHP(true)
				end,
			},
		},
		{
			szOption = "��Ѫ����ɫ��Χ�趨����", szID = "HP_COLOR_ZONE",
		},
		{
			bDevide = true
		},
		{
			szOption = "����ɫ��ͼ����ء���",
			{
				szOption = "�����ְ�ְҵ��ɫ", bCheck = true, bChecked = RaidGrid_CTM_Edition.bColoredName, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bColoredName = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "����ɫ��ְҵ��ɫ", bCheck = true, bChecked = RaidGrid_CTM_Edition.bColoredGrid, fnAction = function(UserData, bCheck)
					RaidGrid_CTM_Edition.bColoredGrid = bCheck
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				bDevide = true
			},
			{
				szOption = "����ʾְҵͼ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.bShowIcon == 1, fnAction = function()
					RaidGrid_CTM_Edition.bShowIcon = 1
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "����ʾ�ڹ�ͼ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.bShowIcon == 2, fnAction = function()
					RaidGrid_CTM_Edition.bShowIcon = 2
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
			{
				szOption = "����ʾ��Ӫͼ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.bShowIcon == 3, fnAction = function()
					RaidGrid_CTM_Edition.bShowIcon = 3
					RaidGrid_Party.ReloadRaidPanel()
				end,
			},
		},
		{
			bDevide = true
		},
	}
	
	for i = 1, #RaidGrid_CTM_Edition.tOptions do
		if RaidGrid_CTM_Edition.tOptions[i].szID then
			if RaidGrid_CTM_Edition.tOptions[i].szID == "HP_COLOR_ZONE" then
				local function GetDistTable(nIndex)
					local tabAllDist = {szOption = "���룺" .. RaidGrid_Party.tDistanceLevel[nIndex],}
					if nIndex == 5 then
						tabAllDist.bDisable = true
					else
						for k = 4, 32 do
							local tabDist = {
								szOption = "������ " .. k .. "������ (����)", bMCheck = true, bChecked = RaidGrid_Party.tDistanceLevel[nIndex] == k, fnAction = function(UserData, bCheck)
									RaidGrid_Party.tDistanceLevel[nIndex] = k
								end,
							}
							table.insert(tabAllDist, tabDist)
						end
					end
					return tabAllDist, RaidGrid_Party.tDistanceLevel[nIndex]
				end
				local function GetColorTable(nIndex)
					local tColor = {
						{szName = "��ɫ", nLevel = 1,		r = RaidGrid_Party.tDistanceColor[1][1], g = RaidGrid_Party.tDistanceColor[1][2], b = RaidGrid_Party.tDistanceColor[1][3]},
						{szName = "��ɫ", nLevel = 2,		r = RaidGrid_Party.tDistanceColor[2][1], g = RaidGrid_Party.tDistanceColor[2][2], b = RaidGrid_Party.tDistanceColor[2][3]},
						{szName = "��ɫ", nLevel = 3,		r = RaidGrid_Party.tDistanceColor[3][1], g = RaidGrid_Party.tDistanceColor[3][2], b = RaidGrid_Party.tDistanceColor[3][3]},
						{szName = "��ɫ", nLevel = 4,		r = RaidGrid_Party.tDistanceColor[4][1], g = RaidGrid_Party.tDistanceColor[4][2], b = RaidGrid_Party.tDistanceColor[4][3]},
						{szName = "��ɫ", nLevel = 5,		r = RaidGrid_Party.tDistanceColor[5][1], g = RaidGrid_Party.tDistanceColor[5][2], b = RaidGrid_Party.tDistanceColor[5][3]},

						{szName = "��ɫ (��)", nLevel = 6,	r = RaidGrid_Party.tDistanceColor[6][1], g = RaidGrid_Party.tDistanceColor[6][2], b = RaidGrid_Party.tDistanceColor[6][3]},
						{szName = "��ɫ (ǳ)", nLevel = 7,	r = RaidGrid_Party.tDistanceColor[7][1], g = RaidGrid_Party.tDistanceColor[7][2], b = RaidGrid_Party.tDistanceColor[7][3]},
						{szName = "��ɫ", nLevel = 8,		r = RaidGrid_Party.tDistanceColor[8][1], g = RaidGrid_Party.tDistanceColor[8][2], b = RaidGrid_Party.tDistanceColor[8][3]},
					}
					
					local szNameC = tColor[RaidGrid_Party.tDistanceColorLevel[nIndex]].szName
					local nR = RaidGrid_Party.tDistanceColor[RaidGrid_Party.tDistanceColorLevel[nIndex]][1]
					local nG = RaidGrid_Party.tDistanceColor[RaidGrid_Party.tDistanceColorLevel[nIndex]][2]
					local nB = RaidGrid_Party.tDistanceColor[RaidGrid_Party.tDistanceColorLevel[nIndex]][3]
					local tabAllColor = {szOption = "��ɫ��" .. szNameC, r = nR, g = nG, b = nB}
					for k = 1, #tColor do
						local tabColor = {
							szOption = tColor[k].szName, bMCheck = true, bChecked = RaidGrid_Party.tDistanceColorLevel[nIndex] == tColor[k].nLevel, fnAction = function(UserData, bCheck)
								RaidGrid_Party.tDistanceColorLevel[nIndex] = k
							end,
							r = tColor[k].r, g = tColor[k].g, b = tColor[k].b, 
						}
						table.insert(tabAllColor, tabColor)
					end
					return tabAllColor, szNameC, nR, nG, nB 
				end
				for j = 1, 5 do
					local tD, nDist = GetDistTable(j)
					local tC, szNameC, nR, nG, nB = GetColorTable(j)
					local szDist = tostring(nDist)
					szDist = ("_"):rep(3 - #szDist) .. szDist
					table.insert(RaidGrid_CTM_Edition.tOptions[i], {szOption = "С�� " .. szDist .. "����Ϊ��" .. szNameC, tD, tC, r = nR, g = nG, b = nB})
				end
			end
		end
	end
	
	if GetClientPlayer().IsInParty() then
		RaidGrid_CTM_Edition.InsertForceCountMenu(RaidGrid_CTM_Edition.tOptions)
	end
	local nX, nY = Cursor.GetPos(true)
	RaidGrid_CTM_Edition.tOptions.x, RaidGrid_CTM_Edition.tOptions.y = nX + 15, nY + 15
	
	local player = GetClientPlayer()
	local hTeam = GetClientTeam()
	local dwDistribute = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)	
	InsertDistributeMenu(RaidGrid_CTM_Edition.tOptions[1], player.dwID ~= dwDistribute)
	PopupMenu(RaidGrid_CTM_Edition.tOptions)
end

function RaidGrid_CTM_Edition.InsertForceCountMenu(tMenu)
	local tForceList = {}
	local hTeam = GetClientTeam()
	for nGroupID = 0, hTeam.nGroupNum - 1 do
		local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
		for _, dwMemberID in ipairs(tGroupInfo.MemberList) do
			local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
			if not tForceList[tMemberInfo.dwForceID] then
				tForceList[tMemberInfo.dwForceID] = 0
			end
			tForceList[tMemberInfo.dwForceID] = tForceList[tMemberInfo.dwForceID] + 1
		end
	end
	local tSubMenu = { szOption = "���鿴����ͳ�ơ���" }
	for dwForceID, nCount in pairs(tForceList) do
		table.insert(tSubMenu, { szOption = g_tStrings.tForceTitle[dwForceID] .. "   " .. nCount })
	end
	table.insert(tMenu, tSubMenu)
end

function RaidGrid_CTM_Edition.InsertChangeGroupMenu(tMenu, dwMemberID)
	local hTeam = GetClientTeam()
	local tSubMenu = { szOption = g_tStrings.STR_RAID_MENU_CHANG_GROUP }
	
	local nCurGroupID = hTeam.GetMemberGroupIndex(dwMemberID)
	for i = 0, hTeam.nGroupNum - 1 do
		if i ~= nCurGroupID then
			local tGroupInfo = hTeam.GetGroupInfo(i)
			if tGroupInfo and tGroupInfo.MemberList then
				local tSubSubMenu = 
				{
					szOption = g_tStrings.STR_NUMBER[i + 1],
					bDisable = (#tGroupInfo.MemberList >= 5),
					fnAction = function() GetClientTeam().ChangeMemberGroup(dwMemberID, i, 0) end,
					fnAutoClose = function() return true end,
				}
				table.insert(tSubMenu, tSubSubMenu)
			end
		end
	end
	
	if #tSubMenu > 0 then
		table.insert(tMenu, tSubMenu)
	end
end

function RaidGrid_CTM_Edition.OutputTeamMemberTip(dwID, rc)
	if GetPlayer(dwID) then
		RaidGrid_CTM_Edition.OutputPlayerTip(dwID, rc)
		return
	end
	
	local hTeam = GetClientTeam()
	local tMemberInfo = hTeam.GetMemberInfo(dwID)
	if not tMemberInfo then
		return
	end

	local r, g, b = RaidGrid_CTM_Edition.GetPartyMemberFontColor()
    local szTip = GetFormatText(FormatString(g_tStrings.STR_NAME_PLAYER, tMemberInfo.szName), 80, r, g, b)
    if tMemberInfo.bIsOnLine then
    	szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, tMemberInfo.nLevel), 82)
		local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
		if szMapName then
			szTip = szTip .. GetFormatText(szMapName .. "\n", 82)
		end
        
        local nCamp = tMemberInfo.nCamp
        szTip = szTip .. GetFormatText(g_tStrings.STR_GUILD_CAMP_NAME[nCamp], 82)
    else
    	szTip = szTip .. GetFormatText(g_tStrings.STR_FRIEND_NOT_ON_LINE .. "\n", 82)
    end
    OutputTip(szTip, 345, rc)
end

function RaidGrid_CTM_Edition.OutputPlayerTip(dwPlayerID, Rect)
	--������Լ�������ʾtip
	local player = GetPlayer(dwPlayerID)
	if not player then
		return
	end
	
	local clientPlayer = GetClientPlayer()
	
	if not IsCursorInExclusiveMode() then	
		if clientPlayer.dwID == dwPlayerID then
			return
		end
	end
	
	local r, g, b = RaidGrid_CTM_Edition.GetForceFontColor(dwPlayerID, clientPlayer.dwID)
	local szTip = ""

	--------------����-------------------------
    szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_NAME_PLAYER, player.szName)).." font=80".." r="..r.." g="..g.." b="..b.." </text>"
    
    -------------�ƺ�----------------------------        
    if player.szTitle ~= "" then
    	szTip = szTip.."<Text>text="..EncodeComponentsString("<"..player.szTitle..">\n").." font=0 </text>"
    end
    
    if player.dwTongID ~= 0 then
    	local szName = GetTongClient().ApplyGetTongName(player.dwTongID)
    	if szName and szName ~= "" then
    		szTip = szTip.."<Text>text="..EncodeComponentsString("["..szName.."]\n").." font=0 </text>"
    	end
    end
    
    -------------�ȼ�----------------------------
    if player.nLevel - clientPlayer.nLevel > 10 and not clientPlayer.IsPlayerInMyParty(dwPlayerID) then 
    	szTip = szTip.."<Text>text="..EncodeComponentsString(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL).." font=82 </text>"
    else
    	szTip = szTip.."<Text>text="..EncodeComponentsString(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, player.nLevel)).." font=82 </text>"
    end

	if RaidGrid_CTM_Edition.g_tReputation.tReputationTable[player.dwForceID] then
		szTip = szTip.."<Text>text="..EncodeComponentsString(RaidGrid_CTM_Edition.g_tReputation.tReputationTable[player.dwForceID].szName.."\n").." font=82 </text>"
	end

	if clientPlayer.IsPlayerInMyParty(dwPlayerID) then
		local hTeam = GetClientTeam()
		local tMemberInfo = hTeam.GetMemberInfo(dwPlayerID)
		if tMemberInfo then
			local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
			if szMapName then
				szTip = szTip.."<Text>text="..EncodeComponentsString(szMapName.."\n").." font=82 </text>"
			end
		end
	end
    
	if player.bCampFlag then
		szTip = szTip .. GetFormatText(g_tStrings.STR_TIP_CAMP_FLAG, 163)
	end
	
    local nCamp = player.nCamp
    szTip = szTip .. GetFormatText(g_tStrings.STR_GUILD_CAMP_NAME[nCamp], 82)
    
    if IsCtrlKeyDown() then
    	szTip = szTip.."<Text>text="..EncodeComponentsString("\n" .. FormatString(g_tStrings.TIP_PLAYER_ID, player.dwID)).." font=102 </text>"
    	--szTip = szTip.."<Text>text="
		--szTip = szTip..EncodeComponentsString(FormatString(g_tStrings.TIP_REPRESENTID_ID, player.dwModelID.." "..var2str(player.GetRepresentID()))).." font=102 </text>" 
    end
    
    OutputTip(szTip, 345, Rect)
end

function RaidGrid_CTM_Edition.GetForceFontColor(dwPeerID, dwSelfID)
	local bInParty = false
	local player = GetClientPlayer()
	if player then
		if player.dwID == dwPeerID then
			bInParty = player.IsPlayerInMyParty(dwSelfID)
		elseif player.dwID == dwSelfID then
			bInParty = player.IsPlayerInMyParty(dwPeerID)
		end
	end
	
	local src = dwPeerID
	local dest = dwSelfID
	
	if IsPlayer(dwPeerID) and IsPlayer(dwSelfID) then
	    src = dwSelfID
	    dest = dwPeerID
	end
	
	local r, g, b
	if dwSelfID == dwPeerID then
		r, g, b = 255, 255, 0
	elseif bInParty then
		r, g, b = RaidGrid_CTM_Edition.GetPartyMemberFontColor()
	elseif IsEnemy(src, dest) then
		r, g, b = 255, 0, 0
	elseif IsNeutrality(src, dest) then
		r, g, b = 255, 255, 0
	elseif IsAlly(src, dest) then
		r, g, b = 0, 200, 72
	else
		r, g, b = 255, 0, 0
	end
	return r, g, b
end

function RaidGrid_CTM_Edition.GetPartyMemberFontColor()
	return 126, 126, 255
end

RaidGrid_CTM_Edition.g_tReputation =				
{				
	tReputationGroupTable =			
	{			
		{szVersionName = "������",		
            tGroup ={				
                {szName = "��������", aForce = {11, 12, 13, 14, 15, 18, 19, 20}, },				
                {szName = "����", aForce = {34, 35, 36}, },				
                {szName = "��������", aForce = {38, 44, 45, 46, 47, 48, 75}, },				
                {szName = "�Ĵ��̻�", aForce = {43, 54, 55, 56}, },				
                {szName = "�ھ�����", aForce = {42}, },				
                {szName = "��Ӫ", aForce = {49, 50}, },				
            }				
		},		
				
		{szVersionName = "�������",		
            tGroup ={				
                {szName = "��������", aForce = {16,17}, },				
                {szName = "��������", aForce = {82, 83, 84, 85, 86, 87, 88, 89, 90, 93}, },				
                {szName = "�ھ�����", aForce = {91}, },				
            }				
		},		
        				
	},			
				
	tReputationTable =			
	{			
		--bInShow = true ��bHide = trueʱ��Ч�����Ϊtrue,����Ҽ��������������ʾ��		
		--nInNoShou = 22 ��bHide = falseʱ��Ч������Ҽ��������ֵ�������Ͳ���ʾ		
				
		[1] = {szName = "����", szDesc = "<text>text=\"��������ʷ�ƾã���ѧԨԴ���������������书������֮�ơ�\"", bHide = true},		
		[2] = {szName = "��", szDesc = "<text>text=\"���Դӽ��������ͳ�Ϊ�˸���������ʿ�ۼ�֮�ء�\"", bHide = true},		
		[3] = {szName = "���", szDesc = "<text>text=\"������֮�ǡ���߸�����̫����������Ϊ����ʱ����������֯���������������̨�𽥳�Ϊ���ܻ��أ������뽭��ǣ��϶�����ˡ�\"", bHide = true},		
		[4] = {szName = "����", szDesc = "<text>text=\"ע���ľ������ĵ��ţ����Ǵ������֮�����е�ʥ�ء�\"", bHide = true},		
		[5] = {szName = "����", szDesc = "<text>text=\"���Ǹ�����Ů֮�أ���Ϊ����λ��Ů�ӵĳ��֣����ơ����㷻����\"", bHide = true},		
		[6] = {szName = "�嶾", szDesc = "<text>text=\"�Ը����㣬һ�����������ԭ��������ʿ��Ϊ��Ը���ǵ�����֮һ��\"", bHide = true},		
		[7] = {szName = "����", szDesc = "<text>text=\"��������Ϊ���صļ��壬�����Ĵ�����֮�ף���ʷ��Ϊ�ƾá�\"", bHide = true},		
		[8] = {szName = "�ؽ�", szDesc = "<text>text=\"�����½���������ң������˾�����ٶ�λ���Ĵ����ң����ǽ���������һҶ֪�Ҷ����һ�ִ����Ľ������š�\"", bHide = true},		
		[9] = {szName = "ؤ��", szDesc = "<text>text=\"Ц�������ġ����µ�һ����һ��Դ�����ײ���м����������е��Ӷ�����������Ϊ֮��Ŀ�ļ�����Ѫ��\"", bHide = true},		
		[10] = {szName = "����", szDesc = "<text>text=\"�����Ƿ�Դ�Բ�˹������˹�½��ɵĽ��ɣ������ڶ��Ļ��������������Ϊ�����Ա���ԭ���ִ����ų⡣\"", bHide = true},		
				
		[11] = {szName = "����", szDesc = "<text>text=\"��������ʷ�ƾã���ѧԨԴ���������������书������֮�ơ�\""},		
		[12] = {szName = "��", szDesc = "<text>text=\"���Դӽ��������ͳ�Ϊ�˸���������ʿ�ۼ�֮�ء�\""},		
		[13] = {szName = "���", szDesc = "<text>text=\"������֮�ǡ���߸�����̫����������Ϊ����ʱ����������֯���������������̨�𽥳�Ϊ���ܻ��أ������뽭��ǣ��϶�����ˡ�\""},		
		[14] = {szName = "����", szDesc = "<text>text=\"ע���ľ������ĵ��ţ����Ǵ������֮�����е�ʥ�ء�\""},		
		[15] = {szName = "����", szDesc = "<text>text=\"���Ǹ�����Ů֮�أ���Ϊ����λ��Ů�ӵĳ��֣����ơ����㷻����\""},		
		[16] = {szName = "�嶾", szDesc = "<text>text=\"�Ը����㣬һ�����������ԭ��������ʿ��Ϊ��Ը���ǵ�����֮һ��\""},		
		[17] = {szName = "����", szDesc = "<text>text=\"��������Ϊ���صļ��壬�����Ĵ�����֮�ף���ʷ��Ϊ�ƾá�\""},		
		[18] = {szName = "�ؽ�", szDesc = "<text>text=\"�����½���������ң������˾�����ٶ�λ���Ĵ����ң����ǽ���������һҶ֪�Ҷ����һ�ִ����Ľ������š�\""},		
		[19] = {szName = "ؤ��", szDesc = "<text>text=\"Ц�������ġ����µ�һ����һ��Դ�����ײ���м����������е��Ӷ�����������Ϊ֮��Ŀ�ļ�����Ѫ��\"", bHide = true},		
		[20] = {szName = "����", szDesc = "<text>text=\"�����Ƿ�Դ�Բ�˹������˹�½��ɵĽ��ɣ������ڶ��Ļ��������������Ϊ�����Ա���ԭ���ִ����ų⡣\"", bHide = true},		
				
				
		[34] = {szName = "����", szDesc = "<text>text=\"��������Ҫ�ĸۿڳ��У�ũҵ����ҵ���ֹ�ҵ�൱�������֮�主�����µ�����������һ���֮�ơ�\""},		
		[35] = {szName = "����", szDesc = "<text>text=\"�������Ǵ��ƵĶ�����Ҳ�ǡ�����֮�ǡ���߸��ķ�Դ�ء�\""},		
		[36] = {szName = "����", szDesc = "<text>text=\"�������Ǵ��ƹ�����ʢ��֮�������������￴����\""},		
				
				
		[38] = {szName = "���½�", szDesc = "<text>text=\"����������������������̺���ԭ������һ�𣬳���������������Ϊһ�塣\""},		
		[44] = {szName = "����կ", szDesc = "<text>text=\"ʮ��������֮һ���䴦����֮�ƣ�ȴ������֮�ġ�\""},		
		[45] = {szName = "������", szDesc = "<text>text=\"������ʿ�ۼ�֮�����䴦����֮Զ��ȷ������֮�ġ�\""},		
		[46] = {szName = "����", szDesc = "<text>text=\"����������ɽ�ϵ�һ������Ʈ�ݵ����ɡ�\""},		
		[47] = {szName = "����", szDesc = "<text>text=\"һ��������֮�󣬼̳�л������־����֯��\""},		
		[48] = {szName = "��Ԫ��", szDesc = "<text>text=\"��Ϣ����֮�£�Ǳ��ն�֮�У�������֪������������\""},		
		[49] = {szName = "���˹�", szDesc = "<text>text=\"���Զ�Ϊ���޾��������ǵľۼ�֮�ء�\""},		
		[50] = {szName = "������", szDesc = "<text>text=\"��Զ��˹ȶ����⽨���Ľ������ˣ��Գ��׳���Ϊ���Ρ�\""},		
				
				
		[54] = {szName = "�����̻�", szDesc = "<text>text=\"��Ծ�ڴ��ƹ�����ԭ���������̻ᡣ\""},		
		[43] = {szName = "�����̻�", szDesc = "<text>text=\"��Ծ�ڴ��ƽ����Լ����ϴ󲿷ֵ������̻ᡣ\""},		
		[55] = {szName = "�����̻�", szDesc = "<text>text=\"��Ծ��˿��֮·���ߺ�������������̻ᡣ\""},		
		[56] = {szName = "�����̻�", szDesc = "<text>text=\"��Ծ�ڴ��������Լ�������������̻ᡣ\""},		
				
		[42] = {szName = "�ھ�����", szDesc = "<text>text=\"Ϊ�ֿ�ʮ����������������ھ����ˡ�\""},		
		[75] = {szName = "�ٱ���", szDesc = "<text>text=\"�����ڴ��Ƹ��أ�ר���Ѽ����¸��౦���������֯ \""},		
		[82] = {szName = "��ԯ��", szDesc = "<text>text=\"����߸��쵼�Ľ�����֯��ר�ŵ�����گ���ơ� \""},		
		[83] = {szName = "�ؾ���", szDesc = "<text>text=\"����Ϊ�˴��ǻ�������׷���׽��ר����ǲ�ĸ��֣���Զǧ���������ϡ� \""},		
		[84] = {szName = "�Ե�", szDesc = "<text>text=\"Ϊ���һؾ��������࣬�Ե�Ҳ��ǲ���ڶྫ�������� \""},		
		[85] = {szName = "����", szDesc = "<text>text=\"����گ��ƽ�ٶμ�κһ�ִ��������������ֺպ������� \""},		
		[86] = {szName = "����", szDesc = "<text>text=\"�����Ŵ�С���������쵼��һ�������һ���Ⱥ���������ʿ�� \""},		
		[87] = {szName = "ף�ڵ�", szDesc = "<text>text=\"�嶾�̷ֲ���ר�Ÿ��������ڲ����ˡ� \""},		
		[88] = {szName = "��������", szDesc = "<text>text=\"���������ң�Ϊ����һ�ԣ�����һ���� \""},		
		[89] = {szName = "�ݻ��", szDesc = "<text>text=\"��Դ�ڲ�˹��������֯���� \""},		
		[90] = {szName = "������", szDesc = "<text>text=\"��������֮�����������岿��ľ������䡣 \""},		
		[91] = {szName = "�����ھ�", szDesc = "<text>text=\"�ھ����������ϵķֶ档 \""},	
		[93] = {szName = "�������ڣ", szDesc = "<text>text=\"����һ��֮�е�ȫ����Ա���Ǳ�ʬ��֮������֮�ˣ�Ϊ�����������׺������һ���������мҲ��ܻأ���Ը����Բ�����鲻���ߵ��޾�����������е�����˶�����һ��ʹ����ǣ�������һ�Կ��ľ����У��������ɶ�����һǿ����Χ������ȥ�ˣ�ʣ�������Ϊ���Ǵ�������ڣ�������ǵ����ֺ�����Ϊ��֮ʱ����ƽ������¼֮�У�������Ϊ���Ǹ���\""},			
		},			
				
	tReputationLevelTable =			
	{			
		--szLevel �ȼ���Ӧ����ʾ���֣� nFont����, nFrame--������ͼƬ֡		
		[0] = {szLevel = "���", nFont = 166, nFrame = 40},		
		[1] = {szLevel = "����", nFont = 166, nFrame = 40},		
		[2] = {szLevel = "��Զ", nFont = 162, nFrame = 38},		
		[3] = {szLevel = "����", nFont = 162, nFrame = 38},		
		[4] = {szLevel = "�Ѻ�", nFont = 165, nFrame = 39},		
		[5] = {szLevel = "����", nFont = 165, nFrame = 39},		
		[6] = {szLevel = "����", nFont = 165, nFrame = 39},		
		[7] = {szLevel = "��", nFont = 165, nFrame = 39},		
		[8] = {szLevel = "����", nFont = 165, nFrame = 39},		
		[9] = {szLevel = "�Ժ�", nFont = 165, nFrame = 39},		
		[10] = {szLevel = "�羴", nFont = 163, nFrame = 79},		
		[11] = {szLevel = "���", nFont = 163, nFrame = 79},		
		[12] = {szLevel = "��˵", nFont = 163, nFrame = 79},		
	},
}

function RaidGrid_CTM_Edition.OpenRaidDragPanel(dwMemberID)
	local hTeam = GetClientTeam()
	local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
	if not tMemberInfo then
		return
	end
	
	local hFrame = Wnd.OpenWindow("RaidDragPanel")
	
	local nX, nY = Cursor.GetPos()
	hFrame:SetAbsPos(nX, nY)
	hFrame:StartMoving()
	
	hFrame.dwID = dwMemberID
	local hMember = hFrame:Lookup("", "")
	
	local szPath, nFrame = GetForceImage(tMemberInfo.dwForceID)
	hMember:Lookup("Image_Force"):FromUITex(szPath, nFrame)
	
	local hTextName = hMember:Lookup("Text_Name")
	hTextName:SetText(tMemberInfo.szName)
	
	local hImageLife = hMember:Lookup("Image_Health")
	local hImageMana = hMember:Lookup("Image_Mana")
	if tMemberInfo.bIsOnLine then
		if tMemberInfo.nMaxLife > 0 then
			hImageLife:SetPercentage(tMemberInfo.nCurrentLife / tMemberInfo.nMaxLife)
		end
		if tMemberInfo.nMaxMana > 0 and tMemberInfo.nMaxMana ~= 1 then
			hImageMana:SetPercentage(tMemberInfo.nCurrentMana / tMemberInfo.nMaxMana)
		end
	else
		hImageLife:SetPercentage(0)
		hImageMana:SetPercentage(0)
	end
	
	hMember:Show()
end

function RaidGrid_CTM_Edition.CloseRaidDragPanel()
	local hFrame = Station.Lookup("Normal/RaidDragPanel")
	if hFrame then
		hFrame:EndMoving()
		Wnd.CloseWindow(hFrame)
	end
end

function RaidGrid_CTM_Edition.EditBox_AppendLinkPlayer(szPlayerName)
	local frame = Station.Lookup("Lowest2/EditBox")
	if not frame or not frame:IsVisible() then
		return false
	end

	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	edit:InsertObj("["..szPlayerName.."]", {type = "name", text = "["..szPlayerName.."]", name = szPlayerName})
	
	Station.SetFocusWindow(edit)
	return true
end
