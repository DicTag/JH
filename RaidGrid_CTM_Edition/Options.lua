RaidGrid_CTM_Edition = RaidGrid_CTM_Edition or {}
RaidGrid_CTM_Edition.bAltNeededForDrag = true;						RegisterCustomData("RaidGrid_CTM_Edition.bAltNeededForDrag")
RaidGrid_CTM_Edition.bRaidEnable = true;							RegisterCustomData("RaidGrid_CTM_Edition.bRaidEnable")
RaidGrid_CTM_Edition.bShowRaid = true;								RegisterCustomData("RaidGrid_CTM_Edition.bShowRaid")
RaidGrid_CTM_Edition.bShowInRaid = false;							RegisterCustomData("RaidGrid_CTM_Edition.bShowInRaid")
RaidGrid_CTM_Edition.bShowSystemRaidPanel = false;					RegisterCustomData("RaidGrid_CTM_Edition.bShowSystemRaidPanel")
RaidGrid_CTM_Edition.bShowSystemTeamPanel = false;					RegisterCustomData("RaidGrid_CTM_Edition.bShowSystemTeamPanel")
RaidGrid_CTM_Edition.tAnchor = {};									RegisterCustomData("RaidGrid_CTM_Edition.tAnchor")
RaidGrid_CTM_Edition.nAutoLinkMode = 5;								RegisterCustomData("RaidGrid_CTM_Edition.nAutoLinkMode")
RaidGrid_CTM_Edition.bShowAllPanel = false;							RegisterCustomData("RaidGrid_CTM_Edition.bShowAllPanel")
RaidGrid_CTM_Edition.bShowAllMemberGrid = false;					RegisterCustomData("RaidGrid_CTM_Edition.bShowAllMemberGrid")
RaidGrid_CTM_Edition.nHPShownMode2 = 2;								RegisterCustomData("RaidGrid_CTM_Edition.nHPShownMode2")
RaidGrid_CTM_Edition.nHPShownNumMode = 1;							RegisterCustomData("RaidGrid_CTM_Edition.nHPShownNumMode")
RaidGrid_CTM_Edition.nShowMP = false;								RegisterCustomData("RaidGrid_CTM_Edition.nShowMP")
RaidGrid_CTM_Edition.bLowMPBar = true;								RegisterCustomData("RaidGrid_CTM_Edition.bLowMPBar")
RaidGrid_CTM_Edition.bHPHitAlert = true;							RegisterCustomData("RaidGrid_CTM_Edition.bHPHitAlert")
RaidGrid_CTM_Edition.bColoredName = true;							RegisterCustomData("RaidGrid_CTM_Edition.bColoredName")
RaidGrid_CTM_Edition.bColoredGrid = false;							RegisterCustomData("RaidGrid_CTM_Edition.bColoredGrid")
RaidGrid_CTM_Edition.bShowIcon = 2;									RegisterCustomData("RaidGrid_CTM_Edition.bShowIcon")
RaidGrid_CTM_Edition.bShowDistance = false;							RegisterCustomData("RaidGrid_CTM_Edition.bShowDistance")
RaidGrid_CTM_Edition.bColorHPBarWithDistance = true;				RegisterCustomData("RaidGrid_CTM_Edition.bColorHPBarWithDistance")
RaidGrid_CTM_Edition.bShowTargetTargetAni = true;					RegisterCustomData("RaidGrid_CTM_Edition.bShowTargetTargetAni")

function RaidGrid_CTM_Edition.IsLeader()
	local hTeam = GetClientTeam()
	local hPlayer = GetClientPlayer()
	return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID
end
local IsLeader = RaidGrid_CTM_Edition.IsLeader
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

function RaidGrid_CTM_Edition.PopOptions()
	local me = GetClientPlayer()
	local team = GetClientTeam()
	local dwDistribute = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
	local menu = {}
	-- �ŶӾ�λ
	table.insert(menu, { szOption = g_tStrings.STR_RAID_MENU_READY_CONFIRM, 
		{ szOption = g_tStrings.STR_RAID_READY_CONFIRM_START, bDisable = not IsLeader(), fnAction = RaidGrid_Party.InitReadyCheckCover },
		{ szOption = g_tStrings.STR_RAID_READY_CONFIRM_RESET, bDisable = not IsLeader(), fnAction = RaidGrid_Party.ClearReadyCheckCover }
	})
	table.insert(menu, { bDevide = true })
	-- ����
	InsertDistributeMenu(menu, me.dwID ~= dwDistribute)
	table.insert(menu, { bDevide = true })
	-- �༭ģʽ
	table.insert(menu, { szOption = string.gsub(g_tStrings.STR_RAID_MENU_RAID_EDIT, "Ctrl", "Alt"), bDisable = not IsLeader() or not me.IsInRaid(), bCheck = true, bChecked = not RaidGrid_CTM_Edition.bAltNeededForDrag, fnAction = function() 
		RaidGrid_CTM_Edition.bAltNeededForDrag = not RaidGrid_CTM_Edition.bAltNeededForDrag
		GetPopupMenu():Hide()
	end })
	-- ����ģʽ
	table.insert(menu, { szOption = g_tStrings.STR_RAID_TARGET_ASSIST, bCheck = true, bChecked = RaidGrid_Party.bTempTargetEnable, fnAction = function() RaidGrid_Party.bTempTargetEnable = not RaidGrid_Party.bTempTargetEnable end,
		{ szOption = "ս���в���ʾTIP��Ϣ", bCheck = true, bChecked = RaidGrid_Party.bTempTargetFightTip, fnDisable = function() return not RaidGrid_Party.bTempTargetEnable end, fnAction = function()
			RaidGrid_Party.bTempTargetFightTip = not RaidGrid_Party.bTempTargetFightTip
		end	}
	})
	table.insert(menu, { bDevide = true })
	-- ���Ѵ���
	table.insert(menu, { szOption = g_tStrings.STR_RAID_TIP_IMAGE,
		{ szOption = g_tStrings.STR_RAID_TIP_TARGET, bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowTargetTargetAni, fnAction = function()
			RaidGrid_CTM_Edition.bShowTargetTargetAni = not RaidGrid_CTM_Edition.bShowTargetTargetAni
			RaidGrid_Party.RedrawTargetSelectImage()
		end },
		{ szOption = "��ʾ����", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowDistance, fnAction = function()
			RaidGrid_CTM_Edition.bShowDistance = not RaidGrid_CTM_Edition.bShowDistance
			RaidGrid_Party.ReloadRaidPanel()
		end },
		{ szOption = "������������ʾ������������", bCheck = true, bChecked = RaidGrid_CTM_Edition.bHPHitAlert, fnAction = function()
			RaidGrid_CTM_Edition.bHPHitAlert = not RaidGrid_CTM_Edition.bHPHitAlert
			RaidGrid_Party.RedrawAllFadeHP(true)
		end }
	})
	
	table.insert(menu, { bDevide = true })
	table.insert(menu, { szOption = g_tStrings.STR_RAID_LIFE_SHOW,
		{ szOption = "Ѫ������ɫ", bCheck = true, bChecked = not RaidGrid_Party.Shadow.bLife, fnAction = function()
			RaidGrid_Party.Shadow.bLife = not RaidGrid_Party.Shadow.bLife
		end	},
		{ szOption = "��������ɫ", bCheck = true, bChecked = not RaidGrid_Party.Shadow.bMana, fnAction = function()
			RaidGrid_Party.Shadow.bMana = not RaidGrid_Party.Shadow.bMana
		end	},
		{ szOption = "��ϸ������", bCheck = true, bChecked = RaidGrid_CTM_Edition.bLowMPBar, fnAction = function()
			RaidGrid_CTM_Edition.bLowMPBar = not RaidGrid_CTM_Edition.bLowMPBar
		end	},
		{ szOption = "͸��������", fnAction = function()
			local x, y = Cursor.GetPos()
			GetUserPercentage(function(val)
				RaidGrid_Party.Shadow.a = tonumber(val) * 255
				Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
			end, nil, RaidGrid_Party.Shadow.a / 255, g_tStrings.STR_ALPHA .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 })
		end	},
		{ bDevide = true },
		{ szOption = "��ʾ����", bCheck = true, bChecked = RaidGrid_CTM_Edition.nShowMP, fnAction = function()
			RaidGrid_CTM_Edition.nShowMP = not RaidGrid_CTM_Edition.nShowMP
			RaidGrid_Party.ReloadRaidPanel()
		end	},
		{ bDevide = true },
		{ szOption = g_tStrings.STR_RAID_LIFE_LEFT, bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownMode2 == 2, fnAction = function()
			RaidGrid_CTM_Edition.nHPShownMode2 = 2
			RaidGrid_Party.ReloadRaidPanel()
		end	},
		{ szOption = g_tStrings.STR_RAID_LIFE_LOSE, bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownMode2 == 1, fnAction = function()
			RaidGrid_CTM_Edition.nHPShownMode2 = 1
			RaidGrid_Party.ReloadRaidPanel()
		end	},
		{ bDevide = true },
		{ szOption = "��ʾ����Ѫ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownNumMode == 1, fnAction = function()
			RaidGrid_CTM_Edition.nHPShownNumMode = 1
			RaidGrid_Party.ReloadRaidPanel()
		end	},
		{ szOption = "��ʾ�ٷֱ�Ѫ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownNumMode == 2, fnAction = function()
			RaidGrid_CTM_Edition.nHPShownNumMode = 2
			RaidGrid_Party.ReloadRaidPanel()
		end	},
		{ szOption = "��ʾ������ֵ", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownNumMode == 3, fnAction = function()
			RaidGrid_CTM_Edition.nHPShownNumMode = 3
			RaidGrid_Party.ReloadRaidPanel()
		end	},
		{ bDevide = true },
		{ szOption = g_tStrings.STR_RAID_LIFE_HIDE, bMCheck = true, bChecked = RaidGrid_CTM_Edition.nHPShownMode2 == 0, fnAction = function()
			RaidGrid_CTM_Edition.nHPShownMode2 = 0
			RaidGrid_Party.ReloadRaidPanel()
		end	},
	})
	table.insert(menu, { szOption = "ͼ������ɫ",
		{ szOption = g_tStrings.STR_RAID_COLOR_NAME_SCHOOL, bCheck = true, bChecked = RaidGrid_CTM_Edition.bColoredName, fnAction = function()
			RaidGrid_CTM_Edition.bColoredName = not RaidGrid_CTM_Edition.bColoredName
			RaidGrid_Party.ReloadRaidPanel()
		end	},		
		{ szOption = "�߿����������ɫ����ʱ��Ч��", bCheck = true, bChecked = RaidGrid_CTM_Edition.bColoredGrid, fnAction = function()
			RaidGrid_CTM_Edition.bColoredGrid = not RaidGrid_CTM_Edition.bColoredGrid
			RaidGrid_Party.ReloadRaidPanel()
		end	},
		{ bDevide = true },
		{ szOption = "��ʾ����ͼ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.bShowIcon == 1, fnAction = function()
			RaidGrid_CTM_Edition.bShowIcon = 1
			RaidGrid_Party.ReloadRaidPanel()
		end	},
		{ szOption = g_tStrings.STR_SHOW_KUNGFU, bMCheck = true, bChecked = RaidGrid_CTM_Edition.bShowIcon == 2, fnAction = function()
			RaidGrid_CTM_Edition.bShowIcon = 2
			RaidGrid_Party.ReloadRaidPanel()
		end	},
		{ szOption = "��ʾ��Ӫͼ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.bShowIcon == 3, fnAction = function()
			RaidGrid_CTM_Edition.bShowIcon = 3
			RaidGrid_Party.ReloadRaidPanel()
		end	},
	})
	
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
	local tDistanceMenu = { szOption = g_tStrings.STR_RAID_DISTANCE, bCheck = true, bChecked = RaidGrid_CTM_Edition.bColorHPBarWithDistance, fnAction = function() 
		RaidGrid_CTM_Edition.bColorHPBarWithDistance = not RaidGrid_CTM_Edition.bColorHPBarWithDistance
		RaidGrid_Party.ReloadRaidPanel() 
	end	}
	for j = 1, 5 do
		local tD, nDist = GetDistTable(j)
		local tC, szNameC, nR, nG, nB = GetColorTable(j)
		local szDist = tostring(nDist)
		szDist = ("_"):rep(3 - #szDist) .. szDist
		table.insert(tDistanceMenu, { szOption = "С�� " .. szDist .. "����Ϊ��" .. szNameC, fnDisable = function() return not RaidGrid_CTM_Edition.bColorHPBarWithDistance end,tD, tC, rgb = { nR, nG, nB }} )
	end

	
	table.insert(menu, tDistanceMenu)
	table.insert(menu, { bDevide = true })
	table.insert(menu, { szOption = "����ģʽ",
		{ szOption = "һ�У�����/����", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 5, fnAction = function()
			RaidGrid_CTM_Edition.nAutoLinkMode = 5
			RaidGrid_Party.ReloadRaidPanel()
		end },
		{ szOption = "���У�һ��/����", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 1, fnAction = function()
			RaidGrid_CTM_Edition.nAutoLinkMode = 1
			RaidGrid_Party.ReloadRaidPanel()
		end },
		{ szOption = "���У�����/����", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 2, fnAction = function()
			RaidGrid_CTM_Edition.nAutoLinkMode = 2
			RaidGrid_Party.ReloadRaidPanel()
		end },
		{ szOption = "���У�����/����", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 3, fnAction = function()
			RaidGrid_CTM_Edition.nAutoLinkMode = 3
			RaidGrid_Party.ReloadRaidPanel()
		end },
		{ szOption = "���У�����/һ��", bMCheck = true, bChecked = RaidGrid_CTM_Edition.nAutoLinkMode == 4, fnAction = function()
			RaidGrid_CTM_Edition.nAutoLinkMode = 4
			RaidGrid_Party.ReloadRaidPanel()
		end },	
	})
	table.insert(menu, { szOption = g_tStrings.WINDOW_ADJUST_SCALE,
		{ szOption = "��ԭΪĬ�� 1:1", bCheck = false, bChecked = false, fnAction = function()
			RaidGrid_Party.fScaleX = 1
			RaidGrid_Party.fScaleY = 1
			RaidGrid_Party.fScaleFont = 1
			RaidGrid_Party.fScaleIcon = 1
			RaidGrid_Party.fScaleShadowX = 1
			RaidGrid_Party.fScaleShadowY = 1
			RaidGrid_Party.ReloadRaidPanel()
		end },
		{ bDevide = true },
		{ szOption = "�Ŷӽ��桾��ȡ�����", fnAction = function()
			local x, y = Cursor.GetPos()
			local fScaleX = RaidGrid_Party.fScaleX
			GetUserPercentage(function(val)
				RaidGrid_Party.fScaleX = tonumber(val)
				RaidGrid_Party.ReloadRaidPanel()
				Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
			end, nil, (fScaleX - 0.5) / 1.00, "���" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
		end	},
		{ szOption = "�Ŷӽ��桾�߶ȡ�����", fnAction = function()
			local x, y = Cursor.GetPos()
			local fScaleY = RaidGrid_Party.fScaleY
			GetUserPercentage(function(val)
				RaidGrid_Party.fScaleY = tonumber(val)
				RaidGrid_Party.ReloadRaidPanel()
				Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
			end, nil, (fScaleY - 0.5) / 1.00, "�߶�" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
		end },
		{ szOption = "�Ŷӽ��桾���ִ�С������", fnAction = function()
			local x, y = Cursor.GetPos()
			local fScaleFont = RaidGrid_Party.fScaleFont
			GetUserPercentage(function(val)
				RaidGrid_Party.fScaleFont = tonumber(val)
				RaidGrid_Party.ReloadRaidPanel()
				Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
			end, nil, (fScaleFont - 0.5) / 1.00, "���ִ�С" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
		end },
		{ szOption = "�Ŷӽ��桾buffͼ�꡿����", fnAction = function()
			local x, y = Cursor.GetPos()
			local fScaleIcon = RaidGrid_Party.fScaleIcon
			GetUserPercentage(function(val)
				RaidGrid_Party.fScaleIcon = tonumber(val)
				RaidGrid_Party.ReloadRaidPanel()
				Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
			end, nil, (fScaleIcon - 0.5) / 1.00, "BUFF��С" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
		end	},
		{ szOption = "�Ŷӽ��桾buff����ɫ����ȱ���", fnAction = function()
			local x, y = Cursor.GetPos()
			local fScaleShadowX = RaidGrid_Party.fScaleShadowX
			GetUserPercentage(function(val)
				RaidGrid_Party.fScaleShadowX = tonumber(val)
				RaidGrid_Party.ReloadRaidPanel()
				Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
			end, nil, (fScaleShadowX - 0.5) / 1.00, "BUFF����ɫ���" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
		end },
		{ szOption = "�Ŷӽ��桾buff����ɫ���߶ȱ���", fnAction = function()
			local x, y = Cursor.GetPos()
			local fScaleShadowY = RaidGrid_Party.fScaleShadowY
			GetUserPercentage(function(val)
				RaidGrid_Party.fScaleShadowY = tonumber(val)
				RaidGrid_Party.ReloadRaidPanel()
				Station.Lookup("Normal/GetPercentagePanel"):BringToTop()
			end, nil, (fScaleShadowY - 0.5) / 1.00, "BUFF����ɫ�߶�" .. g_tStrings.STR_COLON, { x, y, x + 1, y + 1 }, nil, { StartValue = 50, nStepCount = 100 })
		end },
	})
	table.insert(menu, { bDevide = true })
	table.insert(menu, { szOption = g_tStrings.OTHER,
		{ szOption = "����", bCheck = true, bChecked = RaidGrid_CTM_Edition.bRaidEnable, fnAction = function(UserData, bCheck)
			RaidGrid_CTM_Edition.bRaidEnable = bCheck
			RaidGrid_CTM_Edition.bShowRaid = bCheck
			RaidGrid_Party.ReloadRaidPanel()
		end },
		{ szOption = "ֻ���Ŷ�ʱ����ʾ", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowInRaid, fnAction = function(UserData, bCheck)
			RaidGrid_CTM_Edition.bShowInRaid = bCheck
			RaidGrid_Party.ReloadRaidPanel()
		end },
		{ bDevide = true },
		{ szOption = "����ϵͳ�Ŷ����", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowSystemRaidPanel, fnAction = function(UserData, bCheck)
			RaidGrid_CTM_Edition.bShowSystemRaidPanel = bCheck
			RaidGrid_CTM_Edition.RaidPanel_Switch(bCheck)
		end },
		{ szOption = "����ϵͳС�����", bCheck = true, bDisable = me.IsInRaid(), bChecked = RaidGrid_CTM_Edition.bShowSystemTeamPanel, fnAction = function(UserData, bCheck)
			RaidGrid_CTM_Edition.bShowSystemTeamPanel = bCheck
			RaidGrid_CTM_Edition.TeammatePanel_Switch(bCheck)
		end },		
	})
	-- ����ͳ��
	if me.IsInRaid() then
		table.insert(menu, { bDevide = true })
		RaidGrid_CTM_Edition.InsertForceCountMenu(menu)
	end
	local nX, nY = Cursor.GetPos(true)
	menu.x, menu.y = nX + 15, nY + 15
	PopupMenu(menu)
	
end
			-- {
				-- szOption = "��������ʾ������С�Ӹ���", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowAllMemberGrid, fnAction = function(UserData, bCheck)
					-- RaidGrid_CTM_Edition.bShowAllMemberGrid = bCheck
					-- RaidGrid_Party.ReloadRaidPanel()
				-- end,
			-- },
			-- {
				-- szOption = "��������ʾ�����Ŷ����", bCheck = true, bChecked = RaidGrid_CTM_Edition.bShowAllPanel, fnAction = function(UserData, bCheck)
					-- RaidGrid_CTM_Edition.bShowAllPanel = bCheck
					-- RaidGrid_Party.ReloadRaidPanel()
				-- end,
			-- },
function RaidGrid_CTM_Edition.InsertForceCountMenu(tMenu)
	local tForceList = {}
	local hTeam = GetClientTeam()
	local nCount = 0
	for nGroupID = 0, hTeam.nGroupNum - 1 do
		local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
		for _, dwMemberID in ipairs(tGroupInfo.MemberList) do
			local tMemberInfo = hTeam.GetMemberInfo(dwMemberID)
			if not tForceList[tMemberInfo.dwForceID] then
				tForceList[tMemberInfo.dwForceID] = 0
			end
			tForceList[tMemberInfo.dwForceID] = tForceList[tMemberInfo.dwForceID] + 1
		end
		nCount = nCount + #tGroupInfo.MemberList
	end
	local tSubMenu = { szOption = g_tStrings.STR_RAID_MENU_FORCE_COUNT ..
		FormatString(g_tStrings.STR_ALL_PARENTHESES, nCount)
	}
	for dwForceID, nCount in pairs(tForceList) do
		local szPath, nFrame = GetForceImage(dwForceID)
		table.insert(tSubMenu, { 
			szOption = g_tStrings.tForceTitle[dwForceID] .. "   " .. nCount,
			rgb = { JH.GetForceColor(dwForceID) },
			szIcon = szPath,
			nFrame = nFrame,
			szLayer = "ICON_LEFT"
		})
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
	local hTeam = GetClientTeam()
	local tMemberInfo = hTeam.GetMemberInfo(dwID)
	if not tMemberInfo then
		return
	end
	local r, g, b = JH.GetForceColor(tMemberInfo.dwForceID)
	local szPath, nFrame = GetForceImage(tMemberInfo.dwForceID)
	local szTip = GetFormatImage(szPath, nFrame, 24, 24)
    szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_NAME_PLAYER, tMemberInfo.szName), 80, r, g, b)
    if tMemberInfo.bIsOnLine then
    	szTip = szTip .. GetFormatText(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, tMemberInfo.nLevel), 82)
		local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
		if szMapName then
			szTip = szTip .. GetFormatText(szMapName .. "\n", 82)
		end
        
        local nCamp = tMemberInfo.nCamp
        szTip = szTip .. GetFormatText(g_tStrings.STR_GUILD_CAMP_NAME[nCamp] .. "\n", 82)
    else
    	szTip = szTip .. GetFormatText(g_tStrings.STR_FRIEND_NOT_ON_LINE .. "\n", 82, 128, 128, 128)
    end
    if IsCtrlKeyDown() then
    	szTip = szTip .. GetFormatText(FormatString(g_tStrings.TIP_PLAYER_ID, dwID), 102)
    end	
    OutputTip(szTip, 345, rc)
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
		r, g, b = 126, 126, 255
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
	hFrame:BringToTop()
end

function RaidGrid_CTM_Edition.CloseRaidDragPanel()
	local hFrame = Station.Lookup("Normal/RaidDragPanel")
	if hFrame then
		hFrame:EndMoving()
		Wnd.CloseWindow(hFrame)
	end
end

function RaidGrid_CTM_Edition.EditBox_AppendLinkPlayer(szName)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	edit:InsertObj("[" .. szName .. "]", { type = "name", text = "[" .. szName .. "]", name = szName})
	Station.SetFocusWindow(edit)
end
