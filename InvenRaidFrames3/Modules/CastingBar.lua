local _G = _G
local GetTime = _G.GetTime
local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local IRF3 = _G[...]

function InvenRaidFrames3Member_SetupCastingBarPos(self)
	if IRF3.db.units.castingBarPos == 1 then
		self.castingBar:SetPoint("TOPLEFT", 0, 0)
		self.castingBar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -IRF3.db.units.castingBarHeight)
		self.castingBar:SetOrientation("HORIZONTAL")
	elseif IRF3.db.units.castingBarPos == 2 then
		self.castingBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, IRF3.db.units.castingBarHeight)
		self.castingBar:SetPoint("BOTTOMRIGHT", 0, 0)
		self.castingBar:SetOrientation("HORIZONTAL")
	elseif IRF3.db.units.castingBarPos == 3 then
		self.castingBar:SetPoint("TOPLEFT", 0, 0)
		self.castingBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", IRF3.db.units.castingBarHeight, 0)
		self.castingBar:SetOrientation("VERTICAL")
	elseif IRF3.db.units.castingBarPos == 4 then
		self.castingBar:SetPoint("TOPLEFT", self, "TOPRIGHT", -IRF3.db.units.castingBarHeight, 0)
		self.castingBar:SetPoint("BOTTOMRIGHT", 0, 0)
		self.castingBar:SetOrientation("VERTICAL")
	else
		self.castingBar:Hide()
	end
end

function InvenRaidFrames3Member_CastingBarOnUpdate(self)
	self:SetValue(self.isChannel and (self.endTime - GetTime() + self.startTime) or GetTime())
end

function InvenRaidFrames3Member_UpdateCastingBar(self)
	if IRF3.db.units.useCastingBar then
		self.castingBar.startTime, self.castingBar.endTime = select(5, UnitCastingInfo(self.displayedUnit))
		if self.castingBar.startTime then
			self.castingBar.startTime, self.castingBar.endTime, self.castingBar.isChannel = self.castingBar.startTime / 1000, self.castingBar.endTime / 1000
			self.castingBar:SetMinMaxValues(self.castingBar.startTime, self.castingBar.endTime)
			if not self.castingBar.ticker then
				self.castingBar.ticker = C_Timer.NewTicker(0.02, function() InvenRaidFrames3Member_CastingBarOnUpdate(self.castingBar) end)
			end
			InvenRaidFrames3Member_CastingBarOnUpdate(self.castingBar)
			return self.castingBar:Show()
		else
			self.castingBar.startTime, self.castingBar.endTime = select(5, UnitChannelInfo(self.displayedUnit))
			if self.castingBar.startTime then
				self.castingBar.startTime, self.castingBar.endTime, self.castingBar.isChannel = self.castingBar.startTime / 1000, self.castingBar.endTime / 1000, true
				self.castingBar:SetMinMaxValues(self.castingBar.startTime, self.castingBar.endTime)
				if not self.castingBar.ticker then
					self.castingBar.ticker = C_Timer.NewTicker(0.02, function() InvenRaidFrames3Member_CastingBarOnUpdate(self.castingBar) end)
				end
				InvenRaidFrames3Member_CastingBarOnUpdate(self.castingBar)
				return self.castingBar:Show()
			end
		end
	end
	if self.castingBar.ticker then
		self.castingBar.ticker:Cancel()
		self.castingBar.ticker = nil
	end
	self.castingBar.startTime, self.castingBar.endTime, self.castingBar.isChannel = nil
	self.castingBar:Hide()
end
