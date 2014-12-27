local _L = JH.LoadLangPack
-- ��������������
-- 1) ��ͨ��Ҹ��ݸ������ض�Ӧ���ݣ�ÿһ����������ͼ��������15�����ݣ�4Сʱ���������һ�����ݣ��粻������û�д����ơ�
-- 2) �����ֶ���Ӻ�ɾ�����ݣ���ÿ������ͼ����������Ҳ������15�������Ը���BOSS����ÿ��BOSS �����ݡ�
-- 3) ����һ��Ȧ������alphaΪ50�����ݰ뾶�𲽽���alpha�������߿�alphaΪ140��
-- 4) �����ṩ�Ƕ�Ϊ1��Ŀ���ߣ������ṩĿ�����ֻ��ƹ��ܣ������ṩĿ���Ŀ��ע��ʱ�䵹��ʱ��
-- 5) ���Լ����Լ���Ŀ���⣬��ֹ��������һ�����Ȧ��
-- 6) ���е�׷����ͳһΪ140 alpha��
-- 7) �����ⲻ�����ƣ�����ץ���ץ��
-- 8) ���鿪�Ų��ָ�����������������Ѫս��ߵȡ�
-- 9) ȥ���������ݵĹ��ܡ�
-- ����һ�н���������ż಻��Ӱ�졣

-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
local reverse, type = string.reverse, type
local AscIIEncode, AscIIDecode = JH.AscIIEncode, JH.AscIIDecode
local JsonEncode, JsonDecode = JH.JsonEncode, JH.JsonDecode
local IsRemotePlayer, UI_GetClientPlayerID = IsRemotePlayer, UI_GetClientPlayerID
-- ȫ�ֳ��� ������󲿷ֲ��ܴ�����
local GLOBAL_MAX_COUNT = 15 -- Ĭ�ϸ������������
local GLOBAL_CHANGE_TIME = 7200 -- �������ݺ� �ٴμ������ݵ�ʱ�� 2Сʱ ����һ��BOSSһ������
local GLOBAL_CIRCLE_ALPHA = 50 -- ����͸���� ���ݰ뾶�𲽽��� 
local GLOBAL_MAX_RADIUS = 15 -- ���İ뾶
local GLOBAL_LINE_ALPHA = 120 -- �ߺͱ߿����͸����
local GLOBAL_RESERT_DRAW = false
local GLOBAL_CONFUSE_ID
local GLOBAL_DEFAULT_DATA = { nAngle = 80, nRadius = 4, col = { 255, 128, 0 }, bBorder = true }
local GLOBAL_MAP_FIX = { -- ���ָ�����ͼ��������
	[165] = 30, -- Ӣ�۴�����
	[164] = 30, -- ������
	[160] = 20, -- ��е��
	[171] = 20, -- Ӣ�۾�е��
	[175] = 35, -- Ѫս���
	[176] = 35, -- Ӣ��Ѫս���
}
setmetatable(GLOBAL_MAP_FIX, { __index = function()	return GLOBAL_MAX_COUNT end })

local function Confuse(tCode)
	if type(tCode) == "table" then
		return reverse(AscIIEncode(JsonEncode(tCode)))
	else
		return JsonDecode(AscIIDecode(reverse(tCode)))
	end
end
local function GetPlayerID()
	if IsRemotePlayer(UI_GetClientPlayerID()) then
		return AscIIEncode(reverse(99800014 % 1.3677 ^ 57.247))
	else
		GLOBAL_CONFUSE_ID = AscIIEncode(reverse(UI_GetClientPlayerID() % 1.3677 ^ 57.247))
		return GLOBAL_CONFUSE_ID
	end
end

-- ��ȡ����·��
local function GetDataPath()
	local me, szName = GetClientPlayer(), "NONE"
	if me then
		szName = me.szName
	end
	return JH.GetAddonInfo().szDataPath .. "Circle/" .. szName .. "/Circle.jx3dat"
end

local SHADOW = JH.GetAddonInfo().szShadowIni

Circle = {
	bEnable = true,
	bInDungeon = false,
	nLimit = 0,
	bTeamChat = false, -- ����ȫ�ֵ��Ŷ�Ƶ��
	bWhisperChat = false, -- ����ȫ�ֵ�����Ƶ��
}
JH.RegisterCustomData("Circle")

local C = {
	tData = {},
	tCache = {
		[TARGET.NPC] = {},
		[TARGET.DOODAD] = {},
	},
	tList = {
		[TARGET.NPC] = {},
		[TARGET.DOODAD] = {},
	},
	tScrutiny = {
		[TARGET.NPC] = {},
		[TARGET.DOODAD] = {},
	},
	tMapList  = {},
}
for k, v in ipairs(GetMapList()) do
	local szName = Table_GetMapName(v)
	C.tMapList[szName] = { id = v }
	local a = g_tTable.DungeonInfo:Search(v)
	if a and a.dwClassID == 3 then
		C.tMapList[szName]["bDungeon"] = true
	end
end

C.SaveFile = function(szFullPath, bMsg)
	szFullPath = szFullPath or GetDataPath()
	local data = {
		Circle = {},
	}
	for k, v in pairs(C.tData) do -- fix encode
		data.Circle[tostring(k)] = v
	end
	if not bMsg then
		if IsRemotePlayer(UI_GetClientPlayerID()) then
			return
		else
			data.code = GetPlayerID()
		end
	end
	local code = Confuse(data)
	SaveLUAData(szFullPath, code)
	if bMsg then
		JH.Alert(_L("Save success.\n Path:%s", szFullPath))
	end
end

-- ���ر����ļ�ʹ��
C.LoadFile = function(szFullPath, bMsg)
	szFullPath = szFullPath or GetDataPath()
	local code = LoadLUAData(szFullPath)
	if code then
		local data = Confuse(code)
		if type(data) == "table" then
			C.LoadCircleData(data, bMsg)
		else
			if bMsg then
				JH.Sysmsg2(_L["content errors."])
			end
		end
	else
		if bMsg then
			JH.Sysmsg2(_L["File does not exist, or content errors."])
		end
	end
end

-- �������ݻ���ʹ��ͬһ������
-- �ϸ��ж����� ��table
C.LoadCircleData = function(tData, bMsg)
	local data = {}
	if not bMsg then
		if IsRemotePlayer(UI_GetClientPlayerID()) or tData.code ~= GetPlayerID() then
			return JH.RegisterEvent("LOADING_END.LoadCircleData", C.LoadFile)
		end
		JH.UnRegisterEvent("LOADING_END.LoadCircleData")
	else
		if GetCurrentTime() - Circle.nLimit < GLOBAL_CHANGE_TIME then
			return JH.Sysmsg2(_L["Too frequent load file"])
		end
	end
	for k, v in pairs(tData.Circle) do
		local map = C.tMapList[tonumber(k)]
		if map and map.bDungeon then
			if #v < GLOBAL_MAP_FIX[tonumber(k)] then
				data[tonumber(k)] = v
			else
				JH.Debug2(_L["Length limit. # "] .. k)
			end
		else
			data[tonumber(k)] = v
		end
	end
	C.tData = data
	pcall(C.CreateData)
	if bMsg then
		JH.Sysmsg2(_L["Circle loaded."])
	end
end

C.GetMapID = function()
	return GetClientPlayer().GetMapID()
end

C.Release = function()
	C.tScrutiny = {
		[TARGET.NPC] = {},
		[TARGET.DOODAD] = {},
	}
	C.tList = {
		[TARGET.NPC] = {},
		[TARGET.DOODAD] = {},
	}
	C.tCache = {
		[TARGET.NPC] = {},
		[TARGET.DOODAD] = {},
	}
	-- ȡ������
	C.shCircle = JH.GetShadowHandle("Handle_Shadow_Circle")
	C.shCircle:Clear()
	C.shLine = JH.GetShadowHandle("Handle_Shadow_Line")
	C.shLine:Clear()
	C.shName = JH.GetShadowHandle("Handle_Shadow_Name"):AppendItemFromIni(SHADOW, "shadow", "Circle_NAME")
	C.shName:SetTriangleFan(GEOMETRY_TYPE.TEXT)
end

C.CreateData = function()
	pcall(C.Release)
	local mapid = C.GetMapID()
	for k, v in ipairs(C.tData[mapid] or {}) do
		C.tList[v.dwType][v.key] = {}
		setmetatable(C.tList[v.dwType][v.key], { __call = function()
			return C.tData[mapid][k]
		end })
	end
	for k, v in pairs(JH.GetAllNpc()) do
		local t = C.tList[TARGET.NPC][v.dwTemplateID] or C.tList[TARGET.NPC][JH.GetTemplateName(v)]
		if t then
			C.tScrutiny[TARGET.NPC][v.dwID] = t
		end
	end
	for k, v in pairs(JH.GetAllDoodad()) do
		local t = C.tList[TARGET.DOODAD][v.dwTemplateID] or C.tList[TARGET.DOODAD][JH.GetTemplateName(v)]
		if t then
			C.tScrutiny[TARGET.DOODAD][v.dwID] = t
		end
	end
end

C.DrawLine = function(tar, ttar, sha, col, dwType)
	sha:SetTriangleFan(GEOMETRY_TYPE.LINE, 3)
	sha:ClearTriangleFanPoint()
	local r, g, b = unpack(col)
	if dwType == TARGET.DOODAD then
		sha:AppendDoodadID(tar.dwID, r, g, b, GLOBAL_LINE_ALPHA)
	else
		sha:AppendCharacterID(tar.dwID, true, r, g, b, GLOBAL_LINE_ALPHA)
	end
	sha:AppendCharacterID(ttar.dwID, true, r, g, b, GLOBAL_LINE_ALPHA)
	sha:Show()
end

C.DrawShape = function(tar, sha, nAngle, nRadius, col, dwType)
	nRadius = nRadius * 64
	local nFace = math.ceil(128 * nAngle / 360)
	local dwRad1 = math.pi * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - math.pi - math.pi
	end
	local dwRad2 = dwRad1 + (nAngle / 180 * math.pi)
	local nStep = 18
	if nAngle == 360 then
		dwRad2 = dwRad2 + math.pi / 20
	end
	if nAngle <= 45 then nStep = 180 end
	local nAlpha = GLOBAL_CIRCLE_ALPHA - 2.5 * (nRadius / 64)
	local r, g, b = unpack(col)
	-- orgina point
	sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	sha:SetD3DPT(D3DPT.TRIANGLEFAN)
	sha:ClearTriangleFanPoint()
	if dwType == TARGET.DOODAD then
		sha:AppendDoodadID(tar.dwID, r, g, b, nAlpha)
	else
		sha:AppendCharacterID(tar.dwID, false, r, g, b, nAlpha)
	end
	sha:Show()
	-- relative points
	local sX, sZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	repeat
		local sX_, sZ_ = Scene_PlaneGameWorldPosToScene(tar.nX + math.cos(dwRad1) * nRadius, tar.nY + math.sin(dwRad1) * nRadius)
		if dwType == TARGET.DOODAD then
			sha:AppendDoodadID(tar.dwID, r, g, b, nAlpha, { sX_ - sX, 0, sZ_ - sZ })
		else
			sha:AppendCharacterID(tar.dwID, false, r, g, b, nAlpha, { sX_ - sX, 0, sZ_ - sZ })
		end
		dwRad1 = dwRad1 + math.pi / nStep
	until dwRad1 > dwRad2
end

C.DrawBorderCall = function(tar, sha, nAngle, nRadius, col, dwType)
	nRadius = nRadius * 64
	local nThick = 1 + (5 * nRadius / 64 / 20)
	local dwMaxRad = nAngle / 180 * math.pi
	local nFace = math.ceil(128 * nAngle / 360)
	local dwRad1 = math.pi * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - math.pi - math.pi
	end	
	local dwStepRadBase = nRadius / 128
	if dwStepRadBase < 2 then
		dwStepRadBase = 2
	end
	local dwStepRad = dwMaxRad / (nRadius / dwStepRadBase)
	local dwCurRad = 0 - dwStepRad
	local sX, sZ = Scene_PlaneGameWorldPosToScene(tar.nX, tar.nY)
	local r, g, b = unpack(col)
	sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
	sha:SetD3DPT(D3DPT.TRIANGLESTRIP)
	sha:ClearTriangleFanPoint()
	repeat
		local tRad = {}
		tRad[1] = { nRadius, dwCurRad }
		tRad[2] = { nRadius - nThick, dwCurRad }
		for _, v in ipairs(tRad) do
			local nX = tar.nX + math.cos((v[2] + dwRad1)) * v[1]
			local nY = tar.nY + math.sin((v[2] + dwRad1)) * v[1]
			local sX_,sZ_ = Scene_PlaneGameWorldPosToScene(nX ,nY)
			if dwType == TARGET.DOODAD then
				sha:AppendDoodadID(tar.dwID, r, g, b, GLOBAL_LINE_ALPHA, { sX_ - sX, 0, sZ_ - sZ })
			else
				sha:AppendCharacterID(tar.dwID, false, r, g, b, GLOBAL_LINE_ALPHA, { sX_ - sX, 0, sZ_ - sZ })
			end
		end
		dwCurRad = dwCurRad + dwStepRad
	until dwMaxRad <= dwCurRad
end


C.OnNpcEnter = function(szEvent)
	local v = GetNpc(arg0)
	local t = C.tList[TARGET.NPC][v.dwTemplateID] or C.tList[TARGET.NPC][JH.GetTemplateName(v)]
	if t then
		C.tScrutiny[TARGET.NPC][arg0] = t
	end
end

C.OnNpcLeave = function()
	if C.tScrutiny[TARGET.NPC][arg0] then
		if C.tCache[TARGET.NPC][arg0] then
			for k, v in pairs(C.tCache[TARGET.NPC][arg0].Circle) do
				C.shCircle:RemoveItem(v)
			end
			if C.tCache[TARGET.NPC][arg0].Line and C.tCache[TARGET.NPC][arg0].Line.item then
				C.shLine:RemoveItem(C.tCache[TARGET.NPC][arg0].Line.item)
			end
			C.tCache[TARGET.NPC][arg0] = nil
		end
		C.tScrutiny[TARGET.NPC][arg0] = nil
	end
end

C.OnDoodadEnter = function()
	local v = GetDoodad(arg0)
	local t = C.tList[TARGET.DOODAD][v.dwTemplateID] or C.tList[TARGET.DOODAD][v.szName]
	if t then
		C.tScrutiny[TARGET.DOODAD][arg0] = t
	end
end

C.OnDoodadLeave = function()
	if C.tScrutiny[TARGET.DOODAD][arg0] then
		if C.tCache[TARGET.DOODAD][arg0] then
			for k, v in pairs(C.tCache[TARGET.DOODAD][arg0].Circle) do
				C.shCircle:RemoveItem(v)
			end
			if C.tCache[TARGET.DOODAD][arg0].Line and C.tCache[TARGET.DOODAD][arg0].Line.item then
				C.shLine:RemoveItem(C.tCache[TARGET.DOODAD][arg0].Line.item)
			end
			C.tCache[TARGET.DOODAD][arg0] = nil
		end
		C.tScrutiny[TARGET.DOODAD][arg0] = nil
	end
end

C.OnBreathe = function()
	-- NPC�������
	local me = GetClientPlayer()
	if not me then return end
	for k, v in pairs(C.tScrutiny[TARGET.NPC]) do
		local data = v()
		local KGNpc = GetNpc(k)
		if not C.tCache[TARGET.NPC][k] then
			C.tCache[TARGET.NPC][k] = {
				Circle = {},
				Line = {},
			}
		end
		for kk, vv in ipairs(data.tCircles) do
			local sha = C.tCache[TARGET.NPC][k].Circle
			if not sha[kk] then
				sha[kk] = C.shCircle:AppendItemFromIni(SHADOW, "shadow", k .. kk)
			end
			if sha[kk].nFaceDirection ~= KGNpc.nFaceDirection or GLOBAL_RESERT_DRAW then -- ���򲻶� �ػ�
				sha[kk].nFaceDirection = KGNpc.nFaceDirection
				C.DrawShape(KGNpc, sha[kk], vv.nAngle, vv.nRadius, vv.col, data.dwType)
			end
			if vv.bBorder then
				local key = "B" .. kk
				if not sha[key] then
					sha[key] = C.shCircle:AppendItemFromIni(SHADOW, "shadow", k .. key)
				end
				if sha[key].nFaceDirection ~= KGNpc.nFaceDirection or GLOBAL_RESERT_DRAW then -- ���򲻶� �ػ�
					sha[key].nFaceDirection = KGNpc.nFaceDirection
					C.DrawBorderCall(KGNpc, sha[key], vv.nAngle, vv.nRadius, vv.col, data.dwType)
				end
			end
			-- 
		end
		data.bTarget = true
		data.bDrawLine = true
		if data.bTarget then
			local sha = C.tCache[TARGET.NPC][k].Line
			local dwType, dwID = KGNpc.GetTarget()
			Output(sha)
			if data.bDrawLine and dwID ~= 0 and dwType == TARGET.PLAYER and not sha.item and sha.dwID ~= dwID and JH.GetTarget(dwType, dwID) then
				sha.item = sha.item or C.shLine:AppendItemFromIni(SHADOW, "shadow", k)
				sha.dwID = dwID
				local col = { 255, 255, 0 }
				if dwID == me.dwID then
					col = { 255, 0, 128 }
				end
				C.DrawLine(KGNpc, JH.GetTarget(dwType, dwID), sha.item, col, data.dwType)
			elseif (not data.bDrawLine or dwID == 0 or dwType ~= TARGET.PLAYER or not JH.GetTarget(dwType, dwID)) and sha.item then
				C.shLine:RemoveItem(sha.item)
				C.tCache[TARGET.NPC][k].Line = {}
			end			
		end
		
	end
	-- DOODAD�������
	for k, v in pairs(C.tScrutiny[TARGET.DOODAD]) do
		local data = v()
		local KGDoodad = GetDoodad(k)
		if not C.tsha[TARGET.DOODAD][k] then
			C.tsha[TARGET.DOODAD][k] = {
				Circle = {},
				Line = {},
			}
		end
		for kk, vv in ipairs(data.tCircles) do
			local sha = C.tsha[TARGET.DOODAD][k].Circle
			if not sha[kk] then
				sha[kk] = C.shCircle:AppendItemFromIni(SHADOW, "shadow", k .. kk)
			end
			if sha[kk].nFaceDirection ~= KGDoodad.nFaceDirection or GLOBAL_RESERT_DRAW then -- ���򲻶� �ػ�
				sha[kk].nFaceDirection = KGDoodad.nFaceDirection
				C.DrawShape(KGDoodad, sha[kk], vv.nAngle, vv.nRadius, vv.col, data.dwType)
			end
			if vv.bBorder then
				local key = "B" .. kk
				if not sha[key] then
					sha[key] = C.shCircle:AppendItemFromIni(SHADOW, "shadow", k .. key)
				end
				if sha[key].nFaceDirection ~= KGDoodad.nFaceDirection or GLOBAL_RESERT_DRAW then -- ���򲻶� �ػ�
					sha[key].nFaceDirection = KGDoodad.nFaceDirection
					C.DrawBorderCall(KGDoodad, sha[key], vv.nAngle, vv.nRadius, vv.col, data.dwType)
				end
			end
		end
		local sha = C.tsha[TARGET.DOODAD][k].Line
		if data.bDrawLine and not sha.item then
			sha.item = sha.item or C.shCircle:AppendItemFromIni(SHADOW, "shadow", k)
			C.DrawLine(KGNpc, me, sha.item, { 255, 128, 0 }, data.dwType)
		elseif not data.bDrawLine and sha.item then
			C.shLine:RemoveItem(sha.item)
			C.tCache[TARGET.DOODAD][k].Line = {}
		end
	end
	GLOBAL_RESERT_DRAW = false
end

C.Init = function()
	JH.RegisterInit("Circle", 
		{ "Breathe", C.OnBreathe },
		{ "NPC_ENTER_SCENE", C.OnNpcEnter },
		{ "NPC_LEAVE_SCENE", C.OnNpcLeave },
		{ "DOODAD_ENTER_SCENE", C.OnDoodadEnter },
		{ "DOODAD_LEAVE_SCENE", C.OnDoodadLeave },
		{ "LOADING_END", C.CreateData }
	)
	Circle.bEnable = true
end

C.UnInit = function()
	C.Release()
	JH.UnRegisterInit("Circle")
	Circle.bEnable = false
end

-- ע��ͷ���Ҽ��˵�
Target_AppendAddonMenu({function(dwID, dwType)
	if dwType == TARGET.NPC then
		local p = GetNpc(dwID)
		local data = C.tList[TARGET.NPC][p.dwTemplateID] or C.tList[TARGET.NPC][JH.GetTemplateName(p)]
		if data then
			return {{ szOption = _L["Edit Face"], rgb = { 255, 128, 0 }, fnAction = function() end }}
		else
			return {{ szOption = _L["Add Face"], rgb = { 255, 255, 0 }, fnAction = function()
				if IsAltKeyDown() then
					C.OpenAddPanel(p.dwTemplateID, dwType)
				else
					C.OpenAddPanel(JH.GetTemplateName(p), dwType)
				end
			end }}
		end
	else
		return {}
	end
end })

-- ReloadUIAddon()
C.OpenAddPanel = function(szName, dwType)
	if Station.Lookup("Normal/C_NewFace") then
		Wnd.CloseWindow(Station.Lookup("Normal/C_NewFace"))
	end
	dwType = dwType or TARGET.NPC
	GUI.CreateFrame("C_NewFace", { w = 380, h = 250, title = _L["Add Face"], close = true }):Close()
	-- update ui = wnd
	local ui = GUI(Station.Lookup("Normal/C_NewFace"))
	ui:Append("Text", "Name", { txt = szName or _L["Please enter key"], font = 200, w = 380, h = 30, x = 0, y = 50, align = 1 })
	ui:Append("Text", { txt = _L["Key:"], font = 27, w = 105, h = 30, x = 0, y = 80, align = 2 })
	ui:Append("WndEdit", "Key", { txt = szName or _L["Please enter key"], x = 115, y = 83, enable = szName == nil, limit = 20 })
	:Change(function(szText)
		ui:Fetch("Name"):Text(szText)
	end)
	ui:Append("Text", { txt = _L["Map:"], font = 27, w = 105, h = 30, x = 0, y = 110, align = 2 })
	ui:Append("WndEdit", "Map", { txt = Table_GetMapName(C.GetMapID()), x = 115, y = 113, limit = 20 })
	
	ui:Append("WndRadioBox", { x = 100, y = 150, txt = _L["NPC"], group = "type", checked = dwType == TARGET.NPC })
	:Enable(szName == nil):Click(function()
		dwType = TARGET.NPC
	end)
	ui:Append("WndRadioBox", { x = 180, y = 150, txt = _L["DOODAD"], group = "type", checked = dwType == TARGET.DOODAD })
	:Enable(szName == nil):Click(function()
		dwType = TARGET.DOODAD
	end)
	
	ui:Append("WndButton3", { txt = g_tStrings.STR_HOTKEY_SURE, x = 115, y = 185 })
	:Click(function()
		local map = C.tMapList[ui:Fetch("Map"):Text()]
		local key = tonumber(ui:Fetch("Key"):Text()) or ui:Fetch("Key"):Text()
		if JH.Trim(key) == "" then
			return 
		end
		if map then
			local fnAction = function()
				local data = {
					key = key, 
					dwType = dwType,
					tCircles = { GLOBAL_DEFAULT_DATA }
				}
				if not C.tData[map.id] then
					C.tData[map.id] = {}
				end
				table.insert(C.tData[map.id], data)
				C.CreateData()
				ui:Fetch("Btn_Close"):Click()
			end
			if C.tData[map.id] then
				for k, v in ipairs(C.tData[map.id]) do
					if v.key == key and v.dwType == dwType then
						JH.Confirm(_L["Data already exists, whether editor?"], function()
						end)
						return
					end
				end
			end
			if map.bDungeon then
				local n = 0
				if C.tData[map.id] then
					n = #C.tData[map.id]
				end
				if n < GLOBAL_MAP_FIX[map.id] then
					pcall(fnAction)
				else
					JH.Alert(_L("%s Unable to add more data", ui:Fetch("Map"):Text()))
				end
			else
				pcall(fnAction)
			end
		else
			JH.Alert(_L["The map does not exist"])
		end
	end)
end

JH.RegisterEvent("LOGIN_GAME", function()
	if not Circle.bEnable then return end
	C.Init()
end)
JH.RegisterEvent("GAME_EXIT", C.SaveFile)
JH.RegisterEvent("PLAYER_EXIT_GAME", C.SaveFile)
JH.RegisterEvent("FIRST_LOADING_END", C.LoadFile)
-- public

local ui = {
	OpenAddPanel = C.OpenAddPanel,
	LoadFile = C.LoadFile,
	SaveFile = C.SaveFile,
}
setmetatable(Circle, { __index = ui, __metatable = true, __newindex = function() end } )

