local _G = _G
local select = _G.select
local tonumber = _G.tonumber
local twipe = _G.table.wipe
local tinsert = _G.table.insert
local UnitName = _G.UnitName
local UnitClass = _G.UnitClass
local UnitIsUnit = _G.UnitIsUnit
local GetRaidRosterInfo = _G.GetRaidRosterInfo
local IRF3 = _G[...]

local fontString = IRF3:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")

local function getTextWidth(text)
	fontString:SetText(text)
	return ceil(fontString:GetWidth())
end

function IRF3:UpdateFont()
	fontString:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", IRF3.db.font.file), IRF3.db.font.size, IRF3.db.font.attribute)
	fontString:SetShadowColor(0, 0, 0)
	if IRF3.db.font.shadow then
		fontString:SetShadowOffset(1, -1)
	else
		fontString:SetShadowOffset(0, 0)
	end
	fontString.arrowWidth = getTextWidth("▶")
end

local function getCuttingName(names, width)
	for i = 1, #names do
		if width >= getTextWidth(names[i]) then
			return names[i]
		end
	end
	return names[#names] or ""
end

local healthText

local function getHealthText(self)
	if IRF3.db.units.healthType == 1 then
		if IRF3.db.units.shortLostHealth then
			return ("-%.1f"):format(self.lostHealth / 1000)
		else
			return "-"..self.lostHealth
		end
	elseif IRF3.db.units.healthType == 2 then
		if IRF3.db.units.shortLostHealth then
			return ("-%d"):format(self.lostHealth / self.maxHealth * 100)
		else
			return ("-%d%%"):format(self.lostHealth / self.maxHealth * 100)
		end
	elseif IRF3.db.units.healthType == 3 then
		if IRF3.db.units.shortLostHealth then
			return ("%.1f"):format(self.health / 1000)
		else
			return self.health
		end
	elseif IRF3.db.units.healthType == 4 then
		if IRF3.db.units.shortLostHealth then
			return ("%d"):format(self.health / self.maxHealth * 100)
		else
			return ("%d%%"):format(self.health / self.maxHealth * 100)
		end
	else
		return ""
	end
end

local function getHealthText2(self)
	if not IRF3.db.units.showAbsorbHealth then
		return ""
	elseif IRF3.db.units.healthType == 1 then
		if IRF3.db.units.shortLostHealth then
			return ("+%.1f"):format(self.overAbsorb / 1000)
		else
			return "+"..self.overAbsorb
		end
	elseif IRF3.db.units.healthType == 2 then
		if IRF3.db.units.shortLostHealth then
			return ("+%d"):format(self.overAbsorb / self.maxHealth * 100)
		else
			return ("+%d%%"):format(self.overAbsorb / self.maxHealth * 100)
		end
	elseif IRF3.db.units.healthType == 3 then
		if IRF3.db.units.shortLostHealth then
			return ("+%.1f"):format(self.overAbsorb / 1000)
		else
			return self.health
		end
	elseif IRF3.db.units.healthType == 4 then
		if IRF3.db.units.shortLostHealth then
			return ("+%d"):format(self.overAbsorb / self.maxHealth * 100)
		else
			return ("+%d%%"):format(self.overAbsorb / self.maxHealth * 100)
		end
	else
		return ""
	end
end

local function checkRange(self)
	if IRF3.db.units.healthRange == 1 then
		return true
	elseif self.outRange then
		return IRF3.db.units.healthRange == 3
	else
		return IRF3.db.units.healthRange == 2
	end
end

local function getStatusText(self, bracket)
	local prefix = ""
	local postfix = ""
	local text = ""
	local width = 0
	if self.isOffline then
		prefix, postfix = "|cff9d9d9d<", ">|r"
		text = "오프"
	elseif self.isGhost then
		prefix, postfix = "|cff9d9d9d<", ">|r"
		text = "유령"
	elseif self.isDead then
		prefix, postfix = "|cffff0000<", ">|r"
		text = "죽음"
	elseif self.survivalSkill then
		text = ("<%s%s>"):format(self.survivalSkill, self.survivalSkillTimeLeft or "")
	elseif (self.lostHealth > 0 or self.overAbsorb > 0) and IRF3.db.units.healthType ~= 0 and checkRange(self) then
		if self.optionTable.healthRed then
			if self.lostHealth > 0 then
				text = "|cffff0000"..getHealthText(self).."|r"
			else
				text = "|cff00d8ff"..getHealthText2(self).."|r"
			end
		else
			text = self.lostHealth > 0 and getHealthText(self) or getHealthText2(self)
		end
	elseif self.isAFK then
		prefix, postfix = "|cff9d9d9d<", ">|r"
		text = "자리"
	else
		return "", 0
	end
	if bracket and text ~= "" then
		text = "("..text..")"
		width = getTextWidth(text)
	else
		text = prefix..text..postfix
	end
	return text, width
end

function InvenRaidFrames3Member_UpdateDisplayText(self)
	if IRF3.db.units.nameEndl then
		self.name:SetFormattedText("%s%s", (self.optionTable.useAggroArrow and self.hasAggro) and "|cffff0000▶|r" or "", getCuttingName(self.nameTable, IRF3.nameWidth - ((self.optionTable.useAggroArrow and self.hasAggro) and fontString.arrowWidth or 0)))
		InvenRaidFrames3Member_UpdateLostHealth(self)
	else
		if self.survivalSkill then
			self.name:SetFormattedText("%s%s", (self.optionTable.useAggroArrow and self.hasAggro) and "|cffff0000▶|r" or "", getStatusText(self))
		else
			local statusText, statusWidth = getStatusText(self, true)
			self.name:SetFormattedText("%s%s%s", (self.optionTable.useAggroArrow and self.hasAggro) and "|cffff0000▶|r" or "", getCuttingName(self.nameTable, IRF3.nameWidth - ((self.optionTable.useAggroArrow and self.hasAggro) and fontString.arrowWidth or 0) - statusWidth), statusText)
		end
	end
end

function InvenRaidFrames3Member_UpdateLostHealth(self)
	if IRF3.db.units.nameEndl then
		self.losttext:SetText(getStatusText(self))
	else
		InvenRaidFrames3Member_UpdateDisplayText(self)
		self.losttext:SetText("")
	end
end

local unitName, unitNameLen, prevPlayerGroup

function InvenRaidFrames3Member_UpdateName(self)
	if self.unit ~= "player" and UnitIsUnit("player", self.unit) and self:GetParent().partyTag then
		self:GetParent().partyTag.tex:SetTexture(unpack(IRF3.db.partyTagParty))
		IRF3.playerRaidIndex = self.unit:match("raid(%d+)")
		if IRF3.playerRaidIndex then
			IRF3.playerRaidIndex = tonumber(IRF3.playerRaidIndex)
			prevPlayerGroup = IRF3.playerGroup
			IRF3.playerGroup = select(3, GetRaidRosterInfo(IRF3.playerRaidIndex))
			if prevPlayerGroup and prevPlayerGroup ~= IRF3.playerGroup then
				IRF3.headers[prevPlayerGroup].partyTag.tex:SetTexture(unpack(IRF3.db.partyTagRaid))
			end
		end
	end
	unitName = (UnitName(self.unit) or UNKNOWNOBJECT):gsub(" ", "")
	if self.nameTable[1] ~= unitName then
		twipe(self.nameTable)
		unitNameLen = unitName:len()
		if unitNameLen % 3 == 0 then
			for i = unitNameLen, 3, -3 do
				tinsert(self.nameTable, unitName:sub(1, i))
			end
		else
			for i = unitNameLen, 1, -1 do
				tinsert(self.nameTable, unitName:sub(1, i))
			end
		end
	end
	self.name:SetText(unitName)
end

function InvenRaidFrames3Member_UpdateNameColor(self)
	if IRF3.db.colors[self.class] and (self.optionTable.className or (self.isOffline and self.optionTable.offlineName) or (self.outRange and self.optionTable.outRangeName) or ((self.isGhost or self.isDead) and self.optionTable.deathName)) then
		self.name:SetTextColor(IRF3.db.colors[self.class][1], IRF3.db.colors[self.class][2], IRF3.db.colors[self.class][3])
	else
		self.name:SetTextColor(IRF3.db.colors.name[1], IRF3.db.colors.name[2], IRF3.db.colors.name[3])
	end
end