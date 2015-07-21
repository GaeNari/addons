local _G = _G
local IRF3 = ...
IRF3 = _G[IRF3]
local eventHandler = {}

function InvenRaidFrames3Pet_OnLoad(self)
	InvenRaidFrames3Base_OnLoad(self)
	self.UpdateAll = InvenRaidFrames3Pet_UpdateAll
	tinsert(UnitPopupFrames, self.dropDown:GetName())
	CompactUnitFrame_SetMenuFunc(self, CompactUnitFrameDropDown_Initialize)
	self:RegisterEvent("UNIT_FLAGS")
end

function InvenRaidFrames3Pet_OnShow(self)
	self.unit = SecureButton_GetModifiedUnit(self)
	self.displayedUnit = self.unit
	if IRF3.db then
		if IRF3.db.usePet == 2 then
			self:RegisterEvent("UNIT_NAME_UPDATE")
			self:RegisterEvent("UNIT_CONNECTION")
			self:RegisterEvent("UNIT_HEALTH")
			self:RegisterEvent("UNIT_MAXHEALTH")
			self:RegisterEvent("UNIT_HEALTH_FREQUENT")
			self:RegisterEvent("UNIT_HEAL_PREDICTION")
			self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
			self:RegisterEvent("UNIT_POWER")
			self:RegisterEvent("UNIT_MAXPOWER")
			self:RegisterEvent("UNIT_DISPLAYPOWER")
			self:RegisterEvent("UNIT_POWER_BAR_SHOW")
			self:RegisterEvent("UNIT_POWER_BAR_HIDE")
			self:RegisterEvent("UNIT_FACTION")
			self:RegisterEvent("UNIT_AURA")
		end
		self:SetScript("OnEvent", InvenRaidFrames3Pet_OnEvent)
		if not self.ticker then
			self.ticker = C_Timer.NewTicker(0.15, function() InvenRaidFrames3Member_OnUpdate(self) end)
		end
		InvenRaidFrames3Pet_UpdateAll(self)
		IRF3:BorderUpdate()
	end
	IRF3.visibleMembers[self] = true
end

function InvenRaidFrames3Pet_OnHide(self)
	self.unit, self.displayedUnit = nil
	if IRF3.db then
		self:UnregisterEvent("UNIT_NAME_UPDATE")
		self:UnregisterEvent("UNIT_CONNECTION")
		self:UnregisterEvent("UNIT_HEALTH")
		self:UnregisterEvent("UNIT_MAXHEALTH")
		self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
		self:UnregisterEvent("UNIT_HEAL_PREDICTION")
		self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
		self:UnregisterEvent("UNIT_POWER")
		self:UnregisterEvent("UNIT_MAXPOWER")
		self:UnregisterEvent("UNIT_DISPLAYPOWER")
		self:UnregisterEvent("UNIT_POWER_BAR_SHOW")
		self:UnregisterEvent("UNIT_POWER_BAR_HIDE")
		self:UnregisterEvent("UNIT_FACTION")
		self:UnregisterEvent("UNIT_AURA")
		self:SetScript("OnEvent", nil)
		if self.ticker then
			self.ticker:Cancel()
			self.ticker = nil
		end
		InvenRaidFrames3Member_OnDragStop(self)
		IRF3:BorderUpdate()
	end
	self.lostHealth, self.hasAggro, self.isOffline, self.isAFK, self.color, self.class = 0
	IRF3.visibleMembers[self] = nil
end

function InvenRaidFrames3Pet_OnEvent(self, event, unit)
	if unit then
		if unit == self.displayedUnit then
			eventHandler[event](self)
		end
	else
		eventHandler[event](self)
	end
end

function InvenRaidFrames3Pet_UpdateAll(self)
	if IRF3.db then
		if UnitExists(self.displayedUnit or "") then
			InvenRaidFrames3Member_UpdateState(self)
			InvenRaidFrames3Member_UpdateHealth(self)
			InvenRaidFrames3Member_UpdateHealPrediction(self)
			InvenRaidFrames3Member_UpdateMaxPower(self)
			InvenRaidFrames3Member_UpdatePower(self)
			InvenRaidFrames3Member_UpdatePowerColor(self)
			InvenRaidFrames3Member_UpdateOutline(self)
			InvenRaidFrames3Member_OnUpdate2(self)
		end
	end
end

eventHandler.UNIT_HEALTH = function(self)
	InvenRaidFrames3Member_UpdateHealth(self)
	InvenRaidFrames3Member_UpdateHealPrediction(self)
	if self.optionTable.outline.type == 4 then
		InvenRaidFrames3Member_UpdateOutline(self)
	end
end
eventHandler.UNIT_MAXHEALTH = eventHandler.UNIT_HEALTH
eventHandler.UNIT_HEALTH_FREQUENT = function(self)
	InvenRaidFrames3Member_UpdateHealth(self)
end
eventHandler.UNIT_HEAL_PREDICTION = InvenRaidFrames3Member_UpdateHealPrediction
eventHandler.UNIT_ABSORB_AMOUNT_CHANGED = eventHandler.UNIT_HEAL_PREDICTION
eventHandler.UNIT_MAXPOWER = function(self)
	InvenRaidFrames3Member_UpdateMaxPower(self)
	InvenRaidFrames3Member_UpdatePower(self)
end
eventHandler.UNIT_POWER = InvenRaidFrames3Member_UpdatePower
eventHandler.UNIT_DISPLAYPOWER = function(self)
	InvenRaidFrames3Member_UpdateMaxPower(self)
	InvenRaidFrames3Member_UpdatePower(self)
	InvenRaidFrames3Member_UpdatePowerColor(self)
end
eventHandler.UNIT_POWER_BAR_SHOW = eventHandler.UNIT_DISPLAYPOWER
eventHandler.UNIT_POWER_BAR_HIDE = eventHandler.UNIT_DISPLAYPOWER
eventHandler.UNIT_NAME_UPDATE = InvenRaidFrames3Member_UpdateState
eventHandler.UNIT_CONNECTION = eventHandler.UNIT_NAME_UPDATE
eventHandler.UNIT_FLAGS = eventHandler.UNIT_NAME_UPDATE
eventHandler.UNIT_FACTION = eventHandler.UNIT_NAME_UPDATE
eventHandler.UNIT_AURA = function(self)
	if self.optionTable.outline.type == 1 then
		InvenRaidFrames3Member_UpdateOutline(self)
	end
	if self.optionTable.useDispelColor then
		InvenRaidFrames3Member_UpdateState(self)
	end
end
eventHandler.PLAYER_TARGET_CHANGED = InvenRaidFrames3Member_UpdateOutline
eventHandler.UPDATE_MOUSEOVER_UNIT = InvenRaidFrames3Member_UpdateOutline

function IRF3:UpdatePetGroup()
	local inCombat = InCombatLockdown() or UnitAffectingCombat("player")
	if self.db.usePet == 2 and not inCombat then
		if self.db.anchor:find("TOP") then
			for _, header in pairs(self.headers) do
				for _, member in pairs(header.members) do
					member.petButton:ClearAllPoints()
					member.petButton:SetPoint("TOPLEFT", member, "BOTTOMLEFT", 0, 0)
					member.petButton:SetPoint("TOPRIGHT", member, "BOTTOMRIGHT", 0, 0)
					member.petButton.powerBar:SetPoint("BOTTOMRIGHT", 0, 0)
					member.petButton.healthBar:SetPoint("TOPLEFT", 0, -1)
				end
			end
		else
			for _, header in pairs(self.headers) do
				for _, member in pairs(header.members) do
					member.petButton:ClearAllPoints()
					member.petButton:SetPoint("BOTTOMLEFT", member, "TOPLEFT", 0, 0)
					member.petButton:SetPoint("BOTTOMRIGHT", member, "TOPRIGHT", 0, 0)
					member.petButton.powerBar:SetPoint("BOTTOMRIGHT", 0, 1)
					member.petButton.healthBar:SetPoint("TOPLEFT", 0, 0)
				end
			end
		end
	end
end