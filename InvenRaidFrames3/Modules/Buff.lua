local _G = _G

local next = _G.next
local pairs = _G.pairs
local ipairs = _G.ipairs
local select = _G.select
local tinsert = _G.table.insert
local wipe = _G.wipe
local UnitBuff = _G.UnitBuff
local GetSpellInfo = _G.GetSpellInfo
local IsSpellKnown = _G.IsSpellKnown
local UnitIsPlayer = _G.UnitIsPlayer
local UnitInVehicle = _G.UnitInVehicle
local IRF3 = _G[...]

IRF3.raidBuffData = {}

function InvenRaidFrames3Member_UpdateBuffs()

end

function IRF3:SetupClassBuff()
	self.SetupClassBuff = nil
	InvenRaidFrames3CharDB.classBuff, InvenRaidFrames3CharDB.classBuff2 = nil, type(InvenRaidFrames3CharDB.classBuff2) == "table" and InvenRaidFrames3CharDB.classBuff2 or {}
end

local playerClass = select(2, UnitClass("player"))

local classRaidBuffs = ({
	WARRIOR = {
		[469] = { 2 },			-- 지휘의 외침
		[6673] = { 3 },		-- 전투의 외침
	},
	ROGUE = {
		[113742] = { 4, 8 },	-- 스위프트블레이드의 간교함
	},
	PRIEST = {
		[21562] = { 2 },		-- 신의 권능: 인내
		[49868] = { 4, 8 },		-- 사고 촉진
	},
	MAGE = {
		[1459] = { 5, 6 },		-- 신비한 총명함
	},
	WARLOCK = {
		[166928] = { 2 },		-- 피의 서약
		[109773] = { 5, 8 },	-- 검은 의도
	},
	HUNTER = {
		[19506] = { 3 },		-- 정조준 오라
	},
	DRUID = {
		[1126] = { 1, 9 },		-- 야생의 징표
		[17007] = { 6 },		-- 무리의 우두머리
	},
	SHAMAN = {
		[116956] = { 4, 7 },	-- 바람의 은총
	},
	PALADIN = {
		[20217] = { 1 },		-- 왕의 축복
		[19740] = { 7 },		-- 힘의 축복
		[167187] = { 9 },		-- 선성한 오라
	},
	DEATHKNIGHT = {
		[57330] = { 3 },		-- 겨울의 뿔피리
		[55610] = { 4, 9 },		-- 부정의 오라
	},
	MONK = {
		[115921] = { 1 },		-- 황제의 유산
		[116781] = { 1, 6 },	-- 백호의 유산
		[166916] = { 8 },		-- 성난바람
	},
})[playerClass]

if not classRaidBuffs then return end

local raidBuffs = {
	-- 능력치
	[1] = {
		1126,	-- [드루이드] 야생의 징표
		20217,	-- [성기사] 왕의 축복
		116781,	-- [수도사] 백호의 유산
		115921,	-- [수도사] 황제의 유산
		160206,	-- [사냥꾼] 고독한 늑대: 야생의 힘
		90363,	-- [Pet] Embrace of the Shale Spider
		159988,	-- [Pet] Bark of the Wild
		160017,	-- [Pet] Blessing of Kongs
		160077,	-- [Pet] Strength of the Earth
	},
	-- 체력
	[2] = {
		21562,	-- [사제] 신의 권능: 인내
		469,		-- [전사] 지휘의 외침
		166928,	-- [흑마법사] 피의 서약
		160199,	-- [사냥꾼] 고독한 늑대: 곰의 인내력
		50256,	-- [Pet] Invigorating Roar
		90364,	-- [Pet] Qiraji Fortitude
	},
	-- 전투력
	[3] = {
		19506,	-- [사냥꾼] 정조준 오라
		6673,	-- [전사] 전투의 외침
		57330,	-- [죽음의 기사] 겨울의 뿔피리
	},
	-- 가속
	[4] = {
		113742,	-- [도적] 스위프트블레이드의 간교함
		49868,	-- [사제] 사고 촉진
		160203,	-- [사냥꾼] 고독한 늑대: 하이에나의 날렵함
		116956,	-- [주술사] 바람의 은총
		55610,	-- [죽음의 기사] 부정의 오라
		128432,	-- [Pet] Cackling Howl
		135678,	-- [Pet] Energizing Spores
		160074,	-- [Pet] Speed of the Swarm
	},
	-- 주문력
	[5] = {
		1459,	-- [마법사] 신비한 총명함
		61316,	-- [마법사] 달라란의 총명함
		109773,	-- [흑마법사] 검은 의도
		160205,	-- [사냥꾼] 고독한 늑대: 독사의 지혜
		90309,	-- [Pet] Terrifying Roar
		90364,	-- [Pet] Qiraji Fortitude
		128433,	-- [Pet] Serpent's Cunning
		126309,	-- [Pet] Still Water
	},
	-- 치명타 및 극대화
	[6] = {
		1459,	-- [마법사] 신비한 총명함
		61316,	-- [마법사] 달라란의 총명함
		160200,	-- [사냥꾼] 고독한 늑대: 랩터의 흉포함
		17007,	-- [드루이드] 무리의 우두머리
		116781,	-- [수도사] 백호의 유산
		24604,	-- [Pet] Furious Howl
		90363,	-- [Pet] Embrace of the Shale Spider
		126309,	-- [Pet] Still Water
		126373,	-- [Pet] Fearless Roar
		160052,	-- [Pet] Strength of the Pack
	},
	-- 특화
	[7] = {
		160198,	-- [사냥꾼] 고독한 늑대: 표범의 은총
		116956,	-- [주술사] 바람의 은총
		19740,	-- [성기사] 힘의 축복
		93435,	-- [Pet] Roar of Courage
		128997,	-- [Pet] Spirit Beast Blessing
		160073,	-- [Pet] Plainswalking
	},
	-- 연속타격
	[8] = {
		113742,	-- [도적] 스위프트블레이드의 간교함
		49868,	-- [사제] 사고 촉진
		109773,	-- [흑마법사] 검은 의도
		166916,	-- [수도사] 성난바람
		24844,	-- [Pet] Breath of the Winds
		34889,	-- [Pet] Spry Attacks
		57386,	-- [Pet] Wild Strength
		58604,	-- [Pet] Double Bite
	},
	-- 유연성
	[9] = {
		1126,	-- [드루이드] 야생의 징표
		167187,	-- [성기사] 선성한 오라
		55610,	-- [죽음의 기사] 부정의 오라
		35290,	-- [Pet] Indomitable
		50518,	-- [Pet] Chitinous Armor
		57386,	-- [Pet] Wild Strength
		159735,	-- [Pet] Tenacity
		160077,	-- [Pet] Strength of the Earth
	},
}

local sameBuffs = {
	[1459] = 61316,	-- 신비한 총명함 = 달라란의 총명함
}

IRF3.raidBuffData = {
	same = sameBuffs,
	link = {
		[469] = 6673,		-- 지휘의 외침 = 전투의 외침
		[20217] = 19740,	-- 왕의 축복 = 힘의 축복
	},
}

local linkRaidBuffs = {}

local raidBuffInfo = {}

local function addRaidBuff(tbl, spellId, isClassBuff)
	local spellName, spellRank, spellIcon = GetSpellInfo(spellId)
	if spellName then
		if isClassBuff then
			for _, v in ipairs(tbl) do
				if v.id == spellId then
					return true
				end
			end
		end
		tinsert(tbl, {
			id = spellId,
			name = spellName,
			rank = spellRank,
			icon = spellIcon,
			passive = IsPassiveSpell(spellId)
		})
		raidBuffInfo[spellId] = tbl[#tbl]
		return true
	end
	return nil
end

for i, spellIds in pairs(raidBuffs) do
	local n = {}
	for _, spellId in ipairs(spellIds) do
		addRaidBuff(n, spellId)
	end
	raidBuffs[i] = n
end

for spellId, mask in pairs(classRaidBuffs) do
	for _, i in ipairs(mask) do
		if #raidBuffs[i] > 0 and addRaidBuff(raidBuffs[i], spellId, true) and not raidBuffInfo[spellId].passive then
			if sameBuffs[spellId] then
				addRaidBuff(raidBuffs[i], sameBuffs[spellId], true)
			end
		else
			classRaidBuffs[spellId] = nil
			sameBuffs[spellId] = nil
			break
		end
	end
end

if not next(classRaidBuffs) then return end

local currentRaidBuffs, checkMask, buffCnt, buff, buff2 = {}, {}, 0

local function showBuffIcon(icon, texture)
	icon:SetSize(IRF3.db.units.buffIconSize, IRF3.db.units.buffIconSize)
	icon:SetTexture(texture)
	icon:Show()
end

local function hideBuffIcon(icon)
	icon:SetSize(0.001, 0.001)
	icon:Hide()
end

local function getBuff(unit, spellId)
	if UnitBuff(unit, raidBuffInfo[spellId].name, raidBuffInfo[spellId].rank) then
		for _, i in ipairs(classRaidBuffs[spellId]) do
			checkMask[i] = raidBuffInfo[spellId]
		end
	elseif sameBuffs[spellId] and UnitBuff(unit, raidBuffInfo[sameBuffs[spellId]].name, raidBuffInfo[sameBuffs[spellId]].rank) then
		for _, i in ipairs(classRaidBuffs[spellId]) do
			checkMask[i] = raidBuffInfo[sameBuffs[spellId]]
		end
	else
		for _, i in ipairs(classRaidBuffs[spellId]) do
			if checkMask[i] == nil then
				checkMask[i] = false
				for _, v in ipairs(raidBuffs[i]) do
					if UnitBuff(unit, v.name, v.rank) then
						checkMask[i] = v
						break
					end
				end
				if checkMask[i] == false then
					spellId = nil
					break
				end
			elseif checkMask[i] == false then
				spellId = nil
				break
			end
		end
	end
	return spellId
end

InvenRaidFrames3Member_UpdateBuffs = function(self)
	if not UnitIsPlayer(self.displayedUnit) or UnitInVehicle(self.displayedUnit) then 
		hideBuffIcon(self["buffIcon1"])
		hideBuffIcon(self["buffIcon2"])
		return 
	end
	wipe(checkMask)
	buffCnt = 0
	for spellId in pairs(currentRaidBuffs) do
		buff = getBuff(self.displayedUnit, spellId)
		if InvenRaidFrames3CharDB.classBuff2[spellId] == 1 then
			-- 버프가 없을 때 표시
			if not buff then
				buffCnt = buffCnt + 1
				showBuffIcon(self["buffIcon"..buffCnt], raidBuffInfo[spellId].icon)
			end
		elseif InvenRaidFrames3CharDB.classBuff2[spellId] == 2 then
			-- 버프가 있을 때 표시
			if buff then
				buffCnt = buffCnt + 1
				showBuffIcon(self["buffIcon"..buffCnt], raidBuffInfo[spellId].icon)
			end
		end
		if buffCnt == 2 then return end
	end
	for a, b in pairs(linkRaidBuffs) do
		buff = UnitBuff(self.displayedUnit, raidBuffInfo[a].name, raidBuffInfo[a].rank, "PLAYER")
		buff2 = not buff and UnitBuff(self.displayedUnit, raidBuffInfo[b].name, raidBuffInfo[b].rank, "PLAYER") or nil
		if InvenRaidFrames3CharDB.classBuff2[b] == 1 then
			-- 버프가 없을 때 표시
			if not buff and not buff2 then
				buff = getBuff(self.displayedUnit, a)
				buff2 = getBuff(self.displayedUnit, b)
				if not buff and not buff2 then
					buffCnt = buffCnt + 1
					showBuffIcon(self["buffIcon"..buffCnt], raidBuffInfo[a].icon)
					if buffCnt == 1 then
						buffCnt = buffCnt + 1
						showBuffIcon(self["buffIcon"..buffCnt], raidBuffInfo[b].icon)
						return
					end
				elseif not buff then
					buffCnt = buffCnt + 1
					showBuffIcon(self["buffIcon"..buffCnt], raidBuffInfo[a].icon)
				elseif not buff2 then
					buffCnt = buffCnt + 1
					showBuffIcon(self["buffIcon"..buffCnt], raidBuffInfo[b].icon)
				end
			end
		elseif InvenRaidFrames3CharDB.classBuff2[b] == 2 then
			-- 버프가 있을 때 표시
			if buff then
				buffCnt = buffCnt + 1
				showBuffIcon(self["buffIcon"..buffCnt], raidBuffInfo[a].icon)
			elseif buff2 then
				buffCnt = buffCnt + 1
				showBuffIcon(self["buffIcon"..buffCnt], raidBuffInfo[b].icon)
			end
		end
		if buffCnt == 2 then return end
	end
	for i = buffCnt + 1, 2 do
		hideBuffIcon(self["buffIcon"..i])
	end
end

local function updateClassBuff()
	wipe(currentRaidBuffs)
	wipe(linkRaidBuffs)
	for spellId, mask in pairs(classRaidBuffs) do
		if IsSpellKnown(spellId) then
			currentRaidBuffs[spellId] = mask
		end
	end
	for a, b in pairs(IRF3.raidBuffData.link) do
		if currentRaidBuffs[a] and currentRaidBuffs[b] then
			linkRaidBuffs[a] = b
			currentRaidBuffs[a] = nil
			currentRaidBuffs[b] = nil
		end
	end
	if not IRF3.SetupClassBuff then
		for _, header in pairs(IRF3.headers) do
			for _, member in pairs(header.members) do
				if member:IsVisible() then
					InvenRaidFrames3Member_UpdateBuffs(member)
				end
			end
		end
	end
end

local handler = CreateFrame("Frame")
handler:SetScript("OnEvent", updateClassBuff)
handler:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
handler:RegisterEvent("PLAYER_TALENT_UPDATE")
handler:RegisterEvent("PLAYER_ENTERING_WORLD")
handler:RegisterEvent("LEARNED_SPELL_IN_TAB")

function IRF3:SetupClassBuff()
	self.SetupClassBuff = nil
	InvenRaidFrames3CharDB.classBuff = nil
	InvenRaidFrames3CharDB.classBuff2 = type(InvenRaidFrames3CharDB.classBuff2) == "table" and InvenRaidFrames3CharDB.classBuff2 or {}
	for spellId in pairs(InvenRaidFrames3CharDB.classBuff2) do
		if not classRaidBuffs[spellId] then
			InvenRaidFrames3CharDB.classBuff2[spellId] = nil
		end
	end
	for spellId in pairs(classRaidBuffs) do
		if raidBuffInfo[spellId].passive then
			InvenRaidFrames3CharDB.classBuff2[spellId] = nil
		elseif InvenRaidFrames3CharDB.classBuff2[spellId] ~= 0 and InvenRaidFrames3CharDB.classBuff2[spellId] ~= 1 and InvenRaidFrames3CharDB.classBuff2[spellId] ~= 2 then
			InvenRaidFrames3CharDB.classBuff2[spellId] = 1
		end
	end
	updateClassBuff()
end