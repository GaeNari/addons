local _G = _G
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local SetRaidTargetIconTexture = _G.SetRaidTargetIconTexture
local IRF3 = _G[...]
local id

local function hideIcon(icon)
	if icon:IsShown() then
		icon:SetSize(0.001, 0.001)
		icon:Hide()
	end
end

local function setRaidIcon(icon, unit)
	id = GetRaidTargetIndex(unit)
	if id and IRF3.db.units.raidIconFilter[id] then
		SetRaidTargetIconTexture(icon, id)
		icon:SetSize(IRF3.db.units.raidIconSize, IRF3.db.units.raidIconSize)
		icon:Show()
		return true
	end
	return nil
end

function InvenRaidFrames3Member_UpdateRaidIcon(self)
	if not(IRF3.db.units.useRaidIcon and IRF3.db.units.raidIconSelf and setRaidIcon(self.raidIcon1, self.displayedUnit)) then
		hideIcon(self.raidIcon1)
	end
end

function InvenRaidFrames3Member_UpdateRaidIconTarget(self)
	if not(IRF3.db.units.useRaidIcon and IRF3.db.units.raidIconTarget and setRaidIcon(self.raidIcon2, self.displayedUnit.."target")) then
		hideIcon(self.raidIcon2)
	end
end