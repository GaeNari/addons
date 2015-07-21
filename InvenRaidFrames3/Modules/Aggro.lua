local _G = _G
local IRF3 = _G[...]
local UnitThreatSituation = _G.UnitThreatSituation
local GetNumGroupMembers = _G.GetNumGroupMembers
local GetNumSubgroupMembers = _G.GetNumSubgroupMembers
local PlaySoundFile = _G.PlaySoundFile
local SM = LibStub("LibSharedMedia-3.0")

local aggroUnits = {}

local function hasAggro(unit)
	return (UnitThreatSituation(unit) or 0) > 1
end

function InvenRaidFrames3Member_UpdateThreat(self)
	self.hasAggro = hasAggro(self.displayedUnit) or aggroUnits[self]
end

local aggro = CreateFrame("Frame", nil, IRF3)
aggro.timer, aggro.check1 = 0, false
aggro:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
aggro:SetScript("OnEvent", function(self, event, unit)
	if unit == "player" and IRF3.db then
		self.check1, self.check2 = hasAggro(unit), self.check2
		if IRF3.db.units.aggroType == 2 then
			self.trigger = true
		elseif IRF3.db.units.aggroType == 3 then
			self.trigger = IsInGroup()
		elseif IRF3.db.units.aggroType == 4 then
			self.trigger = IsInRaid()
		else
			self.trigger = nil
		end
		if self.trigger and self.check1 ~= self.check2 then
			if self.check1 then
				if IRF3.db.units.aggroGain ~= "None" then
					PlaySoundFile(SM:Fetch("sound", IRF3.db.units.aggroGain))
				end
			elseif IRF3.db.units.aggroLost ~= "None" then
				PlaySoundFile(SM:Fetch("sound", IRF3.db.units.aggroLost))
			end
		end
	end
end)