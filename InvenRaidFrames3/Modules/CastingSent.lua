local _G = _G
local UnitExists = _G.UnitExists
local UnitIsUnit = _G.UnitIsUnit
local GetCursorPosition = _G.GetCursorPosition
local IRF3 = _G[...]

local cx, cy, uiScale

local function showPing(member, cursor)
	IRF3.ping:ClearAllPoints()
	if cursor then
		cx, cy = GetCursorPosition()
		uiScale = UIParent:GetEffectiveScale()
		IRF3.ping:SetPoint("CENTER", nil, "BOTTOMLEFT", cx / uiScale, cy / uiScale)
		cx, cy, uiScale = nil
	else
		IRF3.ping:SetPoint("CENTER", member, 0, 0)
	end
	IRF3.ping:Show()
end

function IRF3:UNIT_SPELLCAST_SENT(unit, spell, _, target)
	if target and UnitExists(target) then
		if self.db.castingSent ~= 0 then
			if self.onEnter and self.onEnter.displayedUnit and UnitIsUnit(self.onEnter.displayedUnit, target) then
				showPing(self.onEnter, true)
			elseif self.db.castingSent == 1 then
				for member in pairs(self.visibleMembers) do
					if member.displayedUnit and UnitIsUnit(member.displayedUnit, target) then
						showPing(member)
						break
					end
				end
			end
		end
	end
end

IRF3:RegisterEvent("UNIT_SPELLCAST_SENT")
