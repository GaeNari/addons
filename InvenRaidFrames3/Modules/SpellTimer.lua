local _G = _G
local IRF3 = _G[...]
local ipairs = _G.ipairs
local UnitAura = _G.UnitAura
local usedIndex = {}
local indexSpellInfo = {}
local delimiter = ","

local numberFont = IRF3:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
local numberFontWidth = {}

local SL = IRF3.GetSpellName
local blockSpellID = {
	[SL(65148)] = 65148,--성스러운 보호막(6초 버프)
}

function IRF3:UpdateSpellTimerFont()
	for _, header in pairs(IRF3.headers) do
		for _, member in pairs(header.members) do
			for i = 1, 8 do
				local frame = member["spellTimer"..i]
				frame.count:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
				frame.count:SetShadowColor(0, 0, 0)
				frame.count:SetShadowOffset(1, -1)
				frame.timer:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
				frame.timer:SetShadowColor(0, 0, 0)
				frame.timer:SetShadowOffset(1, -1)
				frame:SetScale(InvenRaidFrames3CharDB.spellTimer[i].scale)
			end
		end
	end
	for _, member in pairs(IRF3.petHeader.members) do
		for i = 1, 8 do
			local frame = member["spellTimer"..i]
			frame.count:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
			frame.count:SetShadowColor(0, 0, 0)
			frame.count:SetShadowOffset(1, -1)
			frame.timer:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
			frame.timer:SetShadowColor(0, 0, 0)
			frame.timer:SetShadowOffset(1, -1)
			frame:SetScale(InvenRaidFrames3CharDB.spellTimer[i].scale)
		end
	end
	for i = 1, 5 do
		numberFont:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
		numberFont:SetText(strrep("0", i))
		numberFont:SetShadowColor(0, 0, 0)
		numberFont:SetShadowOffset(1, -1)
		numberFontWidth[i] = ceil(numberFont:GetWidth()) + 1
	end
end

local function onUpdateIconTimer(self, opt)
	if opt == 4 or opt == 5 then
		self.timeLeft = GetTime() - self.startTime
	else
		self.timeLeft = self.expirationTime - GetTime()
	end
	if self.timeLeft > 100 then
		if self.noIcon then
			self.timer:SetText("●")
		else
			self.timer:SetText("")
		end
	else
		self.timer:SetFormattedText("%d", self.timeLeft + 0.5)
	end
	self:SetWidth((numberFontWidth[(self.timer:GetText() or ""):len()] or 0) + (self.noIcon and 0 or 13))
end

local function setIcon(self, index, duration, expirationTime, icon, count)
	if self and index then
		if InvenRaidFrames3CharDB.spellTimer[index].display == 1 then
			-- 아이콘 + 남은 시간
			self.noIcon = nil
			self.noLeft = nil
			self.icon:SetWidth(13)
			self.icon:SetTexture(icon)
			self.count:SetText(count and count > 1 and count or "")
		elseif InvenRaidFrames3CharDB.spellTimer[index].display == 2 then
			-- 아이콘
			self.noIcon = nil
			self:SetWidth(13)
			self.icon:SetWidth(13)
			self.icon:SetTexture(icon)
			self.count:SetText(count and count > 1 and count or "")
			duration = nil
		elseif InvenRaidFrames3CharDB.spellTimer[index].display == 3 then
			-- 남은 시간
			self.noIcon = true
			self.icon:SetWidth(0.001)
			self.icon:SetTexture(nil)
			self.count:SetText(nil)
		elseif InvenRaidFrames3CharDB.spellTimer[index].display == 4 then
			-- 아이콘 + 경과 시간
			self.noIcon = nil
			self.icon:SetWidth(13)
			self.icon:SetTexture(icon)
			self.count:SetText(count and count > 1 and count or "")
		else
			-- 경과 시간
			self.noIcon = true
			self.noLeft = true
			self.icon:SetWidth(0.001)
			self.icon:SetTexture(nil)
			self.count:SetText(nil)
		end
		if duration and duration > 0 and expirationTime then
			self.startTime = expirationTime - duration
			self.expirationTime = expirationTime
			if not self.ticker then
				self.ticker = C_Timer.NewTicker(0.1, function() onUpdateIconTimer(self, InvenRaidFrames3CharDB.spellTimer[index].display) end)
			end
			onUpdateIconTimer(self, InvenRaidFrames3CharDB.spellTimer[index].display)
		else
			if self.ticker then
				self.ticker:Cancel()
				self.ticker = nil
			end
			self.expirationTime, self.timeLeft = nil, nil
			if self.noIcon then
				self.timer:SetText("●")
			else
				self.timer:SetText("")
			end
		end
		self:Show()
	elseif self and self:IsShown() then
		if self.ticker then
			self.ticker:Cancel()
			self.ticker = nil
		end
		self.expirationTime, self.timeLeft, self.noIcon = nil
		self:Hide()
	end
end

function InvenRaidFrames3Member_UpdateSpellTimer(self)
	for _, index in ipairs(usedIndex) do
		local found
		for _, spell in ipairs(indexSpellInfo[index]) do
			local spellname = spell[1]
			local filter = spell[2]
			local filterNum = spell[3]
			local name, _, icon, count, _, duration, expirationTime, unitCaster, _, _, spellId = UnitAura(self.displayedUnit, spellname, nil, filter)
			if name and (filterNum == 1 or filterNum == 2) and unitCaster ~= "player" then -- fix 6.0 UnitAura bug.
			elseif name and blockSpellID[name] then
				for i = 1, 40 do
					local name2, _, icon2, count2, _, duration2, expirationTime2, _, _, _, spellId2 = UnitAura(self.displayedUnit, i , filter)
					if name2 and name2 == spellname and spellId2 ~= blockSpellID[name2] then
						found = true
						setIcon(self["spellTimer"..index], index, duration2, expirationTime2, icon2, count2)
						break
					end
				end
			elseif name then
				found = true
				setIcon(self["spellTimer"..index], index, duration, expirationTime, icon, count)
				break
			end
		end
		if not found then
			setIcon(self["spellTimer"..index])
		end
	end
end

local pos = { "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT", "LEFT", "RIGHT", "TOPLEFT", "TOP", "TOPRIGHT" }
local filter = { "HELPFUL|PLAYER", "HARMFUL|PLAYER", "HELPFUL", "HARMFUL" }
local SL = IRF3.GetSpellName

function IRF3:BuildSpellTimerList()
	table.wipe(usedIndex)
	table.wipe(indexSpellInfo)
	for i = 1, 8 do
		if filter[InvenRaidFrames3CharDB.spellTimer[i].use] and InvenRaidFrames3CharDB.spellTimer[i].name then
			table.insert(usedIndex, i)
			local spells = {}
			spells[1], spells[2], spells[3], spells[4], spells[5] = delimiter:split(InvenRaidFrames3CharDB.spellTimer[i].name)
			indexSpellInfo[i] = {}
			for _, spell in ipairs(spells) do
				local info = {spell:trim(), filter[InvenRaidFrames3CharDB.spellTimer[i].use], InvenRaidFrames3CharDB.spellTimer[i].use}
				table.insert(indexSpellInfo[i], info)
			end
		end
	end
end

function IRF3:SetupSpellTimer(reset)
	if not reset and InvenRaidFrames3CharDB.spellTimer and #InvenRaidFrames3CharDB.spellTimer == 8 then return end
	InvenRaidFrames3CharDB.spellTimer = InvenRaidFrames3CharDB.spellTimer or {}
	for i = 1, 8 do
		InvenRaidFrames3CharDB.spellTimer[i] = InvenRaidFrames3CharDB.spellTimer[i] or {}
		InvenRaidFrames3CharDB.spellTimer[i].use = 0		-- 1:내가 시전한 버프 2:내가 시전한 디버프 3:모든 버프 4:모든 디버프 0:사용 안함
		InvenRaidFrames3CharDB.spellTimer[i].display = 1	-- 1:아이콘 + 남은 시간 2:아이콘 3:남은 시간 4:아이콘 + 경과 시간 5:경과 시간
		InvenRaidFrames3CharDB.spellTimer[i].scale = 1
		InvenRaidFrames3CharDB.spellTimer[i].pos = pos[i]
	end
	if self.playerClass == "ROGUE" then
		InvenRaidFrames3CharDB.spellTimer[1].use = 1
		InvenRaidFrames3CharDB.spellTimer[1].name = SL(57934)	-- 속임수 거래
	elseif self.playerClass == "PRIEST" then
		InvenRaidFrames3CharDB.spellTimer[1].use = 1
		InvenRaidFrames3CharDB.spellTimer[1].name = SL(139)	-- 소생
		InvenRaidFrames3CharDB.spellTimer[2].use = 1
		InvenRaidFrames3CharDB.spellTimer[2].name = SL(33076)	-- 회복의 기원
		InvenRaidFrames3CharDB.spellTimer[3].use = 4
		InvenRaidFrames3CharDB.spellTimer[3].name = SL(6788)	-- 약화된 영혼
		InvenRaidFrames3CharDB.spellTimer[4].use = 3
		InvenRaidFrames3CharDB.spellTimer[4].name = SL(17)	-- 신의 권능: 보호막
		InvenRaidFrames3CharDB.spellTimer[5].use = 1
		InvenRaidFrames3CharDB.spellTimer[5].name = SL(152118)	-- 의지의 명료함
	elseif self.playerClass == "HUNTER" then
		InvenRaidFrames3CharDB.spellTimer[1].use = 1
		InvenRaidFrames3CharDB.spellTimer[1].name = SL(34477)	-- 눈속임
	elseif self.playerClass == "DRUID" then
		InvenRaidFrames3CharDB.spellTimer[1].use = 1
		InvenRaidFrames3CharDB.spellTimer[1].name = SL(33763)	-- 피어나는 생명
		InvenRaidFrames3CharDB.spellTimer[2].use = 1
		InvenRaidFrames3CharDB.spellTimer[2].name = SL(774)	-- 회복
		InvenRaidFrames3CharDB.spellTimer[3].use = 1
		InvenRaidFrames3CharDB.spellTimer[3].name = SL(8936)	-- 재생
		InvenRaidFrames3CharDB.spellTimer[4].use = 1
		InvenRaidFrames3CharDB.spellTimer[4].name = SL(48438)	-- 급속 성장
	elseif self.playerClass == "SHAMAN" then
		InvenRaidFrames3CharDB.spellTimer[1].use = 1
		InvenRaidFrames3CharDB.spellTimer[1].name = SL(61295)	-- 성난 해일
		InvenRaidFrames3CharDB.spellTimer[2].use = 1
		InvenRaidFrames3CharDB.spellTimer[2].name = SL(52127)..","..SL(324)	-- 물의 보호막, 번개 보호막
		InvenRaidFrames3CharDB.spellTimer[3].use = 1
		InvenRaidFrames3CharDB.spellTimer[3].name = SL(974)	-- 대지의 보호막
	elseif self.playerClass == "PALADIN" then
		InvenRaidFrames3CharDB.spellTimer[1].use = 3
		InvenRaidFrames3CharDB.spellTimer[1].name = SL(53563)..","..SL(156910)	-- 빛의 봉화, 신념의 봉화
		InvenRaidFrames3CharDB.spellTimer[2].use = 1
		InvenRaidFrames3CharDB.spellTimer[2].name = SL(1022)..","..SL(1044)..","..SL(6940)..","..SL(1038)	-- 보호의 손길, 자유의 손길, 희생의 손길, 구원의 손길
	elseif self.playerClass == "MONK" then
		InvenRaidFrames3CharDB.spellTimer[1].use = 1
		InvenRaidFrames3CharDB.spellTimer[1].name = SL(124682)	-- 포용의 안개
		InvenRaidFrames3CharDB.spellTimer[2].use = 1
		InvenRaidFrames3CharDB.spellTimer[2].name = SL(115151)	-- 소생의 안개
	end
end
