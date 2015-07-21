local _G = _G
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitAlternatePowerInfo = _G.UnitAlternatePowerInfo
local UnitAlternatePowerTextureInfo = _G.UnitAlternatePowerTextureInfo
local IRF3 = _G[...]

function InvenRaidFrames3Member_SetupPowerBarAltPos(self)
	if self.powerBarAlt then
		if IRF3.db.units.powerBarAltPos == 1 then
			self.powerBarAlt:SetPoint("TOPLEFT", 0, 0)
			self.powerBarAlt:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -IRF3.db.units.powerBarAltHeight)
			self.powerBarAlt:SetOrientation("HORIZONTAL")
		elseif IRF3.db.units.powerBarAltPos == 2 then
			self.powerBarAlt:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, IRF3.db.units.powerBarAltHeight)
			self.powerBarAlt:SetPoint("BOTTOMRIGHT", 0, 0)
			self.powerBarAlt:SetOrientation("HORIZONTAL")
		elseif IRF3.db.units.powerBarAltPos == 3 then
			self.powerBarAlt:SetPoint("TOPLEFT", 0, 0)
			self.powerBarAlt:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", IRF3.db.units.powerBarAltHeight, 0)
			self.powerBarAlt:SetOrientation("VERTICAL")
		elseif IRF3.db.units.powerBarAltPos == 4 then
			self.powerBarAlt:SetPoint("TOPLEFT", self, "TOPRIGHT", -IRF3.db.units.powerBarAltHeight, 0)
			self.powerBarAlt:SetPoint("BOTTOMRIGHT", 0, 0)
			self.powerBarAlt:SetOrientation("VERTICAL")
		else
			self.powerBarAlt:Hide()
		end
	end
end

local barType, minPower

function InvenRaidFrames3Member_UpdatePowerBarAlt(self)
	if self.powerBarAlt then
		if IRF3.db.units.usePowerBarAlt then
			barType, minPower = UnitAlternatePowerInfo(self.displayedUnit)
			if barType then
				minPower = minPower or 0
				self.powerBarAlt.r, self.powerBarAlt.g, self.powerBarAlt.b = select(2, UnitAlternatePowerTextureInfo(self.displayedUnit, 2))
				if not self.powerBarAlt.r then
					self.powerBarAlt.r, self.powerBarAlt.g, self.powerBarAlt.b = 1, 0, 1
				end
				self.powerBarAlt:SetStatusBarColor(self.powerBarAlt.r, self.powerBarAlt.g, self.powerBarAlt.b)
				self.powerBarAlt:SetMinMaxValues(0, UnitPowerMax(self.displayedUnit, ALTERNATE_POWER_INDEX) - minPower)
				self.powerBarAlt:SetValue(UnitPower(self.displayedUnit, ALTERNATE_POWER_INDEX) - minPower)
				self.powerBarAlt:Show()
			else
				self.powerBarAlt:Hide()
			end
		else
			self.powerBarAlt:Hide()
		end
	end
end